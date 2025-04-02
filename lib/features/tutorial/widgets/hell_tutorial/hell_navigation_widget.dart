
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:vanishingtictactoe/core/utils/font_preloader.dart';

class HellNavigationControlsWidget extends StatelessWidget {
  final Color primaryColor;
  final PageController pageController;
  final int currentPage;
  final List<Map<String, dynamic>> tutorialData;

  const HellNavigationControlsWidget({
    super.key,
    required this.primaryColor,
    required this.pageController,
    required this.currentPage,
    required this.tutorialData,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24.0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.white, Colors.red.shade50.withOpacity(0.3)],
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.red.shade200.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, -4),
            spreadRadius: 1,
          ),
        ],
        border: Border.all(
          color: Colors.white.withOpacity(0.5),
          width: 1.5,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Interactive page indicators
          Row(
            children: List.generate(
              tutorialData.length,
              (index) => GestureDetector(
                onTap: () {
                  pageController.animateToPage(
                    index,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: currentPage == index ? 24 : 12,
                  height: 12,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(6),
                    color: currentPage == index
                        ? primaryColor
                        : Colors.grey[300],
                    boxShadow: currentPage == index
                        ? [
                            BoxShadow(
                              color: primaryColor.withOpacity(0.4),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                ),
              ),
            ),
          ),
          // Next/Done button
          ElevatedButton(
            onPressed: () {
              HapticFeedback.lightImpact(); // Add haptic feedback
              if (currentPage < tutorialData.length - 1) {
                pageController.nextPage(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
              } else {
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 12,
              ),
              elevation: 3,
              shadowColor: primaryColor.withOpacity(0.6),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  currentPage < tutorialData.length - 1 ? 'Next' : 'Got it!',
                  style: FontPreloader.getTextStyle(
                    fontFamily: 'Orbitron',
                    fontSize: 16,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  currentPage < tutorialData.length - 1 ? Icons.arrow_forward : Icons.check,
                  size: 18,
                  color: Colors.white,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}