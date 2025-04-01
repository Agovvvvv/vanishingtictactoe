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
  late AnimationController _pulseController;
  late Animation<double> _glowAnimation;
  late AnimationController _rotateController;
  late Animation<double> _rotateAnimation;
  late AnimationController _colorController;
  late Animation<Color?> _colorAnimation;
  
  @override
  void initState() {
    super.initState();
    
    // Setup animation for glow effect
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);
    
    _glowAnimation = Tween<double>(begin: 0.0, end: 0.8).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: Curves.easeInOut,
      ),
    );
    
    // Setup rotation animation for the icon
    _rotateController = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    )..repeat();
    
    _rotateAnimation = Tween<double>(begin: 0, end: 2 * math.pi).animate(
      CurvedAnimation(
        parent: _rotateController,
        curve: Curves.linear,
      ),
    );
    
    // Setup color animation
    _colorController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);
  }
  
  @override
  void dispose() {
    _pulseController.dispose();
    _rotateController.dispose();
    _colorController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    String turnText;
    Color baseColor;
    Color secondaryColor;
    IconData iconData;
    
    if (widget.gameProvider.gameLogic is GameLogicOnline || widget.gameProvider.gameLogic is FriendlyGameLogicOnline) {
      turnText = widget.gameProvider.getOnlinePlayerTurnText();
      baseColor = AppColors.primaryBlue;
      secondaryColor = AppColors.player1Light;
      iconData = Icons.public_rounded;
    } else {
      final playerName = widget.gameProvider.getCurrentPlayerName();
      turnText = playerName == 'You' ? 'Your turn' : "$playerName's turn";
      
      // Set colors based on current player's symbol
      if (widget.gameProvider.gameLogic.currentPlayer == 'X') {
        baseColor = AppColors.player1Dark;
        secondaryColor = AppColors.player1Light;
        iconData = Icons.close_rounded;
      } else {
        baseColor = AppColors.player2Dark;
        secondaryColor = AppColors.player2Light;
        iconData = Icons.circle_outlined;
      }
      
      AppLogger.debug('TurnIndicator: Displaying $turnText');
    }
    
    // Setup color animation with the correct colors
    _colorAnimation = ColorTween(begin: baseColor, end: secondaryColor).animate(
      CurvedAnimation(
        parent: _colorController,
        curve: Curves.easeInOut,
      ),
    );
    
    return AnimatedBuilder(
      animation: Listenable.merge([
        _pulseController, 
        _rotateController,
        _colorController
      ]),
      builder: (context, child) {
        final currentColor = _colorAnimation.value ?? baseColor;
        
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withValues(alpha: 0.9),
                Color.lerp(Colors.white, currentColor, 0.1) ?? Colors.white.withValues(alpha: 0.8),
              ],
            ),
            boxShadow: [
              // Main shadow
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 8,
                spreadRadius: 1,
                offset: const Offset(0, 3),
              ),
              // Colored glow
              BoxShadow(
                color: currentColor.withValues(alpha: _glowAnimation.value * 0.4),
                blurRadius: 15 * _glowAnimation.value,
                spreadRadius: 3 * _glowAnimation.value,
                offset: const Offset(0, 0),
              ),
            ],
            border: Border.all(
              color: currentColor.withValues(alpha: 0.3 + (_glowAnimation.value * 0.2)),
              width: 2,
            ),
          ),
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
                    color: currentColor.withValues(alpha: 0.1 + (_glowAnimation.value * 0.1)),
                    boxShadow: [
                      BoxShadow(
                        color: currentColor.withValues(alpha: _glowAnimation.value * 0.3),
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
                          color: currentColor.withValues(alpha: 0.5),
                          blurRadius: 4,
                          offset: const Offset(1, 1),
                        ),
                        Shadow(
                          color: Colors.white.withValues(alpha: 0.5),
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
