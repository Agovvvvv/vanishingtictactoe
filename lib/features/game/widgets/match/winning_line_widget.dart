import 'package:flutter/material.dart';

class WinningLineWidget extends StatefulWidget {
  final List<int> winningPattern;
  final Color color;
  final VoidCallback onAnimationComplete;
  final bool isLocalPlayerWinner;

  const WinningLineWidget({
    super.key,
    required this.winningPattern,
    required this.color,
    required this.onAnimationComplete,
    this.isLocalPlayerWinner = true,
  });

  @override
  State<WinningLineWidget> createState() => _WinningLineWidgetState();
}

class _WinningLineWidgetState extends State<WinningLineWidget>
    with TickerProviderStateMixin {
  late AnimationController _drawController;
  late AnimationController _pulseController;
  late Animation<double> _drawAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _thicknessAnimation;

  @override
  void initState() {
    super.initState();
    // Drawing animation controller with optimized duration for better impact
    _drawController = AnimationController(
      duration: const Duration(milliseconds: 500), // Reduced for less lag
      vsync: this,
    );

    // Pulsing effect controller that starts after drawing is complete
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000), // Reduced for less lag
      vsync: this,
    );

    // Drawing animation with improved curve for more dynamic movement
    _drawAnimation = CurvedAnimation(
      parent: _drawController,
      curve: Curves.easeOutQuart, // Sharper acceleration for more impact
    );

    // Pulsing animation with more subtle range to reduce computation
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2, // Reduced pulse effect for better performance
    ).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOutSine),
    );

    // Simplified thickness animation for better performance
    _thicknessAnimation = Tween<double>(
      begin: 0.0,
      end: 10.0, // Consistent thickness
    ).animate(
      CurvedAnimation(
        parent: _drawController,
        curve: Curves.easeOutQuart,
      ),
    );

    // Start drawing animation
    _drawController.forward().then((_) {
      // Start pulsing animation after drawing completes
      _pulseController.repeat(reverse: true);

      // Notify completion after a short delay to allow pulse to be visible
      Future.delayed(const Duration(milliseconds: 600), () {
        widget.onAnimationComplete();
      });
    });
  }

  @override
  void dispose() {
    _drawController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        _drawAnimation,
        _pulseAnimation,
        _thicknessAnimation,
      ]),
      builder: (context, child) {
        return CustomPaint(
          size: Size.infinite,
          painter: WinningLinePainter(
            winningPattern: widget.winningPattern,
            drawProgress: _drawAnimation,
            pulseValue: _pulseAnimation.value,
            thickness: _thicknessAnimation.value,
            color: widget.isLocalPlayerWinner ? Colors.blue.shade600 : Colors.red.shade600,
          ),
          child: const SizedBox.expand(),
        );
      },
    );
  }
}

class WinningLinePainter extends CustomPainter {
  final List<int> winningPattern;
  final Animation<double> drawProgress;
  final double pulseValue;
  final double thickness;
  final Color color;

  WinningLinePainter({
    required this.winningPattern,
    required this.drawProgress,
    required this.pulseValue,
    required this.thickness,
    required this.color,
  }) : super(repaint: drawProgress);

  @override
  void paint(Canvas canvas, Size size) {
    if (winningPattern.isEmpty || winningPattern.length < 3) return;

    final cellWidth = size.width / 3;
    final cellHeight = size.height / 3;

    // Calculate center points of each cell in the winning pattern
    final points =
        winningPattern.map((index) {
          final row = index ~/ 3;
          final col = index % 3;
          return Offset(
            (col * cellWidth) + (cellWidth / 2),
            (row * cellHeight) + (cellHeight / 2),
          );
        }).toList();

    if (points.length < 2) return;

    // Apply pulse effect to the points
    List<Offset> adjustedPoints = List.from(points);
    if (pulseValue > 1.0) {
      final center = _calculateCenter(points);
      adjustedPoints =
          points.map((point) {
            final vector = point - center;
            final scaledVector = vector * (1.0 + (pulseValue - 1.0) * 0.15);
            return center + scaledVector;
          }).toList();
    }

    // Draw glow effect
    _drawGlowEffect(canvas, adjustedPoints);

    // Draw the main line with animation
    _drawMainLine(canvas, adjustedPoints);
  }

  void _drawGlowEffect(Canvas canvas, List<Offset> points) {
    // Create a path for the entire line
    final path = Path();
    path.moveTo(points[0].dx, points[0].dy);

    // Calculate the path based on animation progress
    for (int i = 1; i < points.length; i++) {
      final previousPoint = points[i - 1];
      final currentPoint = points[i];
      final progressValue = drawProgress.value * points.length;

      if (i < progressValue) {
        // Draw complete segment
        path.lineTo(currentPoint.dx, currentPoint.dy);
      } else if (i - 1 < progressValue && i > progressValue) {
        // Draw partial segment
        final segmentProgress = progressValue - (i - 1);
        final partialX =
            previousPoint.dx +
            (currentPoint.dx - previousPoint.dx) * segmentProgress;
        final partialY =
            previousPoint.dy +
            (currentPoint.dy - previousPoint.dy) * segmentProgress;
        path.lineTo(partialX, partialY);
        break;
      }
    }

    // Further optimized: Draw only 2 layers of glow for better performance
    for (int i = 0; i < 2; i++) {
      // Simplified pulse calculation
      final pulseOffset = (pulseValue - 1.0) * 5.0;
      final glowPaint = Paint()
        ..color = color.withValues(alpha: 0.4 - (i * 0.2))
        ..strokeWidth = thickness + (i * 8.0) + pulseOffset
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke
        ..maskFilter = MaskFilter.blur(
          BlurStyle.normal,
          8.0 + (i * 4.0),
        );

      canvas.drawPath(path, glowPaint);
    }

    // Removed the extra outer glow to improve performance
  }

  void _drawMainLine(Canvas canvas, List<Offset> points) {
    final path = Path();
    path.moveTo(points[0].dx, points[0].dy);

    // Calculate the path based on animation progress
    for (int i = 1; i < points.length; i++) {
      final previousPoint = points[i - 1];
      final currentPoint = points[i];
      final progressValue = drawProgress.value * points.length;

      if (i < progressValue) {
        // Draw complete segment
        path.lineTo(currentPoint.dx, currentPoint.dy);
      } else if (i - 1 < progressValue && i > progressValue) {
        // Draw partial segment
        final segmentProgress = progressValue - (i - 1);
        final partialX =
            previousPoint.dx +
            (currentPoint.dx - previousPoint.dx) * segmentProgress;
        final partialY =
            previousPoint.dy +
            (currentPoint.dy - previousPoint.dy) * segmentProgress;
        path.lineTo(partialX, partialY);
        break;
      }
    }

    // Main line paint with dynamic thickness
    final paint =
        Paint()
          ..color = color
          ..strokeWidth = thickness * pulseValue
          ..strokeCap = StrokeCap.round
          ..style = PaintingStyle.stroke;

    canvas.drawPath(path, paint);
  }

  Offset _calculateCenter(List<Offset> points) {
    double sumX = 0;
    double sumY = 0;

    for (final point in points) {
      sumX += point.dx;
      sumY += point.dy;
    }

    return Offset(sumX / points.length, sumY / points.length);
  }

  @override
  bool shouldRepaint(covariant WinningLinePainter oldDelegate) {
    return oldDelegate.drawProgress != drawProgress ||
        oldDelegate.pulseValue != pulseValue ||
        oldDelegate.thickness != thickness ||
        oldDelegate.winningPattern != winningPattern ||
        oldDelegate.color != color;
  }
}


