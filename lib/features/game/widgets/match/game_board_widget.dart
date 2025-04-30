import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vanishingtictactoe/features/game/models/game_logic_2players.dart';
import 'package:vanishingtictactoe/features/game/models/game_logic_vscomputer.dart';
import 'package:vanishingtictactoe/features/game/models/game_logic_online.dart';
import 'package:vanishingtictactoe/features/game/models/friendly_game_logic_online.dart';
import 'package:vanishingtictactoe/core/utils/app_logger.dart';
import 'package:vanishingtictactoe/features/game/widgets/match/grid_cell.dart';
import 'package:vanishingtictactoe/features/game/widgets/match/winning_line_widget.dart';
import 'package:vanishingtictactoe/shared/providers/game_provider.dart';
import 'package:vanishingtictactoe/core/constants/app_colors.dart';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/services.dart';

class GameBoardWidget extends StatefulWidget {
  final bool isInteractionDisabled;
  final Function(int) onCellTapped;
  final GameLogic gameLogic;
  final VoidCallback? onWinAnimationComplete;

  const GameBoardWidget({
    super.key,
    required this.isInteractionDisabled,
    required this.onCellTapped,
    required this.gameLogic,
    this.onWinAnimationComplete,
  });

  @override
  State<GameBoardWidget> createState() => _GameBoardWidgetState();
}

class _GameBoardWidgetState extends State<GameBoardWidget> with TickerProviderStateMixin {
  bool _isInteractionEnabled = false;
  
  // Animation controllers
  late AnimationController _appearController;
  late AnimationController _pulseController;
  late AnimationController _rotateController;
  
  // Animations
  late Animation<double> _appearAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _rotateAnimation;
  
  // Interaction state
  bool _isPressed = false;
  
  // Map to store references to grid cell keys for animation control
  final Map<int, GlobalKey<GridCellState>> _cellKeys = {};
  
  // Board design properties
  final double _borderRadius = 24.0;
  final double _cellSpacing = 10.0;
  final double _cellBorderRadius = 16.0;

  @override
  void initState() {
    super.initState();
    
    // Setup appearance animation
    _appearController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _appearAnimation = CurvedAnimation(
      parent: _appearController,
      curve: Curves.elasticOut,
    );
    
    // Setup ambient animations
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    );
    
    _pulseAnimation = CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    );
    
    _rotateController = AnimationController(
      duration: const Duration(milliseconds: 20000),
      vsync: this,
    );
    
    _rotateAnimation = CurvedAnimation(
      parent: _rotateController,
      curve: Curves.linear,
    );
    

    
    // Initialize cell keys
    for (int i = 0; i < 9; i++) {
      _cellKeys[i] = GlobalKey<GridCellState>();
    }
    
    // Pre-build the board container for performance
    _buildBoardContainer();
    
    // Start animations
    _appearController.forward();
    _pulseController.repeat(reverse: true);
    _rotateController.repeat();
    
    // Enable interaction after a short delay
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        setState(() => _isInteractionEnabled = true);
        AppLogger.info('GameBoardWidget: Interaction enabled after delay');
      }
    });
    
    // Add haptic feedback for better user experience
    HapticFeedback.lightImpact();
  }
  
  @override
  void dispose() {
    _appearController.dispose();
    _pulseController.dispose();
    _rotateController.dispose();
    super.dispose();
  }
  
  // Initialize the board container (removed caching for simplicity)
  void _buildBoardContainer() {
    // No need to cache the container anymore as we're building it directly in the build method
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      // Just a placeholder to maintain the original method signature
    });
  }
  
  
  // Handle cell press state
  void _onCellPress(bool isPressed) {
    if (_isPressed != isPressed) {
      setState(() {
        _isPressed = isPressed;
        if (isPressed) {
          HapticFeedback.mediumImpact();
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = AppColors.getPrimaryColor(false);
    
    return AnimatedBuilder(
      animation: Listenable.merge([_appearAnimation, _rotateAnimation, _pulseAnimation]),
      builder: (context, child) {
        final rotateValue = _rotateAnimation.value;
        final pulseValue = _pulseAnimation.value;
        
        return Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.001) // Subtle perspective
            ..rotateX(0.01 * math.sin(math.pi * 2 * rotateValue))
            ..rotateY(0.01 * math.cos(math.pi * 2 * rotateValue)),
          child: FadeTransition(
            opacity: _appearAnimation,
            child: ScaleTransition(
              scale: _appearAnimation,
              child: Consumer<GameProvider>(
                builder: (context, gameProvider, child) {
                  final board = gameProvider.board;
                  
                  return Stack(
                    children: [
                      // Ambient glow behind the board
                      AnimatedBuilder(
                        animation: _pulseAnimation,
                        builder: (context, child) {
                          return Container(
                            margin: const EdgeInsets.all(15),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(_borderRadius + 15),
                              boxShadow: [
                                BoxShadow(
                                  color: primaryColor.withOpacity(0.1 + 0.05 * pulseValue),
                                  blurRadius: 30 + 10 * pulseValue,
                                  spreadRadius: 5 + 2 * pulseValue,
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                      
                      // Main board container with glass morphism
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(_borderRadius),
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Colors.white.withOpacity(0.9),
                              Colors.white.withOpacity(0.7 + 0.1 * pulseValue),
                            ],
                            stops: const [0.3, 1.0],
                          ),
                          boxShadow: [
                            // Outer glow
                            BoxShadow(
                              color: primaryColor.withOpacity(0.15 + 0.05 * pulseValue),
                              blurRadius: 15 + 5 * pulseValue,
                              spreadRadius: 1.0 + 0.5 * pulseValue,
                              offset: const Offset(0, 2),
                            ),
                            // Inner shadow
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              spreadRadius: -2,
                              offset: const Offset(0, 2),
                            ),
                            // Inner highlight
                            BoxShadow(
                              color: Colors.white.withOpacity(0.5),
                              blurRadius: 5,
                              spreadRadius: -1,
                              offset: const Offset(0, -1),
                            ),
                          ],
                          border: Border.all(
                            color: Colors.white.withOpacity(0.5 + 0.1 * pulseValue),
                            width: 1.5,
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(_borderRadius - 2),
                          child: BackdropFilter(
                            filter: ui.ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: GridView.count(
                                shrinkWrap: true,
                                crossAxisCount: 3,
                                mainAxisSpacing: _cellSpacing,
                                crossAxisSpacing: _cellSpacing,
                                physics: const NeverScrollableScrollPhysics(),
                                children: List.generate(9, (index) {
                                  final value = board[index];
                                  final isVanishing = widget.gameLogic.vanishingEffectEnabled && 
                                                    widget.gameLogic.getNextToVanish() == index;
                                  
                                  return GestureDetector(
                                      onTapDown: (_) => _onCellPress(true),
                                      onTapUp: (_) => _onCellPress(false),
                                      onTapCancel: () => _onCellPress(false),
                                      child: AbsorbPointer(
                                        absorbing: widget.isInteractionDisabled || !_isInteractionEnabled || gameProvider.winningPattern != null,
                                        child: AnimatedContainer(
                                          duration: const Duration(milliseconds: 150),
                                          curve: Curves.easeOutCubic,
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(_cellBorderRadius),
                                          ),
                                          child: GridCell(
                                            key: _cellKeys[index],
                                            value: value,
                                            index: index,
                                            isVanishing: isVanishing,
                                            onTap: () {
                                              // Call the onCellTapped callback
                                              widget.onCellTapped(index);
                                            },
                                          ),
                                        ),
                                      ),
                                    );
                                }),
                              ),
                            ),
                          ),
                        ),
                      ),
                
                // Display winning line animation if a winning pattern is available from the provider
                if (gameProvider.winningPattern != null)
                  Positioned.fill(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(_borderRadius - 2),
                      child: BackdropFilter(
                        filter: ui.ImageFilter.blur(sigmaX: 1, sigmaY: 1),
                        child: WinningLineWidget(
                          winningPattern: gameProvider.winningPattern!,
                          color: Colors.black, // This will be overridden by the isLocalPlayerWinner parameter
                          onAnimationComplete: () {
                            // Add victory haptic feedback
                            HapticFeedback.heavyImpact();
                            
                            // Trigger animations for winning cells
                            if (gameProvider.winningPattern != null) {
                              for (final index in gameProvider.winningPattern!) {
                                final cellState = _cellKeys[index]?.currentState;
                                if (cellState != null && mounted) {
                                  cellState.triggerGameEndAnimation();
                                }
                              }
                            }
                            
                            if (widget.onWinAnimationComplete != null) {
                              widget.onWinAnimationComplete!();
                            }
                          },
                          // Determine if local player is the winner based on the game state
                          isLocalPlayerWinner: _determineLocalPlayerWinner(gameProvider),
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
          // Fallback widget in case the provider is not found
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(_borderRadius),
              color: Colors.white.withOpacity(0.8),
              boxShadow: [
                BoxShadow(
                  color: primaryColor.withOpacity(0.2),
                  blurRadius: 15,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(_borderRadius - 2),
              child: BackdropFilter(
                filter: ui.ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: GridView.count(
                    shrinkWrap: true,
                    crossAxisCount: 3,
                    mainAxisSpacing: _cellSpacing,
                    crossAxisSpacing: _cellSpacing,
                    physics: const NeverScrollableScrollPhysics(),
                    children: List.generate(9, (index) {
                      final value = widget.gameLogic.board[index];
                      return AbsorbPointer(
                        absorbing: true,
                        child: GridCell(
                          key: GlobalKey<GridCellState>(),
                          value: value,
                          index: index,
                          isVanishing: false,
                          onTap: () {}, // No-op since interaction is disabled
                        ),
                      );
                    }),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    ),
    );
  });
  }
  
  // Helper method to determine if the local player is the winner
  bool _determineLocalPlayerWinner(GameProvider gameProvider) {
    final gameLogic = gameProvider.gameLogic;
    final winner = gameLogic.checkWinner();
    
    // Early return if no winner
    if (winner.isEmpty) return false;
    
    // For online games, check if the local player won
    if (gameLogic is GameLogicOnline) {
      return winner == gameLogic.localPlayerSymbol;
    } 
    // For friendly online games, check if the local player won
    else if (gameLogic is FriendlyGameLogicOnline) {
      return winner == gameLogic.localPlayerSymbol;
    }
    // For computer games, check if player 1 (human) won
    else if (gameLogic is GameLogicVsComputer) {
      return winner == gameLogic.player1Symbol;
    } 
    // For 2-player games, player 1 is considered the "local" player
    else {
      return winner == gameLogic.player1Symbol;
    }
  }

  // Helper method to determine if the local player is the winner
  // Helper method to determine if the local player is the winner
  // Optimized to reduce type checks
  bool _isLocalPlayerWinner(GameProvider gameProvider) {
    final gameLogic = gameProvider.gameLogic;
    final winner = gameLogic.checkWinner();
    
    // Early return if no winner
    if (winner.isEmpty) return false;
    
    // For online games, check if the local player won
    if (gameLogic is GameLogicOnline) {
      return winner == gameLogic.localPlayerSymbol;
    } 
    // For friendly online games, check if the local player won
    else if (gameLogic is FriendlyGameLogicOnline) {
      return winner == gameLogic.localPlayerSymbol;
    }
    // For computer games, check if player 1 (human) won
    else if (gameLogic is GameLogicVsComputer) {
      return winner == gameLogic.player1Symbol;
    } 
    // For 2-player games, player 1 is considered the "local" player
    else {
      return winner == gameLogic.player1Symbol;
    }
  }
}

