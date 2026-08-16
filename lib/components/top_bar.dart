import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:inspire_blur/inspire_blur.dart';
import 'package:kosh/style.dart';

class TopBar extends StatelessWidget {
  const TopBar({super.key, required this.scrollOffset, this.child});

  final ValueListenable<double> scrollOffset;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      height: AppInsets.topBarHeight(context),
      child: ValueListenableBuilder<double>(
        valueListenable: scrollOffset,
        builder: (context, offset, _) {
          final progress = (offset / AppGeometry.topBarHeight).clamp(0.0, 1.0);

          return Stack(
            children: [
              _BlurLayer(progress: progress),
              _TopBarContent(progress: progress, child: child),
            ],
          );
        },
      ),
    );
  }
}

class _BlurLayer extends StatelessWidget {
  const _BlurLayer({required this.progress});

  final double progress;

  @override
  Widget build(BuildContext context) {
    final sigma = Spacing.xl * progress;

    return Inspire.backdropBlur(
      config: InspireBlurConfig.topToBottom(sigma: sigma),
    );
  }
}

class _TopBarContent extends StatelessWidget {
  const _TopBarContent({required this.progress, this.child});

  final double progress;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final child = this.child;
    if (child == null) {
      return const SizedBox.shrink();
    }

    final titleScale = lerpDouble(1, 0, progress)!;

    return SafeArea(
      bottom: false,
      child: SizedBox(
        height: AppGeometry.topBarHeight,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppGeometry.screenEdgePadding,
          ),
          // TODO: currently this button also shrinks on scroll, make it so only text scales and nothing else
          child: Transform.scale(
            scale: titleScale,
            alignment: Alignment.topLeft,
            child: child,
          ),
        ),
      ),
    );
  }
}
