import 'package:flutter/material.dart';
import 'package:vanishingtictactoe/core/utils/font_preloader.dart';

class HellTutorialVisualWidget extends StatelessWidget {
  final int index;
  final Color primaryColor;
  final List<Map<String, dynamic>> tutorialData;

  const HellTutorialVisualWidget({
    super.key,
    required this.index,
    required this.primaryColor,
    required this.tutorialData,
  });

  @override
  Widget build(BuildContext context) {
    if (tutorialData[index]['image'] != null) {
      return Container(
        height: 350,
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.red.shade200, Colors.red.shade50],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.red.shade300.withOpacity(0.4),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(
            color: Colors.red.shade200,
            width: 2,
          ),
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.asset(
                    tutorialData[index]['image'],
                    fit: BoxFit.contain,
                    alignment: Alignment.center,
                    errorBuilder: (context, error, stackTrace) {
                      debugPrint('Error loading image: $error');
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              tutorialData[index]['icon'],
                              size: 80,
                              color: primaryColor,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Visual example',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
            Positioned(
              top: 10,
              right: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: primaryColor,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  'Example',
                  style: FontPreloader.getTextStyle(
                    fontFamily: 'Orbitron',
                    fontSize: 12,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    } else {
      return Container(
        padding: const EdgeInsets.all(32),
        margin: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          gradient: RadialGradient(
            colors: [Colors.red.shade100, Colors.red.shade200],
            radius: 0.8,
          ),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.red.shade300.withOpacity(0.5),
              blurRadius: 15,
              offset: const Offset(0, 5),
              spreadRadius: 1,
            ),
          ],
          border: Border.all(
            color: Colors.red.shade200,
            width: 2,
          ),
        ),
        child: Icon(
          tutorialData[index]['icon'],
          size: 120,
          color: primaryColor,
        ),
      );
    }
  }
}