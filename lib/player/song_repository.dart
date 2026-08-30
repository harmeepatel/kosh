import 'package:kosh/player/song.dart';

class SongRepository {
  Future<List<Song>> getAllSongs() async {
    return [
      Song(
        id: '1',
        title: 'Don\'t You (Forget About Me)',
        artist: 'Simple Minds',
        filePath: '/mock/path/1.mp3',
        format: 'Lossless',
      ),
      Song(
        id: '2',
        title: 'Bohemian Rhapsody',
        artist: 'Queen',
        filePath: '/mock/path/2.mp3',
        format: 'Hi-Res',
      ),
    ];
  }

  Future<List<Song>> getSongsSortedBy(String criterion) async {
    final songs = await getAllSongs();

    if (criterion == 'title') {
      songs.sort((a, b) => a.title.compareTo(b.title));
    } else if (criterion == 'artist') {
      songs.sort((a, b) => a.artist.compareTo(b.artist));
    }

    return songs;
  }
}
