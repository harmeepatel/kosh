import 'package:flutter/material.dart';
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
          IconButton(
            tooltip: 'Play',
            onPressed: () {},
            icon: const Icon(SFSymbols.play_fill, color: Colors.white, size: AppIcon.sm),
          ),
        ],
      ),
    );
  }
}
