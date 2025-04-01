import 'package:flutter/material.dart';
import 'package:vanishingtictactoe/features/friends/widgets/challenge/animated_components.dart';
import 'package:vanishingtictactoe/features/friends/widgets/challenge/gradient_button.dart';

/// View shown when a challenge has expired
class ExpiredView extends StatelessWidget {
  final String friendUsername;
  final VoidCallback onReturn;

  const ExpiredView({
    super.key,
    required this.friendUsername,
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
              icon: Icons.timer_off_rounded,
              color: Colors.orange.shade600,
              size: 120,
            ),
            const SizedBox(height: 32),
            // Animated text with fade-in effect
            AnimatedText(
              text: 'Challenge Expired',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            AnimatedText(
              text: '$friendUsername did not respond to your challenge in time.',
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
                    color: Colors.orange.shade100.withOpacity(0.5),
                    blurRadius: 20,
                    spreadRadius: 1,
                    offset: const Offset(0, 10),
                  ),
                ],
                border: Border.all(
                  color: Colors.orange.shade100,
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
                        color: Colors.orange.shade600,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Try again later',
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
                    'Your friend might be busy right now. You can send another challenge when they\'re available.',
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
