import 'dart:async';
import 'dart:math' as math;
import 'dart:math' show Random;
import 'package:flutter/material.dart';

/// Represents a single particle in a particle effect
class Particle {
  Offset position;
  Offset velocity;
  Color color;
  double size;
  final double maxLifetime;
  double age = 0.0;
  
  // Cache opacity calculation
  double _cachedOpacity = 1.0;
  double _lastOpacityUpdateAge = -1.0;
  
  Particle({
    required this.position,
    required this.velocity,
    required this.color,
    required this.size,
    required this.maxLifetime,
  });
  
  /// Updates the particle state based on the time delta
  void update(double delta) {
    // Use a fixed multiplier for more consistent behavior
    final scaledDelta = delta * 60;
    
    // Apply velocity with a single operation
    position += velocity * scaledDelta;
    
    // Apply drag factor (more efficient than multiplying each component)
    velocity *= 0.95; 
    
    // Shrink size (more efficient than multiplying)
    size *= 0.97;
    
    // Update age
    age += delta;
    
    // Reset cached opacity so it's recalculated on next access
    _lastOpacityUpdateAge = -1.0;
  }
  
  /// Returns true if the particle has reached the end of its lifetime
  bool get isDead => age >= maxLifetime || size < 0.5; // Add size check for early cleanup
  
  /// Returns the current opacity of the particle based on its age
  double get opacity {
    // Only recalculate if age has changed since last calculation
    if (_lastOpacityUpdateAge != age) {
      _cachedOpacity = math.max(0.0, 1.0 - (age / maxLifetime));
      _lastOpacityUpdateAge = age;
    }
    return _cachedOpacity;
  }
}

/// Controller that manages a collection of particles
class ParticleTrailController extends ChangeNotifier {
  // Use a fixed capacity list for better memory management
  final List<Particle> particles = [];
  final Random _random = Random();
  Timer? _updateTimer;
  bool _isActive = false;
  
  // Cached random values for better performance
  final List<double> _cachedRandomValues = List.generate(100, (index) => Random().nextDouble());
  int _randomIndex = 0;
  
  // Maximum number of particles to prevent excessive CPU/GPU usage
  static const int maxParticles = 300;
  
  ParticleTrailController() {
    _startUpdateTimer();
  }
  
  /// Starts the update timer if not already running
  void _startUpdateTimer() {
    if (_updateTimer != null) return;
    
    // Use a fixed interval for more consistent updates
    _updateTimer = Timer.periodic(const Duration(milliseconds: 16), (_) {
      _updateParticles();
    });
  }
  
  /// Updates all particles and removes dead ones
  void _updateParticles() {
    if (particles.isEmpty) {
      // Pause updates when no particles to save CPU
      if (_isActive) {
        _isActive = false;
        notifyListeners();
      }
      return;
    }
    
    _isActive = true;
    
    // Use a single delta value for all particles in this frame
    const double delta = 0.016; // Fixed 16ms delta for consistency
    
    // Update in reverse order for more efficient removal
    for (int i = particles.length - 1; i >= 0; i--) {
      particles[i].update(delta);
      if (particles[i].isDead) {
        particles.removeAt(i);
      }
    }
    
    notifyListeners();
  }
  
  /// Gets a cached random value for better performance
  double _getNextRandom() {
    final value = _cachedRandomValues[_randomIndex];
    _randomIndex = (_randomIndex + 1) % _cachedRandomValues.length;
    return value;
  }
  
  /// Creates and emits new particles at the specified position
  void emitParticles({
    required Offset position,
    required int count,
    required Color color,
    double minSize = 5.0,
    double maxSize = 15.0,
    double velocityMultiplier = 3.0,
    double minLifetime = 0.2,
    double maxLifetime = 1.0,
  }) {
    // Limit the number of particles to prevent performance issues
    final actualCount = math.min(count, maxParticles - particles.length);
    if (actualCount <= 0) return;
    
    // Pre-calculate common values
    final sizeDiff = maxSize - minSize;
    final lifetimeDiff = maxLifetime - minLifetime;
    
    for (int i = 0; i < actualCount; i++) {
      particles.add(Particle(
        position: position,
        color: color,
        size: _getNextRandom() * sizeDiff + minSize,
        velocity: Offset(
          (_getNextRandom() - 0.5) * velocityMultiplier,
          (_getNextRandom() - 0.5) * velocityMultiplier,
        ),
        maxLifetime: _getNextRandom() * lifetimeDiff + minLifetime,
      ));
    }
    
    // Only notify if we actually added particles
    if (actualCount > 0) {
      notifyListeners();
    }
  }
  
  /// Clears all particles
  void clear() {
    if (particles.isNotEmpty) {
      particles.clear();
      notifyListeners();
    }
  }
  
  @override
  void dispose() {
    _updateTimer?.cancel();
    _updateTimer = null;
    particles.clear();
    super.dispose();
  }
}

/// Custom painter that renders particles
class ParticleTrailPainter extends CustomPainter {
  final List<Particle> particles;
  
  // Reusable Paint objects to avoid creating new ones
  final Paint _fillPaint = Paint()
    ..style = PaintingStyle.fill;
  
  final Paint _glowPaint = Paint()
    ..style = PaintingStyle.fill
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8.0);
  
  ParticleTrailPainter({required this.particles});
  
  @override
  void paint(Canvas canvas, Size size) {
    if (particles.isEmpty) return;
    
    // Use batch drawing approach - group particles by color to minimize state changes
    final Map<Color, List<Particle>> particlesByColor = {};
    
    // Group particles by base color
    for (final particle in particles) {
      if (!particlesByColor.containsKey(particle.color)) {
        particlesByColor[particle.color] = [];
      }
      particlesByColor[particle.color]!.add(particle);
    }
    
    // Draw particles by color groups to minimize state changes
    particlesByColor.forEach((color, colorParticles) {
      // Draw glow effects first (all particles of this color)
      for (final particle in colorParticles) {
        final opacity = particle.opacity * 0.5;
        if (opacity <= 0.01) continue; // Skip nearly invisible particles
        
        _glowPaint.color = color.withOpacity(opacity);
        canvas.drawCircle(particle.position, particle.size * 0.7, _glowPaint);
      }
      
      // Then draw main particles (all particles of this color)
      for (final particle in colorParticles) {
        final opacity = particle.opacity;
        if (opacity <= 0.01) continue; // Skip nearly invisible particles
        
        _fillPaint.color = color.withOpacity(opacity);
        canvas.drawCircle(particle.position, particle.size, _fillPaint);
      }
    });
  }
  
  @override
  bool shouldRepaint(ParticleTrailPainter oldDelegate) {
    return true; // Always repaint during animation
  }
  
  @override
  bool shouldRebuildSemantics(ParticleTrailPainter oldDelegate) => false;
}

/// Widget that displays a particle trail effect
class ParticleTrailWidget extends StatelessWidget {
  final ParticleTrailController controller;
  final double width;
  final double height;
  
  const ParticleTrailWidget({
    super.key,
    required this.controller,
    required this.width,
    required this.height,
  });
  
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        if (controller.particles.isEmpty) {
          return const SizedBox.shrink();
        }
        
        return RepaintBoundary(
          child: CustomPaint(
            isComplex: true, // Hint for the rendering engine
            willChange: true, // This will change frequently
            size: Size(width, height),
            painter: ParticleTrailPainter(
              particles: controller.particles,
            ),
          ),
        );
      },
    );
  }
}