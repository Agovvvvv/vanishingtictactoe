import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;
import 'dart:async';
import 'particle_system.dart';
import 'confetti_widget.dart';

class MissionCompleteAnimation extends StatefulWidget {
  final String missionTitle;
  final int xpReward;
  final bool isHellMode;
  final VoidCallback onAnimationComplete;

  const MissionCompleteAnimation({
    super.key,
    required this.missionTitle,
    required this.xpReward,
    required this.isHellMode,
    required this.onAnimationComplete,
  });

  @override
  State<MissionCompleteAnimation> createState() => _MissionCompleteAnimationState();
}

class _MissionCompleteAnimationState extends State<MissionCompleteAnimation> with TickerProviderStateMixin {
  late AnimationController _controller;
  late AnimationController _pulseController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;
  late Animation<double> _rotationAnimation;
  late Animation<double> _xpScaleAnimation;
  late Animation<double> _confettiAnimation;
  late Animation<double> _perspectiveAnimation;
  late Animation<double> _shimmerAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _dismissAnimation;
  
  // For particle trails
  final ParticleTrailController _particleController = ParticleTrailController();
  bool _showParticleTrails = false;
  
  // For interactive elements
  bool _isInteractive = false;
  double _interactiveScale = 1.0;
  
  final ConfettiController _confettiController = ConfettiController();
  final _random = math.Random();
  

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800), // Slightly longer for smoother effect
    );
    
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.08,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
    
    _pulseController.repeat(reverse: true);
    
    _confettiController.generateConfetti(
      count: 45, // Reduced count for better performance
      isHellMode: widget.isHellMode,
    );

    // Add perspective animation for 3D effect
    _perspectiveAnimation = Tween<double>(
      begin: 0.0,
      end: 0.02,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.8, curve: Curves.easeInOut),
    ));

    // Add shimmer animation
    _shimmerAnimation = Tween<double>(
      begin: -1.0,
      end: 2.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.3, 0.8, curve: Curves.easeInOut),
    ));

    // Existing animations with improved curves
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: 1.2)
            .chain(CurveTween(curve: Curves.elasticOut)),
        weight: 30,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.2, end: 1.0),
        weight: 20,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 1.0),
        weight: 50,
      ),
    ]).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    ));

    _opacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.2, curve: Curves.easeIn),
    ));
    
    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 0.05,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.6, curve: Curves.easeInOut),
    ));

    _xpScaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: 0.0),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: 1.2),
        weight: 25,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.2, end: 1.0),
        weight: 25,
      ),
    ]).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.4, 1.0, curve: Curves.easeOut),
    ));
    
    _confettiAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.3, 1.0, curve: Curves.linear),
    ));

    
    // Add dismissal animation
    _dismissAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.9, 1.0, curve: Curves.easeInOut),
    ));

    // Add haptic feedback when animation starts
    HapticFeedback.mediumImpact();
    
    // Enable particle trails after a delay
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) {
        setState(() {
          _showParticleTrails = true;
        });
      }
    });
    
    // Enable interactive elements after animation completes
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (mounted) {
        setState(() {
          _isInteractive = true;
        });
      }
    });

    _controller.forward().then((_) {
      Future.delayed(const Duration(milliseconds: 800), () {
        if (mounted) {
          widget.onAnimationComplete();
        }
      });
    });
  }




  
  // Method to generate particle trails
  void _generateParticleTrail(Offset position) {
    if (!_showParticleTrails) return;
    
    final Color trailColor = widget.isHellMode 
        ? Colors.red.shade400
        : Colors.blue.shade400;
    
    _particleController.emitParticles(
      position: position,
      count: 8,
      color: trailColor.withValues( alpha: 0.7),
      minSize: 5,
      maxSize: 15,
      velocityMultiplier: 3.0,
      minLifetime: 0.2,
      maxLifetime: 1.0,
    );
    
    // Schedule a rebuild to show the particle trail
    setState(() {});
  }
  
  // Method to handle tap interaction
  void _handleTap() {
    if (!_isInteractive) return;
    
    HapticFeedback.lightImpact();
    setState(() {
      _interactiveScale = 0.95;
    });
    
    // Generate particles at random positions
    final size = MediaQuery.of(context).size;
    for (int i = 0; i < 5; i++) {
      _generateParticleTrail(Offset(
        size.width * 0.3 + _random.nextDouble() * size.width * 0.4,
        size.height * 0.3 + _random.nextDouble() * size.height * 0.4,
      ));
    }
    
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        setState(() {
          _interactiveScale = 1.0;
        });
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _pulseController.dispose();
    _particleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Color primaryColor = widget.isHellMode ? Colors.red.shade800 : Colors.blue;
    final Color backgroundColor = widget.isHellMode 
        ? Colors.red.shade900.withValues( alpha: 0.9) 
        : Colors.blue.shade900.withValues( alpha: 0.9);
    final IconData missionIcon = widget.isHellMode ? Icons.whatshot : Icons.emoji_events;
    
    // Update particle trails is now handled by the ParticleTrailController

    return GestureDetector(
      onTap: _handleTap,
      child: Stack(
        children: [
        // Particle trails layer
        ParticleTrailWidget(
          controller: _particleController,
          width: MediaQuery.of(context).size.width,
          height: MediaQuery.of(context).size.height,
        ),
          
        // Confetti layer with optimized rendering
        AnimatedBuilder(
          animation: _confettiAnimation,
          builder: (context, child) {
            // Update the confetti controller with the current animation progress
            _confettiController.updateProgress(_confettiAnimation.value);
            return ConfettiWidget(
              controller: _confettiController,
              width: MediaQuery.of(context).size.width,
              height: MediaQuery.of(context).size.height,
            );
          },
        ),
        
        // Main animation content with 3D perspective effect
        AnimatedBuilder(
          animation: Listenable.merge([_controller, _pulseController]),
          builder: (context, child) {
            return Opacity(
              opacity: _opacityAnimation.value * _dismissAnimation.value,
              child: Center(
                child: Transform.scale(
                  scale: _isInteractive ? _interactiveScale : 1.0,
                  child: Transform.scale(
                    scale: _isInteractive ? _pulseAnimation.value : 1.0,
                    child: Transform(
                  transform: Matrix4.identity()
                    ..setEntry(3, 2, 0.001) // Perspective
                    ..rotateX(_perspectiveAnimation.value * math.sin(_controller.value * 3))
                    ..rotateY(_perspectiveAnimation.value * math.cos(_controller.value * 2)),
                  alignment: Alignment.center,
                  child: Container(
                    width: MediaQuery.of(context).size.width * 0.85,
                    padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 24),
                    decoration: BoxDecoration(
                      color: backgroundColor,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues( alpha: 0.4),
                          blurRadius: 20,
                          spreadRadius: 1,
                          offset: const Offset(0, 10),
                        ),
                      ],
                      border: Border.all(
                        color: Colors.white.withValues( alpha: 0.15),
                        width: 1.5,
                      ),
                    ),
                    // Add a subtle gradient overlay with shimmer effect
                    foregroundDecoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.white.withValues( alpha: 0.15 + 0.1 * math.sin(_controller.value * math.pi * 2)),
                          Colors.transparent,
                        ],
                      ),
                    ),
                    child: ShaderMask(
                      shaderCallback: (bounds) {
                        return LinearGradient(
                          begin: Alignment(
                            _shimmerAnimation.value, 
                            _shimmerAnimation.value
                          ),
                          end: Alignment(
                            _shimmerAnimation.value + 0.5, 
                            _shimmerAnimation.value + 0.5
                          ),
                          colors: [
                            Colors.white.withValues( alpha: 0.0),
                            Colors.white.withValues( alpha: 0.2),
                            Colors.white.withValues( alpha: 0.0),
                          ],
                          stops: const [0.35, 0.5, 0.65],
                        ).createShader(bounds);
                      },
                      blendMode: BlendMode.srcATop,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Mission icon with enhanced animation effects
                          Transform.rotate(
                            angle: _rotationAnimation.value * math.pi,
                            child: Transform.scale(
                              scale: _scaleAnimation.value,
                              child: Container(
                                width: 90,
                                height: 90,
                                decoration: BoxDecoration(
                                  gradient: SweepGradient(
                                    colors: [
                                      primaryColor,
                                      primaryColor.withValues( alpha: 0.8),
                                      primaryColor,
                                    ],
                                    startAngle: 0,
                                    endAngle: math.pi * 2,
                                    transform: GradientRotation(_controller.value * math.pi * 2),
                                  ),
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: primaryColor.withValues( alpha: 0.6),
                                      blurRadius: 16,
                                      spreadRadius: 2,
                                    ),
                                  ],
                                  border: Border.all(
                                    color: Colors.white.withValues( alpha: 0.3),
                                    width: 2,
                                  ),
                                ),
                                child: Icon(
                                  missionIcon,
                                  color: Colors.white,
                                  size: 48,
                                ),
                              ),
                            ),
                          ),
                          
                          const SizedBox(height: 24),
                          // Mission complete text with modern styling
                          ShaderMask(
                            shaderCallback: (bounds) => LinearGradient(
                              colors: [
                                Colors.white,
                                Colors.white.withValues( alpha: 0.8),
                              ],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ).createShader(bounds),
                            child: Text(
                              'Mission Complete!',
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                letterSpacing: 0.5,
                                shadows: [
                                  Shadow(
                                    color: Colors.black.withValues( alpha: 0.6),
                                    blurRadius: 8,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          // Mission title with improved styling
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues( alpha: 0.2),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.white.withValues( alpha: 0.1),
                                width: 1,
                              ),
                            ),
                            child: Text(
                              widget.missionTitle,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 18,
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          // XP reward with modern glass-like effect
                          Transform.scale(
                            scale: _xpScaleAnimation.value,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.amber.shade600,
                                    Colors.amber.shade800,
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(24),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.amber.withValues( alpha: 0.6),
                                    blurRadius: 12,
                                    spreadRadius: 0,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                                border: Border.all(
                                  color: Colors.white.withValues( alpha: 0.3),
                                  width: 1.5,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // Animated star icon
                                  TweenAnimationBuilder<double>(
                                    tween: Tween<double>(begin: 0.5, end: 1.0),
                                    duration: const Duration(milliseconds: 500),
                                    builder: (context, value, child) {
                                      return Transform.scale(
                                        scale: 0.8 + (value * 0.4),
                                        child: const Icon(
                                          Icons.star_rounded,
                                          color: Colors.white,
                                          size: 32,
                                        ),
                                      );
                                    },
                                  ),
                                  const SizedBox(width: 12),
                                  // XP text with enhanced styling
                                  Text(
                                    '+${widget.xpReward} XP',
                                    style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                      letterSpacing: 0.5,
                                      shadows: [
                                        Shadow(
                                          color: Colors.black26,
                                          blurRadius: 4,
                                          offset: Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    ),
                  ),
                ),
              ),
            ),
            );
          },
        ),
      ],
    ),
    );
  }
}


