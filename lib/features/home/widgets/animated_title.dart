import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:vanishingtictactoe/core/utils/font_preloader.dart';

class AnimatedTitle extends StatefulWidget {
  final double fontSize;
  final Duration fontChangeDuration;
  final Duration letterAnimationDuration;
  final int letterAnimationStaggerMillis;
  
  const AnimatedTitle({
    super.key, 
    this.fontSize = 38, // Slightly larger font size
    this.fontChangeDuration = const Duration(seconds: 6),
    this.letterAnimationDuration = const Duration(milliseconds: 2500), // Slightly faster for better UX
    this.letterAnimationStaggerMillis = 120, // Adjusted for smoother animation
  });

  @override
  State<AnimatedTitle> createState() => _AnimatedTitleState();
}

class _AnimatedTitleState extends State<AnimatedTitle> with TickerProviderStateMixin {
  late AnimationController _fontAnimationController;
  late Animation<double> _fontAnimation;
  int _currentFontIndex = 0;
  
  // For letter-by-letter animation
  late AnimationController _letterAnimationController;
  final String _titleText = 'Vanishing\nTic Tac Toe';
  final List<Animation<double>> _letterAnimations = [];
  
  // Cached font styles
  late final List<TextStyle> _cachedFontStyles = _createFontStyles(widget.fontSize);
  
  // Create font styles using preloaded fonts
  List<TextStyle> _createFontStyles(double fontSize) {
    return [
      // Modern gaming style font
      FontPreloader.getTextStyle(
        fontFamily: 'Press Start 2P',
        fontSize: fontSize * 0.65, // Slightly smaller for readability
        color: Colors.black,
        fontWeight: FontWeight.w500,
        shadows: [
          Shadow(color: Colors.blue.shade200, blurRadius: 2, offset: const Offset(1, 1)),
        ],
      ),
      // Bold, energetic style
      FontPreloader.getTextStyle(
        fontFamily: 'Bangers',
        fontSize: fontSize * 1.1, // Slightly larger for impact
        color: Colors.blue.shade700,
        letterSpacing: 2.0,
        shadows: [
          Shadow(color: Colors.blue.shade300, blurRadius: 3, offset: const Offset(1, 1)),
        ],
      ),
      // Elegant, flowing style
      FontPreloader.getTextStyle(
        fontFamily: 'Pacifico',
        fontSize: fontSize,
        foreground: Paint()
          ..shader = LinearGradient(
            colors: [Colors.purple.shade400, Colors.purple.shade700],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ).createShader(const Rect.fromLTWH(0, 0, 200, 70)),
      ),
      // Blocky, modern style
      FontPreloader.getTextStyle(
        fontFamily: 'Rubik Moonrocks',
        fontSize: fontSize,
        foreground: Paint()
          ..shader = LinearGradient(
            colors: [Colors.teal.shade500, Colors.blue.shade500],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ).createShader(const Rect.fromLTWH(0, 0, 200, 70)),
        fontWeight: FontWeight.w500,
      ),
      // Handwritten style with warm colors
      FontPreloader.getTextStyle(
        fontFamily: 'Permanent Marker',
        fontSize: fontSize,
        foreground: Paint()
          ..shader = LinearGradient(
            colors: [Colors.orange.shade600, Colors.red.shade500],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ).createShader(const Rect.fromLTWH(0, 0, 200, 70)),
      ),
      // Futuristic tech style
      FontPreloader.getTextStyle(
        fontFamily: 'Orbitron',
        fontSize: fontSize * 0.9,
        letterSpacing: 1.5,
        color: Colors.indigo.shade700,
        fontWeight: FontWeight.w700,
        shadows: [
          Shadow(color: Colors.indigo.shade300, blurRadius: 5, offset: const Offset(0, 2)),
        ],
      ),
    ];
  }

  @override
  void initState() {
    super.initState();
    
    _fontAnimationController = AnimationController(
      vsync: this,
      duration: widget.fontChangeDuration,
    );
    
    _fontAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _fontAnimationController,
        curve: Curves.easeInOut,
      ),
    );
    
    _letterAnimationController = AnimationController(
      vsync: this,
      duration: widget.letterAnimationDuration,
    );
    
    _initLetterAnimations();
    
    _fontAnimationController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() {
          _currentFontIndex = (_currentFontIndex + 1) % _cachedFontStyles.length;
          // No need to update cached font style as we're using preloaded fonts
        });
        _fontAnimationController.reset();
        _fontAnimationController.forward();
        
        _startLetterAnimations();
      }
    });
    
    _fontAnimationController.forward();
    _startLetterAnimations();
  }

  void _initLetterAnimations() {
    _letterAnimations.clear();
    
    int letterCount = _titleText.replaceAll('\n', '').length;
    
    for (int i = 0; i < letterCount; i++) {
      final startInterval = i * widget.letterAnimationStaggerMillis / widget.letterAnimationDuration.inMilliseconds;
      final endInterval = startInterval + 0.5; // Each letter animation takes 50% of its staggered time
      
      final animation = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: _letterAnimationController,
          curve: Interval(
            startInterval.clamp(0.0, 1.0),
            endInterval.clamp(0.0, 1.0),
            curve: Curves.easeInOut,
          ),
        ),
      );
      
      _letterAnimations.add(animation);
    }
  }
  
  void _startLetterAnimations() {
    _letterAnimationController.reset();
    _letterAnimationController.forward();
  }

  Widget _buildLetterByLetterText() {
    int letterIndex = 0;
    final currentStyle = _cachedFontStyles[_currentFontIndex];
    
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: _titleText.split('\n').map((line) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: line.split('').map((char) {
            final animation = letterIndex < _letterAnimations.length 
                ? _letterAnimations[letterIndex] 
                : null;
            letterIndex++;
            
            return AnimatedBuilder(
              animation: _letterAnimationController,
              builder: (context, child) {
                // Calculate a slight rotation for a more dynamic effect
                final wobble = math.sin(letterIndex * 0.4 + _letterAnimationController.value * math.pi * 2) * 0.05;
                
                return Opacity(
                  opacity: animation?.value ?? 1.0,
                  child: Transform(
                    transform: Matrix4.identity()
                      ..rotateZ(wobble) // Add slight rotation
                      ..scale(0.9 + (animation?.value ?? 1.0) * 0.1), // Add slight scaling
                    alignment: Alignment.center,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 1.0),
                      child: Text(
                        char,
                        style: currentStyle,
                      ),
                    ),
                  ),
                );
              },
            );
          }).toList(),
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 160, // Slightly taller to accommodate animations
      width: 320, // Slightly wider for better spacing
      alignment: Alignment.center,
      decoration: BoxDecoration(
        // Add a subtle glow effect to the container
        boxShadow: [
          BoxShadow(
            color: Colors.blue.shade100.withValues( alpha: 0.3),
            blurRadius: 15,
            spreadRadius: 1,
          ),
        ],
        borderRadius: BorderRadius.circular(12),
      ),
      child: AnimatedBuilder(
        animation: _fontAnimation,
        builder: (context, child) {
          return Stack(
            children: [
              // Optional: Add subtle particle effects behind the text
              if (_currentFontIndex == 5) // Only for the futuristic font
                Positioned.fill(
                  child: CustomPaint(
                    painter: _ParticleEffectPainter(
                      particleCount: 20,
                      animationValue: _letterAnimationController.value,
                    ),
                  ),
                ),
              _buildLetterByLetterText(),
            ],
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _fontAnimationController.dispose();
    _letterAnimationController.dispose();
    super.dispose();
  }
}

// Custom painter for particle effects
class _ParticleEffectPainter extends CustomPainter {
  final int particleCount;
  final double animationValue;
  final math.Random _random = math.Random();
  
  _ParticleEffectPainter({
    required this.particleCount,
    required this.animationValue,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    for (int i = 0; i < particleCount; i++) {
      final x = _random.nextDouble() * size.width;
      final y = _random.nextDouble() * size.height;
      final radius = 1.0 + _random.nextDouble() * 2.0;
      
      // Create a pulsing effect based on animation value
      final pulseOffset = math.sin(animationValue * math.pi * 2 + i * 0.2) * 0.5 + 0.5;
      
      final paint = Paint()
        ..color = Colors.blue.shade400.withValues( alpha: 0.3 * pulseOffset)
        ..style = PaintingStyle.fill;
      
      canvas.drawCircle(Offset(x, y), radius * pulseOffset, paint);
    }
  }
  
  @override
  bool shouldRepaint(_ParticleEffectPainter oldDelegate) => true;
}