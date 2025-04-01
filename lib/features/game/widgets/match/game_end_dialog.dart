import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'dart:math' as math;
import 'package:vanishingtictactoe/shared/models/player.dart';
import 'package:vanishingtictactoe/features/game/models/computer_player.dart';
import 'package:vanishingtictactoe/shared/models/user_level.dart';
import 'package:vanishingtictactoe/core/utils/app_logger.dart';
import 'package:vanishingtictactoe/shared/providers/user_provider.dart';
import 'package:vanishingtictactoe/shared/providers/game_provider.dart';
import '../../screens/coin_flip_screen.dart';
import 'package:vanishingtictactoe/features/game/screens/game_screen.dart';
import 'package:vanishingtictactoe/features/game/models/game_logic_2players.dart';
import 'package:vanishingtictactoe/features/history/services/match_history_updates.dart';

class GameEndDialog extends StatelessWidget {
  final String message;
  final VoidCallback onPlayAgain;
  final VoidCallback? onBackToMenu;
  final bool isOnlineGame;
  final bool isVsComputer;
  final bool isFriendlyMatch;
  final Player player1;
  final Player player2;
  final int? winnerMoves;
  final bool isSurrendered;
  final bool isCellGame;
  final GameProvider? gameProvider;

  const GameEndDialog({
    super.key,
    required this.message,
    required this.onPlayAgain,
    this.onBackToMenu,
    this.isOnlineGame = false,
    this.isVsComputer = false,
    this.isFriendlyMatch = false,
    required this.player1,
    required this.player2,
    this.winnerMoves,
    this.isSurrendered = false,
    this.isCellGame = false,
    this.gameProvider,
  });

  @override
  Widget build(BuildContext context) {
    // Wrap the entire build method in a try-catch to prevent crashes
    try {
      final ColorScheme colorScheme = Theme.of(context).colorScheme;
      
      return Dialog(
        elevation: 0, // Material 3 uses less pronounced shadows
        insetAnimationDuration: const Duration(milliseconds: 300),
        insetAnimationCurve: Curves.easeOutQuint,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28), // Material 3 uses more rounded corners
        ),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOutQuint,
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: colorScheme.shadow.withValues( alpha: 0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
                spreadRadius: 1,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header with title
              Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(28),
                    topRight: Radius.circular(28),
                  ),
                ),
                child: Center(
                  child: TweenAnimationBuilder<double>(
                    tween: Tween<double>(begin: 0.8, end: 1.0),
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.elasticOut,
                    builder: (context, value, child) {
                      return Transform.scale(
                        scale: value,
                        child: Text(
                          'Game Over',
                          style: GoogleFonts.pressStart2p(
                            fontSize: 20,
                            color: colorScheme.onPrimaryContainer,
                            height: 1.2,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      );
                    },
                  ),
                ),
              ),
              
              // Content section
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Animated message container
                    TweenAnimationBuilder<double>(
                      tween: Tween<double>(begin: 0.0, end: 1.0),
                      duration: const Duration(milliseconds: 500),
                      curve: Curves.easeOutCubic,
                      builder: (context, value, child) {
                        return Opacity(
                          opacity: value,
                          child: Transform.translate(
                            offset: Offset(0, 20 * (1 - value)),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                              decoration: BoxDecoration(
                                color: colorScheme.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                message,
                                style: GoogleFonts.pressStart2p(
                                  fontSize: 16,
                                  color: colorScheme.onSurfaceVariant,
                                  height: 1.3,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 24),
                    if (!isCellGame) _buildXpEarnedWidget(context),
                  ],
                ),
              ),
              
              // Actions section
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 8),
                    if (!isOnlineGame && !isFriendlyMatch) 
                      _buildAnimatedButton(
                        context: context,
                        label: 'Play Again',
                        backgroundColor: colorScheme.primary,
                        textColor: colorScheme.onPrimary,
                        icon: Icons.replay,
                        onPressed: () async {
                          if (!isOnlineGame && !isVsComputer && !isFriendlyMatch) {
                            // For 2-player LOCAL games, close dialog and show coin flip
                            Navigator.of(context).pop(); // Close game end dialog
                            showDialog(
                              context: context,
                              barrierDismissible: false,
                              builder: (context) => CoinFlipScreen(
                                player1: player1,
                                player2: player2,
                                onResult: (firstPlayer) {
                                  try {
                                    // Create new game logic with the coin flip result
                                    final isPlayer1First = firstPlayer == player1;
                                    final gameLogic = GameLogic(
                                      onGameEnd: (_) {},  // Will be handled by GameScreen
                                      onPlayerChanged: () {},  // Will be handled by GameScreen
                                      player1Symbol: player1.symbol,
                                      player2Symbol: player2.symbol,
                                      player1GoesFirst: isPlayer1First,
                                    );
                                    Navigator.of(context).pop(); // Close coin flip dialog
                                    
                                    // Use a try-catch block to handle navigation errors
                                    try {
                                      Navigator.of(context).pushReplacement(
                                        MaterialPageRoute(
                                          builder: (context) => GameScreen(
                                            player1: player1,
                                            player2: player2,
                                            logic: gameLogic,
                                          ),
                                        ),
                                      );
                                    } catch (e) {
                                      AppLogger.error('Error navigating to new game: $e');
                                      // Fallback navigation if pushReplacement fails
                                      Navigator.of(context).pop(); // Pop back to game screen
                                      // Try to pop again to get to the menu if needed
                                      if (onBackToMenu != null) {
                                        onBackToMenu!();
                                      }
                                    }
                                  } catch (e) {
                                    AppLogger.error('Error in coin flip result handler: $e');
                                    Navigator.of(context).pop(); // Close coin flip dialog
                                    if (onBackToMenu != null) {
                                      onBackToMenu!();
                                    }
                                  }
                                },
                              ),
                            );
                          } else if (isVsComputer) {
                            try {
                              Navigator.of(context).pop(); // Close dialog
                              onPlayAgain();
                            } catch (e) {
                              AppLogger.error('Error in Play Again handler: $e');
                              // Try to recover by popping the dialog
                              Navigator.of(context).pop();
                              // Try to go back to menu as fallback
                              if (onBackToMenu != null) {
                                onBackToMenu!();
                              }
                            }
                          } 
                        },
                      ),
                    const SizedBox(height: 16),
                    _buildAnimatedButton(
                      context: context,
                      label: 'Go Back',
                      backgroundColor: colorScheme.surfaceContainerHighest,
                      textColor: colorScheme.onSurfaceVariant,
                      icon: Icons.arrow_back,
                      onPressed: () {
                        AppLogger.info('Go Back: Closing dialog');
                        // For friendly matches, redirect to friendly match screen
                        AppLogger.info('Go Back: Notifying match history update');
                        MatchHistoryUpdates.notifyUpdate();
                        Navigator.of(context).pop();
                        if (isFriendlyMatch) {
                          AppLogger.info('Go Back: Redirecting to friendly match screen');
                          Navigator.pushNamedAndRemoveUntil(
                            context, 
                            '/friendly_match', 
                            (route) => route.isFirst
                          );
                          return;
                        } else if (isVsComputer) {
                          AppLogger.info('Go Back: Redirecting to difficulty selection screen');
                          Navigator.pushNamedAndRemoveUntil(
                            context, 
                            '/difficulty-selection', 
                            (route) => route.isFirst
                          );
                          return;
                        } else if (isOnlineGame) {
                          AppLogger.info('Go Back: Redirecting to online screen');
                          Navigator.pushNamedAndRemoveUntil(
                            context, 
                            '/online', 
                            (route) => route.isFirst
                          );
                          return;
                        } else {
                          Navigator.pushNamedAndRemoveUntil(
                            context, 
                            '/two-players-history', 
                            (route) => route.isFirst
                          );
                        }
                      }
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    } catch (e) {
      AppLogger.error('Error building GameEndDialog: $e');
      // Return a simplified fallback dialog in case of errors
      return AlertDialog(
        title: const Text('Game Over'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              if (onBackToMenu != null) {
                onBackToMenu!();
              } else {
                Navigator.of(context).pop();
              }
            },
            child: const Text('Back to Menu'),
          ),
        ],
      );
    }
  }
  
  // Helper method to build animated buttons
  Widget _buildAnimatedButton({
    required BuildContext context,
    required String label,
    required Color backgroundColor,
    required Color textColor,
    IconData? icon,
    required VoidCallback onPressed,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutQuad,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.scale(
            scale: math.max(0.8, value),
            child: _buildButton(
              context: context,
              label: label,
              backgroundColor: backgroundColor,
              textColor: textColor,
              icon: icon,
              onPressed: onPressed,
            ),
          ),
        );
      },
    );
  }
  
  // Helper method to build consistent buttons
  Widget _buildButton({
    required BuildContext context,
    required String label,
    required Color backgroundColor,
    required Color textColor,
    IconData? icon,
    required VoidCallback onPressed,
  }) {
    return FilledButton(
      style: FilledButton.styleFrom(
        backgroundColor: backgroundColor,
        foregroundColor: textColor,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        elevation: 0, // Material 3 uses less pronounced elevation
      ),
      onPressed: onPressed,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 18),
            const SizedBox(width: 8),
          ],
          Text(
            label,
            style: GoogleFonts.pressStart2p(
              fontSize: 12,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildXpEarnedWidget(BuildContext context) {
    // Use a try-catch block to handle potential provider errors
    UserProvider? userProvider;
    try {
      userProvider = Provider.of<UserProvider>(context, listen: false);
    } catch (e) {
      AppLogger.error('Error accessing UserProvider: $e');
      return const SizedBox.shrink(); // Return empty widget if provider is not available
    }
    
    final user = userProvider.user;
    
    // Don't show XP earned if:
    // - User is not logged in
    // - This is a 2-player game or a friendly match
    // - Player surrendered
    if (user == null || (!isOnlineGame && !isVsComputer) || isFriendlyMatch || isSurrendered) {
      return const SizedBox.shrink();
    }
    
    // Determine if the user won, drew, or lost
    bool isWin = false;
    bool isDraw = false;
    
    if (message.contains('win') || message.contains('Win')) {
      // Check if it's the user who won
      if (message.contains('You win')) {
        isWin = true;
      }
    } else if (message.contains('draw') || message.contains('Draw')) {
      isDraw = true;
    }
    
    // Check if this is a hell mode game
    final isHellMode = isVsComputer && message.contains('Hell');
    
    // Determine difficulty level from the message or player
    GameDifficulty difficulty = GameDifficulty.easy;
    if (isVsComputer) {
      if (message.toLowerCase().contains('medium')) {
        difficulty = GameDifficulty.medium;
      } else if (message.toLowerCase().contains('hard')) {
        difficulty = GameDifficulty.hard;
      }
      
      // If player2 is a ComputerPlayer, get difficulty directly
      if (player2 is ComputerPlayer) {
        difficulty = (player2 as ComputerPlayer).difficulty;
      }
    }
    
    // Calculate XP earned based on game outcome
    final xpEarned = UserLevel.calculateGameXp(
      isWin: isWin,
      isDraw: isDraw,
      movesToWin: isWin ? winnerMoves : null,
      level: user.userLevel.level,
      isHellMode: isHellMode,
      difficulty: difficulty,
    );
    
    final colorScheme = Theme.of(context).colorScheme;
    
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 30 * (1 - value)),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorScheme.tertiaryContainer,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: colorScheme.shadow.withValues( alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.stars, color: colorScheme.onTertiaryContainer, size: 22),
                      const SizedBox(width: 8),
                      Text(
                        'XP Earned',
                        style: GoogleFonts.pressStart2p(
                          fontSize: 12,
                          color: colorScheme.onTertiaryContainer,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TweenAnimationBuilder<double>(
                    tween: Tween<double>(begin: 0.0, end: 1.0),
                    duration: const Duration(milliseconds: 800),
                    curve: Curves.elasticOut,
                    builder: (context, value, child) {
                      return Transform.scale(
                        scale: value,
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                          decoration: BoxDecoration(
                            color: colorScheme.surface,
                            borderRadius: BorderRadius.circular(30),
                            boxShadow: [
                              BoxShadow(
                                color: colorScheme.tertiary.withValues( alpha: 0.2),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Text(
                            '+$xpEarned',
                            style: GoogleFonts.pressStart2p(
                              fontSize: 20,
                              color: colorScheme.tertiary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  // Show current level and progress
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: colorScheme.surface.withValues( alpha: 0.7),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'Level ${user.userLevel.level}',
                          style: GoogleFonts.pressStart2p(
                            fontSize: 10,
                            color: colorScheme.onSurface,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        // Progress indicator with animation
                        TweenAnimationBuilder<double>(
                          tween: Tween<double>(begin: 0.0, end: user.userLevel.progressPercentage / 100),
                          duration: const Duration(milliseconds: 1000),
                          curve: Curves.easeOutCubic,
                          builder: (context, value, child) {
                            return Stack(
                              children: [
                                Container(
                                  height: 10,
                                  decoration: BoxDecoration(
                                    color: colorScheme.surfaceContainerHighest,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                FractionallySizedBox(
                                  widthFactor: value,
                                  child: Container(
                                    height: 10,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [colorScheme.tertiary, colorScheme.tertiaryContainer],
                                        begin: Alignment.centerLeft,
                                        end: Alignment.centerRight,
                                      ),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${user.userLevel.currentXp}/${user.userLevel.xpToNextLevel} XP to Level ${user.userLevel.level + 1}',
                          style: GoogleFonts.pressStart2p(
                            fontSize: 8,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}