import 'package:flutter/material.dart';
import 'package:vanishingtictactoe/features/friends/widgets/challenge/animated_components.dart';
import 'package:vanishingtictactoe/features/friends/widgets/challenge/gradient_button.dart';

/// View shown when a challenge has been declined
class DeclinedView extends StatelessWidget {
  final String friendUsername;
  final VoidCallback onReturn;

  const DeclinedView({
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
                icon: Icons.person_remove_rounded,
                color: Colors.red.shade600,
                size: 120,
              ),
              const SizedBox(height: 32),
              // Animated text with fade-in effect
              AnimatedText(
                text: 'Challenge Declined',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 16),
              AnimatedText(
                text: '$friendUsername declined your challenge.',
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.black54,
                ),
              ),
              const SizedBox(height: 32),
              // Modern card with message
              Container(
                width: 280,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.red.shade100.withOpacity(0.6),
                      blurRadius: 16,
                      spreadRadius: 1,
                      offset: const Offset(0, 8),
                    ),
                  ],
                  border: Border.all(
                    color: Colors.red.shade100,
                    width: 1.5,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      color: Colors.red.shade400,
                      size: 28,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Your friend might be busy right now.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey.shade800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'You can try challenging them again later.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              GradientButton(
                icon: Icons.arrow_back_rounded,
                label: 'Return',
                color: Colors.blue.shade400,
                onPressed: onReturn,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
