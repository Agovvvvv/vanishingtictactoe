import 'package:flutter/material.dart';
import 'package:vanishingtictactoe/features/tutorial/widgets/normal_tutorial/action_button_widget.dart';
import 'package:vanishingtictactoe/features/tutorial/widgets/normal_tutorial/page_indicators_widget.dart';

class TutorialNavigationControlsWidget extends StatelessWidget {
  final Color primaryColor;
  final PageController pageController;
  final int currentPage;
  final List<Map<String, dynamic>> tutorialData;
  final VoidCallback startTutorialGame;
  
  const TutorialNavigationControlsWidget({
    super.key,
    required this.primaryColor,
    required this.pageController,
    required this.currentPage,
    required this.tutorialData,
    required this.startTutorialGame,
  });
  
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.shade200.withOpacity(0.3),
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
          // Page indicators
          TutorialPageIndicatorsWidget(
            primaryColor: primaryColor,
            pageController: pageController,
            currentPage: currentPage,
            tutorialData: tutorialData,
          ),
          // Next/Start Game button
          TutorialActionButtonWidget(
            primaryColor: primaryColor,
            currentPage: currentPage,
            totalPages: tutorialData.length,
            pageController: pageController,
            startTutorialGame: startTutorialGame,
          ),
        ],
      ),
    );
  }
}