import 'package:flutter/material.dart';

class AppSpacing {
  AppSpacing._();

  static const double xxs = 4;
  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 20;
  static const double xl = 24;
  static const double xxl = 32;
  static const double xxxl = 40;

  static const EdgeInsets page = EdgeInsets.all(md);
  static const EdgeInsets card = EdgeInsets.all(lg);
  static const EdgeInsets cardCompact =
      EdgeInsets.symmetric(horizontal: md, vertical: sm);
}

class AppRadii {
  AppRadii._();

  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
}
