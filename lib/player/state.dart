import 'dart:io';
import 'dart:async';

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

  static int _loadId = 0;

  // ---------------------------------------------------------------------------
  // PLAYER STATE -> APP STATE
  // ---------------------------------------------------------------------------

  static final List<StreamSubscription<dynamic>> _subscriptions = [];

  static bool _initialized = false;

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

        if (currentSong.value?.id == song.id) {
          return;
        }

        currentSong.value = song;
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

    await _player.dispose();

    _initialized = false;
  }

  // ---------------------------------------------------------------------------
  // PLAYBACK
  // ---------------------------------------------------------------------------

  static bool _isLoadingQueue = false;

  static Future<void> playQueue(List<Song> songs, int startIndex) async {
    if (songs.isEmpty) return;
    if (startIndex < 0 || startIndex >= songs.length) return;

    final loadId = ++_loadId;
    final newQueue = List<Song>.unmodifiable(songs);

    _isLoadingQueue = true;

    try {
      final sources = await Future.wait(newQueue.map(_createAudioSource));

      // User may have selected another song while sources were loading.
      if (loadId != _loadId) return;

      queue.value = newQueue;
      currentSong.value = newQueue[startIndex];

      await _player.setAudioSources(sources, initialIndex: startIndex, initialPosition: Duration.zero);

      // User may have selected another song while the player was loading.
      if (loadId != _loadId) return;

      _player.play();
    } catch (error, stackTrace) {
      if (loadId != _loadId) return;

      debugPrint('Could not start queue: $error');
      debugPrintStack(stackTrace: stackTrace);
    } finally {
      // Only the newest load is allowed to clear this flag.
      if (loadId == _loadId) {
        _isLoadingQueue = false;
      }
    }
  }

  // Keep this for callers that genuinely want to play one song only.
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

    // If the entire queue finished, Play should start again
    // instead of remaining stuck at the completed position.
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
    // Common music-player behaviour:
    // if we're already several seconds into the track,
    // restart it instead of jumping backward immediately.
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
  // AUDIO SOURCE / BACKGROUND METADATA
  // ---------------------------------------------------------------------------

  static Future<AudioSource> _createAudioSource(Song song) async {
    final artUri = await _cacheArtwork(song);

    return AudioSource.uri(
      _audioUri(song.filePath),
      tag: MediaItem(id: song.id, title: song.title, artist: song.artist, album: song.album, artUri: artUri),
    );
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

  static Future<Uri?> _cacheArtwork(Song song) async {
    final bytes = await ArtworkService.forSong(song);

    if (bytes == null || bytes.isEmpty) {
      return null;
    }

    final cacheDirectory = await getTemporaryDirectory();

    final artworkDirectory = Directory('${cacheDirectory.path}/kosh_artwork');

    if (!await artworkDirectory.exists()) {
      await artworkDirectory.create(recursive: true);
    }

    final safeId = song.id.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');

    final file = File('${artworkDirectory.path}/$safeId.jpg');

    if (!await file.exists() || await file.length() != bytes.length) {
      await file.writeAsBytes(bytes, flush: true);
    }

    return file.uri;
  }
}
