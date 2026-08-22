import 'dart:math' as math;
import 'package:flutter/material.dart';

/// 1. SPACING (Proportional Scale)
class AppSpacing {
  AppSpacing._();

  static const double ratio = 1.25;
  static const double base = 16.0;

  static const double xs4 = xs3 / ratio;
  static const double xs3 = xs2 / ratio;
  static const double xs2 = xs / ratio;
  static const double xs = sm / ratio;
  static const double sm = base / ratio; // 12.8
  static const double md = base; // 16.0
  static const double lg = base * ratio; // 20.0
  static const double xl = lg * ratio;
}

/// 2. APPLE-STYLE GEOMETRY & MATH
class AppGeometry {
  AppGeometry._();

  static const double goldenRatio = 1.618;

  /// Calculates a perfect pill radius (always exactly half the height)
  static double pillRadius(double height) => height / 2;

  /// The Golden Rule of Concentric Radii: Inner = Outer - Padding.
  /// Use this whenever nesting a rounded box inside another rounded box.
  /// The [math.max] ensures the radius never drops below 0.
  static double concentricRadius(double outerRadius, double padding) {
    return math.max(0.0, outerRadius - padding);
  }

  /// Apple's "Squircle" continuous curve approximation for standard shapes.
  /// Drop this into a Container's decoration to get smoother corners than BorderRadius.circular.
  static ShapeBorder squircleBorder(
    double radius, {
    BorderSide side = BorderSide.none,
  }) {
    return ContinuousRectangleBorder(
      borderRadius: BorderRadius.circular(radius),
      side: side,
    );
  }

  // --- Base Values ---
  static const double deviceCornerRadius = 34.0;
  static const double topBarHeight = 64.0;

  // Example specific sizes that can be adapted per project
  static const double bottomNavIconSize = 28.0;
  static const double dockHeight = 52.0;

  static const double borderOpacity = 0.08;
  static const double borderWidth = 1.0;
}

/// 3. LAYOUT & INSETS
class AppInset {
  AppInset._();

  static const double screenEdgePadding = AppSpacing.xs2;

  static double topBarHeight(BuildContext context) {
    return AppGeometry.topBarHeight + MediaQuery.paddingOf(context).top;
  }

  static double bottomMargin(BuildContext context) {
    final safeBottom = MediaQuery.paddingOf(context).bottom;
    if (safeBottom == 0) return 16.0;
    if (safeBottom > 36.0) return safeBottom + 8.0;
    return 21.0;
  }

  static double navBarHeight() {
    // 28.0 + (12.8 * 2) = 53.6
    return AppGeometry.bottomNavIconSize + (AppSpacing.sm * 2);
  }

  static double bottomNavHeightWithPad(BuildContext context) {
    return navBarHeight() + bottomMargin(context);
  }

  static double totalBottomheight(BuildContext context) {
    return bottomNavHeightWithPad(context) +
        screenEdgePadding +
        AppGeometry.dockHeight;
  }
}

/// 4. TIMING
class AppTiming {
  AppTiming._();

  static const Duration sm = Duration(milliseconds: 100);
  static const Duration md = Duration(milliseconds: 200);
  static const Duration lg = Duration(milliseconds: 300);
}

/// 5. RADII & BLURS
class AppRadii {
  AppRadii._();
  static const double sm = 6.0;
  static const double md = 8.0;
  static const double lg = 16.0;
}

class AppBlur {
  AppBlur._();
  static const double md = 16.0;
  static const double lg = md * AppGeometry.goldenRatio;
  static const double xl = lg * AppGeometry.goldenRatio;
}
