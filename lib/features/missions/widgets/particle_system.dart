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
  double lifetime;
  double age = 0.0;
  
  Particle({
    required this.position,
    required this.velocity,
    required this.color,
    required this.size,
    required this.lifetime,
  });
  
  /// Updates the particle state based on the time delta
  void update(double delta) {
    position += velocity * delta * 60;
    velocity *= 0.95; // Slow down
    size *= 0.97; // Shrink
    age += delta;
  }
  
  /// Returns true if the particle has reached the end of its lifetime
  bool get isDead => age >= lifetime;
  
  /// Returns the current opacity of the particle based on its age
  double get opacity => math.max(0.0, 1.0 - (age / lifetime));
}

/// Controller that manages a collection of particles
class ParticleTrailController extends ChangeNotifier {
  final List<Particle> particles = [];
  final Random _random = Random();
  Timer? _updateTimer;
  
  ParticleTrailController() {
    // Start update timer
    _updateTimer = Timer.periodic(const Duration(milliseconds: 16), (_) {
      _updateParticles();
    });
  }
  
  /// Updates all particles and removes dead ones
  void _updateParticles() {
    if (particles.isEmpty) return;
    
    for (int i = particles.length - 1; i >= 0; i--) {
      particles[i].update(0.016);
      if (particles[i].isDead) {
        particles.removeAt(i);
      }
    }
    
    notifyListeners();
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
    for (int i = 0; i < count; i++) {
      particles.add(Particle(
        position: position,
        color: color,
        size: _random.nextDouble() * (maxSize - minSize) + minSize,
        velocity: Offset(
          (_random.nextDouble() - 0.5) * velocityMultiplier,
          (_random.nextDouble() - 0.5) * velocityMultiplier,
        ),
        lifetime: _random.nextDouble() * (maxLifetime - minLifetime) + minLifetime,
      ));
    }
    
    notifyListeners();
  }
  
  @override
  void dispose() {
    _updateTimer?.cancel();
    super.dispose();
  }
}

/// Custom painter that renders particles
class ParticleTrailPainter extends CustomPainter {
  final List<Particle> particles;
  
  ParticleTrailPainter({required this.particles});
  
  @override
  void paint(Canvas canvas, Size size) {
    for (final particle in particles) {
      final paint = Paint()
        ..color = particle.color.withValues( alpha: particle.opacity)
        ..style = PaintingStyle.fill
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.0);
      
      canvas.drawCircle(particle.position, particle.size, paint);
      
      // Add glow effect
      final glowPaint = Paint()
        ..color = particle.color.withValues( alpha: particle.opacity * 0.5)
        ..style = PaintingStyle.fill
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8.0);
      
      canvas.drawCircle(particle.position, particle.size * 0.7, glowPaint);
    }
  }
  
  @override
  bool shouldRepaint(ParticleTrailPainter oldDelegate) {
    return particles != oldDelegate.particles;
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
