import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:inspire_blur/inspire_blur.dart';
import 'package:kosh/style.dart';

class TopAppBar extends StatelessWidget {
  const TopAppBar({
    super.key,
    required this.scrollOffset,
    this.children = const [],
  });

  final ValueListenable<double> scrollOffset;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      height: Scale.topBarInset(context),
      child: Stack(
        children: [
          ValueListenableBuilder<double>(
            valueListenable: scrollOffset,
            builder: (context, offset, _) {
              final double sigma = (offset / 4).clamp(0, Scale.xl);
              return Inspire.backdropBlur(
                config: InspireBlurConfig.topToBottom(sigma: sigma),
              );
            },
          ),
          if (children.isNotEmpty)
            SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: Scale.screenEdgePadding,
                  vertical: Scale.screenEdgePadding,
                ),
                child: Row(mainAxisAlignment: .start, children: children),
              ),
            ),
        ],
      ),
    );
  }
}
