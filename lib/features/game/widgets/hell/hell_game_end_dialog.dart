import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'dart:math' as math;
import 'package:vanishingtictactoe/shared/models/player.dart';
import 'package:vanishingtictactoe/features/game/models/computer_player.dart';
import 'package:vanishingtictactoe/shared/models/user_level.dart';
import 'package:vanishingtictactoe/core/utils/app_logger.dart';
import 'package:vanishingtictactoe/shared/providers/user_provider.dart';
import 'package:vanishingtictactoe/features/history/services/match_history_updates.dart';

class HellGameEndDialog extends StatelessWidget {
  final String message;
  final VoidCallback onPlayAgain;
  final VoidCallback? onBackToMenu;
  final bool isOnlineGame;
  final bool isVsComputer;
  final Player player1;
  final Player player2;
  final int? winnerMoves;
  final bool isSurrendered;

  const HellGameEndDialog({
    super.key,
    required this.message,
    required this.onPlayAgain,
    this.onBackToMenu,
    this.isOnlineGame = false,
    this.isVsComputer = false,
    required this.player1,
    required this.player2,
    this.winnerMoves,
    this.isSurrendered = false,
  });

  @override
  Widget build(BuildContext context) {
    try {
      return Dialog(
        elevation: 8,
        insetAnimationDuration: const Duration(milliseconds: 300),
        insetAnimationCurve: Curves.easeOutQuint,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: Colors.red.shade800, width: 2),
        ),
        backgroundColor: Colors.black,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOutQuint,
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.red.withValues(alpha: 0.3),
                blurRadius: 15,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Animated title with flames
              Container(
                padding: const EdgeInsets.symmetric(vertical: 20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.red.shade900, Colors.black],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(18),
                    topRight: Radius.circular(18),
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
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.local_fire_department, color: Colors.orange.shade700, size: 28),
                            const SizedBox(width: 10),
                            Text(
                              'HELL CONQUERED',
                              style: GoogleFonts.pressStart2p(
                                fontSize: 18,
                                color: Colors.red.shade500,
                                height: 1.2,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(width: 10),
                            Icon(Icons.local_fire_department, color: Colors.orange.shade700, size: 28),
                          ],
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
                                color: Colors.red.shade900.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: Colors.red.shade800, width: 1),
                              ),
                              child: Text(
                                message,
                                style: GoogleFonts.pressStart2p(
                                  fontSize: 16,
                                  color: Colors.white,
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
                    _buildXpEarnedWidget(context),
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
                    if (!isOnlineGame) 
                      _buildAnimatedButton(
                        context: context,
                        label: 'PLAY AGAIN',
                        backgroundColor: Colors.red.shade800,
                        textColor: Colors.white,
                        icon: Icons.replay,
                        onPressed: () {
                          Navigator.of(context).pop(); // Close dialog
                          onPlayAgain();
                        },
                      ),
                    
                    const SizedBox(height: 16),
                    _buildAnimatedButton(
                      context: context,
                      label: 'ESCAPE HELL',
                      backgroundColor: Colors.black,
                      textColor: Colors.white,
                      icon: Icons.arrow_back,
                      borderColor: Colors.red.shade800,
                      onPressed: () {
                        AppLogger.info('Escape Hell: Closing dialog');
                        MatchHistoryUpdates.notifyUpdate();
                        Navigator.of(context).pop();
                        if (onBackToMenu != null) {
                          onBackToMenu!();
                        } else {
                          Navigator.pushNamedAndRemoveUntil(
                            context, 
                            '/game/mode-selection', 
                            (route) => route.isFirst
                          );
                        }
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    } catch (e) {
      AppLogger.error('Error building HellGameEndDialog: $e');
      // Return a simplified fallback dialog in case of errors
      return AlertDialog(
        backgroundColor: Colors.black,
        title: Text('HELL CONQUERED', 
          style: GoogleFonts.pressStart2p(color: Colors.red.shade500),
          textAlign: TextAlign.center,
        ),
        content: Text(message, 
          style: GoogleFonts.pressStart2p(color: Colors.white),
          textAlign: TextAlign.center,
        ),
        actions: [
          TextButton(
            style: TextButton.styleFrom(backgroundColor: Colors.red.shade900),
            onPressed: () {
              Navigator.of(context).pop();
              if (onBackToMenu != null) {
                onBackToMenu!();
              } else {
                Navigator.of(context).pop();
              }
            },
            child: Text('ESCAPE', style: GoogleFonts.pressStart2p(color: Colors.white)),
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
    Color? borderColor,
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
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  color: backgroundColor,
                  borderRadius: BorderRadius.circular(12),
                  border: borderColor != null ? Border.all(color: borderColor, width: 2) : null,
                  boxShadow: [
                    BoxShadow(
                      color: (borderColor ?? backgroundColor).withValues(alpha: 0.5),
                      blurRadius: 10,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: onPressed,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (icon != null) ...[
                            Icon(icon, color: textColor, size: 18),
                            const SizedBox(width: 8),
                          ],
                          Text(
                            label,
                            style: GoogleFonts.pressStart2p(
                              fontSize: 12,
                              color: textColor,
                              letterSpacing: 1,
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
    // - This is a 2-player game
    // - Player surrendered
    if (user == null || !isVsComputer || isSurrendered) {
      return const SizedBox.shrink();
    }
    
    // Determine if the user won, drew, or lost
    bool isWin = false;
    bool isDraw = false;
    
    if (message.contains('WIN') || message.contains('WINS')) {
      // Check if it's the user who won (not the computer)
      if (!message.contains('COMPUTER')) {
        isWin = true;
      }
    } else if (message.contains('DRAW')) {
      isDraw = true;
    }
    
    // This is always a hell mode game
    final isHellMode = true;
    
    // Determine difficulty level
    GameDifficulty difficulty = GameDifficulty.easy;
    if (player2 is ComputerPlayer) {
      difficulty = (player2 as ComputerPlayer).difficulty;
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
                gradient: LinearGradient(
                  colors: [Colors.orange.shade900.withValues(alpha: 0.5), Colors.red.shade900.withValues(alpha: 0.3)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.orange.shade800, width: 1),
                boxShadow: [
                  BoxShadow(
                    color: Colors.orange.shade900.withValues(alpha: 0.3),
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
                      Icon(Icons.local_fire_department, color: Colors.orange.shade500, size: 22),
                      const SizedBox(width: 8),
                      Text(
                        'HELL BONUS XP',
                        style: GoogleFonts.pressStart2p(
                          fontSize: 12,
                          color: Colors.orange.shade300,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(Icons.local_fire_department, color: Colors.orange.shade500, size: 22),
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
                            color: Colors.black,
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(color: Colors.orange.shade700, width: 2),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.orange.shade700.withValues(alpha: 0.5),
                                blurRadius: 8,
                                spreadRadius: 0,
                              ),
                            ],
                          ),
                          child: Text(
                            '+$xpEarned',
                            style: GoogleFonts.pressStart2p(
                              fontSize: 20,
                              color: Colors.orange.shade500,
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
                      color: Colors.black.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.red.shade900, width: 1),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'LEVEL ${user.userLevel.level}',
                          style: GoogleFonts.pressStart2p(
                            fontSize: 10,
                            color: Colors.white,
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
                                    color: Colors.red.shade900.withValues(alpha: 0.3),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                FractionallySizedBox(
                                  widthFactor: value,
                                  child: Container(
                                    height: 10,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [Colors.orange.shade700, Colors.red.shade700],
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
                          '${user.userLevel.currentXp}/${user.userLevel.xpToNextLevel} XP TO LEVEL ${user.userLevel.level + 1}',
                          style: GoogleFonts.pressStart2p(
                            fontSize: 8,
                            color: Colors.orange.shade200,
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
