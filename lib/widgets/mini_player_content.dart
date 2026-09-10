import 'package:flutter/material.dart';
import 'package:kosh/player/state.dart';
import 'package:kosh/style/style.dart';
import 'package:flutter_cupertino_symbols/flutter_cupertino_symbols.dart';

class MiniPlayerContent extends StatelessWidget {
  const MiniPlayerContent({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Row(
        children: [
          const Spacer(),
          IconButton(
            tooltip: 'Favorite',
            onPressed: () {},
            icon: const Icon(SFSymbols.suit_heart, color: Colors.white, size: AppIcon.sm),
          ),
          ValueListenableBuilder<bool>(
            valueListenable: PlayerState.isPlaying,
            builder: (context, isPlaying, _) {
              return IconButton(
                tooltip: isPlaying ? 'Pause' : 'Play',
                onPressed: PlayerState.togglePlayPause,
                icon: Icon(
                  isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                  color: Colors.white,
                  size: AppIcon.md,
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
