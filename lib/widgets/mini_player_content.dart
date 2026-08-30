import 'package:flutter/material.dart';
import 'package:kosh/player/song.dart';
import 'package:kosh/player/state.dart';
import 'package:kosh/style/style.dart';
import 'package:kosh/widgets/album_art.dart';
import 'package:kosh/widgets/song_info.dart';

class MiniPlayerContent extends StatelessWidget {
  const MiniPlayerContent({super.key});

  @override
  Widget build(BuildContext context) {
    final iconSize = AppAlbumCoverSize.sm;
    final navHeight = AppInset.navBarHeight();

    return SizedBox(
      height: navHeight,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          vertical: AppSpacing.xs2,
          horizontal: AppSpacing.lg,
        ),

        child: ValueListenableBuilder<Song?>(
          valueListenable: PlayerState.currentSong,
          builder: (context, song, _) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.center,

              children: [
                AlbumArt(
                  size: AppAlbumCoverSize.xs,
                  radius: AppRadii.xs,
                  imageBytes: song?.albumArt,
                  fallbackIconColor: Colors.white54,
                ),
                const SizedBox(width: AppSpacing.sm),

                Expanded(
                  child: SongInfo(
                    title: song?.title ?? "Not Playing",
                    artist: song?.artist ?? "Tap a song to play",
                    titleStyle: TextStyle(
                      color: AppColors.primaryText,
                      fontWeight: FontWeight.w600,
                      fontSize: (iconSize * 0.45).clamp(11.0, 13.5),
                      height: 1.0,
                    ),
                    artistStyle: TextStyle(
                      color: AppColors.primaryText.withValues(alpha: 0.7),
                      fontSize: (iconSize * 0.38).clamp(10.0, 11.5),
                      height: 1.0,
                    ),
                  ),
                ),

                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: BoxConstraints.tight(Size(iconSize, iconSize)),
                  icon: Icon(
                    Icons.play_arrow_rounded,
                    color: AppColors.primaryText,
                    size: iconSize * 0.85,
                  ),
                  onPressed: () {},
                ),

                const SizedBox(width: 6),
                AspectRatio(
                  aspectRatio: 1,
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    constraints: BoxConstraints.tight(Size(iconSize, iconSize)),
                    icon: Icon(
                      Icons.fast_forward_rounded,
                      color: AppColors.primaryText,
                      size: iconSize * 0.75,
                    ),
                    onPressed: () {},
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
