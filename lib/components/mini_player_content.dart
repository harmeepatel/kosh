import 'package:flutter/material.dart';
import 'package:kosh/style.dart';

/// Pure content for the collapsed pill state.
/// No GestureDetector, no ClipRRect, no BackdropFilter — PlayerDock owns all of that.
class MiniPlayerContent extends StatelessWidget {
  const MiniPlayerContent({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: Spacing.lg,
        vertical: Spacing.xs5,
      ),
      child: Row(
        children: [
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
    );
  }
}
