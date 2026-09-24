import 'package:flutter/material.dart';

class AppSpacing {
  AppSpacing._();

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;
}

class AppRadius {
  AppRadius._();

  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double pill = 100;
  static const double card = 16;
}

class AppShadows {
  AppShadows._();

  static const card = BoxShadow(
    color: Color(0x140B1F45),
    blurRadius: 14,
    offset: Offset(0, 6),
  );

  static const soft = BoxShadow(
    color: Color(0x0A0B1F45),
    blurRadius: 8,
    offset: Offset(0, 3),
  );
}