import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vanishingtictactoe/core/constants/app_colors.dart';
import 'dart:async';

class AnimatedTitleWidget extends StatefulWidget {
  final String text;
  final bool isHellMode;

  const AnimatedTitleWidget({
    super.key,
    required this.text,
    this.isHellMode = false,
  });

  @override
  State<AnimatedTitleWidget> createState() => _AnimatedTitleWidgetState();
}

class _AnimatedTitleWidgetState extends State<AnimatedTitleWidget>
    with TickerProviderStateMixin {
  late List<AnimationController> _letterControllers;
  late List<Animation<double>> _letterAnimations;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    // Create an animation controller for each letter
    _letterControllers = List.generate(
      widget.text.length,
      (index) => AnimationController(
        duration: const Duration(milliseconds: 500),
        vsync: this,
      ),
    );

    // Create bounce animations for each letter
    _letterAnimations = _letterControllers.map((controller) {
      return CurvedAnimation(parent: controller, curve: Curves.elasticOut);
    }).toList();

    // Start animations sequentially, one letter at a time
    _startSequentialAnimation();
  }

  void _startSequentialAnimation() {
    // Start with the first letter
    for (int i = 0; i < _letterControllers.length; i++) {
      Future.delayed(Duration(milliseconds: 150 * i), () {
        if (mounted) {
          _letterControllers[i].forward().then((_) {
            // After the initial animation, start random bounces
            _startRandomBounce(i);
          });
        }
      });
    }
  }

  void _startRandomBounce(int index) {
    if (!mounted) return;

    // Random delay between 2-6 seconds before next bounce
    final random = DateTime.now().millisecondsSinceEpoch % 4000 + 2000;

    Future.delayed(Duration(milliseconds: random), () {
      if (mounted && _letterControllers[index].isCompleted) {
        _letterControllers[index].reset();
        _letterControllers[index].forward().then((_) {
          _startRandomBounce(index);
        });
      }
    });
  }

  @override
  void didUpdateWidget(AnimatedTitleWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.text != oldWidget.text) {
      // Dispose old controllers
      for (var controller in _letterControllers) {
        controller.dispose();
      }

      // Initialize new animations for new text
      _initializeAnimations();
    }
  }

  @override
  void dispose() {
    for (var controller in _letterControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = AppColors.getPrimaryColor(widget.isHellMode);

    return Container(
      constraints: const BoxConstraints(maxWidth: 300), // Increased width to prevent overflow
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20), // Balanced vertical padding for better centering
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withOpacity(0.95),
            Colors.white.withOpacity(0.85),
          ],
        ),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.25),
            blurRadius: 20,
            spreadRadius: 1,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: Colors.white.withOpacity(0.2),
            blurRadius: 10,
            spreadRadius: -2,
            offset: const Offset(0, -2),
          ),
        ],
        border: Border.all(color: primaryColor.withOpacity(0.3), width: 1.5),
      ),
      child: Center(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0), // Add extra padding for vertical centering
            child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Create animated letters
              ...List.generate(widget.text.length, (index) {
                return AnimatedBuilder(
                  animation: _letterAnimations[index],
                  builder: (context, child) {
                    return Transform.translate(
                      offset: Offset(0, -10 * _letterAnimations[index].value),
                      child: Text(
                        widget.text[index],
                        style: GoogleFonts.poppins(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: primaryColor,
                          letterSpacing: 1.2,
                          height: 1.2, // Adjusted line height for better vertical centering
                          shadows: [
                            Shadow(
                              color: primaryColor.withOpacity(0.4),
                              blurRadius: 8,
                              offset: const Offset(2, 2),
                            ),
                            Shadow(
                              color: Colors.white.withOpacity(0.3),
                              blurRadius: 2,
                              offset: const Offset(-1, -1),
                            ),
                          ],
                      ),
                    ),
                  );
                },
              );
            }),
          ],
            ),
          ),
        ),
      ),
    );
  }
}
