import 'package:kosh/player/song.dart';

enum SongSortCriterion { title, artist }

class SongRepository {
  Future<List<Song>> getAllSongs() async => const [
    Song(
      id: '1',
      title: "Don't You (Forget About Me)",
      artist: 'Simple Minds',
      filePath: '/mock/path/1.mp3',
      length: 128,
      format: 'Lossless',
    ),
    Song(
      id: '2',
      title: 'Bohemian Rhapsody',
      artist: 'Queen',
      filePath: '/mock/path/2.mp3',
      length: 128,
      format: 'Hi-Res',
    ),
  ];

  Future<List<Song>> getSongsSortedBy(SongSortCriterion criterion) async {
    final songs = await getAllSongs();
    switch (criterion) {
      case SongSortCriterion.title:
        songs.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
      case SongSortCriterion.artist:
        songs.sort((a, b) => a.artist.toLowerCase().compareTo(b.artist.toLowerCase()));
    }
    return songs;
  }
}
