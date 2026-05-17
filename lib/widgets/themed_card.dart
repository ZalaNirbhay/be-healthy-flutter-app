import 'package:flutter/material.dart';
import '../services/theme_service.dart';
import '../theme/app_theme.dart';

/// Theme-aware card container that replaces hardcoded
/// `Colors.white.withOpacity(0.7)` across the entire app.
///
/// Usage:
/// ```dart
/// ThemedCard(
///   child: Text("Hello"),
/// )
/// ```
class ThemedCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double? borderRadius;
  final CardStrength strength;
  final VoidCallback? onTap;

  const ThemedCard({
    super.key,
    required this.child,
    this.padding,
    this.borderRadius,
    this.strength = CardStrength.normal,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = switch (strength) {
      CardStrength.light => ThemeService.cardColorLight,
      CardStrength.normal => ThemeService.cardColor,
      CardStrength.strong => ThemeService.cardColorStrong,
      CardStrength.surface => ThemeService.surfaceColor,
    };

    final card = Container(
      padding: padding ?? const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(borderRadius ?? AppRadius.xl),
      ),
      child: child,
    );

    if (onTap != null) {
      return GestureDetector(onTap: onTap, child: card);
    }
    return card;
  }
}

enum CardStrength { light, normal, strong, surface }
