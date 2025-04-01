import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:vanishingtictactoe/core/constants/app_colors.dart';

class GridCell extends StatefulWidget {
  final String value;
  final int index;
  final bool isVanishing;
  final VoidCallback onTap;

  const GridCell({
    super.key,
    required this.value,
    required this.index,
    required this.isVanishing,
    required this.onTap,
  });

  @override
  State<GridCell> createState() => GridCellState();
}

// Making the state class public so it can be accessed from outside
class GridCellState extends State<GridCell> with TickerProviderStateMixin {
  late AnimationController _vanishController;
  late Animation<double> _opacity;
  late Animation<double> _colorPulse;
  late AnimationController _hoverController;
  late Animation<double> _hoverAnimation;
  late AnimationController _symbolController;
  late Animation<double> _symbolAnimation;
  late AnimationController _glowController;
  late Animation<double> _glowAnimation;
  late AnimationController _gameEndController;
  late Animation<double> _gameEndScaleAnimation;
  late Animation<double> _gameEndRotateAnimation;

  bool _isHovered = false;

  @override
  void initState() {
    super.initState();

    // Vanishing effect animation
    _vanishController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _opacity = Tween<double>(begin: 1.0, end: 0.2).animate(
      CurvedAnimation(parent: _vanishController, curve: Curves.easeInOut),
    );

    _colorPulse = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _vanishController, curve: Curves.easeInOut),
    );

    // Hover animation
    _hoverController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _hoverAnimation = CurvedAnimation(
      parent: _hoverController,
      curve: Curves.easeOut,
    );

    // Symbol appearance animation
    _symbolController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _symbolAnimation = CurvedAnimation(
      parent: _symbolController,
      curve: Curves.elasticOut,
    );

    // Glow animation for placed symbols
    _glowController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _glowAnimation = Tween<double>(begin: 0.2, end: 0.6).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );
    
    // Game end celebration animation
    _gameEndController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _gameEndScaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 1.15)
          .chain(CurveTween(curve: Curves.easeOutQuad)),
        weight: 30,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.15, end: 0.95)
          .chain(CurveTween(curve: Curves.easeInOutQuad)),
        weight: 30,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.95, end: 1.05)
          .chain(CurveTween(curve: Curves.easeInOutQuad)),
        weight: 20,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.05, end: 1.0)
          .chain(CurveTween(curve: Curves.easeInOutQuad)),
        weight: 20,
      ),
    ]).animate(_gameEndController);
    
    _gameEndRotateAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0, end: 0.05)
          .chain(CurveTween(curve: Curves.easeOutQuad)),
        weight: 25,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.05, end: -0.05)
          .chain(CurveTween(curve: Curves.easeInOutQuad)),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: -0.05, end: 0)
          .chain(CurveTween(curve: Curves.easeInQuad)),
        weight: 25,
      ),
    ]).animate(_gameEndController);

    // Start animations
    if (widget.isVanishing) {
      _vanishController.repeat(reverse: true);
    }

    if (widget.value.isNotEmpty) {
      _symbolController.forward();
      _glowController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(GridCell oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Handle value changes
    if (widget.value != oldWidget.value) {
      if (widget.value.isNotEmpty && oldWidget.value.isEmpty) {
        // Symbol was added - animate it in
        _symbolController.reset();
        _symbolController.forward();
        _glowController.repeat(reverse: true);
      }
    }

    // Handle vanishing state changes
    if (widget.isVanishing != oldWidget.isVanishing) {
      if (widget.isVanishing) {
        _vanishController.repeat(reverse: true);
      } else {
        _vanishController.stop();
        _vanishController.value = 0; // Reset to fully opaque
      }
    }
  }
  
  // Method to trigger the game end animation
  void triggerGameEndAnimation() {
    if (!_gameEndController.isAnimating && widget.value.isNotEmpty) {
      _gameEndController.reset();
      _gameEndController.forward();
    }
  }
  
  // Method to check if this cell is part of the winning pattern
  void triggerWinningAnimation() {
    if (widget.value.isNotEmpty) {
      _gameEndController.reset();
      _gameEndController.forward();
    }
  }

  @override
  void dispose() {
    _vanishController.dispose();
    _hoverController.dispose();
    _symbolController.dispose();
    _glowController.dispose();
    _gameEndController.dispose();
    super.dispose();
  }

  Color _getSymbolColor(BuildContext context) {
    if (widget.value == 'X') {
      return Color.lerp(
            AppColors.player1Dark,
            AppColors.player1Light,
            _glowAnimation.value,
          ) ??
          AppColors.player1Dark;
    } else if (widget.value == 'O') {
      return Color.lerp(
            AppColors.player2Dark,
            AppColors.player2Light,
            _glowAnimation.value,
          ) ??
          AppColors.player2Dark;
    }

    return Colors.transparent;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final bool isEmpty = widget.value.isEmpty;

    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: (_) => _hoverController.forward(),
      onTapUp: (_) => _hoverController.reverse(),
      onTapCancel: () => _hoverController.reverse(),
      child: MouseRegion(
        onEnter: (_) {
          if (isEmpty) {
            setState(() => _isHovered = true);
            _hoverController.forward();
          }
        },
        onExit: (_) {
          if (isEmpty) {
            setState(() => _isHovered = false);
            _hoverController.reverse();
          }
        },
        child: AnimatedBuilder(
          animation: Listenable.merge([
            _vanishController,
            _hoverController,
            _symbolController,
            _glowController,
            _gameEndController,
          ]),
          builder: (context, child) {
            final symbolColor = _getSymbolColor(context);

            // Generate gradient colors based on cell state
            List<Color> gradientColors =
                isEmpty
                    ? [Colors.white, Colors.grey.shade50]
                    : widget.value == 'X'
                    ? [
                      Colors.white,
                      Colors.white.withValues(alpha: 0.9),
                    ]
                    : [
                      Colors.white,
                      Colors.white.withValues(alpha: 0.9),
                    ];

            if (widget.isVanishing) {
              gradientColors =
                  widget.value == 'X'
                      ? [
                        Color.lerp(
                              AppColors.primaryBlueLight,
                              Colors.blue.shade100,
                              _colorPulse.value,
                            ) ??
                            AppColors.primaryBlueLight,
                        Colors.white.withValues(alpha: 0.8),
                      ]
                      : [
                        Color.lerp(
                              Colors.red.shade50,
                              Colors.red.shade100,
                              _colorPulse.value,
                            ) ??
                            Colors.red.shade50,
                        Colors.white.withValues(alpha: 0.8),
                      ];
            }
            
            // Apply game end animation scale and rotation
            return Transform.scale(
              scale: !isEmpty ? _gameEndScaleAnimation.value : 1.0,
              child: Transform.rotate(
                angle: !isEmpty ? _gameEndRotateAnimation.value : 0.0,
                child: Opacity(
                  opacity: widget.isVanishing ? _opacity.value : 1.0,
                  child: Container(
                    margin: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: gradientColors,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        // Main shadow
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 8,
                          spreadRadius: 1,
                          offset: const Offset(0, 3),
                        ),
                        // Glow effect for non-empty cells
                        if (!isEmpty)
                          BoxShadow(
                            color: symbolColor.withValues(
                              alpha:
                                  widget.isVanishing
                                      ? 0.3 * _opacity.value * _glowAnimation.value
                                      : 0.3 * _glowAnimation.value,
                            ),
                            blurRadius: 12,
                            spreadRadius: 2,
                            offset: const Offset(0, 0),
                          ),
                        // Hover glow
                        if (isEmpty && _isHovered)
                          BoxShadow(
                            color: (widget.index % 2 == 0
                                    ? AppColors.player1Light
                                    : AppColors.player2Light)
                                .withValues(alpha: 0.3 * _hoverAnimation.value),
                            blurRadius: 12,
                            spreadRadius: 2,
                            offset: const Offset(0, 0),
                          ),
                      ],
                      border: Border.all(
                        color:
                            isEmpty
                                ? _isHovered
                                    ? (widget.index % 2 == 0
                                            ? AppColors.player1Light
                                            : AppColors.player2Light)
                                        .withValues(
                                          alpha: 0.5 * _hoverAnimation.value,
                                        )
                                    : Colors.grey.withValues(alpha: 0.3)
                                : symbolColor.withValues(
                                  alpha:
                                      widget.isVanishing
                                          ? 0.5 * _opacity.value
                                          : 0.5,
                                ),
                        width:
                            isEmpty && _isHovered
                                ? 2.0 + (_hoverAnimation.value * 1.0)
                                : 2.0,
                      ),
                    ),
                    child: Center(
                      child:
                          isEmpty
                              ? _buildEmptyCell(colorScheme)
                              : _buildSymbol(symbolColor),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildEmptyCell(ColorScheme colorScheme) {
    return AnimatedBuilder(
      animation: _hoverController,
      builder: (context, child) {
        if (!_isHovered) return const SizedBox.shrink();

        final hoverColor =
            widget.index % 2 == 0
                ? AppColors.player1Light.withValues(
                  alpha: 0.5 * _hoverAnimation.value,
                )
                : AppColors.player2Light.withValues(
                  alpha: 0.5 * _hoverAnimation.value,
                );

        return Stack(
          alignment: Alignment.center,
          children: [
            // Outer circle
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: hoverColor, width: 2),
              ),
            ),
            // Inner dot
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: hoverColor,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSymbol(Color symbolColor) {
    return AnimatedBuilder(
      animation: Listenable.merge([_symbolAnimation, _glowAnimation, _gameEndController]),
      builder: (context, child) {
        // Enhanced shadow effect during game end animation
        final List<Shadow> shadows = [
          Shadow(
            color: symbolColor.withValues(
              alpha: 0.6 * (_gameEndController.isAnimating ? 1.3 : 1.0),
            ),
            blurRadius: 8 * (_gameEndController.isAnimating ? 1.5 : 1.0),
            offset: const Offset(1, 1),
          ),
          Shadow(
            color: symbolColor.withValues(
              alpha: 0.3 * (_gameEndController.isAnimating ? 1.3 : 1.0),
            ),
            blurRadius: 4 * (_gameEndController.isAnimating ? 1.5 : 1.0),
            offset: const Offset(-1, -1),
          ),
        ];
        
        // Add extra glow shadow during game end animation
        if (_gameEndController.isAnimating) {
          shadows.add(
            Shadow(
              color: symbolColor.withValues(alpha: 0.4 * _gameEndController.value),
              blurRadius: 15,
              offset: const Offset(0, 0),
            ),
          );
        }
        
        return Transform.scale(
          scale: _symbolAnimation.value,
          child: Transform.rotate(
            angle: (1.0 - _symbolAnimation.value) * math.pi * 0.5,
            child: Text(
              widget.value,
              style: TextStyle(
                fontSize: 58,
                fontWeight: FontWeight.w700,
                color: symbolColor,
                shadows: shadows,
              ),
            ),
          ),
        );
      },
    );
  }
}
