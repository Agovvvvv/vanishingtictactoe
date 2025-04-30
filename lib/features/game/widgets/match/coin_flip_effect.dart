import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:vanishingtictactoe/core/constants/app_colors.dart';

class CoinFlipEffect extends StatefulWidget {
  final String frontSymbol;
  final String backSymbol;
  final bool showFront;
  final bool isFlipping;
  final Animation<double> flipAnimation;
  final bool isComplete;

  const CoinFlipEffect({
    super.key,
    required this.frontSymbol,
    required this.backSymbol,
    required this.showFront,
    required this.isFlipping,
    required this.flipAnimation,
    required this.isComplete,
  });

  @override
  State<CoinFlipEffect> createState() => _CoinFlipEffectState();
}

class _CoinFlipEffectState extends State<CoinFlipEffect> with SingleTickerProviderStateMixin {
  late AnimationController _glowController;
  late Animation<double> _glowAnimation;
  
  @override
  void initState() {
    super.initState();
    
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    
    _glowAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _glowController,
      curve: Curves.easeInOut,
    ));
  }
  
  @override
  void dispose() {
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([widget.flipAnimation, _glowAnimation]),
      builder: (context, child) {
        // Pre-calculate values once to avoid redundant calculations
        final sinValue = math.sin(widget.flipAnimation.value).abs();
        final showFront = widget.isComplete
            ? widget.showFront
            : (widget.flipAnimation.value / math.pi).floor() % 2 == 0;
        
        // Calculate a dynamic scale factor for 3D effect
        final scaleFactor = 1.0 - 0.15 * sinValue;
        
        // Calculate shadow opacity based on rotation
        final shadowOpacity = 0.3 + (0.2 * sinValue);
        
        // Calculate edge thickness based on rotation angle
        final edgeVisible = sinValue > 0.95;
        
        // Determine colors based on which side is showing
        final primaryColor = showFront 
            ? AppColors.player1Dark
            : AppColors.player2Dark;
        final secondaryColor = showFront
            ? AppColors.player1Light
            : AppColors.player2Light;
        
        return Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.003) // Enhanced perspective
            ..rotateY(widget.flipAnimation.value)
            ..scale(scaleFactor, scaleFactor),
          child: Stack(
            children: [
              // Main coin body
              Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    center: Alignment(
                      0.2 + (0.3 * math.sin(widget.flipAnimation.value)),
                      -0.3 - (0.2 * math.cos(widget.flipAnimation.value)),
                    ),
                    radius: 0.8,  // Slightly larger radius for more realistic lighting
                    colors: [
                      Color.lerp(secondaryColor, Colors.white, 0.5) ?? secondaryColor,
                      primaryColor,
                    ],
                    stops: const [0.4, 1.0],  // Adjusted stops for better gradient
                  ),
                  boxShadow: [
                    // Main shadow - more subtle and Material 3 style
                    BoxShadow(
                      color: primaryColor.withOpacity(shadowOpacity * 0.8),
                      blurRadius: 20,
                      spreadRadius: 2,
                      offset: const Offset(0, 8),
                    ),
                    // Inner glow with improved animation
                    BoxShadow(
                      color: secondaryColor.withOpacity(0.25 * _glowAnimation.value),
                      blurRadius: 12,
                      spreadRadius: -1,
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    // Edge highlight
                    if (edgeVisible)
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withOpacity(0.3),
                            width: 2,
                          ),
                        ),
                      ),
                    
                    // Symbol with glow effect
                    Center(
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Glow behind symbol
                          Text(
                            showFront ? widget.frontSymbol : widget.backSymbol,
                            style: TextStyle(
                              fontSize: 80,
                              fontWeight: FontWeight.bold,
                              color: Colors.white.withOpacity(0.3 * _glowAnimation.value),
                              shadows: [
                                Shadow(
                                  color: Colors.white.withOpacity(0.5 * _glowAnimation.value),
                                  blurRadius: 15,
                                ),
                              ],
                            ),
                          ),
                          
                          // Main symbol
                          Text(
                            showFront ? widget.frontSymbol : widget.backSymbol,
                            style: TextStyle(
                              fontSize: 80,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              shadows: [
                                Shadow(
                                  color: Colors.black.withOpacity(0.5),
                                  blurRadius: 5,
                                  offset: const Offset(2, 2),
                                ),
                                Shadow(
                                  color: Colors.white.withOpacity(0.5),
                                  blurRadius: 5,
                                  offset: const Offset(-1, -1),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // No reflective highlight - removed as requested
                  ],
                ),
              ),
              
              // Animated ring when complete
              if (widget.isComplete)
                AnimatedBuilder(
                  animation: _glowAnimation,
                  builder: (context, child) {
                    return Container(
                      width: 160,
                      height: 160,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: primaryColor.withOpacity(0.3 + (0.4 * _glowAnimation.value)),
                          width: 3 + (2 * _glowAnimation.value),
                        ),
                      ),
                    );
                  },
                ),
            ],
          ),
        );
      },
    );
  }
}
