import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:kosh/player/artwork_service.dart';
import 'package:kosh/player/song.dart';
import 'package:path_provider/path_provider.dart';

class PlayerState {
  PlayerState._();

  static final AudioPlayer _player = AudioPlayer();
  static final ValueNotifier<Song?> currentSong = ValueNotifier<Song?>(null);
  static final ValueNotifier<bool> isPlaying = ValueNotifier<bool>(false);
  static final ValueNotifier<List<Song>> queue = ValueNotifier<List<Song>>(<Song>[]);
  static final ValueNotifier<Uri?> currentArtworkUri = ValueNotifier<Uri?>(null);
  static final List<StreamSubscription<dynamic>> _subscriptions = [];
  static final Map<String, Uri?> _artworkUriCache = {};
  static List<Uri?> _queueArtworkUris = <Uri?>[];
  static Future<Directory>? _artworkDirectoryFuture;

  static int _loadId = 0;
  static bool _initialized = false;
  static bool _isLoadingQueue = false;

  // ---------------------------------------------------------------------------
  // INITIALIZATION
  // ---------------------------------------------------------------------------

  static void initialize() {
    if (_initialized) return;

    _initialized = true;

    _subscriptions.add(
      _player.playingStream.distinct().listen((playing) {
        if (isPlaying.value != playing) {
          isPlaying.value = playing;
        }
      }),
    );

    _subscriptions.add(
      _player.currentIndexStream.distinct().listen((index) {
        if (index == null || _isLoadingQueue) return;

        final songs = queue.value;

        if (index < 0 || index >= songs.length) {
          debugPrint('Player index $index is outside queue length ${songs.length}');
          return;
        }

        final song = songs[index];

        if (currentSong.value?.id != song.id) {
          currentSong.value = song;
        }

        currentArtworkUri.value = index < _queueArtworkUris.length ? _queueArtworkUris[index] : null;
      }),
    );
  }

  static Future<void> dispose() async {
    for (final subscription in _subscriptions) {
      await subscription.cancel();
    }

    _subscriptions.clear();

    currentSong.dispose();
    isPlaying.dispose();
    queue.dispose();
    currentArtworkUri.dispose();

    await _player.dispose();

    _initialized = false;
  }

  // ---------------------------------------------------------------------------
  // PLAYBACK
  // ---------------------------------------------------------------------------

  static Future<void> playQueue(List<Song> songs, int startIndex) async {
    if (songs.isEmpty) return;
    if (startIndex < 0 || startIndex >= songs.length) return;

    final loadId = ++_loadId;
    final newQueue = List<Song>.unmodifiable(songs);

    _isLoadingQueue = true;

    try {
      final prepared = await Future.wait(newQueue.map(_prepareSource));

      // User may have selected another song while the queue was preparing.
      if (loadId != _loadId) return;

      final sources = [for (final item in prepared) item.source];

      final artworkUris = [for (final item in prepared) item.artUri];

      queue.value = newQueue;
      _queueArtworkUris = artworkUris;

      currentSong.value = newQueue[startIndex];
      currentArtworkUri.value = artworkUris[startIndex];

      await _player.setAudioSources(sources, initialIndex: startIndex, initialPosition: Duration.zero);

      // User may have selected another song while just_audio was loading.
      if (loadId != _loadId) return;

      _player.play();
    } catch (error, stackTrace) {
      if (loadId != _loadId) return;

      debugPrint('Could not start queue: $error');
      debugPrintStack(stackTrace: stackTrace);
    } finally {
      // Only the newest request is allowed to clear this flag.
      if (loadId == _loadId) {
        _isLoadingQueue = false;
      }
    }
  }

  static Future<void> playSong(Song song) {
    return playQueue([song], 0);
  }

  // ---------------------------------------------------------------------------
  // CONTROLS
  // ---------------------------------------------------------------------------

  static Future<void> togglePlayPause() async {
    if (_player.audioSources.isEmpty) return;

    if (_player.playing) {
      await _player.pause();
      return;
    }

    if (_player.processingState == ProcessingState.completed) {
      await _player.seek(Duration.zero, index: _player.currentIndex ?? 0);
    }

    _player.play();
  }

  static Future<void> skipToNext() async {
    if (!_player.hasNext) return;

    await _player.seekToNext();
  }

  static Future<void> skipToPrevious() async {
    if (_player.position > const Duration(seconds: 3)) {
      await _player.seek(Duration.zero);
      return;
    }

    if (_player.hasPrevious) {
      await _player.seekToPrevious();
    } else {
      await _player.seek(Duration.zero);
    }
  }

  // ---------------------------------------------------------------------------
  // AUDIO SOURCE
  // ---------------------------------------------------------------------------

  static Future<_PreparedSource> _prepareSource(Song song) async {
    final artUri = await _cacheArtwork(song);

    final source = AudioSource.uri(
      _audioUri(song.filePath),
      tag: MediaItem(id: song.id, title: song.title, artist: song.artist, album: song.album, artUri: artUri),
    );

    return _PreparedSource(source: source, artUri: artUri);
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

  static Future<Uri?> _cacheArtwork(Song song) async {
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

  static Future<Directory> _getArtworkDirectory() {
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

class _PreparedSource {
  const _PreparedSource({required this.source, required this.artUri});

  final AudioSource source;
  final Uri? artUri;
}
