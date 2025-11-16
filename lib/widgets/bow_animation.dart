import 'package:flutter/material.dart';

class BowAnimation extends StatefulWidget {
  const BowAnimation({super.key});

  @override
  State<BowAnimation> createState() => _BowAnimationState();
}

class _BowAnimationState extends State<BowAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final double horizontalShift = (_controller.value - 0.5) * 90;
        return Transform.translate(
          offset: Offset(horizontalShift, 0),
          child: Transform.rotate(
            angle: 0.96,
            child: Image.asset(
              'assets/images/bow.png',
              width: 850,
              height: 250,
              fit: BoxFit.contain,
            ),
          ),
        );
      },
    );
  }
}