import 'dart:typed_data';

class Song {
  const Song({
    required this.id,
    required this.title,
    required this.artist,
    required this.filePath,
    required this.length,
    this.album,
    this.format,
    this.albumArt,
  });

  final String id;
  final String title;
  final String artist;
  final String filePath;
  final int length;
  final String? album;
  final String? format;
  final Uint8List? albumArt;

  factory Song.fromMap(Map<String, dynamic> map) => Song(
    id: map['id'] as String,
    title: map['title'] as String,
    artist: map['artist'] as String,
    filePath: map['filePath'] as String,
    length: map['length'] as int,
    album: map['album'] as String?,
    format: map['format'] as String?,
    albumArt: map['albumArt'] as Uint8List?,
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'title': title,
    'artist': artist,
    'filePath': filePath,
    'length': length,
    'album': album,
    'format': format,
    'albumArt': albumArt,
  };
}
