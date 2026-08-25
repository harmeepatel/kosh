import 'dart:io';

import 'package:figma_squircle/figma_squircle.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_taglib/flutter_taglib.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:kosh/style.dart';

// =============================================================================
// 1. METADATA ABSTRACTION (Shared between Android & iOS)
// =============================================================================

/// Structured representation of audio file metadata.
class AudioMetadata {
  const AudioMetadata({
    this.title,
    this.artist,
    this.album,
    this.genre,
    this.year,
    this.track,
    this.format,
    this.duration,
    this.bitrate,
    this.sampleRate,
    this.hasCover = false,
  });

  final String? title;
  final String? artist;
  final String? album;
  final String? genre;
  final int? year;
  final int? track;
  final String? format;
  final int? duration;
  final int? bitrate;
  final int? sampleRate;
  final bool hasCover;
}

/// Abstract metadata service for reading and writing audio tags via TagLib.
class AudioMetadataService {
  AudioMetadataService._();

  /// Reads metadata tags and audio properties from a file path.
  static AudioMetadata? readMetadata(String filePath) {
    if (!TagLibFile.isSupported) {
      debugPrint('TagLib is not supported on this platform.');
      return null;
    }

    final file = TagLibFile.open(filePath);
    if (file == null) return null;

    try {
      return AudioMetadata(
        title: file.title.isNotEmpty == true ? file.title : null,
        artist: file.artist.isNotEmpty == true ? file.artist : null,
        album: file.album.isNotEmpty == true ? file.album : null,
        genre: file.genre.isNotEmpty == true ? file.genre : null,
        year: file.year,
        track: file.track,
        format: file.format,
        duration: file.duration.inSeconds,
        bitrate: file.bitrate,
        sampleRate: file.sampleRate,
        hasCover: file.hasCover,
      );
    } finally {
      file.close();
    }
  }

  /// Writes/Updates metadata tags for a file path.
  static bool writeMetadata(
    String filePath, {
    String? title,
    String? artist,
    String? album,
    String? genre,
    int? year,
    int? track,
  }) {
    if (!TagLibFile.isSupported) return false;

    final file = TagLibFile.open(filePath);
    if (file == null) return false;

    try {
      if (title != null) file.title = title;
      if (artist != null) file.artist = artist;
      if (album != null) file.album = album;
      if (genre != null) file.genre = genre;
      if (year != null) file.year = year;
      if (track != null) file.track = track;

      return file.save();
    } finally {
      file.close();
    }
  }
}

// =============================================================================
// 2. SONG & SOURCE MODELS
// =============================================================================

class Song {
  const Song({
    required this.id,
    required this.title,
    required this.artist,
    required this.source,
    this.album,
    this.format,
  });

  final String id;
  final String title;
  final String artist;
  final String? album;
  final String? format;
  final SongSource source;
}

sealed class SongSource {
  const SongSource();
}

class MediaStoreSource extends SongSource {
  const MediaStoreSource(this.uri);
  final String uri;
}

class FileSource extends SongSource {
  const FileSource(this.path);
  final String path;
}

// =============================================================================
// 3. SONG LIBRARY & DISCOVERY
// =============================================================================

class SongLibrary {
  SongLibrary._();

  static const _audioExtensions = {'mp3', 'm4a', 'wav', 'aac', 'flac', 'opus'};

  static Future<List<Song>> fetchAll() {
    if (Platform.isAndroid) return _fetchAndroid();
    if (Platform.isIOS) return _fetchIOS();
    throw UnsupportedError('Unsupported platform: ${Platform.operatingSystem}');
  }

  static Future<List<Song>> _fetchAndroid() async {
    final status = await Permission.audio.request();
    if (!status.isGranted) {
      throw StateError('Audio permission was denied');
    }

    final query = OnAudioQuery();
    final tracks = await query.querySongs(
      sortType: SongSortType.TITLE,
      orderType: OrderType.ASC_OR_SMALLER,
    );

    return tracks
        .where((t) => t.uri != null)
        .map(
          (t) => Song(
            id: t.id.toString(),
            title: t.title,
            artist: (t.artist == null || t.artist == '<unknown>')
                ? 'Unknown Artist'
                : t.artist!,
            album: t.album,
            source: MediaStoreSource(t.uri!),
          ),
        )
        .toList();
  }

  static Future<List<Song>> _fetchIOS() async {
    final dir = await getApplicationDocumentsDirectory();
    if (!dir.existsSync()) return [];

    // Purge unwanted trash directory if it exists
    final trashDir = Directory('${dir.path}/.Trash');
    if (trashDir.existsSync()) {
      try {
        trashDir.deleteSync(recursive: true);
      } catch (_) {}
    }

    return scanDirectory(dir);
  }

  /// Scans any target directory in-place without copying files.
  /// Filters out hidden directories (like .Trash or system folders).
  static Future<List<Song>> scanDirectory(Directory dir) async {
    if (!dir.existsSync()) return [];

    final files = dir.listSync(recursive: true).whereType<File>().where((f) {
      // Exclude hidden files or folders starting with "."
      final isHidden = f.uri.pathSegments.any((s) => s.startsWith('.'));
      return !isHidden && _audioExtensions.contains(_extensionOf(f.path));
    });

    final songs = <Song>[];

    for (final file in files) {
      // Common metadata abstraction call
      final metadata = AudioMetadataService.readMetadata(file.path);
      final fileName = file.uri.pathSegments.last;
      final fallbackTitle = fileName.contains('.')
          ? fileName.substring(0, fileName.lastIndexOf('.'))
          : fileName;

      songs.add(
        Song(
          id: file.path,
          title: metadata?.title ?? fallbackTitle,
          artist: metadata?.artist ?? 'Unknown Artist',
          album: metadata?.album,
          format: metadata?.format,
          source: FileSource(file.path),
        ),
      );
    }

    songs.sort((a, b) => a.title.compareTo(b.title));
    return songs;
  }

  static String _extensionOf(String path) =>
      path.contains('.') ? path.split('.').last.toLowerCase() : '';
}

// =============================================================================
// 4. UI VIEWS
// =============================================================================

class SongListView extends StatefulWidget {
  const SongListView({super.key});

  @override
  State<SongListView> createState() => _SongListViewState();
}

class _SongListViewState extends State<SongListView> {
  late Future<List<Song>> _future = SongLibrary.fetchAll();

  void _reload() {
    setState(() {
      _future = SongLibrary.fetchAll();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: FutureBuilder<List<Song>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.white54),
            );
          }

          if (snapshot.hasError) {
            return _CenteredMessage(
              icon: Icons.error_outline_rounded,
              text: 'Could not load songs.\n${snapshot.error}',
            );
          }

          final songs = snapshot.data ?? [];
          if (songs.isEmpty) {
            return const _CenteredMessage(
              icon: Icons.music_off_rounded,
              text: 'No songs found.',
            );
          }

          return CustomScrollView(
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            slivers: [
              CupertinoSliverRefreshControl(onRefresh: () async => _reload()),
              SliverPadding(
                padding: EdgeInsets.only(
                  top: AppInset.topBarHeight(context),
                  bottom: AppInset.totalBottomheight(context),
                ),
                sliver: SliverList.separated(
                  itemCount: songs.length,
                  separatorBuilder: (context, index) => Container(
                    height: 1,
                    margin: const EdgeInsets.only(
                      left: 75,
                      right: AppInset.screenEdgePadding,
                    ),
                    color: Colors.white12,
                  ),
                  itemBuilder: (context, i) => _SongTile(song: songs[i]),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SongTile extends StatelessWidget {
  const _SongTile({required this.song});

  final Song song;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {},
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppInset.screenEdgePadding,
          vertical: AppInset.screenEdgePadding,
        ),
        child: Row(
          children: [
            Container(
              width: AppAlbumCoverSize.sm,
              height: AppAlbumCoverSize.sm,
              alignment: Alignment.center,
              decoration: ShapeDecoration(
                color: Colors.grey.shade800,
                shape: SmoothRectangleBorder(
                  borderRadius: SmoothBorderRadius(
                    cornerRadius: AppRadii.sm,
                    cornerSmoothing: AppRadii.cornerSmoothing,
                  ),
                ),
              ),
              child: const Icon(Icons.music_note, color: Colors.white70),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    song.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs3),
                  Text(
                    '${song.artist}${song.format != null ? " • ${song.format}" : ""}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            const Icon(Icons.more_horiz, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}

class _CenteredMessage extends StatelessWidget {
  const _CenteredMessage({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white38, size: 42),
            const SizedBox(height: AppSpacing.sm),
            Text(
              text,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white.withValues(alpha: 0.6)),
            ),
          ],
        ),
      ),
    );
  }
}
