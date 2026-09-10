import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:kosh/player/song.dart';
import 'package:path_provider/path_provider.dart';
import 'package:kosh/player/artwork_service.dart';

class PlayerState {
  PlayerState._();

  static final AudioPlayer _player = AudioPlayer();
  static final ValueNotifier<Song?> currentSong = ValueNotifier<Song?>(null);
  static final ValueNotifier<bool> isPlaying = ValueNotifier<bool>(false);

  static int _loadId = 0;

  static final _playingSubscription = _player.playingStream.listen((playing) {
    if (isPlaying.value != playing) {
      isPlaying.value = playing;
    }
  });

  static Future<void> playSong(Song song) async {
    final loadId = ++_loadId;

    currentSong.value = song;

    try {
      final artUri = await _cacheArtwork(song);

      if (loadId != _loadId) return;

      final source = AudioSource.uri(
        _audioUri(song.filePath),
        tag: MediaItem(id: song.id, title: song.title, artist: song.artist, album: song.album, artUri: artUri),
      );

      await _player.setAudioSource(source);

      // The user may have selected another song while this one was loading.
      if (loadId != _loadId) return;

      await _player.play();
    } catch (error, stackTrace) {
      if (loadId != _loadId) return;

      isPlaying.value = false;

      debugPrint('Could not play ${song.filePath}: $error\n$stackTrace');
    }
  }

  static Future<void> togglePlayPause() async {
    if (currentSong.value == null) return;

    if (_player.playing) {
      await _player.pause();
    } else {
      await _player.play();
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
