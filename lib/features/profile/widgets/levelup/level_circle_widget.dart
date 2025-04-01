import 'package:flutter/material.dart';
import 'package:vanishingtictactoe/core/utils/font_preloader.dart';

class LevelCircleWidget extends StatelessWidget {
  final int newLevel;
  final bool showUnlockables;
  final Animation<double> scaleAnimation;
  final Animation<double> pulseAnimation;
  
  const LevelCircleWidget({
    super.key,
    required this.newLevel,
    required this.showUnlockables,
    required this.scaleAnimation,
    required this.pulseAnimation,
  });
  
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([scaleAnimation, pulseAnimation]),
      builder: (context, child) {
        return Transform.scale(
          scale: scaleAnimation.value * (showUnlockables ? pulseAnimation.value : 1.0),
          child: Container(
            width: 150,
            height: 150,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  Colors.blue.shade500,
                  Colors.blue.shade700,
                ],
                center: Alignment.topLeft,
                radius: 1.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.shade400.withAlpha(204),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
              border: Border.all(
                color: Colors.white,
                width: 3,
              ),
            ),
            child: Center(
              child: Text(
                newLevel.toString(),
                style: FontPreloader.getTextStyle(
                  fontFamily: 'Orbitron',
                  fontSize: 72,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ).copyWith(shadows: const [
                  Shadow(
                    color: Colors.black26,
                    blurRadius: 5,
                    offset: Offset(2, 2),
                  ),
                ]),
              ),
            ),
          ),
        );
      },
    );
  }
}