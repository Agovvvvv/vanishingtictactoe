import 'package:flutter/material.dart';

class LevelUpTextWidget extends StatelessWidget {
  final Animation<double> levelAnimation;
  
  const LevelUpTextWidget({
    super.key,
    required this.levelAnimation,
  });
  
  @override
  Widget build(BuildContext context) {

    return AnimatedBuilder(
      animation: levelAnimation,
      builder: (context, child) {
        final opacity = levelAnimation.value.clamp(0.0, 1.0);
        return Opacity(
          opacity: opacity,
          child: Transform.translate(
            offset: Offset(0, 30 * (1 - opacity)),
            child: const Text(
              "LEVEL UP!",
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 2.0,
                shadows: [
                  Shadow(
                    color: Colors.blue,
                    blurRadius: 15,
                    offset: Offset(0, 0),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}