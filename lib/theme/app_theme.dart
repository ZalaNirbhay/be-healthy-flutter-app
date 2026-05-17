import 'package:flutter/material.dart';

/// ═══════════════════════════════════════════════
///  APP SPACING — Consistent spacing tokens
/// ═══════════════════════════════════════════════
class AppSpacing {
  AppSpacing._();

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double base = 16;
  static const double lg = 20;
  static const double xl = 24;
  static const double xxl = 32;
  static const double xxxl = 40;
}

/// ═══════════════════════════════════════════════
///  APP RADIUS — Consistent border radius tokens
/// ═══════════════════════════════════════════════
class AppRadius {
  AppRadius._();

  static const double sm = 12;
  static const double md = 16;
  static const double lg = 20;
  static const double xl = 25;
  static const double xxl = 30;
  static const double pill = 50;

  static BorderRadius get smBorder => BorderRadius.circular(sm);
  static BorderRadius get mdBorder => BorderRadius.circular(md);
  static BorderRadius get lgBorder => BorderRadius.circular(lg);
  static BorderRadius get xlBorder => BorderRadius.circular(xl);
  static BorderRadius get xxlBorder => BorderRadius.circular(xxl);
  static BorderRadius get pillBorder => BorderRadius.circular(pill);
}

/// ═══════════════════════════════════════════════
///  APP TEXT STYLES — Consistent typography
/// ═══════════════════════════════════════════════
class AppTextStyles {
  AppTextStyles._();

  static TextStyle heading(Color color) => TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.bold,
        color: color,
      );

  static TextStyle title(Color color) => TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: color,
      );

  static TextStyle subtitle(Color color) => TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: color,
      );

  static TextStyle body(Color color) => TextStyle(
        fontSize: 16,
        color: color,
      );

  static TextStyle bodyBold(Color color) => TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: color,
      );

  static TextStyle caption(Color color) => TextStyle(
        fontSize: 13,
        color: color,
      );

  static TextStyle small(Color color) => TextStyle(
        fontSize: 12,
        color: color,
      );

  static TextStyle label(Color color) => TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: color,
      );

  static TextStyle sectionHeader(Color color) => TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: color,
      );
}

/// ═══════════════════════════════════════════════
///  APP DURATIONS — Consistent animation timings
/// ═══════════════════════════════════════════════
class AppDurations {
  AppDurations._();

  static const Duration fast = Duration(milliseconds: 150);
  static const Duration normal = Duration(milliseconds: 300);
  static const Duration slow = Duration(milliseconds: 500);
  static const Duration stagger = Duration(milliseconds: 100);
  static const Duration pageTransition = Duration(milliseconds: 350);
}
