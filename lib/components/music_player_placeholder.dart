import 'dart:ui';

import 'package:flutter/material.dart';

class MusicPlayerPlaceholder extends StatelessWidget {
  const MusicPlayerPlaceholder({
    super.key,
    this.albumArt,
    this.title = "Don't You (Forget About Me)",
    this.artist = 'Simple Minds',
  });

  final ImageProvider? albumArt;
  final String title;
  final String artist;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff453c3c),
      body: Stack(
        children: [
          // Blurred album art background.
          if (albumArt != null)
            Positioned.fill(
              child: ImageFiltered(
                imageFilter: ImageFilter.blur(sigmaX: 45, sigmaY: 45),
                child: Image(image: albumArt!, fit: BoxFit.cover),
              ),
            ),

          // Dark overlay.
          Positioned.fill(
            child: ColoredBox(color: Colors.black.withValues(alpha: 0.48)),
          ),

          SafeArea(
            child: Column(
              children: [
                // const SizedBox(height: 55),

                // Album artwork.
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 38),
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: albumArt != null
                          ? Image(image: albumArt!, fit: BoxFit.cover)
                          : const _AlbumPlaceholder(),
                    ),
                  ),
                ),

                // const Spacer(),

                // Song information.
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 27,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              artist,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.65),
                                fontSize: 22,
                              ),
                            ),
                          ],
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
                ),

                // const SizedBox(height: 32),

                // Progress.
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28),
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

                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('0:58', style: _secondaryText),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 13,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.graphic_eq_rounded,
                                    color: Colors.white70,
                                    size: 19,
                                  ),
                                  SizedBox(width: 6),
                                  Text(
                                    'Lossless',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Text('-3:23', style: _secondaryText),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // const SizedBox(height: 55),

                // Playback controls.
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      onPressed: () {},
                      iconSize: 46,
                      icon: const Icon(
                        Icons.skip_previous_rounded,
                        color: Colors.white,
                      ),
                    ),

                    const SizedBox(width: 65),

                    IconButton(
                      onPressed: () {},
                      iconSize: 76,
                      icon: const Icon(
                        Icons.play_arrow_rounded,
                        color: Colors.white,
                      ),
                    ),

                    // const SizedBox(width: 65),

                    IconButton(
                      onPressed: () {},
                      iconSize: 46,
                      icon: const Icon(
                        Icons.skip_next_rounded,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),

                // const SizedBox(height: 55),

                // Volume.
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28),
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
                      const Icon(
                        Icons.volume_up_rounded,
                        color: Colors.white70,
                        size: 27,
                      ),
                    ],
                  ),
                ),

                // const SizedBox(height: 35),

                // Bottom actions.
                Row(
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
                ),

                // const SizedBox(height: 12),

                Text(
                  "HP's APP 3",
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.75),
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                // const SizedBox(height: 18),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static const _secondaryText = TextStyle(
    color: Colors.white54,
    fontSize: 17,
    fontWeight: FontWeight.w500,
  );
}

class _AlbumPlaceholder extends StatelessWidget {
  const _AlbumPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xffd5c0b7), Color(0xff735f5b)],
        ),
      ),
      child: const Center(
        child: Icon(Icons.music_note_rounded, color: Colors.white54, size: 100),
      ),
    );
  }
}
