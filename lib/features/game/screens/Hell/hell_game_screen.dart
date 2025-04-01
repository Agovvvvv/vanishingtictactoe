import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vanishingtictactoe/core/constants/app_colors.dart';
import 'package:vanishingtictactoe/features/game/models/game_logic_2players.dart';
import 'package:vanishingtictactoe/features/game/models/game_logic_vscomputer_hell.dart';
import 'package:vanishingtictactoe/shared/models/player.dart';
import 'package:vanishingtictactoe/features/game/models/computer_player.dart';
import 'package:vanishingtictactoe/core/utils/app_logger.dart';

import 'cell_game_screen.dart';
import 'base_hell_game_state.dart';

class HellGameScreen extends StatefulWidget {
  final Player player1;
  final Player player2;
  final GameLogic? logic;

  const HellGameScreen({
    super.key,
    required this.player1,
    required this.player2,
    this.logic,
    String? firstPlayerSymbol,
  });

  @override
  State<HellGameScreen> createState() => _HellGameScreenState();
}

class _HellGameScreenState extends BaseHellGameState<HellGameScreen> {

  @override
  void initState() {
    super.initState();
    AppLogger.info('HellGameScreen: Initializing game logic');
    
    gameLogic = initializeGameLogic(
      player1: widget.player1,
      player2: widget.player2,
      onGameEnd: handleGameEnd,
      onPlayerChanged: updateState,
      existingLogic: widget.logic,
    );

    final computerPlayer = widget.player2 is ComputerPlayer ? widget.player2 as ComputerPlayer : null;
    if (computerPlayer != null && gameLogic is GameLogicVsComputerHell) {
      final vsComputer = gameLogic as GameLogicVsComputerHell;
      final isComputerTurn = vsComputer.currentPlayer != widget.player1.symbol;
      
      AppLogger.info('HellGameScreen: Computer player detected, isComputerTurn: $isComputerTurn');

      if (isComputerTurn) {
        vsComputer.isComputerTurn = true;
        Future.delayed(const Duration(milliseconds: 200), makeComputerMove);
      }
    }
  }

  @override
  void updateState() {
    if (mounted) setState(() {});
  }

  @override
  void onComputerMoveComplete(int move) {
    _navigateToVanishingGame(move);
  }

  @override
  void handleGameEnd([String? forcedWinner]) {
    final winner = forcedWinner ?? gameLogic.checkWinner();
    final isDraw = winner.isEmpty && gameLogic.board.every((cell) => cell.isNotEmpty);

    if (winner.isNotEmpty || isDraw) {
      showMainGameEndDialog(
        winner: winner,
        isDraw: isDraw,
        player1: widget.player1,
        player2: widget.player2,
        context: context,
        isOnlineGame: false,
        onPlayAgain: () {
          setState(() {
            gameLogic.resetGame();
          });
        },
        onBackToMenu: () {
          Navigator.of(context).pop({
            'player1': widget.player1.name,
            'player2': widget.player2.name,
            'winner': winner,
            'player1WentFirst': gameLogic.xMoveCount >= gameLogic.oMoveCount,
            'player1Symbol': widget.player1.symbol,
            'player2Symbol': widget.player2.symbol,
          });
        },
      );
    }
  }

  void _navigateToVanishingGame(int index) {
    AppLogger.info('HellGameScreen: Navigating to cell game at index $index');
    
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => CellGameScreen(
          player1: widget.player1,
          player2: widget.player2,
          initialCell: index,
          currentPlayer: gameLogic.currentPlayer,
          mainBoard: gameLogic.board,
          onGameComplete: (winnerSymbol) {
            AppLogger.info('HellGameScreen: Cell game completed with winner: $winnerSymbol');
            
            if (winnerSymbol.isNotEmpty && winnerSymbol != 'draw') {
              setState(() {
                gameLogic.board[index] = winnerSymbol;
                gameLogic.currentPlayer = winnerSymbol == 'X' ? 'O' : 'X';
                if (gameLogic is GameLogicVsComputerHell) {
                  final vsComputer = gameLogic as GameLogicVsComputerHell;
                  vsComputer.boardNotifier.value = List<String>.from(gameLogic.board);
                  vsComputer.isComputerTurn = winnerSymbol == widget.player1.symbol;
                  AppLogger.info('HellGameScreen: Updated computer turn state: ${vsComputer.isComputerTurn}');
                }
              });
              
              // Check if the game has ended
              final winner = gameLogic.checkWinner();
              final isDraw = winner.isEmpty && gameLogic.board.every((cell) => cell.isNotEmpty);
              
              if (winner.isNotEmpty || isDraw) {
                handleGameEnd(winner);
              } else if (gameLogic is GameLogicVsComputerHell && (gameLogic as GameLogicVsComputerHell).isComputerTurn) {
                Future.delayed(const Duration(milliseconds: 200), makeComputerMove);
              }
            } else {
              checkGameEnd();
            }
          },
        ),
      ),
    );
  }

  Widget _buildGrid(List<String> board, bool isComputerTurn) {
    return buildGameGrid(board, isComputerTurn, _navigateToVanishingGame);
  }
  
  @override
  String getCurrentPlayerName(Player? player1, Player? player2) {
    if (gameLogic is GameLogicVsComputerHell) {
      final vsComputer = gameLogic as GameLogicVsComputerHell;
      return vsComputer.isComputerTurn ? 'Computer' : widget.player1.name;
    }
    
    final currentPlayerSymbol = gameLogic.currentPlayer;
    return currentPlayerSymbol == widget.player1.symbol ? widget.player1.name : widget.player2.name;
  }

  @override
  Widget build(BuildContext context) {
    final bool isComputerTurn = gameLogic is GameLogicVsComputerHell ? 
        (gameLogic as GameLogicVsComputerHell).isComputerTurn : false;
    final currentPlayerName = getCurrentPlayerName(widget.player1, widget.player2);
    final isCurrentPlayerHuman = currentPlayerName == widget.player1.name;
    
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          // Help button with tooltip
          IconButton(
            icon: const Icon(Icons.help_outline, color: Colors.white),
            tooltip: 'Hell Mode: Win each cell game to claim the cell in the main board',
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  backgroundColor: Colors.black87,
                  title: Text(
                    'HELL MODE RULES',
                    style: GoogleFonts.pressStart2p(
                      color: Colors.red,
                      fontSize: 16,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildRuleItem('Each cell is its own Vanishing Tic Tac Toe game'),
                      const SizedBox(height: 8),
                      _buildRuleItem('Win a cell game to claim that cell on the main board'),
                      const SizedBox(height: 8),
                      _buildRuleItem('Win the main board to win Hell Mode'),
                      const SizedBox(height: 8),
                      _buildRuleItem('Beware: cells vanish in the mini-games too!'),
                    ],
                  ),
                  actions: [
                    TextButton(
                      child: Text(
                        'CLOSE',
                        style: GoogleFonts.pressStart2p(
                          color: Colors.red,
                          fontSize: 12,
                        ),
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.red.shade900,
              Colors.black,
            ],
            stops: const [0.3, 0.9],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Animated title with fire effect
                      _buildAnimatedTitle(),
                      
                      // Player turn indicator with styled container
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.only(bottom: 30),
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                        decoration: BoxDecoration(
                          color: isCurrentPlayerHuman 
                              ? AppColors.player1Dark.withValues(alpha: 0.8)
                              : AppColors.player2Dark.withValues(alpha: 0.8),
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(
                            color: isCurrentPlayerHuman 
                                ? Colors.orange.shade800 
                                : Colors.red.shade800, 
                            width: 2
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: isCurrentPlayerHuman 
                                  ? Colors.orange.withValues(alpha: 0.3) 
                                  : Colors.red.withValues(alpha: 0.3),
                              blurRadius: 15,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Flame icon that pulses
                            TweenAnimationBuilder<double>(
                              tween: Tween<double>(begin: 0.8, end: 1.2),
                              duration: const Duration(milliseconds: 800),
                              builder: (context, value, child) {
                                return Transform.scale(
                                  scale: value,
                                  child: Icon(
                                    Icons.local_fire_department,
                                    color: isCurrentPlayerHuman 
                                        ? Colors.orange 
                                        : Colors.red,
                                    size: 24,
                                  ),
                                );
                              },
                              onEnd: () => setState(() {}), // Restart animation
                            ),
                            const SizedBox(width: 10),
                            // Player name
                            Text(
                              currentPlayerName == 'You'
                                  ? 'YOUR TURN'
                                  : "${currentPlayerName.toUpperCase()}'S TURN",
                              style: GoogleFonts.pressStart2p(
                                fontSize: 16,
                                fontWeight: FontWeight.w400,
                                color: Colors.white,
                                letterSpacing: 1.2,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      
                      // Game board explanation
                      Padding(
                        padding: const EdgeInsets.only(bottom: 20),
                        child: Text(
                          'TAP A CELL TO PLAY A MINI-GAME',
                          style: GoogleFonts.pressStart2p(
                            fontSize: 10,
                            color: Colors.white70,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      
                      // Game grid with improved styling
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.red.withValues(alpha: 0.4),
                              blurRadius: 20,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: gameLogic is GameLogicVsComputerHell
                            ? ValueListenableBuilder<List<String>>(
                                valueListenable: (gameLogic as GameLogicVsComputerHell).boardNotifier,
                                builder: (context, board, child) => _buildGrid(board, isComputerTurn),
                            )
                            : _buildGrid(gameLogic.board, false),
                      ),
                      
                      // Instructions text
                      Padding(
                        padding: const EdgeInsets.only(top: 20),
                        child: Text(
                          isComputerTurn ? 'COMPUTER IS THINKING...' : 'WIN 3 IN A ROW TO ESCAPE HELL',
                          style: GoogleFonts.pressStart2p(
                            fontSize: 10,
                            color: isComputerTurn ? Colors.red.shade300 : Colors.white70,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildAnimatedTitle() {
    return Container(
      margin: const EdgeInsets.only(bottom: 30),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Animated flames
          TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 2000),
            curve: Curves.easeInOut,
            builder: (context, value, child) {
              return ShaderMask(
                shaderCallback: (bounds) => RadialGradient(
                  colors: [
                    Colors.orange.withValues(alpha: 0.8 * value),
                    Colors.red.withValues(alpha: 0.6 * value),
                    Colors.red.withValues(alpha: 0.0),
                  ],
                  radius: 0.8,
                  center: Alignment.center,
                ).createShader(bounds),
                child: Container(
                  height: 80,
                  width: 280,
                  color: Colors.white,
                ),
              );
            },
            onEnd: () => setState(() {}), // Restart animation
          ),
          
          // Main title with gradient
          ShaderMask(
            shaderCallback: (bounds) => LinearGradient(
              colors: [
                Colors.yellow,
                Colors.orange,
                Colors.red.shade900,
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ).createShader(bounds),
            child: Text(
              "HELL MODE",
              style: GoogleFonts.pressStart2p(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                shadows: [
                  Shadow(
                    color: Colors.red.shade900,
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildRuleItem(String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.local_fire_department, color: Colors.red, size: 16),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(color: Colors.white, fontSize: 14),
          ),
        ),
      ],
    );
  }
}
