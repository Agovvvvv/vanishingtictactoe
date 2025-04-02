// Helper method to build a demo cell for the vanishing effect explanation
import 'package:flutter/material.dart';

class TutorialDemoCellWidget extends StatelessWidget {
  final String symbol;
  final bool isFlashing;
  final Animation<double> flashingAnimation;

  
  const TutorialDemoCellWidget({
    super.key,
    required this.symbol,
    required this.isFlashing,
    required this.flashingAnimation,
  });
  
  @override
  Widget build(BuildContext context) {
    // Define semantic label based on cell state
    final String semanticLabel = isFlashing
        ? 'Flashing empty cell demonstrating vanishing effect'
        : symbol.isEmpty 
            ? 'Empty cell'
            : '$symbol cell';
    
    final Color symbolColor = symbol == 'X' 
        ? Colors.blue.shade700 // Darker blue for better contrast
        : Colors.red.shade700;  // Darker red for better contrast
    
    if (!isFlashing) {
      return Semantics(
        label: semanticLabel,
        excludeSemantics: true,
        child: Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: Colors.grey.shade400),
            borderRadius: BorderRadius.circular(4),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.shade200,
                offset: const Offset(0, 1),
                blurRadius: 2,
              ),
            ],
          ),
          child: Center(
            child: Text(
              symbol,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: symbolColor,
              ),
            ),
          ),
        ),
      );
    }
    
    // Use AnimatedBuilder for efficient animation
    return Semantics(
      label: semanticLabel,
      excludeSemantics: true,
      child: AnimatedBuilder(
        animation: flashingAnimation,
        builder: (context, child) {
          return Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: Color.lerp(Colors.white, Colors.orange.withOpacity(0.3), flashingAnimation.value),
              border: Border.all(color: Colors.grey.shade400),
              borderRadius: BorderRadius.circular(4),
              boxShadow: [
                BoxShadow(
                  color: Colors.orange.withOpacity(0.1 * flashingAnimation.value),
                  offset: const Offset(0, 1),
                  blurRadius: 3,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: child,
          );
        },
        child: Center(
          child: Text(
            symbol,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: symbolColor,
            ),
          ),
        ),
      ),
    );
  }
}