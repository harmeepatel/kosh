import 'dart:math' as math;
import 'package:flutter/material.dart';

class AppSpacing {
  AppSpacing._();
  static const double _ratio = 1.25;
  static const double xs6 = xs5 / _ratio;
  static const double xs5 = xs4 / _ratio;
  static const double xs4 = xs3 / _ratio;
  static const double xs3 = xs2 / _ratio;
  static const double xs2 = xs / _ratio;
  static const double xs = sm / _ratio;
  static const double sm = md / _ratio;
  static const double md = 16;
  static const double lg = md * _ratio;
  static const double xl = lg * _ratio;
  static const double xxl = xl * _ratio;
  static const double xxxl = xxl * _ratio;
}

class AppGeometry {
  AppGeometry._();
  static const double ratio = 1.618;
  static double pillRadius(double height) => height / 2;
  static double concentricRadius(double outerRadius, double padding) => math.max(0, outerRadius - padding);
  static const double deviceCornerRadius = 34;
  static const double topBarHeight = 64;
  static const double dockHeight = 52;
  static const double borderOpacity = 0.08;
  static const double borderWidth = 1;
}

class AppInset {
  AppInset._();
  static const double screenEdgePadding = AppSpacing.sm;
  static const double listSeparatorLeft = screenEdgePadding + AppAlbumCover.sm + AppSpacing.md;

  static double topBarHeight(BuildContext context) => AppGeometry.topBarHeight + MediaQuery.paddingOf(context).top;

  static double bottomMargin(BuildContext context) {
    final safeBottom = MediaQuery.paddingOf(context).bottom;
    if (safeBottom == 0) return AppSpacing.md;
    if (safeBottom > 36) return safeBottom + AppSpacing.xs;
    return 21;
  }

  static double navBarHeight() => AppAlbumCover.sm;
  static double bottomNavHeightWithPad(BuildContext context) => navBarHeight() + bottomMargin(context);
  static double totalBottomHeight(BuildContext context) =>
      bottomNavHeightWithPad(context) + screenEdgePadding + AppGeometry.dockHeight;
}

class AppTiming {
  AppTiming._();
  static const Duration sm = Duration(milliseconds: 120);
  static const Duration md = Duration(milliseconds: 240);
  static const Duration lg = Duration(milliseconds: 360);
}

class AppBlur {
  AppBlur._();
  static const double xs = sm / AppGeometry.ratio;
  static const double sm = md / AppGeometry.ratio;
  static const double md = 16;
  static const double lg = md * AppGeometry.ratio;
  static const double xl = lg * AppGeometry.ratio;
}

class AppRadii {
  AppRadii._();
  static const double cornerSmoothing = 1;
  static const double xs = sm / AppGeometry.ratio;
  static const double sm = md / AppGeometry.ratio;
  static const double md = 8;
  static const double lg = md * AppGeometry.ratio;
  static const double xl = lg * AppGeometry.ratio;
}

class AppAlbumCover {
  AppAlbumCover._();
  static const double xs = sm / AppGeometry.ratio;
  static const double sm = 52;
  static const double md = sm * AppGeometry.ratio;
  static const double lg = md * AppGeometry.ratio;
}

class AppIcon {
  AppIcon._();
  static const double xs = sm / AppGeometry.ratio;
  static const double sm = md / AppGeometry.ratio;
  static const double md = 36;
  static const double lg = md * AppGeometry.ratio;
  static const double xl = lg * AppGeometry.ratio;
}

class AppColors {
  AppColors._();
  static const Color background = Colors.black;
  static const Color primaryText = Color(0xfffdfdfd);
  static final Color secondaryText = Colors.grey.shade500;
  static final Color albumPlaceholder = Colors.blue.shade800;
  static const Color divider = Colors.white12;
}

class AppTextStyles {
  AppTextStyles._();
  static const TextStyle header = TextStyle(fontSize: 32, fontWeight: FontWeight.w500, color: AppColors.primaryText);
  static const TextStyle listTitle = TextStyle(color: AppColors.primaryText, fontSize: 16);
  static final TextStyle listArtist = TextStyle(
    color: AppColors.secondaryText,
    fontWeight: FontWeight.w300,
    fontSize: 12,
  );
}
