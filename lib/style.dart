import 'package:flutter/material.dart';

class Spacing {
  Spacing._();

  static const ratio = 1.25;
  static const base = 16.0;

  static const xs5 = xs4 / ratio;
  static const xs4 = xs3 / ratio;
  static const xs3 = xs2 / ratio;
  static const xs2 = xs / ratio;
  static const xs = sm / ratio;
  static const sm = base / ratio;
  static const md = base;
  static const lg = base * ratio;
  static const xl = lg * ratio;
  static const xl2 = xl * ratio;
  static const xl3 = xl2 * ratio;
  static const xl4 = xl3 * ratio;
  static const xl5 = xl4 * ratio;
  static const xl6 = xl5 * ratio;
  static const xl7 = xl6 * ratio;
}

class AppGeometry {
  AppGeometry._();

  static const goldenRatio = 1.618;

  static const topBarHeight = 64.0;
  static const borderRadius = 8.0;
  static const deviceCornerRadius = 44.0;

  static const bottomPadding = 20.0;
  static const bottomNavIconSize = 28.0;
  static const bottomNavPadding = Spacing.sm;
  static const bottomNavCollapsedScale = 0.2;

  static const dockHeight = 52.0;
}

// class AppInset {
//   AppInset._();
//
//   static const screenEdgePadding = Spacing.xs2;
//
//   static double topBarHeight(BuildContext context) {
//     return AppGeometry.topBarHeight + MediaQuery.paddingOf(context).top;
//   }
//
//   static double bottomNavHeightWithPad(BuildContext context) {
//     final safeBottom = MediaQuery.paddingOf(context).bottom;
//     final actualBottomPadding = safeBottom > AppGeometry.bottomPadding
//         ? safeBottom
//         : AppGeometry.bottomPadding;
//
//     return AppGeometry.bottomNavIconSize +
//         actualBottomPadding +
//         (AppGeometry.bottomNavPadding * 2);
//   }
// }

class AppInset {
  AppInset._();

  static const screenEdgePadding = Spacing.xs2;

  static double topBarHeight(BuildContext context) {
    return AppGeometry.topBarHeight + MediaQuery.paddingOf(context).top;
  }

  static double bottomMargin(BuildContext context) {
    final safeBottom = MediaQuery.paddingOf(context).bottom;

    if (safeBottom == 0) {
      return 16.0;
    }
    if (safeBottom > 36.0) {
      return safeBottom + 8.0;
    }
    return 21.0;
  }

  static double navBarHeight() {
    return AppGeometry.bottomNavIconSize + (AppGeometry.bottomNavPadding * 2);
  }

  static double bottomNavHeightWithPad(BuildContext context) {
    return navBarHeight() + bottomMargin(context);
  }
}

class AppTiming {
  AppTiming._();

  static const scrollBuffer = 10.0;

  static const sm = Duration(milliseconds: 128);
  static const md = Duration(milliseconds: 256);
  static const lg = Duration(milliseconds: 512);
}

class AppBlur {
  AppBlur._();

  static const bottomNavBlur = Spacing.xs2;
}
