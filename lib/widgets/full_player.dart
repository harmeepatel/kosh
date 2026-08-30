import 'dart:typed_data';
import 'package:figma_squircle/figma_squircle.dart';
import 'package:flutter/material.dart';
import 'package:kosh/player/song.dart';
import 'package:kosh/player/state.dart';
import 'package:kosh/style/style.dart';
import 'package:kosh/widgets/album_art.dart';
import 'package:kosh/widgets/song_info.dart';

const _horizontalPadding = AppSpacing.xl;

class FullPlayer extends StatelessWidget {
  const FullPlayer({super.key});

  @override
  Widget build(BuildContext context) {
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
                    Padding(
                      padding: EdgeInsets.only(
                        bottom: MediaQuery.paddingOf(context).top * 1.5,
                      ),

                      child: Container(
                        width: MediaQuery.sizeOf(context).width * 0.2,
                        height: AppGeometry.borderWidth * 4,
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

                    _AlbumArtCover(albumArtData: song?.albumArt),

                    _SongDetails(
                      title: song?.title ?? "Not Playing",
                      artist: song?.artist ?? "-",
                      format: song?.format,
                    ),

                    _PlaybackProgress(mediaType: song?.format),
                    const _PlaybackControls(),
                    const _VolumeControls(),
                    const _BottomActions(),

                    Text(
                      "HP's APP 3",
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.75),
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
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
  const _AlbumArtCover({this.albumArtData});
  final Uint8List? albumArtData;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: _horizontalPadding),
      child: AlbumArt(
        radius: AppRadii.lg,
        imageBytes: albumArtData,
        customFallback: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xffd5c0b7), Color(0xff735f5b)],
            ),
          ),
          child: const Center(
            child: Icon(
              Icons.music_note_rounded,
              color: Colors.white54,
              size: 100,
            ),
          ),
        ),
      ),
    );
  }
}

class _SongDetails extends StatelessWidget {
  const _SongDetails({required this.title, required this.artist, this.format});
  final String title;
  final String artist;
  final String? format;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: _horizontalPadding,
        vertical: AppSpacing.lg,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: SongInfo(
              title: title,
              artist: artist,
              titleStyle: const TextStyle(
                color: AppColors.primaryText,
                fontSize: 22,
                fontWeight: FontWeight.w600,
              ),
              artistStyle: TextStyle(
                color: AppColors.primaryText.withValues(alpha: 0.65),
                fontSize: 18,
              ),
              spacing: 4,
            ),
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(
              Icons.star_border_rounded,
              color: Colors.white,
              size: 36,
            ),
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(
              Icons.more_horiz_rounded,
              color: Colors.white,
              size: 32,
            ),
          ),
        ],
      ),
    );
  }
}

class _PlaybackProgress extends StatelessWidget {
  const _PlaybackProgress({this.mediaType});
  static const _secondaryText = TextStyle(
    color: Colors.white54,
    fontSize: 17,
    fontWeight: FontWeight.w500,
  );

  final String? mediaType;

  @override
  Widget build(BuildContext context) {
    final localMediaType = mediaType;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: _horizontalPadding),
      child: Column(
        children: [
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 7,
              thumbShape: SliderComponentShape.noThumb,
              overlayShape: SliderComponentShape.noOverlay,
              activeTrackColor: Colors.white70,
              inactiveTrackColor: Colors.white24,
            ),
            child: Slider(value: 0.23, onChanged: (_) {}),
          ),
          if (localMediaType != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('0:58', style: _secondaryText),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 13,
                      vertical: 6,
                    ),
                    decoration: ShapeDecoration(
                      color: Colors.white.withValues(alpha: 0.12),
                      shape: SmoothRectangleBorder(
                        borderRadius: SmoothBorderRadius(
                          cornerRadius: AppRadii.md,
                          cornerSmoothing: AppRadii.cornerSmoothing,
                        ),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.graphic_eq_rounded,
                          color: Colors.white70,
                          size: 19,
                        ),
                        SizedBox(width: 6),
                        Text(
                          localMediaType,
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Text('-3:23', style: _secondaryText),
                ],
              ),
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
          iconSize: 46,
          icon: const Icon(Icons.skip_previous_rounded, color: Colors.white),
        ),
        const SizedBox(width: 65),
        IconButton(
          onPressed: () {},
          iconSize: 76,
          icon: const Icon(Icons.play_arrow_rounded, color: Colors.white),
        ),
        const SizedBox(width: 65),
        IconButton(
          onPressed: () {},
          iconSize: 46,
          icon: const Icon(Icons.skip_next_rounded, color: Colors.white),
        ),
      ],
    );
  }
}

class _VolumeControls extends StatelessWidget {
  const _VolumeControls();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: _horizontalPadding),
      child: Row(
        children: [
          const Icon(
            Icons.volume_mute_rounded,
            color: Colors.white70,
            size: 25,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 7,
                thumbShape: SliderComponentShape.noThumb,
                overlayShape: SliderComponentShape.noOverlay,
                activeTrackColor: Colors.white70,
                inactiveTrackColor: Colors.white24,
              ),
              child: Slider(value: 0.58, onChanged: (_) {}),
            ),
          ),
          const SizedBox(width: 12),
          const Icon(Icons.volume_up_rounded, color: Colors.white70, size: 27),
        ],
      ),
    );
  }
}

class _BottomActions extends StatelessWidget {
  const _BottomActions();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        IconButton(
          onPressed: () {},
          icon: const Icon(
            Icons.chat_bubble_outline_rounded,
            color: Colors.white70,
            size: 31,
          ),
        ),
        IconButton(
          onPressed: () {},
          icon: const Icon(
            Icons.headphones_rounded,
            color: Colors.white70,
            size: 32,
          ),
        ),
        IconButton(
          onPressed: () {},
          icon: const Icon(
            Icons.queue_music_rounded,
            color: Colors.white70,
            size: 32,
          ),
        ),
      ],
    );
  }
}
