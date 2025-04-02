// Build the page indicators
import 'package:flutter/material.dart';

class TutorialPageIndicatorsWidget extends StatelessWidget {
  final Color primaryColor;
  final PageController pageController;
  final int currentPage;
  final List<Map<String, dynamic>> tutorialData;
  
  const TutorialPageIndicatorsWidget({
    super.key,
    required this.primaryColor,
    required this.pageController,
    required this.currentPage,
    required this.tutorialData,
  });
  
  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Page ${currentPage + 1} of ${tutorialData.length}',
      excludeSemantics: true,
      child: Row(
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
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: currentPage == index ? 20 : 10,
                height: 10,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(5),
                  color: currentPage == index
                      ? primaryColor
                      : Colors.grey[300],
                  boxShadow: currentPage == index ? [
                    BoxShadow(
                      color: primaryColor.withOpacity(0.3),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ] : null,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}