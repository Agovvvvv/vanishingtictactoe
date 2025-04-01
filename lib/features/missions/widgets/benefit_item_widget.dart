import 'package:flutter/material.dart';

class BenefitItemWidget extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String text;
  const BenefitItemWidget({super.key, required this.icon, required this.color, required this.text});
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues( alpha: 0.1),
            shape: BoxShape.circle,
        ),
        child: Icon(icon, color: color, size: 20),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: Text(
          text,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade700,
          ),
        ),
      ),
    ],
  );
  }
}