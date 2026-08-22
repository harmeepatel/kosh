import 'package:flutter/material.dart';
import 'package:kosh/style.dart';

class MiniPlayerContent extends StatelessWidget {
  const MiniPlayerContent({super.key});

  @override
  Widget build(BuildContext context) {
    final iconSize = AppGeometry.bottomNavIconSize;
    final navHeight = AppInset.navBarHeight();

    return SizedBox(
      height: navHeight,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(5),
              child: AspectRatio(
                aspectRatio: 1,
                child: Container(
                  color: Colors.grey.shade800,
                  child: Icon(
                    Icons.music_note,
                    color: Colors.white54,
                    size: iconSize,
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "Don't You (Forget About Me)",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: (iconSize * 0.45).clamp(11.0, 13.5),
                      height: 1.0,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    "Simple Minds",
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: (iconSize * 0.38).clamp(10.0, 11.5),
                      height: 1.0,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            IconButton(
              padding: EdgeInsets.zero,
              constraints: BoxConstraints.tight(Size(iconSize, iconSize)),
              icon: Icon(
                Icons.play_arrow_rounded,
                color: Colors.white,
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
                  color: Colors.white,
                  size: iconSize * 0.75,
                ),
                onPressed: () {},
              ),
            ),
          ],
        ),
      ),
    );
  }
}
