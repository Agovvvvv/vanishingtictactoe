import 'dart:math' as math;
import 'package:flutter/material.dart';

class OnlineCoinFlipWidget extends StatefulWidget {
  final Animation<double> flipAnimation;
  final Animation<double> scaleAnimation;
  final bool coinFlipComplete;
  final String? currentTurn; // 'X' or 'O'
  final String? player1Symbol; // Symbol for player 1
  final String? player2Symbol; // Symbol for player 2
  
  const OnlineCoinFlipWidget({
    super.key,
    required this.flipAnimation,
    required this.scaleAnimation,
    required this.coinFlipComplete,
    this.currentTurn,
    this.player1Symbol,
    this.player2Symbol,
  });

  @override
  State<OnlineCoinFlipWidget> createState() => _OnlineCoinFlipWidgetState();
}

class _OnlineCoinFlipWidgetState extends State<OnlineCoinFlipWidget> {
  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: widget.scaleAnimation,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues( alpha: 0.05),
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: const Text(
              'Flipping coin to decide who goes first...',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.black54,
              ),
            ),
          ),
          const SizedBox(height: 30),
          AnimatedBuilder(
            animation: widget.flipAnimation,
            builder: (context, child) {
              // Determine which side to show based on the animation and current turn
              bool showFront;
              
              if (widget.coinFlipComplete) {
                // When animation is complete, show the side that matches the winning symbol
                showFront = widget.currentTurn == widget.player1Symbol;
              } else {
                // During animation, alternate between sides
                showFront = (widget.flipAnimation.value / math.pi).floor() % 2 == 0;
              }
              
              return Transform(
                alignment: Alignment.center,
                transform: Matrix4.identity()
                  ..setEntry(3, 2, 0.001) // Perspective
                  ..rotateY(widget.flipAnimation.value),
                child: Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: showFront 
                          ? [Colors.blue.shade400, Colors.blue.shade700]
                          : [Colors.red.shade400, Colors.red.shade700],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: (showFront ? Colors.blue : Colors.red).withValues( alpha: 0.4),
                        blurRadius: 15,
                        spreadRadius: 2,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      showFront 
                          ? (widget.player1Symbol ?? 'X') 
                          : (widget.player2Symbol ?? 'O'),
                      style: const TextStyle(
                        fontSize: 70,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        shadows: [
                          Shadow(
                            color: Colors.black26,
                            blurRadius: 5,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

// Helper widget to show the result after coin flip
class CoinFlipResultWidget extends StatelessWidget {
  final String resultText;
  final bool isVisible;
  final String? winnerName;
  final String? winnerSymbol;
  
  const CoinFlipResultWidget({
    super.key,
    required this.resultText,
    required this.isVisible,
    this.winnerName,
    this.winnerSymbol,
  });
  
  @override
  Widget build(BuildContext context) {
    return Visibility(
      visible: isVisible,
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.only(top: 40),
            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.shade100.withValues( alpha: 0.5),
                  blurRadius: 15,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Column(
              children: [
                Text(
                  resultText,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                if (winnerName != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      '$winnerName (${winnerSymbol ?? ''}) will go first',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Container(
            margin: const EdgeInsets.only(top: 20),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(30),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Starting game...',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}