import 'package:flutter/material.dart';
import 'package:vanishingtictactoe/features/game/widgets/friendly/option_card_widget.dart';

class AnimatedOptionCardWidget extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final VoidCallback onTap;
  final Color color;
  final double delay;

  const AnimatedOptionCardWidget({
    super.key,
    required this.title,
    required this.description,
    required this.icon,
    required this.onTap,
    required this.color,
    required this.delay,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 50 * (1 - value)),
          child: Transform.scale(
            scale: 0.95 + (0.05 * value),
            child: Opacity(
              opacity: value,
              child: OptionCardWidget(
                title: title,
                description: description,
                icon: icon,
                onTap: onTap,
                color: color,
              ),
            ),
          ),
        );
      },
    );
  }
}