import 'package:flutter/material.dart';
import '../services/theme_service.dart';
import '../theme/app_theme.dart';

/// Custom shimmer loading effect — no external packages.
///
/// Uses AnimationController + LinearGradient sweep for a
/// premium loading skeleton effect.
class ShimmerLoading extends StatefulWidget {
  final double width;
  final double height;
  final double borderRadius;

  const ShimmerLoading({
    super.key,
    this.width = double.infinity,
    this.height = 80,
    this.borderRadius = AppRadius.lg,
  });

  @override
  State<ShimmerLoading> createState() => _ShimmerLoadingState();
}

class _ShimmerLoadingState extends State<ShimmerLoading>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final baseColor = ThemeService.isDark
        ? const Color(0xFF253548)
        : Colors.grey.shade200;
    final highlightColor = ThemeService.isDark
        ? const Color(0xFF344C64)
        : Colors.grey.shade50;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            gradient: LinearGradient(
              begin: Alignment(-1.0 + 2.0 * _controller.value, 0),
              end: Alignment(-1.0 + 2.0 * _controller.value + 1.0, 0),
              colors: [
                baseColor,
                highlightColor,
                baseColor,
              ],
              stops: const [0.0, 0.5, 1.0],
            ),
          ),
        );
      },
    );
  }
}

/// A shimmer placeholder for a card (with optional inner lines)
class ShimmerCard extends StatelessWidget {
  final int lineCount;
  final double height;

  const ShimmerCard({
    super.key,
    this.lineCount = 3,
    this.height = 120,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: ThemeService.cardColor,
        borderRadius: AppRadius.xlBorder,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: List.generate(lineCount, (index) {
          final widthFactor = index == 0 ? 0.6 : (index == lineCount - 1 ? 0.4 : 0.85);
          return Padding(
            padding: EdgeInsets.only(bottom: index < lineCount - 1 ? AppSpacing.md : 0),
            child: ShimmerLoading(
              height: index == 0 ? 20 : 14,
              width: MediaQuery.of(context).size.width * widthFactor,
              borderRadius: AppRadius.sm,
            ),
          );
        }),
      ),
    );
  }
}

/// Multiple shimmer cards stacked
class ShimmerList extends StatelessWidget {
  final int count;

  const ShimmerList({super.key, this.count = 3});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(count, (index) {
        return Padding(
          padding: EdgeInsets.only(bottom: index < count - 1 ? AppSpacing.md : 0),
          child: const ShimmerCard(lineCount: 2),
        );
      }),
    );
  }
}

/// Shimmer circle placeholder
class ShimmerCircle extends StatelessWidget {
  final double size;

  const ShimmerCircle({super.key, this.size = 60});

  @override
  Widget build(BuildContext context) {
    return ClipOval(
      child: ShimmerLoading(
        width: size,
        height: size,
        borderRadius: size / 2,
      ),
    );
  }
}
