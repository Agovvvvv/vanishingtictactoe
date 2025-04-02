import 'package:flutter/material.dart';
import 'package:vanishingtictactoe/core/utils/font_preloader.dart';

class HellTutorialContentWidget extends StatelessWidget {
    final int index;
    final Color primaryColor;
    final List<Map<String, dynamic>> tutorialData;
    
    const HellTutorialContentWidget({
      super.key,
      required this.index,
      required this.primaryColor,
      required this.tutorialData,
    });
    @override
    Widget build(BuildContext context) {
      return Column(
      children: [
        const SizedBox(height: 30),
        // Title
        Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [primaryColor.withOpacity(0.1), primaryColor.withOpacity(0.2)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: primaryColor.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Text(
            tutorialData[index]['title'],
            style: FontPreloader.getTextStyle(
              fontFamily: 'Orbitron',
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: primaryColor,
              letterSpacing: 0.5,
              shadows: [
                Shadow(
                  color: Colors.grey.withOpacity(0.3),
                  blurRadius: 2,
                  offset: const Offset(1, 1),
                ),
              ],
            ),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 20),
        // Description
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.red.shade50.withOpacity(0.8), Colors.red.shade100.withOpacity(0.6)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.red.shade200,
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.red.shade100.withOpacity(0.4),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: primaryColor,
                    size: 24,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      "How It Works",
                      style: FontPreloader.getTextStyle(
                        fontFamily: 'Orbitron',
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: primaryColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                tutorialData[index]['description'],
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 18,
                  color: Colors.grey[800],
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ],
    );
  }
}