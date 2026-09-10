import 'dart:async';
import 'dart:io';

import 'package:audio_service/audio_service.dart';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:kosh/player/artwork_service.dart';
import 'package:kosh/player/song.dart';
import 'package:path_provider/path_provider.dart';

class KoshAudioHandler extends BaseAudioHandler with QueueHandler, SeekHandler {
  KoshAudioHandler() {
    _subscriptions.add(
      _player.playbackEventStream.listen(
        (event) {
          _publishPlaybackState(event);
        },
        onError: (Object error, StackTrace stackTrace) {
          debugPrint('Playback error: $error');
          debugPrintStack(stackTrace: stackTrace);
        },
      ),
    );

    _subscriptions.add(
      _player.currentIndexStream.distinct().listen((index) {
        if (_loadingQueue || index == null) return;
        _publishCurrentItem(index);
      }),
    );

    _subscriptions.add(
      _player.durationStream.distinct().listen((duration) {
        if (duration == null || duration <= Duration.zero) return;
        _publishResolvedDuration(duration);
      }),
    );
  }

  final AudioPlayer _player = AudioPlayer();
  final List<StreamSubscription<dynamic>> _subscriptions = [];

  final Map<String, Uri?> _artworkUriCache = {};
  Future<Directory>? _artworkDirectoryFuture;

  List<Song> _songs = const [];
  List<MediaItem> _mediaItems = const [];

  bool _loadingQueue = false;
  int _loadId = 0;

  PlaybackState _lastPlaybackState = PlaybackState();

  // ---------------------------------------------------------------------------
  // AUTHORITATIVE SNAPSHOT GETTERS
  // ---------------------------------------------------------------------------

  MediaItem? get currentItem => mediaItem.valueOrNull;
  PlaybackState get currentPlaybackState => _lastPlaybackState;

  int? get currentIndex => _player.currentIndex;
  Duration get currentPosition => _player.position;
  Duration? get currentDuration => _player.duration;
  Duration get currentBufferedPosition => _player.bufferedPosition;
  bool get playing => _player.playing;
  ProcessingState get processingState => _player.processingState;

  MediaItem? mediaItemAt(int index) {
    if (index < 0 || index >= _mediaItems.length) return null;
    return _mediaItems[index];
  }

  // Foreground UI clock streams.
  //
  // audio_service PlaybackState is a state snapshot used by system clients.
  // It is NOT intended to rebuild a Flutter seek bar every few hundred
  // milliseconds. The UI should consume just_audio's live streams directly
  // through the handler, while the handler remains the sole owner of AudioPlayer.
  Stream<Duration> get positionStream => _player.positionStream;
  Stream<Duration?> get durationStream => _player.durationStream;
  Stream<Duration> get bufferedPositionStream => _player.bufferedPositionStream;

  // ---------------------------------------------------------------------------
  // QUEUE LOADING
  // ---------------------------------------------------------------------------

  Future<void> loadQueue(List<Song> songs, int startIndex) async {
    if (songs.isEmpty) return;
    if (startIndex < 0 || startIndex >= songs.length) return;

    final loadId = ++_loadId;
    _loadingQueue = true;

    try {
      final immutableSongs = List<Song>.unmodifiable(songs);

      // Fast path: metadata + audio sources only. Never block playback on
      // artwork extraction/file I/O for the entire queue.
      final prepared = [for (final song in immutableSongs) _prepareTrack(song)];

      if (loadId != _loadId) return;

      _songs = immutableSongs;
      _mediaItems = List<MediaItem>.unmodifiable([for (final track in prepared) track.mediaItem]);

      final sources = [for (final track in prepared) track.source];

      queue.add(_mediaItems);

      // Publish selected metadata immediately so both Kosh and system clients
      // have the new title/artist before the decoder finishes preparing.
      mediaItem.add(_mediaItems[startIndex]);

      // Artwork is an independent concern. Warm it concurrently, prioritising
      // current/adjacent tracks, but never make playback wait for it.
      unawaited(_warmArtworkCache(startIndex, loadId));

      await _player.setAudioSources(sources, initialIndex: startIndex, initialPosition: Duration.zero);

      if (loadId != _loadId) return;

      _loadingQueue = false;
      _publishCurrentItem(_player.currentIndex ?? startIndex);

      // Starting audio should not wait on unrelated UI/background metadata work.
      unawaited(_player.play());
    } catch (error, stackTrace) {
      if (loadId != _loadId) return;

      debugPrint('Could not start queue: $error');
      debugPrintStack(stackTrace: stackTrace);
      rethrow;
    } finally {
      if (loadId == _loadId) {
        _loadingQueue = false;
      }
    }
  }

  // ---------------------------------------------------------------------------
  // SYSTEM / APP CONTROLS
  // ---------------------------------------------------------------------------

  @override
  Future<void> play() async {
    if (_player.audioSources.isEmpty) return;

    if (_player.processingState == ProcessingState.completed) {
      await _player.seek(Duration.zero, index: _player.currentIndex ?? 0);
    }

    await _player.play();
  }

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> seek(Duration position) async {
    final total = _player.duration;
    if (total == null || total <= Duration.zero) return;

    final target = position < Duration.zero
        ? Duration.zero
        : position > total
        ? total
        : position;

    await _player.seek(target);

    // A remote seek is a discrete state change. Publish an authoritative
    // snapshot immediately rather than waiting for the next periodic event.
    _publishPlaybackState(_player.playbackEvent);
  }

  Future<void> seekFraction(double fraction) async {
    final total = _player.duration;
    if (total == null || total <= Duration.zero) return;

    final normalized = fraction.clamp(0.0, 1.0);
    final targetUs = (total.inMicroseconds * normalized).round();

    await seek(Duration(microseconds: targetUs));
  }

  @override
  Future<void> skipToNext() async {
    if (!_player.hasNext) return;

    final current = _player.currentIndex;
    final expectedIndex = current == null
        ? null
        : current + 1 < _mediaItems.length
        ? current + 1
        : null;

    // Remote controls should update app-visible metadata immediately.
    // Do this BEFORE awaiting the native decoder transition, which may take
    // noticeable time for FLAC/precise Darwin seeking.
    if (expectedIndex != null) {
      _publishCurrentItem(expectedIndex);
    }

    await _player.seekToNext();

    // Reconcile with whatever index the player actually landed on.
    final actualIndex = _player.currentIndex;
    if (actualIndex != null) {
      _publishCurrentItem(actualIndex);
    }

    _publishPlaybackState(_player.playbackEvent);
  }

  @override
  Future<void> skipToPrevious() async {
    if (_player.position > const Duration(seconds: 3)) {
      await seek(Duration.zero);
      return;
    }

    if (_player.hasPrevious) {
      final current = _player.currentIndex;
      final expectedIndex = current == null
          ? null
          : current - 1 >= 0
          ? current - 1
          : null;

      if (expectedIndex != null) {
        _publishCurrentItem(expectedIndex);
      }

      await _player.seekToPrevious();

      final actualIndex = _player.currentIndex;
      if (actualIndex != null) {
        _publishCurrentItem(actualIndex);
      }

      _publishPlaybackState(_player.playbackEvent);
      return;
    }

    await seek(Duration.zero);
  }

  @override
  Future<void> skipToQueueItem(int index) async {
    if (index < 0 || index >= _mediaItems.length) return;

    _publishCurrentItem(index);

    await _player.seek(Duration.zero, index: index);

    final actualIndex = _player.currentIndex;
    if (actualIndex != null) {
      _publishCurrentItem(actualIndex);
    }

    _publishPlaybackState(_player.playbackEvent);
  }

  @override
  Future<void> stop() async {
    await _player.stop();

    _publishPlaybackState(_player.playbackEvent);
    await super.stop();
  }

  Future<void> disposeHandler() async {
    for (final subscription in _subscriptions) {
      await subscription.cancel();
    }
    _subscriptions.clear();

    await _player.dispose();
  }

  // ---------------------------------------------------------------------------
  // BROADCASTING
  // ---------------------------------------------------------------------------

  void _publishCurrentItem(int index) {
    if (index < 0 || index >= _mediaItems.length) return;

    var item = _mediaItems[index];

    // Only attach the decoder duration when this item is ACTUALLY current.
    // skipToNext/Previous intentionally pre-publish the expected MediaItem
    // before the native transition completes; using _player.duration there
    // would copy the previous track's duration onto the next track.
    if (_player.currentIndex == index) {
      final resolvedDuration = _player.duration;

      if (resolvedDuration != null && resolvedDuration > Duration.zero && item.duration != resolvedDuration) {
        item = item.copyWith(duration: resolvedDuration);

        final mutable = List<MediaItem>.of(_mediaItems);
        mutable[index] = item;
        _mediaItems = List<MediaItem>.unmodifiable(mutable);
        queue.add(_mediaItems);
      }
    }

    mediaItem.add(item);
  }

  void _publishResolvedDuration(Duration duration) {
    final index = _player.currentIndex;
    if (index == null || index < 0 || index >= _mediaItems.length) return;

    final oldItem = _mediaItems[index];
    if (oldItem.duration == duration) return;

    final updatedItem = oldItem.copyWith(duration: duration);
    final mutable = List<MediaItem>.of(_mediaItems);
    mutable[index] = updatedItem;

    _mediaItems = List<MediaItem>.unmodifiable(mutable);
    queue.add(_mediaItems);

    if (mediaItem.valueOrNull?.id == updatedItem.id) {
      mediaItem.add(updatedItem);
    }
  }

  void _publishPlaybackState(PlaybackEvent event) {
    final state = PlaybackState(
      controls: [
        MediaControl.skipToPrevious,
        if (_player.playing) MediaControl.pause else MediaControl.play,
        MediaControl.skipToNext,
      ],
      systemActions: const {MediaAction.seek, MediaAction.seekForward, MediaAction.seekBackward},
      androidCompactActionIndices: const [0, 1, 2],
      processingState: switch (_player.processingState) {
        ProcessingState.idle => AudioProcessingState.idle,
        ProcessingState.loading => AudioProcessingState.loading,
        ProcessingState.buffering => AudioProcessingState.buffering,
        ProcessingState.ready => AudioProcessingState.ready,
        ProcessingState.completed => AudioProcessingState.completed,
      },
      playing: _player.playing,
      updatePosition: _player.position,
      bufferedPosition: _player.bufferedPosition,
      speed: _player.speed,
      queueIndex: event.currentIndex,
    );

    _lastPlaybackState = state;
    playbackState.add(state);
  }

  // ---------------------------------------------------------------------------
  // SOURCE / MEDIA ITEM CREATION
  // ---------------------------------------------------------------------------

  _PreparedTrack _prepareTrack(Song song) {
    final item = MediaItem(
      id: song.id,
      title: song.title,
      artist: song.artist,
      album: song.album,
      extras: {'filePath': song.filePath, if (song.format != null) 'format': song.format},
    );

    final source = ProgressiveAudioSource(
      _audioUri(song.filePath),
      tag: item,
      options: ProgressiveAudioSourceOptions(
        // This accuracy mode is useful for FLAC on Apple platforms, but it can
        // increase preparation cost. Do not pay that price for every MP3/AAC.
        darwinAssetOptions: DarwinAssetOptions(preferPreciseDurationAndTiming: _needsPreciseDarwinTiming(song)),
      ),
    );

    return _PreparedTrack(mediaItem: item, source: source);
  }

  bool _needsPreciseDarwinTiming(Song song) {
    if (!Platform.isIOS && !Platform.isMacOS) return false;

    final format = song.format?.toLowerCase() ?? '';
    return format.contains('flac') || song.filePath.toLowerCase().endsWith('.flac');
  }

  Future<void> _warmArtworkCache(int startIndex, int loadId) async {
    if (_songs.isEmpty) return;

    final priority = <int>[
      startIndex,
      if (startIndex + 1 < _songs.length) startIndex + 1,
      if (startIndex - 1 >= 0) startIndex - 1,
    ];

    final seen = <int>{...priority};

    for (var i = 0; i < _songs.length; i++) {
      if (!seen.contains(i)) {
        priority.add(i);
      }
    }

    for (final index in priority) {
      if (loadId != _loadId) return;

      final artUri = await _cacheArtwork(_songs[index]);

      if (loadId != _loadId || artUri == null) continue;

      final oldItem = _mediaItems[index];
      if (oldItem.artUri == artUri) continue;

      final updatedItem = oldItem.copyWith(artUri: artUri);
      final mutable = List<MediaItem>.of(_mediaItems);
      mutable[index] = updatedItem;
      _mediaItems = List<MediaItem>.unmodifiable(mutable);

      queue.add(_mediaItems);

      // If this track is currently active (or was pre-published by a remote
      // next/previous command), update Now Playing metadata immediately.
      if (_player.currentIndex == index || mediaItem.valueOrNull?.id == updatedItem.id) {
        mediaItem.add(updatedItem);
      }

      // Give the isolate a chance to service UI/player events between files.
      await Future<void>.delayed(Duration.zero);
    }
  }

  static Uri _audioUri(String path) {
    if (path.startsWith('content://') ||
        path.startsWith('file://') ||
        path.startsWith('http://') ||
        path.startsWith('https://')) {
      return Uri.parse(path);
    }

    return Uri.file(path);
  }

  // ---------------------------------------------------------------------------
  // ARTWORK
  // ---------------------------------------------------------------------------

  Future<Uri?> _cacheArtwork(Song song) async {
    if (_artworkUriCache.containsKey(song.id)) {
      return _artworkUriCache[song.id];
    }

    final bytes = await ArtworkService.forSong(song);

    if (bytes == null || bytes.isEmpty) {
      _artworkUriCache[song.id] = null;
      return null;
    }

    final artworkDirectory = await _getArtworkDirectory();
    final safeId = song.id.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
    final file = File('${artworkDirectory.path}/$safeId.jpg');

    if (!await file.exists() || await file.length() != bytes.length) {
      await file.writeAsBytes(bytes, flush: true);
    }

    final uri = file.uri;
    _artworkUriCache[song.id] = uri;

    return uri;
  }

  Future<Directory> _getArtworkDirectory() {
    return _artworkDirectoryFuture ??= () async {
      final cacheDirectory = await getTemporaryDirectory();
      final directory = Directory('${cacheDirectory.path}/kosh_artwork');

      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }

      return directory;
    }();
  }
}

class _PreparedTrack {
  const _PreparedTrack({required this.mediaItem, required this.source});

  final MediaItem mediaItem;
  final AudioSource source;
}
