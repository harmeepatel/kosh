import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class Scale {
  Scale._();

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

  static const topBlurHeight = 80.0;
  static const topBlurPadding = topBlurHeight * 0.6;
  static double topBarInset(BuildContext context) =>
      topBlurHeight + MediaQuery.paddingOf(context).top;

  static const screenEdgePadding = xs5;

  static const borderRadius = 8.0;
}
