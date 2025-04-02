// Build an individual tutorial page
import 'package:flutter/material.dart';
import 'package:vanishingtictactoe/features/tutorial/widgets/normal_tutorial/icon_container_widget.dart';

class TutorialPageWidget extends StatelessWidget {
  final int index;
  final Color primaryColor;
  final List<Map<String, dynamic>> tutorialData;
  
  const TutorialPageWidget({
    super.key,
    required this.index,
    required this.primaryColor,
    required this.tutorialData,
  });
  
  @override
  Widget build(BuildContext context) {
    final String title = tutorialData[index]['title'];
    final String description = tutorialData[index]['description'];
    
    return Semantics(
      label: 'Tutorial page ${index + 1} of ${tutorialData.length}',
      hint: title,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon container
            TutorialIconContainerWidget(
              index: index, 
              primaryColor: primaryColor, 
              tutorialData: tutorialData
            ),
            const SizedBox(height: 40),
            // Title
            Text(
              title,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
                letterSpacing: 0.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            // Description
            Text(
              description,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[800], // Darker grey for better contrast
                height: 1.3, // Better line height for readability
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}