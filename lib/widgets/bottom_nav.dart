import 'package:flutter/material.dart';
import '../pages/dashboard.dart';
import '../pages/bmi_calculator.dart';
import '../pages/food_tracker.dart';
import '../pages/progress.dart';
import '../pages/profile_setting.dart';
import '../services/theme_service.dart';

/// Centralized bottom navigation bar.
///
/// Replaces 7 duplicated buildBottomNav methods across pages.
class AppBottomNav extends StatelessWidget {
  final int currentIndex;

  const AppBottomNav({super.key, required this.currentIndex});

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      type: BottomNavigationBarType.fixed,
      selectedItemColor: ThemeService.accent,
      unselectedItemColor: ThemeService.textSecondary,
      backgroundColor:
          ThemeService.isDark ? const Color(0xFF0F172A) : Colors.white,
      elevation: 8,
      selectedFontSize: 12,
      unselectedFontSize: 12,
      onTap: (index) {
        if (index == currentIndex) return;
        Widget page;
        switch (index) {
          case 0:
            page = const Dashboard();
            break;
          case 1:
            page = const BmiCalculator();
            break;
          case 2:
            page = const FoodTracker();
            break;
          case 3:
            page = const progress();
            break;
          case 4:
            page = const ProfileSetting();
            break;
          default:
            return;
        }
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (_, __, ___) => page,
            transitionDuration: const Duration(milliseconds: 250),
            transitionsBuilder: (_, animation, __, child) {
              return FadeTransition(opacity: animation, child: child);
            },
          ),
        );
      },
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: "Home"),
        BottomNavigationBarItem(
            icon: Icon(Icons.monitor_weight_rounded), label: "BMI"),
        BottomNavigationBarItem(
            icon: Icon(Icons.local_fire_department_rounded), label: "Calories"),
        BottomNavigationBarItem(
            icon: Icon(Icons.show_chart_rounded), label: "Progress"),
        BottomNavigationBarItem(
            icon: Icon(Icons.person_rounded), label: "Profile"),
      ],
    );
  }
}
