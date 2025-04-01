import 'package:flutter/material.dart';
import 'dart:math' as math;

/// A single confetti particle
class Confetti {
  double x;
  double y;
  Color color;
  double size;
  Offset velocity;
  double rotation;
  double rotationSpeed;
  int shapeType;
  bool isActive = true;
  
  Confetti({
    required this.x,
    required this.y,
    required this.color,
    required this.size,
    required this.velocity,
    required this.rotation,
    required this.shapeType,
    this.rotationSpeed = 0.01,
  });
  
  /// Update the confetti position and rotation
  void update(double delta, Size screenSize) {
    // Skip update if not active
    if (!isActive) return;
    
    // Update position with smoother physics
    x += velocity.dx * delta;
    y += velocity.dy * delta;
    
    // Add gravity effect with enhanced physics
    // Horizontal velocity decreases over time (air resistance)
    // Vertical velocity increases (gravity) but with a terminal velocity
    final horizontalDrag = velocity.dx * 0.985; // Slightly less drag for longer travel
    final verticalAcceleration = math.min(velocity.dy + 0.15 * delta * 60, 7.0); // Adjusted gravity and terminal velocity
    velocity = Offset(horizontalDrag, verticalAcceleration);
    
    // Add enhanced horizontal oscillation for more natural movement
    // This creates a more pronounced fluttering effect
    x += math.sin(y * 2.5 + rotation * 1.2) * 0.0015 * delta * 60;
    
    // Update rotation with improved randomness for more natural movement
    rotation += (rotationSpeed + math.sin(y * 1.8) * 0.003) * delta * 60;
    
    // Deactivate if out of bounds (with some margin)
    // Extended bounds to keep confetti visible longer
    if (y > 1.3 || y < -0.3 || x > 1.3 || x < -0.3) {
      isActive = false;
    }
  }
}

/// Controller for managing confetti animations
class ConfettiController extends ChangeNotifier {
  final List<Confetti> confetti = [];
  final math.Random _random = math.Random();
  bool _isActive = false;
  double _progress = 0.0;
  
  bool get isActive => _isActive;
  double get progress => _progress;
  
  /// Generate confetti with the given parameters
  void generateConfetti({
    required int count,
    required bool isHellMode,
    double spread = 1.4,
    double verticalPosition = 0.4,
  }) {
    // Clear any existing confetti
    confetti.clear();
    
    // Significantly increase the number of confetti particles for a more impressive effect
    // Default count is now a base value that we'll multiply
    final int actualCount = count * 3; // Triple the confetti count
    
    // Generate new confetti with staggered emission for more natural effect
    for (int i = 0; i < actualCount; i++) {
      // Create multiple burst points for a more dynamic effect
      final burstPoint = i % 3; // Create 3 different burst points
      final double burstOffsetX = (burstPoint - 1) * 0.15; // Spread burst points horizontally
      
      // Vary the initial positions more for a wider, more natural burst
      final double angle = _random.nextDouble() * math.pi * 2;
      final double distance = _random.nextDouble() * 0.35 * spread;
      final double centerX = 0.5 + burstOffsetX;
      final double centerY = 0.5 - verticalPosition / 2;
      
      // Calculate position based on angle and distance from center
      final double x = centerX + math.cos(angle) * distance;
      final double y = centerY + math.sin(angle) * distance;
      
      // Create more varied velocities for more dynamic movement
      final double speed = _random.nextDouble() * 4.0 + 2.0; // Increased base speed
      final double vAngle = angle + (_random.nextDouble() - 0.5) * 1.2; // More angle variation
      
      // Create different sizes for different types of confetti
      final double baseSize = _random.nextDouble() * 6 + 2; // Slightly smaller base size for performance
      final double sizeVariation = i % 10 == 0 ? 2.0 : 1.0; // Some particles are larger
      
      confetti.add(Confetti(
        x: x,
        y: y,
        color: _getRandomColor(isHellMode),
        size: baseSize * sizeVariation,
        velocity: Offset(
          math.cos(vAngle) * speed * (_random.nextDouble() * 0.6 + 0.4),
          math.sin(vAngle) * speed * (_random.nextDouble() * 0.6 + 0.4) - 5.0, // Stronger initial upward velocity
        ),
        rotation: _random.nextDouble() * 2 * math.pi,
        shapeType: i % 5, // Use 5 different shapes
        rotationSpeed: (_random.nextDouble() - 0.5) * 0.08, // More rotation variation
      ));
    }
    
    _isActive = true;
    _progress = 0.0;
    notifyListeners();
  }
  
  /// Update the confetti animation progress
  void updateProgress(double value) {
    _progress = value;
    notifyListeners();
  }
  
  /// Stop the confetti animation
  void stop() {
    _isActive = false;
    notifyListeners();
  }
  
  /// Get a random color based on the mode
  Color _getRandomColor(bool isHellMode) {
    final colors = isHellMode
        ? [
            Colors.red.shade300,
            Colors.red.shade400,
            Colors.red.shade500,
            Colors.orange.shade300,
            Colors.orange.shade400,
            Colors.amber.shade300,
            Colors.yellow.shade400,
            Colors.pink.shade300,
          ]
        : [
            Colors.blue.shade300,
            Colors.blue.shade400,
            Colors.green.shade300,
            Colors.green.shade400,
            Colors.purple.shade300,
            Colors.teal.shade300,
            Colors.cyan.shade300,
            Colors.amber.shade300,
          ];
    return colors[_random.nextInt(colors.length)];
  }
}

/// Widget that displays confetti animation
class ConfettiWidget extends StatefulWidget {
  final ConfettiController controller;
  final double width;
  final double height;
  
  const ConfettiWidget({
    super.key,
    required this.controller,
    required this.width,
    required this.height,
  });
  
  @override
  State<ConfettiWidget> createState() => _ConfettiWidgetState();
}

class _ConfettiWidgetState extends State<ConfettiWidget> with SingleTickerProviderStateMixin {
  // Cached paths for better performance
  final Map<int, Path> _cachedPaths = {};
  late AnimationController _animController;
  
  // Track the last frame time for delta calculation
  double _lastFrameTime = 0;
  
  @override
  void initState() {
    super.initState();
    // Create a ticker for smooth animation independent of parent rebuilds
    // Use a higher frame rate for smoother animation
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 8), // ~120fps target for smoother animation
    );
    _animController.repeat();
    
    // Initialize the last frame time
    _lastFrameTime = DateTime.now().millisecondsSinceEpoch / 1000.0;
  }
  
  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    // Use both the controller and our ticker for smooth animation
    return AnimatedBuilder(
      animation: Listenable.merge([widget.controller, _animController]),
      builder: (context, child) {
        if (!widget.controller.isActive || widget.controller.confetti.isEmpty) {
          return const SizedBox.shrink();
        }
        
        // Calculate delta time for smoother physics
        final currentTime = DateTime.now().millisecondsSinceEpoch / 1000.0;
        final deltaTime = math.min(0.05, currentTime - _lastFrameTime); // Cap at 50ms to prevent huge jumps
        _lastFrameTime = currentTime;
        
        // Update all confetti with the calculated delta time
        // This ensures smooth animation regardless of frame rate
        for (final confetti in widget.controller.confetti) {
          if (confetti.isActive) {
            confetti.update(deltaTime, Size(widget.width, widget.height));
          }
        }
        
        return RepaintBoundary(
          child: CustomPaint(
            isComplex: true, // Hint to the framework that this is a complex painting operation
            willChange: true, // Hint that this will change frequently
            size: Size(widget.width, widget.height),
            painter: _ConfettiPainter(
              confetti: widget.controller.confetti,
              progress: widget.controller.progress,
              cachedPaths: _cachedPaths,
            ),
          ),
        );
      },
    );
  }
}

/// Custom painter for rendering confetti
class _ConfettiPainter extends CustomPainter {
  final List<Confetti> confetti;
  final double progress;
  final Map<int, Path> cachedPaths;
  
  // Reusable paint objects
  final Paint _fillPaint = Paint()..style = PaintingStyle.fill;
  final Paint _strokePaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.2;
  
  _ConfettiPainter({
    required this.confetti,
    required this.progress,
    required this.cachedPaths,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    // Pre-compute common values
    final opacity = math.max(0.0, 1.0 - progress * 1.2);
    final whiteOpacity = opacity * 0.8;
    
    // Update stroke paint opacity
    _strokePaint.color = Colors.white.withValues( alpha: whiteOpacity);
    
    // Only process active confetti - no need to update physics here as it's now done in the build method
    final activeConfetti = confetti.where((c) => c.isActive).toList();
    
    // Skip drawing if no active confetti
    if (activeConfetti.isEmpty) return;
    
    // Group confetti by shape type to minimize state changes
    final Map<int, List<Confetti>> groupedConfetti = {};
    for (final item in activeConfetti) {
      if (!item.isActive) continue;
      
      if (!groupedConfetti.containsKey(item.shapeType)) {
        groupedConfetti[item.shapeType] = [];
      }
      groupedConfetti[item.shapeType]!.add(item);
    }
    
    // Draw confetti by type (minimizes state changes)
    groupedConfetti.forEach((shapeType, items) {
      // Prepare the path for this shape type if needed
      Path? shapePath;
      if (shapeType >= 2) { // Only for complex shapes (star, heart, diamond)
        // Use the first item's size to get a representative path
        // This is an approximation but works well for batching
        final refSize = items.first.size;
        switch (shapeType) {
          case 2: shapePath = _getStarPath(refSize, cachedPaths); break;
          case 3: shapePath = _getHeartPath(refSize, cachedPaths); break;
          case 4: shapePath = _getDiamondPath(refSize, cachedPaths); break;
        }
      }
      
      // Draw all items of this shape type
      for (final item in items) {
        canvas.save();
        canvas.translate(item.x * size.width, item.y * size.height);
        canvas.rotate(item.rotation);
        
        // Set color for current confetti with slight shimmer effect
        final shimmerFactor = 1.0 + math.sin(item.rotation * 2) * 0.1;
        _fillPaint.color = item.color.withValues( alpha: opacity * shimmerFactor);
        
        switch (shapeType) {
          case 0: // Rectangle
            canvas.drawRect(
              Rect.fromCenter(
                center: Offset.zero,
                width: item.size,
                height: item.size * 0.5,
              ),
              _fillPaint,
            );
            
            // Add shine to some rectangles
            if ((item.hashCode % 3) == 0) { // Deterministic instead of random
              canvas.drawLine(
                Offset(-item.size * 0.3, -item.size * 0.1),
                Offset(item.size * 0.3, item.size * 0.1),
                _strokePaint,
              );
            }
            break;
            
          case 1: // Circle
            canvas.drawCircle(
              Offset.zero,
              item.size * 0.4,
              _fillPaint,
            );
            break;
            
          case 2: // Star
          case 3: // Heart
          case 4: // Diamond
            if (shapePath != null) {
              // Scale the path to match this item's size
              final scale = item.size / items.first.size;
              if (scale != 1.0) {
                canvas.scale(scale, scale);
              }
              canvas.drawPath(shapePath, _fillPaint);
            }
            break;
        }
        
        canvas.restore();
      }
    });
  }
  @override
  bool shouldRepaint(_ConfettiPainter oldDelegate) {
    // Always repaint during active animation for maximum smoothness
    // This ensures we get constant updates for the animation
    return true;
  }
  
  @override
  bool shouldRebuildSemantics(_ConfettiPainter oldDelegate) => false;
  
  /// Get a cached star path or create a new one
  Path _getStarPath(double size, Map<int, Path> cache) {
    final cacheKey = 2000 + size.toInt();
    if (cache.containsKey(cacheKey)) {
      return cache[cacheKey]!;
    }
    
    final path = Path();
    final points = 5;
    final innerRadius = size * 0.2;
    final outerRadius = size * 0.5;
    
    for (var j = 0; j < points * 2; j++) {
      final radius = j.isEven ? outerRadius : innerRadius;
      final angle = j * math.pi / points;
      final x = math.cos(angle) * radius;
      final y = math.sin(angle) * radius;
      
      if (j == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    
    cache[cacheKey] = path;
    return path;
  }
  
  /// Get a cached heart path or create a new one
  Path _getHeartPath(double size, Map<int, Path> cache) {
    final cacheKey = 3000 + size.toInt();
    if (cache.containsKey(cacheKey)) {
      return cache[cacheKey]!;
    }
    
    final path = Path();
    final s = size * 0.5;
    
    path.moveTo(0, s * 0.3);
    path.cubicTo(
      s * 0.5, -s * 0.4,
      s, s * 0.3,
      0, s,
    );
    path.cubicTo(
      -s, s * 0.3,
      -s * 0.5, -s * 0.4,
      0, s * 0.3,
    );
    
    cache[cacheKey] = path;
    return path;
  }
  
  /// Get a cached diamond path or create a new one
  Path _getDiamondPath(double size, Map<int, Path> cache) {
    final cacheKey = 4000 + size.toInt();
    if (cache.containsKey(cacheKey)) {
      return cache[cacheKey]!;
    }
    
    final path = Path();
    path.moveTo(0, -size * 0.5);
    path.lineTo(size * 0.3, 0);
    path.lineTo(0, size * 0.5);
    path.lineTo(-size * 0.3, 0);
    path.close();
    
    cache[cacheKey] = path;
    return path;
  }
  
}