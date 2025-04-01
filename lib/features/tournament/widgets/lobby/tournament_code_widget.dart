import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class TournamentCodeWidget extends StatelessWidget {
  final String code;
  final Color primaryColor;

  const TournamentCodeWidget ({
    super.key,
    required this.code,
    required this.primaryColor
  });

    @override
    Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _copyTournamentCode(code, context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade300, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Animated code display
            TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0.9, end: 1.0),
              duration: const Duration(milliseconds: 1500),
              curve: Curves.easeInOut,
              builder: (context, value, child) {
                return Transform.scale(
                  scale: value,
                  child: Text(
                    code,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 4,
                      color: Colors.grey.shade800,
                      fontFamily: 'monospace',
                    ),
                  ),
                );
              },
            ),
            const SizedBox(width: 16),
            
            // Animated copy icon
            TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 500),
              curve: Curves.elasticOut,
              builder: (context, value, child) {
                return Transform.scale(
                  scale: value,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.copy_rounded,
                      size: 24,
                      color: primaryColor,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _copyTournamentCode(String code, context) async {
    await Clipboard.setData(ClipboardData(text: code));
        
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Tournament code copied to clipboard')),
    );
  }
}