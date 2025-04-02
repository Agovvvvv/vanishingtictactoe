import 'package:flutter/material.dart';

class TutorialIconContainerWidget extends StatelessWidget {
  final int index;
  final Color primaryColor;
  final List<Map<String, dynamic>> tutorialData;

  const TutorialIconContainerWidget({super.key, 
    required this.index, 
    required this.primaryColor, 
    required this.tutorialData
  });

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.blue.shade50,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.blue.shade200.withOpacity(0.2),
              blurRadius: 10,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Icon(
          tutorialData[index]['icon'],
          size: 100,
          color: primaryColor,
          semanticLabel: 'Tutorial icon',
        ),
      ),
    );
  }
}