import 'dart:math' show pi;
import 'package:flutter/material.dart';
import 'package:vanishingtictactoe/features/friends/widgets/challenge/animated_components.dart';
import 'package:vanishingtictactoe/features/friends/widgets/challenge/gradient_button.dart';

/// View shown when the receiver is waiting for the sender to join
class WaitingForSenderView extends StatefulWidget {
  final String friendUsername;
  final VoidCallback onCancel;

  const WaitingForSenderView({
    super.key,
    required this.friendUsername,
    required this.onCancel,
  });

  @override
  State<WaitingForSenderView> createState() => _WaitingForSenderViewState();
}

class _WaitingForSenderViewState extends State<WaitingForSenderView>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(); // Continuous rotation without reversing
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

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
                icon: Icons.check_circle_rounded,
                color: Colors.green.shade600,
                size: 120,
              ),
              const SizedBox(height: 32),
              // Animated text with fade-in effect
              AnimatedText(
                text: 'Challenge accepted!',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 16),
              AnimatedText(
                text:
                    'Waiting for ${widget.friendUsername} to join the game...',
                style: const TextStyle(fontSize: 16, color: Colors.black54),
              ),
              const SizedBox(height: 32),
              // Compact waiting indicator with subtle animation
              Container(
                width: 220, // More compact width
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.green.shade100.withOpacity(0.6),
                      blurRadius: 16,
                      spreadRadius: 1,
                      offset: const Offset(0, 8),
                    ),
                  ],
                  border: Border.all(
                    color: Colors.green.shade100,
                    width: 1.5,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.sports_esports_rounded,
                          size: 18,
                          color: Colors.green.shade600,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Game will start soon',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: Colors.black54,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Improved loading indicator
                    SizedBox(
                      width: 48,
                      height: 48,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Outer circle with clockwise rotation
                          AnimatedBuilder(
                            animation: _controller,
                            builder: (context, child) {
                              return Transform.rotate(
                                angle: _controller.value * 2 * pi, // Full rotation
                                child: CustomPaint(
                                  size: const Size(48, 48),
                                  painter: _LoadingArcPainter(
                                    color: Colors.green.shade500,
                                    strokeWidth: 3.5,
                                  ),
                                ),
                              );
                            },
                          ),
                          // Transparent center - ensures the middle is empty
                          Container(
                            width: 38,
                            height: 38,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              GradientButton(
                icon: Icons.cancel_rounded,
                label: 'Cancel',
                color: Colors.red.shade400,
                onPressed: widget.onCancel,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Custom painter that draws an arc for the loading indicator
class _LoadingArcPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;

  _LoadingArcPainter({
    required this.color,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(
      strokeWidth / 2,
      strokeWidth / 2,
      size.width - strokeWidth,
      size.height - strokeWidth,
    );
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Draw an arc that covers 270 degrees (3/4 of a circle)
    canvas.drawArc(
      rect,
      0,  // Start angle (0 radians = 3 o'clock position)
      3 * pi / 2,  // Sweep angle (270 degrees = 3π/2 radians)
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(_LoadingArcPainter oldDelegate) {
    return oldDelegate.color != color || 
           oldDelegate.strokeWidth != strokeWidth;
  }
}
