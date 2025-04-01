import 'package:flutter/material.dart';

class GridPatternPainterWidget extends StatelessWidget {
  const GridPatternPainterWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: GridPatternPainter(),
    );
  }
}

class GridPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withValues( alpha: 0.1)
      ..strokeWidth = 0.5
      ..style = PaintingStyle.stroke;
    
    // Draw horizontal lines
    for (double y = 0; y < size.height; y += 40) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
    
    // Draw vertical lines
    for (double x = 0; x < size.width; x += 40) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
  }
  
  @override
  bool shouldRepaint(GridPatternPainter oldDelegate) => false;
}