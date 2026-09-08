import 'package:figma_squircle/figma_squircle.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cupertino_symbols/flutter_cupertino_symbols.dart';
import 'package:kosh/player/song.dart';
import 'package:kosh/player/state.dart';
import 'package:kosh/style/style.dart';

const horizontalPadding = AppSpacing.lg;

class FullPlayer extends StatelessWidget {
  const FullPlayer({super.key, this.progress = 1.0});

  final double progress;

  @override
  Widget build(BuildContext context) {
    final handleOpacity = ((progress - 0.85) / 0.15).clamp(0.0, 1.0);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: ValueListenableBuilder<Song?>(
        valueListenable: PlayerState.currentSong,
        builder: (context, song, _) {
          return Stack(
            children: [
              SafeArea(
                child: Column(
                  children: [
                    // Handle container
                    Padding(
                      padding: const EdgeInsets.only(top: AppSpacing.md, bottom: AppSpacing.lg),
                      child: Opacity(
                        opacity: handleOpacity,
                        child: Container(
                          width: MediaQuery.sizeOf(context).width / 5,
                          height: AppSpacing.xs5,
                          decoration: ShapeDecoration(
                            color: Colors.white30,
                            shape: SmoothRectangleBorder(
                              borderRadius: SmoothBorderRadius(
                                cornerRadius: AppRadii.xs,
                                cornerSmoothing: AppRadii.cornerSmoothing,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                    const _AlbumArtCover(),
                    const _SongDetails(),

                    _PlaybackProgress(mediaType: song?.format),

                    const _PlaybackControls(),
                    const _VolumeControls(),
                    const _BottomActions(),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _AlbumArtCover extends StatelessWidget {
  const _AlbumArtCover();

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context).width - (horizontalPadding * 1.2);
    return SizedBox(width: size, height: size);
  }
}

class _SongDetails extends StatelessWidget {
  const _SongDetails();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: AppAlbumCover.sm,
      margin: const EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: AppSpacing.lg),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Spacer for floating shared song info title
          const Expanded(child: SizedBox.expand()),
          IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: AppAlbumCover.xs, minHeight: AppAlbumCover.xs),
            onPressed: () {},
            icon: const Icon(SFSymbols.suit_heart, color: Colors.white, size: AppIcon.md),
          ),
          IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: AppAlbumCover.xs, minHeight: AppAlbumCover.xs),
            onPressed: () {},
            icon: const Icon(SFSymbols.ellipsis, color: Colors.white, size: AppIcon.md),
          ),
        ],
      ),
    );
  }
}

class _PlaybackProgress extends StatelessWidget {
  const _PlaybackProgress({this.mediaType});

  static const _secondaryText = TextStyle(color: Colors.white54, fontSize: AppSpacing.sm, fontWeight: FontWeight.w500);

  final String? mediaType;

  @override
  Widget build(BuildContext context) {
    final localMediaType = mediaType;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: horizontalPadding),
      child: Column(
        children: [
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: AppRadii.sm,
              thumbShape: SliderComponentShape.noThumb,
              overlayShape: SliderComponentShape.noOverlay,
              activeTrackColor: Colors.white70,
              inactiveTrackColor: Colors.white24,
            ),
            child: Slider(value: 0.2, onChanged: (_) {}),
          ),
          if (localMediaType != null)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('0:58', style: _secondaryText),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs5, vertical: AppSpacing.xs6),
                  decoration: ShapeDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    shape: SmoothRectangleBorder(
                      borderRadius: SmoothBorderRadius(
                        cornerRadius: AppRadii.xs,
                        cornerSmoothing: AppRadii.cornerSmoothing,
                      ),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.graphic_eq_rounded, color: Colors.white70, size: AppRadii.md),
                      const SizedBox(width: AppSpacing.xs5),
                      Text(
                        localMediaType,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: AppSpacing.xs3,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const Text('-3:23', style: _secondaryText),
              ],
            ),
        ],
      ),
    );
  }
}

class _PlaybackControls extends StatelessWidget {
  const _PlaybackControls();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          onPressed: () {},
          iconSize: AppIcon.md,
          icon: const Icon(SFSymbols.backward_fill, color: Colors.white),
        ),
        const SizedBox(width: AppSpacing.xxxl),
        IconButton(
          onPressed: () {},
          iconSize: AppIcon.lg,
          icon: const Icon(SFSymbols.play_fill, color: Colors.white),
        ),
        const SizedBox(width: AppSpacing.xxxl),
        IconButton(
          onPressed: () {},
          iconSize: AppIcon.md,
          icon: const Icon(SFSymbols.forward_fill, color: Colors.white),
        ),
      ],
    );
  }
}

class _VolumeControls extends StatelessWidget {
  const _VolumeControls();

  @override
  Widget build(BuildContext context) {
    const double iconSize = AppAlbumCover.xs;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: horizontalPadding),
      child: Row(
        children: [
          const Icon(Icons.volume_mute_rounded, color: Colors.white70, size: iconSize),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: AppRadii.sm,
                thumbShape: SliderComponentShape.noThumb,
                tickMarkShape: SliderTickMarkShape.noTickMark,
                overlayShape: SliderComponentShape.noOverlay,
                activeTrackColor: Colors.white70,
                inactiveTrackColor: Colors.white24,
              ),
              child: Slider(value: 0.58, onChanged: (_) {}),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          const Icon(Icons.volume_up_rounded, color: Colors.white70, size: iconSize),
        ],
      ),
    );
  }
}

class _BottomActions extends StatelessWidget {
  const _BottomActions();

  @override
  Widget build(BuildContext context) {
    const double size = AppIcon.md;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        IconButton(
          onPressed: () {},
          icon: const Icon(SFSymbols.text_bubble, color: Colors.white70, size: size),
        ),
        IconButton(
          onPressed: () {},
          icon: const Icon(SFSymbols.airpodspro, color: Colors.white70, size: size),
        ),
        IconButton(
          onPressed: () {},
          icon: const Icon(SFSymbols.list_bullet, color: Colors.white70, size: size),
        ),
      ],
    );
  }
}
