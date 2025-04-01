import 'dart:math' as math show Random;

import 'package:flutter/material.dart';

class HellPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.red.shade800.withValues( alpha: 0.4)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;
    
    final random = math.Random(42); // Fixed seed for consistent pattern
    
    // Draw a grid of small flame-like patterns
    for (int i = 0; i < size.width; i += 40) {
      for (int j = 0; j < size.height; j += 40) {
        final offsetX = random.nextDouble() * 10;
        final offsetY = random.nextDouble() * 10;
        
        final path = Path();
        path.moveTo(i + offsetX, j + offsetY);
        
        // Create flame-like shapes
        path.quadraticBezierTo(
          i + 10 + random.nextDouble() * 5, 
          j + 15 + random.nextDouble() * 5,
          i + 5 + random.nextDouble() * 10, 
          j + 25 + random.nextDouble() * 5
        );
        
        path.quadraticBezierTo(
          i + 15 + random.nextDouble() * 5, 
          j + 20 + random.nextDouble() * 5,
          i + 20 + random.nextDouble() * 5, 
          j + 10 + random.nextDouble() * 5
        );
        
        path.quadraticBezierTo(
          i + 25 + random.nextDouble() * 5, 
          j + 5 + random.nextDouble() * 5,
          i + offsetX, 
          j + offsetY
        );
        
        canvas.drawPath(path, paint);
      }
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}