import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vanishingtictactoe/features/game/models/game_logic_online.dart';
import 'package:vanishingtictactoe/features/game/models/friendly_game_logic_online.dart';
import 'package:vanishingtictactoe/core/utils/app_logger.dart';
import 'package:vanishingtictactoe/shared/providers/game_provider.dart';
import 'package:vanishingtictactoe/core/constants/app_colors.dart';
import 'dart:math' as math;

class TurnIndicatorWidget extends StatefulWidget {
  final GameProvider gameProvider;

  const TurnIndicatorWidget({
    super.key,
    required this.gameProvider,
  });
  
  @override
  State<TurnIndicatorWidget> createState() => _TurnIndicatorWidgetState();
}

class _TurnIndicatorWidgetState extends State<TurnIndicatorWidget> with TickerProviderStateMixin {
  // Single animation controller to drive multiple animations
  late AnimationController _mainController;
  late Animation<double> _glowAnimation;
  late Animation<double> _rotateAnimation;
  late Animation<Color?> _colorAnimation;
  
  // Track current colors for animation
  Color _baseColor = Colors.blue;
  Color _secondaryColor = Colors.lightBlue;
  
  @override
  void initState() {
    super.initState();
    
    // Use a single controller for all animations to reduce overhead
    _mainController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);
    
    // Setup glow animation with improved curve
    _glowAnimation = Tween<double>(begin: 0.0, end: 0.6).animate(
      CurvedAnimation(
        parent: _mainController,
        // Use a different curve interval for the glow
        curve: const Interval(0.0, 0.7, curve: Curves.easeInOut),
      ),
    );
    
    // Setup rotation animation with different interval
    _rotateAnimation = Tween<double>(begin: 0, end: 2 * math.pi).animate(
      CurvedAnimation(
        parent: _mainController,
        // Full rotation over the controller's duration
        curve: Curves.linear,
      ),
    );
    
    // Initialize color animation (will be updated in didUpdateWidget)
    _initializeColorAnimation();
  }
  
  void _initializeColorAnimation() {
    // Get initial colors based on game state
    _updateColors();
    
    // Setup color animation
    _colorAnimation = ColorTween(begin: _baseColor, end: _secondaryColor).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.2, 0.8, curve: Curves.easeInOut),
      ),
    );
  }
  
  void _updateColors() {
    if (widget.gameProvider.gameLogic is GameLogicOnline || 
        widget.gameProvider.gameLogic is FriendlyGameLogicOnline) {
      _baseColor = AppColors.primaryBlue;
      _secondaryColor = AppColors.player1Light;
    } else {
      // Set colors based on current player's symbol
      if (widget.gameProvider.gameLogic.currentPlayer == 'X') {
        _baseColor = AppColors.player1Dark;
        _secondaryColor = AppColors.player1Light;
      } else {
        _baseColor = AppColors.player2Dark;
        _secondaryColor = AppColors.player2Light;
      }
    }
  }
  
  @override
  void didUpdateWidget(TurnIndicatorWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Check if we need to update colors when game state changes
    final oldCurrentPlayer = oldWidget.gameProvider.gameLogic.currentPlayer;
    final newCurrentPlayer = widget.gameProvider.gameLogic.currentPlayer;
    
    if (oldCurrentPlayer != newCurrentPlayer) {
      _updateColors();
      // Update color animation with new colors
      _colorAnimation = ColorTween(begin: _baseColor, end: _secondaryColor).animate(
        CurvedAnimation(
          parent: _mainController,
          curve: const Interval(0.2, 0.8, curve: Curves.easeInOut),
        ),
      );
    }
  }
  
  @override
  void dispose() {
    _mainController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    String turnText;
    IconData iconData;
    
    if (widget.gameProvider.gameLogic is GameLogicOnline || widget.gameProvider.gameLogic is FriendlyGameLogicOnline) {
      turnText = widget.gameProvider.getOnlinePlayerTurnText();
      iconData = Icons.public_rounded;
    } else {
      final playerName = widget.gameProvider.getCurrentPlayerName();
      turnText = playerName == 'You' ? 'Your turn' : "$playerName's turn";
      
      // Set icon based on current player's symbol
      if (widget.gameProvider.gameLogic.currentPlayer == 'X') {
        iconData = Icons.close_rounded;
      } else {
        iconData = Icons.circle_outlined;
      }
      
      AppLogger.debug('TurnIndicator: Displaying $turnText');
    }
    
    return AnimatedBuilder(
      animation: _mainController,
      builder: (context, child) {
        final currentColor = _colorAnimation.value ?? _baseColor;
        
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withOpacity(0.9),
                Color.lerp(Colors.white, currentColor, 0.15) ?? Colors.white.withOpacity(0.8),
              ],
            ),
            boxShadow: [
              // Main shadow
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 8,
                spreadRadius: 1,
                offset: const Offset(0, 3),
              ),
              // Colored glow
              BoxShadow(
                color: currentColor.withOpacity(_glowAnimation.value * 0.4),
                blurRadius: 15 * _glowAnimation.value,
                spreadRadius: 3 * _glowAnimation.value,
                offset: const Offset(0, 0),
              ),
            ],
            border: Border.all(
              color: currentColor.withOpacity(0.3 + (_glowAnimation.value * 0.2)),
              width: 2,
            ),
          ),
          // Add a subtle scale animation on rebuild for emphasis when turn changes
          key: ValueKey(widget.gameProvider.gameLogic.currentPlayer),
          child: LayoutBuilder(builder: (context, constraints) {
            // Calculate available width for the text
            final maxWidth = constraints.maxWidth - 50; // Account for icon and padding
            
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Animated icon with rotation and glow
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: currentColor.withOpacity(0.1 + (_glowAnimation.value * 0.1)),
                    boxShadow: [
                      BoxShadow(
                        color: currentColor.withOpacity(_glowAnimation.value * 0.3),
                        blurRadius: 8,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Transform.rotate(
                      angle: _rotateAnimation.value,
                      child: Icon(
                        iconData,
                        color: currentColor,
                        size: 20,
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(width: 12),
                // Constrain text width to prevent overflow
                ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: maxWidth),
                  child: Text(
                    turnText,
                    style: GoogleFonts.pressStart2p(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: currentColor,
                      letterSpacing: 0.8,
                      height: 1.2,
                      shadows: [
                        Shadow(
                          color: currentColor.withOpacity(0.5),
                          blurRadius: 4,
                          offset: const Offset(1, 1),
                        ),
                        Shadow(
                          color: Colors.white.withOpacity(0.5),
                          blurRadius: 2,
                          offset: const Offset(-0.5, -0.5),
                        ),
                      ],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            );
          }),
        );
      },
    );
  }
}
