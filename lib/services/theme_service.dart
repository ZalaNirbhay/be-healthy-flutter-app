import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Global Theme Service — Dark/Light mode with Firestore persistence
///
/// Uses a static ValueNotifier so all pages react instantly.
/// Persists preference in Firestore: users/{uid}.dark_mode
class ThemeService {
  static final ValueNotifier<ThemeMode> themeMode =
      ValueNotifier(ThemeMode.light);

  static bool get isDark => themeMode.value == ThemeMode.dark;

  // ═══════════════════════════════════════════════
  //  THEME DATA
  // ═══════════════════════════════════════════════

  static ThemeData get lightTheme => ThemeData(
        brightness: Brightness.light,
        primarySwatch: Colors.green,
        scaffoldBackgroundColor: Colors.transparent,
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Colors.white,
          selectedItemColor: Colors.green,
          unselectedItemColor: Colors.grey,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
      );

  static ThemeData get darkTheme => ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.green,
        scaffoldBackgroundColor: Colors.transparent,
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Color(0xFF1A1A2E),
          selectedItemColor: Color(0xFF6FCF97),
          unselectedItemColor: Colors.grey,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
      );

  // ═══════════════════════════════════════════════
  //  GRADIENT COLORS (used by all pages)
  // ═══════════════════════════════════════════════

  /// Primary gradient for Dashboard
  static List<Color> get dashboardGradient => isDark
      ? const [Color(0xFF1A1A2E), Color(0xFF16213E)]
      : const [Color(0xFF6FCF97), Color(0xFFDFF5EA)];

  /// Secondary gradient for inner pages
  static List<Color> get pageGradient => isDark
      ? const [Color(0xFF1A1A2E), Color(0xFF0F3460)]
      : const [Color(0xFFDFF5EA), Color(0xFFB7E4C7)];

  /// Sidebar gradient
  static List<Color> get sidebarGradient => isDark
      ? const [Color(0xFF16213E), Color(0xFF1A1A2E)]
      : const [Color(0xFF6FCF97), Color(0xFFB7E4C7)];

  // ═══════════════════════════════════════════════
  //  COMPONENT COLORS
  // ═══════════════════════════════════════════════

  static Color get cardColor =>
      isDark ? const Color(0xFF1E2D4A).withOpacity(0.7) : Colors.white.withOpacity(0.7);

  static Color get cardColorLight =>
      isDark ? const Color(0xFF1E2D4A).withOpacity(0.5) : Colors.white.withOpacity(0.5);

  static Color get cardColorStrong =>
      isDark ? const Color(0xFF1E2D4A).withOpacity(0.9) : Colors.white.withOpacity(0.8);

  static Color get surfaceColor =>
      isDark ? const Color(0xFF1E2D4A).withOpacity(0.3) : Colors.white.withOpacity(0.3);

  static Color get textPrimary =>
      isDark ? Colors.white : Colors.black;

  static Color get textSecondary =>
      isDark ? Colors.white70 : Colors.black54;

  static Color get accent => const Color(0xFF6FCF97);

  static Color get dividerColor =>
      isDark ? Colors.white24 : Colors.grey.shade300;

  // ═══════════════════════════════════════════════
  //  PERSISTENCE
  // ═══════════════════════════════════════════════

  /// Load user's theme preference from Firestore
  static Future<void> loadPreference() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;

      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();

      if (doc.exists) {
        final darkMode = doc.data()?['dark_mode'] ?? false;
        themeMode.value = darkMode ? ThemeMode.dark : ThemeMode.light;
      }
    } catch (_) {}
  }

  /// Toggle and persist theme
  static Future<void> toggleTheme() async {
    final newMode =
        isDark ? ThemeMode.light : ThemeMode.dark;
    themeMode.value = newMode;

    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;

      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .update({'dark_mode': newMode == ThemeMode.dark});
    } catch (_) {}
  }

  /// Set theme explicitly
  static Future<void> setDarkMode(bool dark) async {
    themeMode.value = dark ? ThemeMode.dark : ThemeMode.light;

    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;

      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .update({'dark_mode': dark});
    } catch (_) {}
  }
}
