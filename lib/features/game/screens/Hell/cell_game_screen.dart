import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vanishingtictactoe/core/constants/app_colors.dart';
import 'package:vanishingtictactoe/features/game/models/game_logic_vscomputer_hell.dart';
import 'package:vanishingtictactoe/features/game/widgets/hell/cell_game_end_dialog.dart';
import 'package:vanishingtictactoe/shared/models/player.dart';
import 'package:vanishingtictactoe/features/game/models/computer_player.dart';
import 'package:vanishingtictactoe/features/game/widgets/hell/mini_board_display.dart';
import 'package:vanishingtictactoe/core/utils/app_logger.dart';
import 'base_hell_game_state.dart';

class CellGameScreen extends StatefulWidget {
  final Player player1;
  final Player player2;
  final int initialCell;
  final Function(String) onGameComplete;
  final String currentPlayer;
  final List<String> mainBoard;

  const CellGameScreen({
    super.key,
    required this.player1,
    required this.player2,
    required this.initialCell,
    required this.onGameComplete,
    required this.currentPlayer,
    required this.mainBoard,
  });

  @override
  State<CellGameScreen> createState() => _CellGameScreenState();
}

class _CellGameScreenState extends BaseHellGameState<CellGameScreen> {
  bool isShowingDialog = false;

  @override
  void initState() {
    super.initState();
    AppLogger.info('CellGameScreen: Initializing for cell ${widget.initialCell}');
    
    final computerPlayer = widget.player2 is ComputerPlayer ? widget.player2 as ComputerPlayer : null;
    final isComputerFirst = computerPlayer != null && widget.currentPlayer == widget.player2.symbol;
    
    AppLogger.info('CellGameScreen: Computer player detected: ${computerPlayer != null}, isComputerFirst: $isComputerFirst');

    gameLogic = initializeGameLogic(
      player1: widget.player1,
      player2: widget.player2,
      onGameEnd: handleGameEnd,
      onPlayerChanged: updateState,
      player1GoesFirst: widget.currentPlayer == 'X',
    );

    if (computerPlayer != null) {
      gameLogic.currentPlayer = isComputerFirst ? widget.player2.symbol : widget.player1.symbol;
      (gameLogic as GameLogicVsComputerHell).isComputerTurn = isComputerFirst;
      
      AppLogger.info('CellGameScreen: Set computer turn to $isComputerFirst');

      if (isComputerFirst && mounted) {
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
    if (!mounted || (gameLogic is! GameLogicVsComputerHell)) return;
    
    final vsComputer = gameLogic as GameLogicVsComputerHell;
    vsComputer.isComputerTurn = false;
    
    AppLogger.info('CellGameScreen: Computer made move at position $move');
    
    setState(() {
      vsComputer.board[move] = vsComputer.player2Symbol;
      vsComputer.boardNotifier.value = List<String>.from(vsComputer.board);
      vsComputer.oMoves.add(move);
      vsComputer.oMoveCount++;

      int? vanishIndex;
      if (vsComputer.oMoveCount >= 4 && vsComputer.oMoves.length > 3) {
        vanishIndex = vsComputer.oMoves.removeAt(0);
        vsComputer.board[vanishIndex] = '';
        vsComputer.boardNotifier.value = List<String>.from(vsComputer.board);
        AppLogger.info('CellGameScreen: Vanished cell at position $vanishIndex');
      }

      handleGameEnd(null, vanishIndex);

      vsComputer.currentPlayer = vsComputer.player1Symbol;
    });
  }

  @override
  void handleGameEnd([String? forcedWinner, int? vanishedIndex]) {
    final winner = forcedWinner ?? gameLogic.checkWinner(vanishedIndex);
    final isDraw = winner.isEmpty && gameLogic.board.every((cell) => cell.isNotEmpty);

    if (winner.isNotEmpty || isDraw) {
      final String message;
      if (isDraw) {
        message = "IT'S A DRAW!";
      } else {
        final winnerName = winner == widget.player1.symbol ? widget.player1.name : 'Computer';
        message = winnerName == "you" ? "${winnerName.toUpperCase()} WIN!": "${winnerName.toUpperCase()} WINS!";
      }
      
      // Set flag to prevent multiple dialogs
      isShowingDialog = true;
      
      // Prepare the result before showing dialog
      final result = winner.isEmpty ? 'draw' : winner;
      
      showDialog(
        context: context,
        barrierDismissible: false,
        barrierColor: Colors.black.withValues(alpha: 0.7),
        builder: (context) => CellGameEndDialog(
          message: message,
          onBackToMainBoard: () {
            AppLogger.debug("CellGameScreen: Returning to main board with result: $result");
            
            // First notify the parent about the game result
            // This must be done before any navigation
            widget.onGameComplete(result);
          },
        ),
      ).then((_) {
        isShowingDialog = false;
        
        // After dialog is closed, pop back to main board
        if (mounted) {
          AppLogger.info("CellGameScreen: Popping screen to return to main board");
          Navigator.of(context).pop();
        }
      });
    }
  }

  Widget _buildGrid(List<String> board, bool isComputerTurn) {
    return buildGameGrid(
      board,
      isComputerTurn,
      (index) {
        if (gameLogic is GameLogicVsComputerHell && (gameLogic as GameLogicVsComputerHell).isComputerTurn) {
          AppLogger.info('CellGameScreen: Ignoring human tap during computer turn');
          return;
        }

        AppLogger.info('CellGameScreen: Human made move at position $index');
        
        setState(() {
          gameLogic.makeMove(index);
        });

        final winner = gameLogic.checkWinner();
        final isDraw = winner.isEmpty && gameLogic.board.every((cell) => cell.isNotEmpty);
        
        if (winner.isNotEmpty || isDraw) {
          handleGameEnd(winner);
        } else if (gameLogic is GameLogicVsComputerHell && (gameLogic as GameLogicVsComputerHell).isComputerTurn) {
          Future.delayed(const Duration(milliseconds: 200), makeComputerMove);
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isComputerTurn = gameLogic is GameLogicVsComputerHell ? 
        (gameLogic as GameLogicVsComputerHell).isComputerTurn : false;
    final currentPlayerName = getCurrentPlayerName(widget.player1, widget.player2);
    final isCurrentPlayerHuman = currentPlayerName == widget.player1.name;
    
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(40),
        child: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          automaticallyImplyLeading: false,
          title: Row(
            children: [
              const SizedBox(width: 8),
              Text(
                'CELL ${widget.initialCell + 1}',
                style: GoogleFonts.pressStart2p(
                  fontSize: 12,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          centerTitle: false,
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.red.shade800,
              Colors.black,
            ],
            stops: const [0.3, 0.9],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      // Main board section with card styling and animation
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.red.shade800, width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.red.withValues(alpha: 0.3),
                              blurRadius: 15,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.grid_3x3,
                                  color: Colors.red.shade400,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  "MAIN BOARD",
                                  style: GoogleFonts.pressStart2p(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w400,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            // Animated mini board display
                            TweenAnimationBuilder<double>(
                              tween: Tween<double>(begin: 0.95, end: 1.0),
                              duration: const Duration(milliseconds: 1500),
                              curve: Curves.elasticOut,
                              builder: (context, value, child) {
                                return Transform.scale(
                                  scale: value,
                                  child: MiniBoardDisplay(
                                    board: widget.mainBoard,
                                    highlightedCell: widget.initialCell,
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                      
                      // Player turn indicator with animated container
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 20),
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
                                    size: 16,
                                  ),
                                );
                              },
                              onEnd: () => setState(() {}), // Restart animation
                            ),
                            const SizedBox(width: 8),
                            // Player name
                            Text(
                              currentPlayerName == 'You'
                                  ? 'YOUR TURN'
                                  : "${currentPlayerName.toUpperCase()}'S TURN",
                              style: GoogleFonts.pressStart2p(
                                fontSize: 11,
                                fontWeight: FontWeight.w400,
                                color: Colors.white,
                                letterSpacing: 0.8,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      
                      // Game board explanation
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(
                          'WIN THIS CELL GAME',
                          style: GoogleFonts.pressStart2p(
                            fontSize: 9,
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
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          isComputerTurn ? 'COMPUTER IS THINKING...' : 'CELLS WILL VANISH AFTER 3 MOVES',
                          style: GoogleFonts.pressStart2p(
                            fontSize: 9,
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
}