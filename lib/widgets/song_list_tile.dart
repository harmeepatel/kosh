import 'package:flutter/material.dart';
import 'package:kosh/player/song.dart';
import 'package:kosh/player/state.dart';
import 'package:kosh/style/style.dart';
import 'album_art.dart';
import 'song_info.dart';

class SongListTile extends StatelessWidget {
  const SongListTile({super.key, required this.song, this.fallbackColor});

  final Song song;
  final Color? fallbackColor;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        PlayerState.currentSong.value = song;
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppInset.screenEdgePadding,
          vertical: AppSpacing.xs4,
        ),
        child: Row(
          children: [
            AlbumArt(
              size: AppAlbumCoverSize.sm,
              radius: AppRadii.sm,
              imageBytes: song.albumArt,
              fallbackColor: fallbackColor,
            ),

            const SizedBox(width: AppSpacing.md),

            Expanded(
              child: SongInfo(
                title: song.title,
                artist: song.artist,
                format: song.format,
                titleStyle: AppTextStyles.listTitle,
                artistStyle: AppTextStyles.listArtist,
                spacing: AppSpacing.xs3,
              ),
            ),

            const SizedBox(width: AppSpacing.md),

            const Icon(Icons.more_horiz, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}
