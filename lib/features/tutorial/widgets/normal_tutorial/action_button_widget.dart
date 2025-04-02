import 'package:flutter/material.dart';

class TutorialActionButtonWidget extends StatelessWidget {
  final Color primaryColor;
  final int currentPage;
  final int totalPages;
  final PageController pageController;
  final VoidCallback startTutorialGame;
  
  const TutorialActionButtonWidget({
    super.key,
    required this.primaryColor,
    required this.currentPage,
    required this.totalPages,
    required this.pageController,
    required this.startTutorialGame,
  });
  
  @override
  Widget build(BuildContext context) {
    final bool isLastPage = currentPage >= totalPages - 1;
    final String buttonText = isLastPage ? 'Start Tutorial Game' : 'Next';
    final IconData buttonIcon = isLastPage ? Icons.play_arrow : Icons.arrow_forward;
    
    return Semantics(
      label: buttonText,
      button: true,
      hint: isLastPage ? 'Begin the interactive tutorial' : 'Go to next tutorial page',
      child: ElevatedButton(
        onPressed: () {
          if (!isLastPage) {
            pageController.nextPage(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            );
          } else {
            startTutorialGame();
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 12,
          ),
          elevation: 2, // Added slight elevation for better visual feedback
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              buttonText,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              buttonIcon,
              size: 18,
              color: Colors.white,
            ),
          ],
        ),
      ),
    );
  }
}