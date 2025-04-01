// import 'dart:math' as math;
// import 'package:flutter/material.dart';

// // Background particle class for animated background
// class BackgroundParticle {
//   Offset position;
//   final double size;
//   final double speed;
//   final double angle;
  
//   BackgroundParticle({
//     required this.position,
//     required this.size,
//     required this.speed,
//     required this.angle,
//   });
  
//   void update(Size screenSize, double animationValue) {
//     // Move particles in a circular pattern
//     final time = animationValue * 2 * math.pi;
//     final dx = math.cos(angle + time) * speed;
//     final dy = math.sin(angle + time) * speed;
    
//     position = Offset(
//       (position.dx + dx) % screenSize.width,
//       (position.dy + dy) % screenSize.height,
//     );
//   }
// }

// // Painter for background particles
// class BackgroundParticlePainter extends CustomPainter {
//   final List<BackgroundParticle> particles;
//   final double animationValue;
//   final math.Random _random = math.Random();
//   final List<BackgroundParticle> _particles = [];


//   BackgroundParticlePainter({
//     required this.particles,
//     required this.animationValue,
//   });
  
//   @override
//   void paint(Canvas canvas, Size size) {
//     // Update and draw particles
//     for (final particle in particles) {
//       particle.update(size, animationValue);
      
//       // Calculate opacity based on position (fade out at edges)
//       final distanceFromCenter = (particle.position - Offset(size.width / 2, size.height / 2)).distance;
//       final maxDistance = size.width < size.height ? size.width / 2 : size.height / 2;
//       final opacity = 0.7 - (distanceFromCenter / maxDistance).clamp(0.0, 0.6);
      
//       final paint = Paint()
//         ..color = Colors.blue.shade200.withValues( alpha: opacity * 0.3)
//         ..style = PaintingStyle.fill
//         ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
      
//       canvas.drawCircle(particle.position, particle.size, paint);
//     }
//   }
  
//   void generateBackgroundParticles(context) {
//     // Create background particles for a more dynamic background
//     for (int i = 0; i < 20; i++) {
//       _particles.add(BackgroundParticle(
//         position: Offset(
//           _random.nextDouble() * MediaQuery.of(context).size.width,
//           _random.nextDouble() * MediaQuery.of(context).size.height,
//         ),
//         size: _random.nextDouble() * 8 + 2,
//         speed: _random.nextDouble() * 0.2 + 0.1,
//         angle: _random.nextDouble() * math.pi * 2,
//       ));
//     }
//   }

//   @override
//   bool shouldRepaint(BackgroundParticlePainter oldDelegate) => true;
// }