import 'package:flutter/material.dart';
import 'package:vanishingtictactoe/core/navigation/navigation_service.dart';

class TutorialCompletionDialogWidget extends StatelessWidget {
  const TutorialCompletionDialogWidget({super.key});
  
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Semantics(
        label: 'Tutorial Complete!',
        header: true,
        child: Row(
          children: [
            Icon(Icons.celebration, color: Colors.blue.shade700, size: 24),
            const SizedBox(width: 8),
            const Text('Tutorial Complete!'),
          ],
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Great job! You now understand how Vanishing Tic Tac Toe works. Ready to play for real?',
            style: TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.shade100.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Column(
              children: [
                Icon(Icons.emoji_events, color: Colors.amber, size: 40),
                SizedBox(height: 8),
                Text(
                  'You\'re ready to play!',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        Semantics(
          label: 'Let\'s Play button',
          button: true,
          hint: 'Start playing the game',
          child: ElevatedButton.icon(
            onPressed: () {
              Navigator.of(context).pop();
              NavigationService.instance.navigateToAndRemoveUntil('/main');
            },
            icon: const Icon(Icons.play_arrow, size: 18, color: Colors.white),
            label: const Text('Let\'s Play!'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue.shade700,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ),
      ],
    );
  }
}