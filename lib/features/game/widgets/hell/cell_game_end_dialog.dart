import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CellGameEndDialog extends StatelessWidget {
  final String message;
  final VoidCallback onBackToMainBoard;

  const CellGameEndDialog({
    super.key,
    required this.message,
    required this.onBackToMainBoard,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      elevation: 8,
      insetAnimationDuration: const Duration(milliseconds: 300),
      insetAnimationCurve: Curves.easeOutQuint,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: Colors.red.shade800, width: 2),
      ),
      backgroundColor: Colors.black,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutQuint,
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.red.withValues(alpha: 0.3),
              blurRadius: 15,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Animated title
            TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0.8, end: 1.0),
              duration: const Duration(milliseconds: 500),
              curve: Curves.elasticOut,
              builder: (context, value, child) {
                return Transform.scale(
                  scale: value,
                  child: Text(
                    'CELL GAME OVER',
                    style: GoogleFonts.pressStart2p(
                      fontSize: 18,
                      color: Colors.red.shade500,
                      height: 1.2,
                    ),
                    textAlign: TextAlign.center,
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
            // Message with flame icon
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.local_fire_department, color: Colors.orange.shade700, size: 24),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    message,
                    style: GoogleFonts.pressStart2p(
                      fontSize: 16,
                      color: Colors.white,
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(width: 8),
                Icon(Icons.local_fire_department, color: Colors.orange.shade700, size: 24),
              ],
            ),
            const SizedBox(height: 30),
            // Button with hover effect
            MouseRegion(
              cursor: SystemMouseCursors.click,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.red.shade900, Colors.red.shade700],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.red.shade800.withValues(alpha: 0.5),
                      blurRadius: 10,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () {
                      // Just close the dialog and call the callback
                      // Don't do any navigation here
                      Navigator.of(context).pop();
                      onBackToMainBoard();
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.arrow_back,
                            color: Colors.white,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'RETURN TO HELL',
                            style: GoogleFonts.pressStart2p(
                              fontSize: 12,
                              color: Colors.white,
                              letterSpacing: 1,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
