import 'package:flutter/material.dart';
import 'package:flutter_cupertino_symbols/flutter_cupertino_symbols.dart';
import 'package:kosh/player/song.dart';
import 'package:kosh/player/state.dart';
import 'package:kosh/style/style.dart';
import 'package:kosh/widgets/album_art.dart';
import 'package:kosh/widgets/song_info.dart';

class SongListTile extends StatelessWidget {
  const SongListTile({super.key, required this.song});

  final Song song;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '${song.title}, ${song.artist}',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          PlayerState.playSong(song);
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppInset.screenEdgePadding, vertical: AppSpacing.xs4),
          child: Row(
            children: [
              AlbumArt(size: AppAlbumCover.sm, radius: AppRadii.sm, imageBytes: song.albumArt),
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
              const Icon(SFSymbols.ellipsis, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}
