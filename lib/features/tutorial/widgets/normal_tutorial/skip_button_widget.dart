import 'package:flutter/material.dart';
import 'package:vanishingtictactoe/core/navigation/navigation_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TutorialSkipButtonWidget extends StatelessWidget {
  const TutorialSkipButtonWidget({super.key});

  void _markTutorialComplete() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('tutorial_completed', true);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Semantics(
            label: 'Skip tutorial and go to main menu',
            hint: 'Double tap to skip the tutorial',
            button: true,
            child: TextButton.icon(
              onPressed: () {
                _markTutorialComplete();
                NavigationService.instance.navigateToAndRemoveUntil('/main');
              },
              icon: const Icon(Icons.skip_next),
              label: const Text('Skip'),
              style: TextButton.styleFrom(
                foregroundColor: Colors.blue.shade700, // Darker blue for better contrast
              ),
            ),
          ),
        ],
      ),
    );
  }
}