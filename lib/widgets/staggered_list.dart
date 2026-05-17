import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Wrapper that applies stagger fade+slide animation to each child.
///
/// Usage:
/// ```dart
/// StaggeredList(
///   children: [card1, card2, card3],
/// )
/// ```
class StaggeredList extends StatefulWidget {
  final List<Widget> children;
  final Duration staggerDelay;
  final Duration itemDuration;
  final double slideOffset;
  final Axis axis;

  const StaggeredList({
    super.key,
    required this.children,
    this.staggerDelay = AppDurations.stagger,
    this.itemDuration = AppDurations.normal,
    this.slideOffset = 20.0,
    this.axis = Axis.vertical,
  });

  @override
  State<StaggeredList> createState() => _StaggeredListState();
}

class _StaggeredListState extends State<StaggeredList>
    with TickerProviderStateMixin {
  final List<AnimationController> _controllers = [];
  final List<Animation<double>> _fadeAnimations = [];
  final List<Animation<Offset>> _slideAnimations = [];

  @override
  void initState() {
    super.initState();
    _initAnimations();
  }

  void _initAnimations() {
    for (int i = 0; i < widget.children.length; i++) {
      final controller = AnimationController(
        duration: widget.itemDuration,
        vsync: this,
      );
      _controllers.add(controller);

      _fadeAnimations.add(
        Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(parent: controller, curve: Curves.easeOut),
        ),
      );

      final slideBegin = widget.axis == Axis.vertical
          ? Offset(0, widget.slideOffset)
          : Offset(widget.slideOffset, 0);

      _slideAnimations.add(
        Tween<Offset>(begin: slideBegin, end: Offset.zero).animate(
          CurvedAnimation(parent: controller, curve: Curves.easeOut),
        ),
      );

      // Stagger the start
      Future.delayed(widget.staggerDelay * i, () {
        if (mounted) controller.forward();
      });
    }
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(widget.children.length, (index) {
        return AnimatedBuilder(
          animation: _controllers[index],
          builder: (context, child) {
            return Opacity(
              opacity: _fadeAnimations[index].value,
              child: Transform.translate(
                offset: _slideAnimations[index].value,
                child: child,
              ),
            );
          },
          child: widget.children[index],
        );
      }),
    );
  }
}
