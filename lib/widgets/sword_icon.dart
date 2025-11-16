import 'package:flutter/material.dart';

class SwordIcon extends StatelessWidget {
  final double size;

  const SwordIcon({
    super.key,
    this.size = 60,
  });

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'images/sword.png',
      width: size,
      height: size,
      fit: BoxFit.contain,
    );
  }
}