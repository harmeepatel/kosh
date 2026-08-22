// import 'dart:ui';
//
// import 'package:flutter/material.dart';
//
// import '../style.dart';
//
// class FrostedGlassShell extends StatelessWidget {
//   const FrostedGlassShell({
//     super.key,
//     required this.radius,
//     required this.child,
//     this.borderAlpha = AppGeometry.borderOpacity,
//     this.blurSigma = AppBlur.lg,
//   });
//
//   final double radius;
//   final Widget child;
//   final double borderAlpha;
//   final double blurSigma;
//
//   Color get backgroundColor => Colors.black.withValues(alpha: 0.0);
//
//   @override
//   Widget build(BuildContext context) {
//     final borderRadius = BorderRadius.circular(radius);
//
//     return ClipRRect(
//       clipBehavior: Clip.antiAlias,
//       borderRadius: borderRadius,
//       child: BackdropFilter(
//         filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
//         child: Container(
//           decoration: BoxDecoration(
//             color: backgroundColor,
//             borderRadius: borderRadius,
//             border: borderAlpha > 0
//                 ? Border.all(
//                     color: Colors.white.withValues(alpha: borderAlpha),
//                     width: AppGeometry.borderWidth,
//                   )
//                 : null,
//           ),
//           child: child,
//         ),
//       ),
//     );
//   }
// }

import 'dart:ui';
import 'package:flutter/material.dart';
import '../style.dart';

class FrostedGlassShell extends StatelessWidget {
  const FrostedGlassShell({
    super.key,
    required this.radius,
    required this.child,
    this.borderAlpha = AppGeometry.borderOpacity,
    this.blurSigma = AppBlur.lg,
    this.grainOpacity = 0.05, // Added to control noise intensity
  });

  final double radius;
  final Widget child;
  final double borderAlpha;
  final double blurSigma;
  final double grainOpacity;

  Color get backgroundColor => Colors.black.withValues(alpha: 0.16);

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(radius);

    return ClipRRect(
      clipBehavior: Clip.antiAlias,
      borderRadius: borderRadius,
      child: Stack(
        fit: StackFit.passthrough,
        children: [
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
              child: const SizedBox.shrink(),
            ),
          ),

          // The Grain Overlay
          Positioned.fill(
            child: Opacity(
              opacity: grainOpacity,
              child: Image.asset(
                'assets/noise.png',
                repeat: ImageRepeat.repeat,
                fit: BoxFit.none,
              ),
            ),
          ),

          // 3. The Border, Background Color, and Content
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
