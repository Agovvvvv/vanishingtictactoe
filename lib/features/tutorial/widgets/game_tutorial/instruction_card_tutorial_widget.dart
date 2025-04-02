import 'package:flutter/material.dart';

class TutorialInstructionCardWidget extends StatelessWidget {
  final int moveCount;
  
  const TutorialInstructionCardWidget({
    super.key,
    required this.moveCount,
  });
  
  @override
  Widget build(BuildContext context) {
    final String instructionText = moveCount < 3 
        ? 'Play normally - make your move!' 
        : 'Watch for the vanishing effect!';
        
    return Semantics(
      label: 'Tutorial instruction: $instructionText',
      container: true,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue.shade50, Colors.blue.shade100],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.blue.shade200.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: Icon(
                moveCount < 3 ? Icons.touch_app : Icons.remove_circle_outline,
                color: Colors.blue.shade700,
                size: 24,
                semanticLabel: moveCount < 3 ? 'Touch icon' : 'Vanishing effect icon',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                instructionText,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.blue.shade900,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
  