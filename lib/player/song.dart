import 'dart:typed_data';

class Song {
  final String id;
  final String title;
  final String artist;
  final String filePath;
  final String? album;
  final String? format;
  final Uint8List? albumArt;

  Song({
    required this.id,
    required this.title,
    required this.artist,
    required this.filePath,
    this.album,
    this.format,
    this.albumArt,
  });

  factory Song.fromMap(Map<String, dynamic> map) {
    return Song(
      id: map['id'] as String,
      title: map['title'] as String,
      artist: map['artist'] as String,
      filePath: map['filePath'] as String,
      album: map['album'] as String?,
      format: map['format'] as String?,
      albumArt: map['albumArt'] as Uint8List?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'artist': artist,
      'filePath': filePath,
      'album': album,
      'format': format,
      'albumArt': albumArt,
    };
  }
}
