import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:inspire_blur/inspire_blur.dart';
import 'package:kosh/style.dart';

class TopBar extends StatelessWidget {
  const TopBar({
    super.key,
    required this.scrollOffset,
    this.title,
    this.children,
  });

  final ValueListenable<double> scrollOffset;
  final Widget? title;
  final List<Widget>? children;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 0,
      right: 0,
      height: AppInset.topBarHeight(context),
      child: ValueListenableBuilder<double>(
        valueListenable: scrollOffset,
        builder: (context, offset, _) {
          final progress = (offset / AppGeometry.topBarHeight).clamp(0.0, 1.0);

          return Stack(
            children: [
              _BlurLayer(progress: progress),
              _TopBarContent(
                progress: progress,
                title: title,
                actions: children,
              ),
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
    final sigma = Spacing.md * progress;

    return Inspire.backdropBlur(
      config: InspireBlurConfig.topToBottom(sigma: sigma, extent: 1.2),
    );
  }
}

class _TopBarContent extends StatelessWidget {
  const _TopBarContent({required this.progress, this.title, this.actions});

  final double progress;
  final Widget? title;
  final List<Widget>? actions;

  @override
  Widget build(BuildContext context) {
    if (title == null && actions == null) {
      return const SizedBox.shrink();
    }

    final titleScale = lerpDouble(1, 0, progress)!;

    return SafeArea(
      child: SizedBox(
        height: AppGeometry.topBarHeight,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppInset.screenEdgePadding,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (title != null)
                Transform.scale(
                  scale: titleScale,
                  alignment: Alignment.centerLeft,
                  child: title,
                ),
              if (actions != null)
                Row(mainAxisSize: MainAxisSize.min, children: actions!),
            ],
          ),
        ),
      ),
    );
  }
}
