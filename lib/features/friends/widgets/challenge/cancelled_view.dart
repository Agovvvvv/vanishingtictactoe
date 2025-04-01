import 'package:flutter/material.dart';
import 'package:vanishingtictactoe/features/friends/widgets/challenge/animated_components.dart';
import 'package:vanishingtictactoe/features/friends/widgets/challenge/gradient_button.dart';

/// View shown when a challenge has been cancelled
class CancelledView extends StatelessWidget {
  final VoidCallback onReturn;

  const CancelledView({
    super.key,
    required this.onReturn,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Animated icon with pulsing effect
            AnimatedIconContainer(
              icon: Icons.cancel_rounded,
              color: Colors.red.shade600,
              size: 120,
            ),
            const SizedBox(height: 32),
            // Animated text with fade-in effect
            AnimatedText(
              text: 'Challenge Cancelled',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            AnimatedText(
              text: 'Your friend cancelled the challenge.',
              style: const TextStyle(
                fontSize: 16,
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 32),
            // Modern card with message
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.red.shade100.withOpacity(0.5),
                    blurRadius: 20,
                    spreadRadius: 1,
                    offset: const Offset(0, 10),
                  ),
                ],
                border: Border.all(
                  color: Colors.red.shade100,
                  width: 2,
                ),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.info_outline_rounded,
                        size: 20,
                        color: Colors.red.shade600,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Challenge Ended',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'You can send a new challenge anytime when you are ready to play.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.black45,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            GradientButton(
              icon: Icons.arrow_back_rounded,
              label: 'Return to Friends',
              color: Colors.blue.shade500,
              onPressed: onReturn,
            ),
          ],
        ),
      ),
    ),
    );
  }
}
