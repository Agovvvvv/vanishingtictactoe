import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'dart:math';

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
  late Animation<double> _glowAnimation;
  late Animation<double> _shimmerAnimation;

  @override
  void initState() {
    super.initState();
    // Drawing animation controller with optimized duration for better impact
    _drawController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    // Pulsing effect controller with optimized parameters
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    // Drawing animation with improved curve for more dynamic movement
    _drawAnimation = CurvedAnimation(
      parent: _drawController,
      curve: Curves.easeOutExpo,
    );

    // Pulsing animation with more subtle range to reduce computation
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.25,
    ).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOutSine),
    );

    // Thickness animation for the line
    _thicknessAnimation = Tween<double>(
      begin: 0.0,
      end: 12.0,
    ).animate(
      CurvedAnimation(
        parent: _drawController,
        curve: Curves.easeOutQuart,
      ),
    );
    
    // Glow animation for the line
    _glowAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _drawController,
        curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
      ),
    );
    
    // Shimmer effect animation that travels along the line
    _shimmerAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _drawController,
        curve: const Interval(0.7, 1.0, curve: Curves.easeInOut),
      ),
    );

    // Coordinate animations with game flow
    _startAnimationSequence();
  }
  
  void _startAnimationSequence() {
    // Start drawing animation with a slight delay to coordinate with cell highlighting
    Future.delayed(const Duration(milliseconds: 100), () {
      _drawController.forward().then((_) {
        // Start pulsing animation after drawing completes, with optimized parameters
        _pulseController.repeat(reverse: true);
        
        // After 3 seconds, slow down the pulse to save resources
        Future.delayed(const Duration(milliseconds: 3000), () {
          if (mounted) {
            _pulseController.stop();
            _pulseController.duration = const Duration(milliseconds: 2000);
            _pulseController.repeat(reverse: true);
          }
        });

        // Notify completion after a short delay to allow pulse to be visible
        Future.delayed(const Duration(milliseconds: 800), () {
          if (mounted) {
            widget.onAnimationComplete();
          }
        });
      });
    });
  }

  @override
  void dispose() {
    // Stop animations before disposing to prevent memory leaks
    _pulseController.stop();
    _drawController.stop();
    
    _drawController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Determine if device is high-performance based on screen size
    final bool isHighPerformanceDevice = MediaQuery.of(context).size.width >= 768;
    
    return AnimatedBuilder(
      animation: Listenable.merge([
        _drawAnimation,
        _pulseAnimation,
        _thicknessAnimation,
        _glowAnimation,
        _shimmerAnimation,
      ]),
      builder: (context, child) {
        // Use the widget's color but allow for customization based on winner
        final baseColor = widget.isLocalPlayerWinner ? 
            widget.color : 
            Colors.red.shade600;
            
        return RepaintBoundary(
          child: CustomPaint(
            size: Size.infinite,
            painter: WinningLinePainter(
              winningPattern: widget.winningPattern,
              drawProgress: _drawAnimation,
              pulseValue: _pulseAnimation.value,
              thickness: _thicknessAnimation.value,
              glowIntensity: _glowAnimation.value,
              shimmerAnimation: _shimmerAnimation,
              color: baseColor,
              isLocalPlayerWinner: widget.isLocalPlayerWinner,
              highPerformanceMode: isHighPerformanceDevice,
            ),
            child: const SizedBox.expand(),
          ),
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
  final double glowIntensity;
  final Color color;
  final bool isLocalPlayerWinner;
  final Animation<double>? shimmerAnimation;
  final bool highPerformanceMode;
  
  // Caching variables for performance optimization
  Path? _cachedPath;
  List<Offset>? _cachedPoints;
  Rect? _cachedPathBounds;
  final List<_WinParticle> _particles = [];
  final Random _random = Random();

  WinningLinePainter({
    required this.winningPattern,
    required this.drawProgress,
    required this.pulseValue,
    required this.thickness,
    required this.color,
    this.glowIntensity = 1.0,
    this.isLocalPlayerWinner = true,
    this.shimmerAnimation,
    this.highPerformanceMode = true,
  }) : super(repaint: shimmerAnimation ?? drawProgress);
  
  // Helper function to convert radius to sigma for blur filter
  double _convertRadiusToSigma(double radius) {
    return radius * 0.57735 + 0.5;
  }
  
  // Helper method to compare lists of offsets
  bool _listEquals(List<Offset> list1, List<Offset> list2) {
    if (list1.length != list2.length) return false;
    for (int i = 0; i < list1.length; i++) {
      if (list1[i] != list2[i]) return false;
    }
    return true;
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (winningPattern.isEmpty || winningPattern.length < 3) return;

    final cellWidth = size.width / 3;
    final cellHeight = size.height / 3;

    // Calculate center points of each cell in the winning pattern
    final points = winningPattern.map((index) {
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
      adjustedPoints = points.map((point) {
        final vector = point - center;
        final scaledVector = vector * (1.0 + (pulseValue - 1.0) * 0.15);
        return center + scaledVector;
      }).toList();
    }

    // Create or use cached path
    Path path;
    if (_cachedPath != null && 
        _cachedPoints != null && 
        _listEquals(adjustedPoints, _cachedPoints!)) {
      path = _cachedPath!;
    } else {
      path = _createAnimatedPath(adjustedPoints);
      _cachedPath = path;
      _cachedPoints = List.from(adjustedPoints);
      _cachedPathBounds = path.getBounds();
    }

    // Draw effects based on device capability
    if (highPerformanceMode) {
      // Draw glow effect with optimized rendering
      _drawOptimizedGlowEffect(canvas, path, adjustedPoints);
      
      // Generate and draw particles for winner celebration
      _generateParticles(adjustedPoints);
      _updateAndDrawParticles(canvas);
    } else {
      // Draw simpler glow effect for lower-end devices
      _drawSimpleGlowEffect(canvas, path);
    }

    // Draw the main line with animation
    _drawMainLine(canvas, path, adjustedPoints);
    
    // Draw end caps for a more polished look
    _drawEndCaps(canvas, adjustedPoints);
    
    // Draw shimmer effect
    _drawShimmerEffect(canvas, path);
  }
  
  Path _createAnimatedPath(List<Offset> points) {
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
        final partialX = previousPoint.dx +
            (currentPoint.dx - previousPoint.dx) * segmentProgress;
        final partialY = previousPoint.dy +
            (currentPoint.dy - previousPoint.dy) * segmentProgress;
        path.lineTo(partialX, partialY);
        break;
      }
    }
    
    return path;
  }

  void _drawOptimizedGlowEffect(Canvas canvas, Path path, List<Offset> points) {
    final Rect pathBounds = _cachedPathBounds ?? path.getBounds();
    
    // Calculate angle for directional gradient
    final angle = _calculateLineAngle(points.first, points.last);
    final gradientDirection = _getGradientDirection(angle, pathBounds);
    
    // Create a gradient shader for more dynamic appearance
    final gradient = ui.Gradient.linear(
      gradientDirection.start,
      gradientDirection.end,
      [
        color.withOpacity(0.8),
        Color.lerp(color, Colors.white, 0.5) ?? color,
        color.withOpacity(0.8),
      ],
      [0.0, 0.5, 1.0],
    );

    // Use a single composite glow with layered effect instead of multiple draws
    final pulseOffset = (pulseValue - 1.0) * 5.0 * glowIntensity;
    
    // Outer glow
    final outerGlowPaint = Paint()
      ..color = color.withOpacity(0.3)
      ..strokeWidth = thickness * 2.5 + pulseOffset
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke
      ..maskFilter = MaskFilter.blur(
        BlurStyle.normal,
        _convertRadiusToSigma(8.0),
      );
    
    // Middle glow with gradient
    final middleGlowPaint = Paint()
      ..shader = gradient
      ..strokeWidth = thickness * 1.5 + (pulseOffset * 0.7)
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke
      ..maskFilter = MaskFilter.blur(
        BlurStyle.normal,
        _convertRadiusToSigma(4.0),
      );
    
    // Draw glows in order from outer to inner
    canvas.drawPath(path, outerGlowPaint);
    canvas.drawPath(path, middleGlowPaint);
  }
  
  void _drawSimpleGlowEffect(Canvas canvas, Path path) {
    // Simplified glow for lower-end devices
    final pulseOffset = (pulseValue - 1.0) * 3.0 * glowIntensity;
    final glowPaint = Paint()
      ..color = color.withOpacity(0.3)
      ..strokeWidth = thickness * 2.0 + pulseOffset
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke
      ..maskFilter = MaskFilter.blur(
        BlurStyle.normal,
        _convertRadiusToSigma(5.0),
      );
    
    canvas.drawPath(path, glowPaint);
  }

  void _drawMainLine(Canvas canvas, Path path, List<Offset> points) {
    final Rect pathBounds = _cachedPathBounds ?? path.getBounds();
    
    // Calculate angle for directional gradient
    final angle = _calculateLineAngle(points.first, points.last);
    final gradientDirection = _getGradientDirection(angle, pathBounds);
    
    // Create a gradient for the main line
    final gradient = ui.Gradient.linear(
      gradientDirection.start,
      gradientDirection.end,
      [
        color.withOpacity(0.9),
        Color.lerp(color, Colors.white, 0.5) ?? color,
        color.withOpacity(0.9),
      ],
      [0.0, 0.5, 1.0],
    );

    // Main line paint with dynamic thickness and gradient
    final paint = Paint()
      ..shader = gradient
      ..strokeWidth = thickness * pulseValue
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
      
    // Add a subtle inner glow for high-performance mode
    if (highPerformanceMode && glowIntensity > 0.5) {
      paint.maskFilter = MaskFilter.blur(
        BlurStyle.normal,
        _convertRadiusToSigma(1.0),
      );
    }

    canvas.drawPath(path, paint);
    
    // Draw a thinner, brighter line on top for a highlight effect
    if (isLocalPlayerWinner) {
      final highlightPaint = Paint()
        ..color = Colors.white.withOpacity(0.7 * glowIntensity)
        ..strokeWidth = (thickness * 0.4) * pulseValue
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;
        
      canvas.drawPath(path, highlightPaint);
    }
  }
  
  void _drawEndCaps(Canvas canvas, List<Offset> points) {
    if (points.isEmpty || drawProgress.value < 0.95) return;
    
    final startPoint = points.first;
    final endPoint = points.last;
    
    final capPaint = Paint()
      ..color = Color.lerp(color, Colors.white, 0.3) ?? color
      ..style = PaintingStyle.fill;
      
    if (highPerformanceMode) {
      capPaint.maskFilter = MaskFilter.blur(
        BlurStyle.normal, 
        _convertRadiusToSigma(2)
      );
    }
    
    // Draw end caps with subtle glow
    canvas.drawCircle(startPoint, thickness * 0.7 * pulseValue, capPaint);
    canvas.drawCircle(endPoint, thickness * 0.7 * pulseValue, capPaint);
  }
  
  void _drawShimmerEffect(Canvas canvas, Path path) {
    if (shimmerAnimation == null || shimmerAnimation!.value <= 0 || !highPerformanceMode) return;
    
    final shimmerPaint = Paint()
      ..color = Colors.white.withOpacity(0.6 * shimmerAnimation!.value)
      ..strokeWidth = thickness * 0.6
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    
    final pathMetrics = path.computeMetrics().toList();
    if (pathMetrics.isEmpty) return;
    
    final pathMetric = pathMetrics.first;
    final shimmerPosition = pathMetric.length * shimmerAnimation!.value;
    
    final shimmerStart = max(0.0, shimmerPosition - 20);
    final shimmerEnd = min(pathMetric.length, shimmerPosition + 20);
    
    if (shimmerStart < shimmerEnd) {
      final extractPath = pathMetric.extractPath(shimmerStart, shimmerEnd);
      canvas.drawPath(extractPath, shimmerPaint);
    }
  }
  
  void _generateParticles(List<Offset> points) {
    if (!isLocalPlayerWinner || drawProgress.value < 0.95 || !highPerformanceMode) return;
    
    // Only generate particles occasionally to improve performance
    if (_random.nextDouble() > 0.1) return;
    
    // Add particles at endpoints
    final startPoint = points.first;
    final endPoint = points.last;
    
    for (int i = 0; i < 2; i++) {
      final point = i == 0 ? startPoint : endPoint;
      
      for (int j = 0; j < 2; j++) {  // Reduced particle count for better performance
        final angle = _random.nextDouble() * 2 * pi;
        final speed = _random.nextDouble() * 2.0 + 1.0;
        
        _particles.add(_WinParticle(
          point,
          Offset(cos(angle) * speed, sin(angle) * speed),
          _random.nextDouble() * 3.0 + 2.0,
          Color.lerp(color, Colors.white, _random.nextDouble() * 0.5) ?? color,
        ));
      }
    }
    
    // Remove dead particles
    _particles.removeWhere((p) => p.isDead());
    
    // Limit total particles for performance
    if (_particles.length > 30) {
      _particles.removeRange(0, _particles.length - 30);
    }
  }
  
  void _updateAndDrawParticles(Canvas canvas) {
    for (final particle in _particles) {
      particle.update();
      particle.draw(canvas);
    }
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
  
  double _calculateLineAngle(Offset start, Offset end) {
    return (end - start).direction;
  }
  
  _GradientDirection _getGradientDirection(double angle, Rect bounds) {
    final center = bounds.center;
    final radius = bounds.width > bounds.height ? bounds.width / 2 : bounds.height / 2;
    
    return _GradientDirection(
      Offset(center.dx + cos(angle) * radius, center.dy + sin(angle) * radius),
      Offset(center.dx - cos(angle) * radius, center.dy - sin(angle) * radius),
    );
  }

  @override
  bool shouldRepaint(covariant WinningLinePainter oldDelegate) {
    return oldDelegate.drawProgress != drawProgress ||
        oldDelegate.pulseValue != pulseValue ||
        oldDelegate.thickness != thickness ||
        oldDelegate.winningPattern != winningPattern ||
        oldDelegate.color != color ||
        oldDelegate.glowIntensity != glowIntensity ||
        oldDelegate.isLocalPlayerWinner != isLocalPlayerWinner ||
        oldDelegate.shimmerAnimation != shimmerAnimation;
  }
}

class _GradientDirection {
  final Offset start;
  final Offset end;
  
  _GradientDirection(this.start, this.end);
}

class _WinParticle {
  Offset position;
  Offset velocity;
  double size;
  double opacity;
  Color color;
  
  _WinParticle(this.position, this.velocity, this.size, this.color)
    : opacity = 1.0;
  
  void update() {
    position += velocity;
    opacity -= 0.02;  // Faster fade-out for better performance
    size *= 0.98;
  }
  
  bool isDead() => opacity <= 0 || size <= 0.5;
  
  void draw(Canvas canvas) {
    final paint = Paint()
      ..color = color.withOpacity(opacity)
      ..style = PaintingStyle.fill;
    
    canvas.drawCircle(position, size, paint);
  }
}