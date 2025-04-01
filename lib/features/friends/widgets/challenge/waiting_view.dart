import 'package:flutter/material.dart';
import 'package:vanishingtictactoe/features/friends/widgets/challenge/animated_components.dart';
import 'package:vanishingtictactoe/features/friends/widgets/challenge/gradient_button.dart';

/// View shown when waiting for a friend to accept a challenge
class WaitingView extends StatelessWidget {
  final String friendUsername;
  final int secondsRemaining;
  final VoidCallback onCancel;

  const WaitingView({
    super.key,
    required this.friendUsername,
    required this.secondsRemaining,
    required this.onCancel,
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
              icon: Icons.sports_esports,
              color: Colors.blue.shade600,
              size: 120,
            ),
            const SizedBox(height: 32),
            // Animated text with fade-in effect
            AnimatedText(
              text: 'Challenge sent to $friendUsername',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            AnimatedText(
              text: 'Waiting for your friend to accept the challenge...',
              style: const TextStyle(
                fontSize: 16,
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 32),
            // Modern timer card with gradient border
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.shade100.withOpacity(0.5),
                    blurRadius: 20,
                    spreadRadius: 1,
                    offset: const Offset(0, 10),
                  ),
                ],
                border: Border.all(
                  color: Colors.blue.shade100,
                  width: 2,
                ),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.timer,
                        size: 20,
                        color: secondsRemaining > 30
                            ? Colors.green
                            : (secondsRemaining > 10 ? Colors.orange : Colors.red),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Challenge expires in:',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TweenAnimationBuilder<double>(
                    tween: Tween<double>(begin: 0.0, end: 1.0),
                    duration: const Duration(milliseconds: 500),
                    builder: (context, value, child) {
                      return Opacity(
                        opacity: value,
                        child: Text(
                          '$secondsRemaining seconds',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: secondsRemaining > 30
                                ? Colors.green
                                : (secondsRemaining > 10 ? Colors.orange : Colors.red),
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  // Animated progress indicator
                  TweenAnimationBuilder<double>(
                    tween: Tween<double>(begin: 0.0, end: secondsRemaining / 60),
                    duration: const Duration(milliseconds: 500),
                    builder: (context, value, child) {
                      return Container(
                        height: 10,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          color: Colors.grey.shade100,
                        ),
                        child: FractionallySizedBox(
                          alignment: Alignment.centerLeft,
                          widthFactor: value,
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              gradient: LinearGradient(
                                colors: [
                                  secondsRemaining > 30
                                      ? Colors.green
                                      : (secondsRemaining > 10 ? Colors.orange : Colors.red),
                                  secondsRemaining > 30
                                      ? Colors.green.shade300
                                      : (secondsRemaining > 10 ? Colors.orange.shade300 : Colors.red.shade300),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            GradientButton(
              icon: Icons.cancel_rounded,
              label: 'Cancel Challenge',
              color: Colors.red.shade400,
              onPressed: onCancel,
            ),
          ],
        ),
      ),
    ),
    );
  }
}
