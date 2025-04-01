import 'package:flutter/material.dart';
import 'package:vanishingtictactoe/core/utils/font_preloader.dart';

class EmptyHistoryState extends StatelessWidget {
  final Color accentColor;
  
  const EmptyHistoryState({
    super.key,
    this.accentColor = const Color(0xFF2E86DE),
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: accentColor.withValues( alpha: 0.1),
              blurRadius: 20,
              spreadRadius: 5,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Animated icon with gradient
            ShaderMask(
              shaderCallback: (bounds) => LinearGradient(
                colors: [accentColor.withValues( alpha: 0.6), accentColor],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ).createShader(bounds),
              child: Icon(
                Icons.history,
                size: 80,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No matches yet',
              style: FontPreloader.getTextStyle(
                fontFamily: 'Press Start 2P',
                fontSize: 16,
                color: accentColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: accentColor.withValues( alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: accentColor.withValues( alpha: 0.2),
                  width: 1,
                ),
              ),
              child: Text(
                'Play a game to see your history',
                style: TextStyle(
                  color: Color(0xFF7F8C8D),
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}