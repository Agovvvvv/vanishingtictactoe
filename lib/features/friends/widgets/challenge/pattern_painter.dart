import 'package:flutter/material.dart';

/// Background pattern painter for subtle visual interest
class PatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.blue.withValues( alpha: 0.1)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    const spacing = 40.0;
    
    // Draw horizontal lines
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
    
    // Draw vertical lines
    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    
    // Draw some circles for added visual interest
    final circlePaint = Paint()
      ..color = Colors.blue.withValues( alpha: 0.05)
      ..style = PaintingStyle.fill;
      
    for (int i = 0; i < 10; i++) {
      final x = (i * spacing * 2) % size.width;
      final y = (i * spacing * 3) % size.height;
      canvas.drawCircle(Offset(x, y), spacing, circlePaint);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
