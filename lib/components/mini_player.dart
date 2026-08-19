import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:kosh/style.dart';

class MiniPlayer extends StatelessWidget {
  const MiniPlayer({super.key});

  static final _blurFilter = ImageFilter.blur(
    sigmaX: AppBlur.bottomNavBlur,
    sigmaY: AppBlur.bottomNavBlur,
  );

  @override
  Widget build(BuildContext context) {
    return Padding(
      // Keep it horizontally constrained like the bottom nav
      padding: EdgeInsets.symmetric(horizontal: AppGeometry.bottomPadding),
      child: ClipRRect(
        clipBehavior: Clip.antiAlias,
        borderRadius: BorderRadius.circular(999),
        child: BackdropFilter(
          filter: _blurFilter,
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: Spacing.lg,
              vertical: Spacing.xs5,
            ),
            foregroundDecoration: BoxDecoration(
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.25),
                width: 0.8,
              ),
              borderRadius: BorderRadius.circular(999),
            ),
            decoration: const BoxDecoration(color: Color(0x20000000)),
            child: Row(
              children: [
                // Album Art Placeholder
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: Container(
                    width: 38,
                    height: 38,
                    color: Colors.grey.shade800,
                    child: const Icon(
                      Icons.music_note,
                      color: Colors.white54,
                      size: 24,
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Track Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        "Don't You (Forget About Me)",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        "Simple Minds",
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontSize: 13,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),

                // Playback Controls
                IconButton(
                  icon: const Icon(
                    Icons.play_arrow_rounded,
                    color: Colors.white,
                    size: 34,
                  ),
                  onPressed: () {},
                ),
                IconButton(
                  icon: const Icon(
                    Icons.fast_forward_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                  onPressed: () {},
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
