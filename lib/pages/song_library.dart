import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cupertino_symbols/flutter_cupertino_symbols.dart';
import 'package:flutter_taglib/flutter_taglib.dart';
import 'package:kosh/player/song.dart';
import 'package:kosh/style/style.dart';
import 'package:kosh/widgets/song_list_tile.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:kosh/player/state.dart';

// =============================================================================
// METADATA ABSTRACTION (Shared between Android & iOS)
// =============================================================================

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
    this.coverData,
    this.coverMimeType,
  });

  final String? title, artist, album, genre, format, coverMimeType;
  final int? year, track, duration, bitrate, sampleRate;
  final Uint8List? coverData;

  bool get hasCover => coverData != null;
}

class AudioMetadataService {
  AudioMetadataService._();

  static AudioMetadata? readMetadata(String filePath) {
    if (!TagLibFile.isSupported) return null;
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
        coverData: file.hasCover ? file.coverData : null,
        coverMimeType: file.hasCover ? file.coverMimeType : null,
      );
    } finally {
      file.close();
    }
  }

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
// SONG LIBRARY & DISCOVERY
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
    if (!status.isGranted) throw StateError('Audio permission was denied');

    final tracks = await OnAudioQuery().querySongs(sortType: SongSortType.TITLE, orderType: OrderType.ASC_OR_SMALLER);
    return tracks
        .where((t) => t.uri != null)
        .map(
          (t) => Song(
            id: t.id.toString(),
            title: t.title,
            artist: (t.artist == null || t.artist == '<unknown>') ? 'Unknown Artist' : t.artist!,
            album: t.album,
            filePath: t.uri!,
            length: t.duration!,
          ),
        )
        .toList();
  }

  static Future<List<Song>> _fetchIOS() async {
    final dir = await getApplicationDocumentsDirectory();
    if (!dir.existsSync()) return [];

    final trashDir = Directory('${dir.path}/.Trash');
    if (trashDir.existsSync()) {
      try {
        trashDir.deleteSync(recursive: true);
      } catch (_) {}
    }

    return scanDirectory(dir);
  }

  static Future<List<Song>> scanDirectory(Directory dir) async {
    if (!dir.existsSync()) return [];

    final songs = <Song>[];
    await for (final entity in dir.list(recursive: true, followLinks: false)) {
      if (entity is! File) continue;
      final isHidden = entity.uri.pathSegments.any((segment) => segment.startsWith('.'));
      if (isHidden || !_audioExtensions.contains(_extensionOf(entity.path))) continue;
      final file = entity;
      final metadata = AudioMetadataService.readMetadata(file.path);
      final fileName = file.uri.pathSegments.last;
      final fallbackTitle = fileName.contains('.') ? fileName.substring(0, fileName.lastIndexOf('.')) : fileName;

      if (metadata != null) {
        songs.add(
          Song(
            id: file.path,
            title: metadata.title ?? fallbackTitle,
            artist: metadata.artist ?? 'Unknown Artist',
            album: metadata.album,
            format: metadata.format,
            length: metadata.duration!,
            albumArt: metadata.coverData,
            filePath: file.path,
          ),
        );
      }
    }
    songs.sort((a, b) => a.title.compareTo(b.title));
    return songs;
  }

  static String _extensionOf(String path) => path.contains('.') ? path.split('.').last.toLowerCase() : '';
}

// =============================================================================
// UI VIEWS
// =============================================================================

class SongListView extends StatefulWidget {
  const SongListView({super.key});

  @override
  State<SongListView> createState() => _SongListViewState();
}

class _SongListViewState extends State<SongListView> {
  late Future<List<Song>> _future = SongLibrary.fetchAll();

  Future<void> _reload() async {
    final future = SongLibrary.fetchAll();
    setState(() {
      _future = future;
    });
    await future;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: FutureBuilder<List<Song>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done && !snapshot.hasData) {
            return const Center(child: CircularProgressIndicator(color: Colors.white54));
          }

          if (snapshot.hasError && !snapshot.hasData) {
            return _CenteredMessage(
              icon: SFSymbols.waveform_badge_xmark,
              text: 'Could not load songs.\n${snapshot.error}',
            );
          }

          final songs = snapshot.data ?? [];

          return CustomScrollView(
            physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
            slivers: [
              CupertinoSliverRefreshControl(
                onRefresh: _reload,
                builder: (context, refreshState, pulledExtent, refreshTriggerPullDistance, refreshIndicatorExtent) {
                  return Padding(
                    padding: EdgeInsets.only(top: MediaQuery.paddingOf(context).top),
                    child: CupertinoSliverRefreshControl.buildRefreshIndicator(
                      context,
                      refreshState,
                      pulledExtent,
                      refreshTriggerPullDistance,
                      refreshIndicatorExtent,
                    ),
                  );
                },
              ),

              if (songs.isEmpty && snapshot.connectionState == ConnectionState.done)
                const SliverFillRemaining(
                  child: _CenteredMessage(icon: SFSymbols.music_note_slash, text: 'No Songs...'),
                )
              else
                SliverPadding(
                  padding: EdgeInsets.only(
                    top: AppInset.topBarHeight(context),
                    bottom: AppInset.totalBottomHeight(context),
                  ),
                  sliver: SliverList.separated(
                    itemCount: songs.length,
                    separatorBuilder: (context, index) => Container(
                      height: 1,
                      margin: const EdgeInsets.only(
                        left: AppInset.listSeparatorLeft,
                        right: AppInset.screenEdgePadding,
                      ),
                      color: AppColors.divider,
                    ),
                    itemBuilder: (context, i) {
                      return SongListTile(
                        song: songs[i],
                        onTap: () {
                          PlayerState.playQueue(songs, i);
                        },
                      );
                    },
                  ),
                ),
            ],
          );
        },
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
              style: TextStyle(color: AppColors.primaryText.withValues(alpha: 0.6)),
            ),
          ],
        ),
      ),
    );
  }
}
