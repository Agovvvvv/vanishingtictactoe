import 'package:flutter/material.dart';
import 'package:vanishingtictactoe/core/utils/font_preloader.dart';

class MatchHistoryItem extends StatelessWidget {
  final Map<String, dynamic> match;
  final Function(Map<String, dynamic>) onRematch;
  final bool isHellMode;

  const MatchHistoryItem({
    super.key,
    required this.match,
    required this.onRematch,
    this.isHellMode = false,
  });

  @override
  Widget build(BuildContext context) {
    final player1 = match['player1'] as String;
    final player2 = match['player2'] as String;
    final winner = match['winner'] as String;
    final timestamp = DateTime.parse(match['timestamp'] as String);
    final formattedDate = '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    // Extract vanishing effect status from match data
    final vanishingEffectEnabled = match['vanishingEffectEnabled'] as bool? ?? true;
    
    String resultText;
    Color resultColor;
    
    if (winner == 'draw') {
      resultText = 'Draw';
      resultColor = Colors.orange;
    } else {
      final winnerName = winner == 'X' ? player1 : player2;
      resultText = '$winnerName wins';
      resultColor = winner == 'X' ? Colors.blue : Colors.red;
    }
    
    // Define colors based on mode
    final primaryColor = isHellMode ? const Color(0xFFE74C3C) : const Color(0xFF2E86DE);
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      elevation: 8,
      shadowColor: primaryColor.withValues( alpha: 0.3),
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: primaryColor.withValues( alpha: 0.3),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isHellMode 
                        ? const Color(0xFFE74C3C).withValues( alpha: 0.1)
                        : const Color(0xFF2E86DE).withValues( alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isHellMode)
                        Padding(
                          padding: const EdgeInsets.only(right: 4),
                          child: Icon(
                            Icons.whatshot,
                            size: 12,
                            color: const Color(0xFFE74C3C),
                          ),
                        ),
                      Text(
                        isHellMode ? 'HELL MODE' : 'REGULAR MATCH',
                        style: FontPreloader.getTextStyle(
                          fontFamily: 'Press Start 2P',
                          fontSize: 10,
                          color: isHellMode 
                              ? const Color(0xFFE74C3C)
                              : const Color(0xFF2E86DE),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues( alpha: 0.05),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: 12,
                        color: Colors.grey.shade700,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        formattedDate,
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues( alpha: 0.03),
                    blurRadius: 8,
                    spreadRadius: 1,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: const Color(0xFF2E86DE),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF2E86DE).withValues( alpha: 0.3),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Text(
                            'X',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        player1,
                        style: const TextStyle(
                          color: Color(0xFF2C3E50),
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'vs',
                      style: TextStyle(
                        color: Color(0xFF7F8C8D),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      Text(
                        player2,
                        style: const TextStyle(
                          color: Color(0xFF2C3E50),
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE74C3C),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFE74C3C).withValues( alpha: 0.3),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Text(
                            'O',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: resultColor.withValues( alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: resultColor.withValues( alpha: 0.3),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: resultColor.withValues( alpha: 0.1),
                    blurRadius: 8,
                    spreadRadius: 1,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    winner == 'draw' ? Icons.balance : Icons.emoji_events,
                    color: resultColor,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    resultText,
                    style: FontPreloader.getTextStyle(
                      fontFamily: 'Orbitron',
                      fontSize: 16,
                      color: resultColor,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Add vanishing effect status indicator
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: vanishingEffectEnabled 
                        ? Colors.purple.withValues( alpha: 0.1)
                        : Colors.grey.withValues( alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: vanishingEffectEnabled 
                          ? Colors.purple.withValues( alpha: 0.3)
                          : Colors.grey.withValues( alpha: 0.3),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues( alpha: 0.03),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        vanishingEffectEnabled ? Icons.visibility_off : Icons.visibility,
                        size: 14,
                        color: vanishingEffectEnabled ? Colors.purple : Colors.grey[700],
                      ),
                      const SizedBox(width: 6),
                      Text(
                        vanishingEffectEnabled ? 'Vanishing Effect: ON' : 'Vanishing Effect: OFF',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: vanishingEffectEnabled ? Colors.purple : Colors.grey[700],
                        ),
                      ),
                    ],
                  ),
                ),
                // Keep the rematch button
                ElevatedButton(
                  onPressed: () => onRematch(match),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    elevation: 5,
                    shadowColor: primaryColor.withValues( alpha: 0.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.replay_rounded,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'REMATCH',
                        style: FontPreloader.getTextStyle(
                          fontFamily: 'Orbitron',
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}