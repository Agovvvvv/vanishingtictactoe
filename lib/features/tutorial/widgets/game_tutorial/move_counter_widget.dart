// Build the move counter at the bottom
import 'package:flutter/material.dart';

class TutorialMoveCounterWidget extends StatelessWidget {
  final int playerMoves;
  
  const TutorialMoveCounterWidget({
    super.key,
    required this.playerMoves,
  });
  
  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Move counter showing $playerMoves moves',
      child: ExcludeSemantics(
        child: Container(
          margin: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.history,
                size: 18,
                color: Colors.blue.shade700,
              ),
              const SizedBox(width: 8),
              Text(
                'Your moves: $playerMoves',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey.shade800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}