import 'dart:math' as math;
import 'package:flutter/material.dart';

class AppSpacing {
  AppSpacing._();

  static const double ratio = 1.25;
  static const double base = 16.0;

  static const double xs6 = xs5 / ratio;
  static const double xs5 = xs4 / ratio;
  static const double xs4 = xs3 / ratio;
  static const double xs3 = xs2 / ratio;
  static const double xs2 = xs / ratio; // 10.24
  static const double xs = sm / ratio; // 12.8
  static const double sm = base / ratio; // 12.8
  static const double md = base; // 16.0
  static const double lg = base * ratio; // 20.0
  static const double xl = lg * ratio; // 25.0
  static const double xxl = xl * ratio; // 31.25
  static const double xxxl = xxl * ratio; // 39.06
}

class AppGeometry {
  AppGeometry._();

  static const double goldenRatio = 1.618;

  static double pillRadius(double height) => height / 2;

  static double concentricRadius(double outerRadius, double padding) {
    return math.max(0.0, outerRadius - padding);
  }

  static const double deviceCornerRadius = 34.0;
  static const double topBarHeight = 64.0;
  static const double dockHeight = 52.0;
  static const double borderOpacity = 0.08;
  static const double borderWidth = 1.0;
}

class AppInset {
  AppInset._();

  static const double screenEdgePadding = AppSpacing.sm;
  static const double listSeparatorLeft =
      screenEdgePadding + AppAlbumCoverSize.sm + AppSpacing.md;

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
    return AppAlbumCoverSize.xs + (AppSpacing.sm * 2);
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

class AppTiming {
  AppTiming._();
  static const Duration sm = Duration(milliseconds: 120);
  static const Duration md = Duration(milliseconds: 240);
  static const Duration lg = Duration(milliseconds: 360);
}

class AppBlur {
  AppBlur._();
  static const double xs = sm / AppGeometry.goldenRatio;
  static const double sm = md / AppGeometry.goldenRatio;
  static const double md = 16.0;
  static const double lg = md * AppGeometry.goldenRatio;
  static const double xl = lg * AppGeometry.goldenRatio;
}

class AppRadii {
  AppRadii._();
  static double cornerSmoothing = 1.0;
  static const double md = 8.0;
  static const double sm = md / AppGeometry.goldenRatio;
  static const double xs = sm / AppGeometry.goldenRatio;
  static const double lg = md * AppGeometry.goldenRatio;
  static const double xl = lg * AppGeometry.goldenRatio;
}

class AppAlbumCoverSize {
  AppAlbumCoverSize._();
  static const double sm = 52.0;
  static const double xs = sm / AppGeometry.goldenRatio;
  static const double md = sm * AppGeometry.goldenRatio;
  static const double lg = md * AppGeometry.goldenRatio;
}

class AppColors {
  AppColors._();
  static const Color background = Colors.black;
  static const Color primaryText = Color(0xfffdfdfd);
  static final Color secondaryText = Colors.grey.shade500;
  static final Color albumPlaceholder = Colors.grey.shade800;
  static const Color divider = Colors.white12;
}

class AppTextStyles {
  AppTextStyles._();
  static const TextStyle header = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.w700,
    color: AppColors.primaryText,
  );
  static const TextStyle listTitle = TextStyle(
    color: AppColors.primaryText,
    fontSize: 16,
  );
  static TextStyle listArtist = TextStyle(
    color: AppColors.secondaryText,
    fontWeight: .w200,
    fontSize: 12,
  );
}
