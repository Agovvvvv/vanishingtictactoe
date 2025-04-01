import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'dart:math' as math;
import 'package:vanishingtictactoe/shared/providers/hell_mode_provider.dart';
import 'package:vanishingtictactoe/core/utils/font_preloader.dart';

class HellModeButton extends StatefulWidget {
  final double size;
  final EdgeInsetsGeometry padding;
  
  const HellModeButton({
    super.key,
    this.size = 48.0,
    this.padding = const EdgeInsets.all(8.0),
  });

  @override
  State<HellModeButton> createState() => _HellModeButtonState();
}

class _HellModeButtonState extends State<HellModeButton> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  bool _isPressed = false;
  
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<HellModeProvider>(
      builder: (context, hellModeProvider, _) {
        final isActive = hellModeProvider.isHellModeActive;
        
        // Manage animation state based on active status
        if (isActive && !_animationController.isAnimating) {
          _animationController.repeat();
        } else if (!isActive && _animationController.isAnimating) {
          _animationController.stop();
          _animationController.reset();
        }
        
        return Padding(
          padding: widget.padding,
          child: Tooltip(
            message: isActive ? 'Disable Hell Mode' : 'Enable Hell Mode',
            textStyle: FontPreloader.getTextStyle(
              fontFamily: 'Orbitron',
              fontSize: 12,
              color: Colors.white,
            ),
            decoration: BoxDecoration(
              color: isActive ? Colors.red.shade900 : Colors.grey.shade800,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues( alpha: 0.2),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: GestureDetector(
              onTapDown: (_) => setState(() => _isPressed = true),
              onTapUp: (_) => setState(() => _isPressed = false),
              onTapCancel: () => setState(() => _isPressed = false),
              onTap: () {
                HapticFeedback.mediumImpact();
                hellModeProvider.toggleHellMode();
                
                if (!isActive) {
                  // Starting animation when enabling Hell Mode
                  _animationController.forward(from: 0.0).then((_) {
                    if (hellModeProvider.isHellModeActive) {
                      _animationController.repeat();
                    }
                  });
                }
              },
              child: AnimatedBuilder(
                animation: _animationController,
                builder: (context, child) {
                  return Container(
                    width: widget.size * 1.2,
                    height: widget.size * 1.2,
                    color: Colors.transparent,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Main button with animated shadow
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: widget.size,
                          height: widget.size,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: isActive 
                                ? [Colors.red.shade400, Colors.red.shade900]
                                : [Colors.grey.shade300, Colors.grey.shade600],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: isActive 
                                  ? Colors.red.withValues( alpha: _isPressed ? 0.3 : 0.5)
                                  : Colors.black.withValues( alpha: _isPressed ? 0.1 : 0.2),
                                blurRadius: _isPressed ? 4 : 8,
                                spreadRadius: _isPressed ? 0 : 1,
                                offset: _isPressed ? const Offset(0, 1) : const Offset(0, 2),
                              ),
                            ],
                            border: isActive ? Border.all(
                              color: Colors.red.shade300.withValues( alpha: 0.6),
                              width: 1.5,
                            ) : null,
                          ),
                          transform: Matrix4.identity()..scale(_isPressed ? 0.95 : 1.0),
                          child: Center(
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                // Shadow icon for depth effect
                                if (isActive)
                                  Icon(
                                    Icons.whatshot,
                                    color: Colors.red.shade900.withValues( alpha: 0.7),
                                    size: widget.size * 0.55,
                                  ),
                                
                                // Main icon with animation
                                Icon(
                                  Icons.whatshot,
                                  color: isActive 
                                    ? Colors.white.withValues( alpha: 0.7 + 0.3 * math.sin(_animationController.value * math.pi * 2))
                                    : Colors.white.withValues( alpha: 0.8),
                                  size: widget.size * 0.5 * (isActive 
                                    ? 1.0 + 0.1 * math.sin(_animationController.value * math.pi * 3) 
                                    : 1.0),
                                ),
                              ],
                            ),
                          ),
                        ),
                        
                        // Animated glow ring when active
                        if (isActive)
                          Positioned.fill(
                            child: IgnorePointer(
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: RadialGradient(
                                    colors: [
                                      Colors.red.withValues( alpha: 0.2 + 0.1 * math.sin(_animationController.value * math.pi * 2)),
                                      Colors.transparent,
                                    ],
                                    stops: const [0.6, 1.0],
                                  ),
                                ),
                              ),
                            ),
                          ),
                          
                        // Flame particles when active
                        if (isActive)
                          ...List.generate(3, (index) {
                            final angle = _animationController.value * math.pi * 2 + (index * math.pi);
                            final distance = widget.size * 0.55;
                            final xOffset = math.cos(angle) * distance;
                            final yOffset = math.sin(angle) * distance;
                            
                            return Positioned(
                              top: (widget.size * 1.2) / 2 - 4 + yOffset,
                              left: (widget.size * 1.2) / 2 - 4 + xOffset,
                              child: TweenAnimationBuilder<double>(
                                tween: Tween<double>(begin: 0.0, end: 1.0),
                                duration: const Duration(milliseconds: 300),
                                builder: (context, value, child) {
                                  return Opacity(
                                    opacity: value * 0.7 * math.max(0.2, math.sin((_animationController.value + index * 0.5) * math.pi * 2)),
                                    child: Container(
                                      width: 8,
                                      height: 8,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: index == 0 ? Colors.orange : Colors.yellow,
                                        boxShadow: [
                                          BoxShadow(
                                            color: (index == 0 ? Colors.orange : Colors.yellow).withValues( alpha: 0.5),
                                            blurRadius: 4,
                                            spreadRadius: 1,
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            );
                          }),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}