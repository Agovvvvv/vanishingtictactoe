// Helper method to build info cards
import 'package:flutter/material.dart';

class InfoCardWidget extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final bool isHellMode;
  
  const InfoCardWidget({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.isHellMode,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isHellMode 
            ? Colors.red.shade900.withValues(alpha: 0.3)
          : Colors.white.withValues(alpha: 0.2),
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: isHellMode
              ? Colors.red.shade900.withValues(alpha: 0.3)
              : Colors.blue.shade200.withValues(alpha: 0.2),
          blurRadius: 4,
          offset: const Offset(0, 2),
        ),
      ],
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          title,
          style: TextStyle(
            color: isHellMode ? Colors.orange.shade300 : Colors.blue.shade800,
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 2),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon, 
              size: 12, 
              color: isHellMode ? Colors.orange.shade500 : Colors.blue.shade600
            ),
            const SizedBox(width: 3),
            Text(
              value,
              style: TextStyle(
                color: isHellMode ? Colors.white : Colors.black87,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ],
    ),
  );
}
}
