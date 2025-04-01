import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;
import 'dart:async';
import 'particle_system.dart';
import 'confetti_widget.dart';

/// A widget that displays an animated celebration when a mission is completed.
/// 
/// This widget shows a visually rich animation with confetti, particle effects,
/// and interactive elements to celebrate mission completion.
class MissionCompleteAnimation extends StatefulWidget {
  /// The title of the completed mission
  final String missionTitle;
  
  /// The amount of XP rewarded for completing the mission
  final int xpReward;
  
  /// Whether the mission was completed in hell mode
  final bool isHellMode;
  
  /// Callback that is triggered when the animation sequence completes
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
  // Main animation controllers
  late final AnimationController _controller;
  late final AnimationController _pulseController;
  
  // Cached animations to avoid recalculation
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _opacityAnimation;
  late final Animation<double> _rotationAnimation;
  late final Animation<double> _xpScaleAnimation;
  late final Animation<double> _confettiAnimation;
  late final Animation<double> _perspectiveAnimation;
  late final Animation<double> _shimmerAnimation;
  late final Animation<double> _pulseAnimation;
  late final Animation<double> _dismissAnimation;
  
  // For particle trails - using a single controller for better performance
  final ParticleTrailController _particleController = ParticleTrailController();
  bool _showParticleTrails = false;
  
  // For interactive elements
  bool _isInteractive = false;
  double _interactiveScale = 1.0;
  
  // Confetti controller - created once and reused
  final ConfettiController _confettiController = ConfettiController();
  
  // Single random instance for all randomization needs
  final _random = math.Random();
  
  // Cached values to avoid recalculation in build method
  late final Color _primaryColor;
  late final Color _backgroundColor;
  late final IconData _missionIcon;
  

  @override
  void initState() {
    super.initState();
    
    // Initialize cached values to avoid recalculation in build method
    _primaryColor = widget.isHellMode ? Colors.red.shade800 : Colors.blue;
    _backgroundColor = widget.isHellMode 
        ? Colors.red.shade900.withOpacity(0.9) 
        : Colors.blue.shade900.withOpacity(0.9);
    _missionIcon = widget.isHellMode ? Icons.whatshot : Icons.emoji_events;
    
    // Initialize animation controllers with optimized durations
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500), // Slightly reduced for better performance
    );
    
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    
    // Initialize animations once to avoid rebuilding them
    _initializeAnimations();
    
    // Start pulse animation with repeat
    _pulseController.repeat(reverse: true);
    
    // Generate confetti with optimized count
    _confettiController.generateConfetti(
      count: 35, // Further reduced count for better performance
      isHellMode: widget.isHellMode,
    );

    // Add haptic feedback when animation starts
    // Using light impact instead of medium for better performance
    HapticFeedback.lightImpact();
    
    // Use a single timer with multiple callbacks instead of multiple timers
    // This reduces the overhead of creating multiple timers
    _scheduleStateUpdates();

    // Start the main animation
    _controller.forward().then((_) {
      // Schedule callback after animation completes
      Future.delayed(const Duration(milliseconds: 800), () {
        if (mounted) {
          widget.onAnimationComplete();
        }
      });
    });
  }
  
  /// Initializes all animations to avoid rebuilding them later
  void _initializeAnimations() {
    // Perspective animation for 3D effect (optimized values)
    _perspectiveAnimation = Tween<double>(
      begin: 0.0,
      end: 0.015, // Slightly reduced for better performance
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.8, curve: Curves.easeInOut),
    ));

    // Shimmer animation with optimized range
    _shimmerAnimation = Tween<double>(
      begin: -0.8, // Reduced range
      end: 1.8,    // Reduced range
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.3, 0.8, curve: Curves.easeInOut),
    ));

    // Scale animation with optimized sequence
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: 1.15) // Reduced overshoot
            .chain(CurveTween(curve: Curves.easeOutBack)), // Using easeOutBack instead of elasticOut for better performance
        weight: 30,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.15, end: 1.0),
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

    // Opacity animation
    _opacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.2, curve: Curves.easeIn),
    ));
    
    // Rotation animation with reduced range
    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 0.04, // Reduced for better performance
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.6, curve: Curves.easeInOut),
    ));

    // XP scale animation
    _xpScaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: 0.0),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: 1.15), // Reduced overshoot
        weight: 25,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.15, end: 1.0),
        weight: 25,
      ),
    ]).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.4, 1.0, curve: Curves.easeOut),
    ));
    
    // Confetti animation
    _confettiAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.3, 1.0, curve: Curves.linear),
    ));
    
    // Pulse animation
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.06, // Reduced range for better performance
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
    
    // Dismissal animation
    _dismissAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.9, 1.0, curve: Curves.easeInOut),
    ));
  }
  
  /// Schedules state updates using a more efficient approach
  void _scheduleStateUpdates() {
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
  }




  
  // Method to generate particle trails with optimized parameters
  void _generateParticleTrail(Offset position) {
    if (!_showParticleTrails) return;
    
    // Use cached color value
    final Color trailColor = widget.isHellMode 
        ? Colors.red.shade400
        : Colors.blue.shade400;
    
    _particleController.emitParticles(
      position: position,
      count: 6, // Reduced count for better performance
      color: trailColor.withOpacity(0.7),
      minSize: 4, // Reduced size for better performance
      maxSize: 12, // Reduced size for better performance
      velocityMultiplier: 2.5, // Reduced for better performance
      minLifetime: 0.2,
      maxLifetime: 0.8, // Reduced lifetime for better performance
    );
    
    // No need to call setState here as the ParticleTrailWidget handles its own rendering
  }
  
  // Method to handle tap interaction with optimized particle generation
  void _handleTap() {
    if (!_isInteractive) return;
    
    HapticFeedback.lightImpact(); // Using light impact for better performance
    setState(() {
      _interactiveScale = 0.95;
    });
    
    // Generate fewer particles at random positions
    final size = MediaQuery.of(context).size;
    for (int i = 0; i < 3; i++) { // Reduced count for better performance
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

  /// Properly stops and disposes animation controllers to prevent the
  /// "disposed with an active Ticker" error
  @override
  void dispose() {
    // Stop all animations before disposing
    _controller.stop();
    _pulseController.stop();
    
    // Properly dispose all controllers
    _controller.dispose();
    _pulseController.dispose();
    _particleController.dispose();
    
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Cache MediaQuery values to avoid repeated lookups
    final Size size = MediaQuery.of(context).size;
    final double screenWidth = size.width;
    final double screenHeight = size.height;
    
    return GestureDetector(
      onTap: _handleTap,
      child: Stack(
        children: [
        // Particle trails layer - using cached size values
        ParticleTrailWidget(
          controller: _particleController,
          width: screenWidth,
          height: screenHeight,
        ),
          
        // Confetti layer with optimized rendering
        AnimatedBuilder(
          animation: _confettiAnimation,
          builder: (context, _) { // Using _ for unused child parameter
            // Update the confetti controller with the current animation progress
            _confettiController.updateProgress(_confettiAnimation.value);
            return ConfettiWidget(
              controller: _confettiController,
              width: screenWidth,
              height: screenHeight,
            );
          },
        ),
        
        // Main animation content with 3D perspective effect
        AnimatedBuilder(
          animation: Listenable.merge([_controller, _pulseController]),
          builder: (context, _) { // Using _ for unused child parameter
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
                        width: screenWidth * 0.85,
                        padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 24),
                        decoration: BoxDecoration(
                          color: _backgroundColor, // Using cached color
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.4),
                              blurRadius: 20,
                              spreadRadius: 1,
                              offset: const Offset(0, 10),
                            ),
                          ],
                          border: Border.all(
                            color: Colors.white.withOpacity(0.15),
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
                              Colors.white.withOpacity(0.15 + 0.1 * math.sin(_controller.value * math.pi * 2)),
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
                                Colors.white.withOpacity(0.0),
                                Colors.white.withOpacity(0.2),
                                Colors.white.withOpacity(0.0),
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
                                          _primaryColor, // Using cached color
                                          _primaryColor.withOpacity(0.8), // Using cached color
                                          _primaryColor, // Using cached color
                                        ],
                                        startAngle: 0,
                                        endAngle: math.pi * 2,
                                        transform: GradientRotation(_controller.value * math.pi * 2),
                                      ),
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: _primaryColor.withOpacity(0.6), // Using cached color
                                          blurRadius: 16,
                                          spreadRadius: 2,
                                        ),
                                      ],
                                      border: Border.all(
                                        color: Colors.white.withOpacity(0.3),
                                        width: 2,
                                      ),
                                    ),
                                    child: Icon(
                                      _missionIcon, // Using cached icon
                                      color: Colors.white,
                                      size: 48,
                                    ),
                                  ),
                                ),
                              ),
                          
                          const SizedBox(height: 24),
                          // Mission complete text with optimized styling
                          ShaderMask(
                            shaderCallback: (bounds) => const LinearGradient(
                              colors: [
                                Colors.white,
                                Colors.white70, // Using predefined opacity
                              ],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ).createShader(bounds),
                            child: const Text(
                              'Mission Complete!',
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                letterSpacing: 0.5,
                                shadows: [
                                  Shadow(
                                    color: Color(0x99000000), // Optimized shadow color
                                    blurRadius: 8,
                                    offset: Offset(0, 3),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          // Mission title with optimized styling
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0x33000000), // Optimized background color
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.white10, // Using predefined opacity
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
                          // XP reward with optimized styling
                          Transform.scale(
                            scale: _xpScaleAnimation.value,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                              decoration: BoxDecoration(
                                // Cache gradient colors
                                gradient: LinearGradient(
                                  colors: const [
                                    Color(0xFFFFA000), // Amber 600
                                    Color(0xFFFF8F00), // Amber 800
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(24),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Color(0x99FFA000), // Optimized shadow color
                                    blurRadius: 12,
                                    spreadRadius: 0,
                                    offset: Offset(0, 4),
                                  ),
                                ],
                                border: Border.all(
                                  color: Colors.white30, // Using predefined opacity
                                  width: 1.5,
                                ),
                              ),
                              // Use RepaintBoundary to isolate this widget's painting
                              child: RepaintBoundary(
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    // Optimized star icon animation
                                    // Using a simpler animation approach
                                    AnimatedScale(
                                      scale: _controller.value > 0.6 ? 1.0 : 0.5,
                                      duration: const Duration(milliseconds: 300),
                                      curve: Curves.easeOut,
                                      child: const Icon(
                                        Icons.star_rounded,
                                        color: Colors.white,
                                        size: 32,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    // XP text with optimized styling
                                    Text(
                                      '+${widget.xpReward} XP',
                                      style: const TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.w800,
                                        color: Colors.white,
                                        letterSpacing: 0.5,
                                        shadows: [
                                          Shadow(
                                            color: Color(0x40000000), // Optimized shadow color
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


