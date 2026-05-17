import 'package:flutter/material.dart';
import '../services/theme_service.dart';
import '../theme/app_theme.dart';

/// Beautiful empty state widget with animation.
///
/// Replaces broken plain-text empty states across the app.
/// Supports icon, title, subtitle, and an optional CTA button.
class EmptyStateWidget extends StatefulWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String? buttonLabel;
  final VoidCallback? onButtonPressed;
  final double iconSize;

  const EmptyStateWidget({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.buttonLabel,
    this.onButtonPressed,
    this.iconSize = 64,
  });

  @override
  State<EmptyStateWidget> createState() => _EmptyStateWidgetState();
}

class _EmptyStateWidgetState extends State<EmptyStateWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: AppDurations.slow,
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(
            vertical: AppSpacing.xxl,
            horizontal: AppSpacing.lg,
          ),
          decoration: BoxDecoration(
            color: ThemeService.cardColor,
            borderRadius: AppRadius.xlBorder,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon with circular background
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: ThemeService.accent.withOpacity(0.12),
                ),
                child: Icon(
                  widget.icon,
                  size: widget.iconSize,
                  color: ThemeService.accent.withOpacity(0.6),
                ),
              ),

              const SizedBox(height: AppSpacing.xl),

              // Title
              Text(
                widget.title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: ThemeService.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: AppSpacing.sm),

              // Subtitle
              Text(
                widget.subtitle,
                style: TextStyle(
                  fontSize: 14,
                  color: ThemeService.textSecondary,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),

              // Optional button
              if (widget.buttonLabel != null && widget.onButtonPressed != null) ...[
                const SizedBox(height: AppSpacing.xl),
                SizedBox(
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: widget.onButtonPressed,
                    icon: const Icon(Icons.add, color: Colors.white, size: 20),
                    label: Text(
                      widget.buttonLabel!,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ThemeService.accent,
                      shape: RoundedRectangleBorder(
                        borderRadius: AppRadius.xxlBorder,
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.xl,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
