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
  //  PREMIUM COLOR PALETTE
  // ═══════════════════════════════════════════════

  // Dark mode base colors
  static const Color _darkBg = Color(0xFF0F172A);
  static const Color _darkSurface = Color(0xFF1E293B);
  static const Color _darkCard = Color(0xFF253548);
  static const Color _darkCardLight = Color(0xFF1E293B);

  // Light mode base colors
  static const Color _lightBg = Color(0xFFF8FAF9);
  static const Color _lightCard = Colors.white;

  // ═══════════════════════════════════════════════
  //  THEME DATA
  // ═══════════════════════════════════════════════

  static ThemeData get lightTheme => ThemeData(
        brightness: Brightness.light,
        primarySwatch: Colors.green,
        scaffoldBackgroundColor: Colors.transparent,
        colorScheme: ColorScheme.light(
          primary: const Color(0xFF4CAF50),
          secondary: const Color(0xFF6FCF97),
          surface: _lightBg,
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Colors.white,
          selectedItemColor: Color(0xFF4CAF50),
          unselectedItemColor: Colors.grey,
          elevation: 8,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        cardTheme: CardThemeData(
          color: _lightCard,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
          ),
        ),
        dialogTheme: DialogThemeData(
          backgroundColor: _lightCard,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        snackBarTheme: SnackBarThemeData(
          backgroundColor: const Color(0xFF323232),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFFF5F5F5),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(25),
            borderSide: BorderSide.none,
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      );

  static ThemeData get darkTheme => ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.green,
        scaffoldBackgroundColor: Colors.transparent,
        colorScheme: ColorScheme.dark(
          primary: const Color(0xFF6FCF97),
          secondary: const Color(0xFF6FCF97),
          surface: _darkBg,
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: _darkBg,
          selectedItemColor: Color(0xFF6FCF97),
          unselectedItemColor: Colors.grey,
          elevation: 8,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        cardTheme: CardThemeData(
          color: _darkCard,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
          ),
        ),
        dialogTheme: DialogThemeData(
          backgroundColor: _darkSurface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        snackBarTheme: SnackBarThemeData(
          backgroundColor: _darkCard,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: _darkCard,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(25),
            borderSide: BorderSide.none,
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          hintStyle: TextStyle(color: Colors.white.withOpacity(0.4)),
        ),
      );

  // ═══════════════════════════════════════════════
  //  GRADIENT COLORS (used by all pages)
  // ═══════════════════════════════════════════════

  /// Primary gradient for Dashboard
  static List<Color> get dashboardGradient => isDark
      ? const [Color(0xFF0F172A), Color(0xFF162036)]
      : const [Color(0xFF6FCF97), Color(0xFFDFF5EA)];

  /// Secondary gradient for inner pages
  static List<Color> get pageGradient => isDark
      ? const [Color(0xFF0F172A), Color(0xFF162036)]
      : const [Color(0xFFDFF5EA), Color(0xFFB7E4C7)];

  /// Sidebar gradient
  static List<Color> get sidebarGradient => isDark
      ? const [Color(0xFF162036), Color(0xFF0F172A)]
      : const [Color(0xFF6FCF97), Color(0xFFB7E4C7)];

  /// Login/Register gradient
  static List<Color> get authGradient => isDark
      ? const [Color(0xFF0F172A), Color(0xFF162036)]
      : const [Color(0xFFDFF5EA), Color(0xFFF5F5F5)];

  // ═══════════════════════════════════════════════
  //  COMPONENT COLORS
  // ═══════════════════════════════════════════════

  static Color get cardColor =>
      isDark ? _darkCard.withOpacity(0.85) : Colors.white.withOpacity(0.75);

  static Color get cardColorLight =>
      isDark ? _darkCardLight.withOpacity(0.6) : Colors.white.withOpacity(0.5);

  static Color get cardColorStrong =>
      isDark ? _darkCard.withOpacity(0.95) : Colors.white.withOpacity(0.9);

  static Color get surfaceColor =>
      isDark ? _darkSurface.withOpacity(0.5) : Colors.white.withOpacity(0.35);

  static Color get textPrimary =>
      isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1E293B);

  static Color get textSecondary =>
      isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

  static Color get accent => const Color(0xFF6FCF97);

  static Color get dividerColor =>
      isDark ? Colors.white.withOpacity(0.12) : Colors.grey.shade300;

  /// Bottom sheet background
  static Color get bottomSheetColor =>
      isDark ? const Color(0xFF1E293B) : const Color(0xFFF5FFF8);

  /// Input field fill color
  static Color get inputFillColor =>
      isDark ? _darkCard : const Color(0xFFF5F5F5);

  /// Selected chip/pill color for light themes
  static Color get chipSelectedColor =>
      isDark ? _darkCard : Colors.white;

  /// Unselected chip text color
  static Color get chipUnselectedText =>
      isDark ? const Color(0xFF94A3B8) : Colors.black54;

  /// Dialog/card solid background (no opacity)
  static Color get solidCardColor =>
      isDark ? _darkCard : Colors.white;

  /// Tab/selector background
  static Color get selectorBackground =>
      isDark ? _darkSurface.withOpacity(0.6) : Colors.white.withOpacity(0.5);

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
