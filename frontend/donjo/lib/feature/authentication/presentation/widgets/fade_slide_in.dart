import 'package:flutter/material.dart';

import 'package:donjo/core/motion/app_motion.dart';

class FadeSlideIn extends StatefulWidget {
  const FadeSlideIn({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.duration = AppMotion.durationModerate02,
  });

  final Widget child;
  final Duration delay;
  final Duration duration;

  static List<Widget> staggered(
    List<Widget> children, {
    Duration interval = const Duration(milliseconds: 70),
  }) {
    return [
      for (var i = 0; i < children.length; i++)
        FadeSlideIn(
          key: ValueKey('fade_slide_$i'),
          delay: interval * i,
          child: children[i],
        ),
    ];
  }

  @override
  State<FadeSlideIn> createState() => _FadeSlideInState();
}

class _FadeSlideInState extends State<FadeSlideIn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final CurvedAnimation _curve;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    _curve = CurvedAnimation(
      parent: _controller,
      curve: AppMotion.easeProductiveStandard,
    );
    Future<void>.delayed(widget.delay, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _curve.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _curve,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.04),
          end: Offset.zero,
        ).animate(_curve),
        child: widget.child,
      ),
    );
  }
}
