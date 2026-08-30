import 'dart:ui';
import 'package:figma_squircle/figma_squircle.dart';
import 'package:flutter/material.dart';
import 'package:kosh/style/style.dart';

class FrostedGlassShell extends StatelessWidget {
  const FrostedGlassShell({
    super.key,
    required this.radius,
    required this.child,
    this.borderAlpha = AppGeometry.borderOpacity,
    this.blurSigma = AppBlur.sm,
    this.grainOpacity = 0.1,
  });

  final double radius;
  final Widget child;
  final double borderAlpha;
  final double blurSigma;
  final double grainOpacity;

  Color get backgroundColor => Colors.black.withValues(alpha: 0.4);

  @override
  Widget build(BuildContext context) {
    final borderRadius = SmoothBorderRadius(
      cornerRadius: radius,
      cornerSmoothing: AppRadii.cornerSmoothing,
    );

    return ClipSmoothRect(
      clipBehavior: Clip.antiAlias,
      radius: borderRadius,
      child: Stack(
        fit: StackFit.passthrough,
        children: [
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
              child: const SizedBox.shrink(),
            ),
          ),
          Positioned.fill(
            child: Opacity(
              opacity: grainOpacity,
              child: Image.asset(
                'assets/noise.png',
                repeat: ImageRepeat.repeat,
                fit: BoxFit.fill,
                colorBlendMode: BlendMode.difference,
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: borderRadius,
              border: borderAlpha > 0
                  ? Border.all(
                      color: Colors.white.withValues(alpha: borderAlpha),
                      width: AppGeometry.borderWidth,
                    )
                  : null,
            ),
            child: child,
          ),
        ],
      ),
    );
  }
}
