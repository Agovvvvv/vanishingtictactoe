import 'package:flutter/material.dart';

/// A pulsing animated icon container with gradient effects
class AnimatedIconContainer extends StatelessWidget {
  final IconData icon;
  final Color color;
  final double size;

  const AnimatedIconContainer({
    super.key,
    required this.icon,
    required this.color,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.9, end: 1.0),
      duration: const Duration(seconds: 2),
      curve: Curves.easeInOut,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.2),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Icon(
              icon,
              size: size * 0.45,
              color: color,
            ),
          ),
        );
      },
    );
  }
}

/// Text with fade-in and slide-up animations
class AnimatedText extends StatelessWidget {
  final String text;
  final TextStyle style;

  const AnimatedText({
    super.key,
    required this.text,
    required this.style,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 800),
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - value)),
            child: Text(
              text,
              style: style,
              textAlign: TextAlign.center,
            ),
          ),
        );
      },
    );
  }
}
