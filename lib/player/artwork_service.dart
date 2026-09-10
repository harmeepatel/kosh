import 'dart:io';
import 'dart:typed_data';

import 'package:kosh/player/song.dart';
import 'package:on_audio_query/on_audio_query.dart';

class ArtworkService {
  ArtworkService._();

  static Future<Uint8List?> forSong(Song song) async {
    if (song.albumArt != null) {
      return song.albumArt;
    }

    if (!Platform.isAndroid) {
      return null;
    }

    final id = int.tryParse(song.id);
    if (id == null) {
      return null;
    }

    return OnAudioQuery().queryArtwork(
      id,
      ArtworkType.AUDIO,
      format: ArtworkFormat.JPEG,
      size: 1000,
      quality: 90,
    );
  }
}
