import 'package:flutter/material.dart';
import 'package:kosh/style/style.dart';

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
            icon: const Icon(
              Icons.favorite_border_rounded,
              color: Colors.white,
              size: AppIcon.md,
            ),
          ),
          IconButton(
            tooltip: 'Play',
            onPressed: () {},
            icon: const Icon(
              Icons.play_arrow_rounded,
              color: Colors.white,
              size: AppIcon.md,
            ),
          ),
        ],
      ),
    );
  }
}
