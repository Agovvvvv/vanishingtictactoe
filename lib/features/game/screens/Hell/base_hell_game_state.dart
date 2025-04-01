import 'package:flutter/material.dart';
import 'package:vanishingtictactoe/features/game/models/game_logic_2players.dart';
import 'package:vanishingtictactoe/features/game/models/game_logic_vscomputer_hell.dart';
import 'package:vanishingtictactoe/features/history/services/match_history_service.dart';
import 'package:vanishingtictactoe/shared/models/player.dart';
import 'package:vanishingtictactoe/features/game/models/computer_player.dart';
import 'package:vanishingtictactoe/features/game/widgets/match/grid_cell.dart';
import 'package:provider/provider.dart';
import 'package:vanishingtictactoe/shared/providers/user_provider.dart';
import 'package:vanishingtictactoe/shared/providers/mission_provider.dart';
import 'package:vanishingtictactoe/core/utils/app_logger.dart';
import 'package:vanishingtictactoe/features/game/widgets/hell/hell_game_end_dialog.dart';

abstract class BaseHellGameState<T extends StatefulWidget> extends State<T> {
  late GameLogic gameLogic;
  bool isShowingDialog = false;
  
  // Abstract methods that must be implemented by child classes
  void handleGameEnd([String? forcedWinner]);
  void updateState();
  void onComputerMoveComplete(int move);

  // Protected methods for computer move handling
  void makeComputerMove() {
    if (gameLogic is! GameLogicVsComputerHell || !mounted) return;

    final vsComputer = gameLogic as GameLogicVsComputerHell;
    if (!vsComputer.isComputerTurn) return;
    
    AppLogger.info('BaseHellGameState: Computer move started');

    Future.delayed(const Duration(milliseconds: 500), () {
      if (!mounted) return;

      final computerPlayer = vsComputer.computerPlayer;
      final emptyCells = List.generate(9, (index) => index)
          .where((index) => vsComputer.board[index].isEmpty)
          .toList();

      if (emptyCells.isEmpty) {
        AppLogger.info('BaseHellGameState: No empty cells available for computer move');
        return;
      }

      AppLogger.info('BaseHellGameState: Computer calculating move with ${emptyCells.length} empty cells');
      computerPlayer.getMove(List<String>.from(vsComputer.board)).then((move) {
        if (mounted && vsComputer.board[move].isEmpty) {
          AppLogger.info('BaseHellGameState: Computer selected move at position $move');
          onComputerMoveComplete(move);
        } else {
          final randomMove = emptyCells[DateTime.now().millisecondsSinceEpoch % emptyCells.length];
          AppLogger.info('BaseHellGameState: Computer using fallback random move at position $randomMove');
          onComputerMoveComplete(randomMove);
        }
      }).catchError((e) {
        AppLogger.error('BaseHellGameState: Error in computer move: $e');
        final randomMove = emptyCells[DateTime.now().millisecondsSinceEpoch % emptyCells.length];
        AppLogger.info('BaseHellGameState: Computer using error-recovery random move at position $randomMove');
        onComputerMoveComplete(randomMove);
      });
    });
  }

  // Protected method to check game end
  void checkGameEnd() {
    final winner = gameLogic.checkWinner();
    if (winner.isNotEmpty || gameLogic.board.every((cell) => cell.isNotEmpty)) {
      handleGameEnd(winner);
    }
  }

  // Protected method to get winner name
  String getWinnerName(String winner, bool isDraw, Player? player1, Player? player2) {
    if (isDraw) return 'Nobody';
    
    return gameLogic is GameLogicVsComputerHell
        ? winner == (gameLogic as GameLogicVsComputerHell).player1Symbol
            ? player1?.name ?? 'Player 1'
            : 'Computer'
        : winner == 'X'
            ? player1?.name ?? 'Player 1'
            : player2?.name ?? 'Player 2';
  }

  // Protected method to check if human is winner
  bool isHumanWinner(String winner, Player? player1) {
    return gameLogic is GameLogicVsComputerHell
        ? winner == (gameLogic as GameLogicVsComputerHell).player1Symbol
        : winner == player1?.symbol;
  }

  // Common grid building logic with enhanced Hell styling
  Widget buildGameGrid(List<String> board, bool isComputerTurn, void Function(int) onCellTap) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.red.withValues(alpha: 0.3),
            blurRadius: 15,
            spreadRadius: 2,
          ),
        ],
      ),
      child: GridView.count(
        shrinkWrap: true,
        crossAxisCount: 3,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        children: List.generate(9, (index) {
          final isVanishing = gameLogic.getNextToVanish() == index;
          
          return AbsorbPointer(
            absorbing: isComputerTurn,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 300),
              opacity: isComputerTurn && board[index].isEmpty ? 0.7 : 1.0,
              child: GridCell(
                key: ValueKey('cell_${index}_${board[index]}'),
                value: board[index],
                index: index,
                isVanishing: isVanishing,
                onTap: () => onCellTap(index),
              ),
            ),
          );
        }),
      ),
    );
  }

  // Main game end handling with stats tracking and full dialog options
  void showMainGameEndDialog({
    required String winner,
    required bool isDraw,
    required Player player1,
    required Player player2,
    required BuildContext context,
    required bool isOnlineGame,
    required VoidCallback onPlayAgain,
    required VoidCallback onBackToMenu,
  }) {
    if (!mounted || isShowingDialog) return;

    final isHumanWinner = this.isHumanWinner(winner, player1);
    final winnerName = getWinnerName(winner, isDraw, player1, player2);
    final message = isDraw ? 'IT\'S A DRAW!' : '${winnerName.toUpperCase()} WINS!';

    // Update stats and missions for main game only
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final missionProvider = Provider.of<MissionProvider>(context, listen: false);
    final matchHistoryService = MatchHistoryService();
    
    if (userProvider.user != null) {
      GameDifficulty difficulty = GameDifficulty.easy;
      if (player2 is ComputerPlayer) {
        difficulty = player2.difficulty;
      }

      final isHellMode = true;
      // Track game completion

      // Save to Hell Mode specific match history
      matchHistoryService.saveMatchResult(
        userId: userProvider.user!.id, 
        difficulty: difficulty, 
        result: isHumanWinner ? 'win' : isDraw ? 'draw' : 'loss',
        isHellMode: true,
      );
      
      // Also update regular stats
      userProvider.updateGameStats(
        isWin: isDraw ? false : isHumanWinner,
        isDraw: isDraw,
        isOnline: isOnlineGame,
        isFriendlyMatch: gameLogic is! GameLogicVsComputerHell,
        isHellMode: isHellMode,
        difficulty: difficulty,
      );

      missionProvider.trackGamePlayed(
        isHellMode: isHellMode,
        isWin: isHumanWinner,
        difficulty: difficulty,
      );

      AppLogger.info('Hell Mode game stats updated - Winner: ${isDraw ? 'Draw' : (isHumanWinner ? 'Human' : 'Computer')}, Difficulty: $difficulty');
    }

    _showEndDialog(
      context: context,
      message: message,
      isOnlineGame: isOnlineGame,
      player1: player1,
      player2: player2,
      onPlayAgain: onPlayAgain,
      onBackToMenu: onBackToMenu,
      backButtonText: 'Back to Menu',
      showPlayAgain: true,
    );
  }

  // Private helper method for showing the dialog
  void _showEndDialog({
    required BuildContext context,
    required String message,
    required bool isOnlineGame,
    required Player player1,
    required Player player2,
    VoidCallback? onPlayAgain,
    required VoidCallback onBackToMenu,
    required String backButtonText,
    required bool showPlayAgain,
  }) {
    Future.delayed(const Duration(milliseconds: 300), () {
      if (!mounted || isShowingDialog) return;

      isShowingDialog = true;
      showDialog(
        context: context.mounted ? context : context,
        barrierDismissible: false,
        barrierColor: Colors.black.withValues(alpha: 0.8),
        builder: (context) => HellGameEndDialog(
          message: message,
          isOnlineGame: isOnlineGame,
          isVsComputer: gameLogic is GameLogicVsComputerHell,
          player1: player1,
          player2: player2,
          winnerMoves: gameLogic.moveCount,
          onPlayAgain: showPlayAgain && onPlayAgain != null ? () {
            isShowingDialog = false;
            onPlayAgain();
          } : () {},
          onBackToMenu: () {
            isShowingDialog = false;
            onBackToMenu();
          },
        ),
      ).then((_) => isShowingDialog = false);
    });
  }

  String getCurrentPlayerName(Player? player1, Player? player2) {
    if (gameLogic is GameLogicVsComputerHell) {
      final vsComputer = gameLogic as GameLogicVsComputerHell;
      return vsComputer.isComputerTurn ? 'Computer' : 'You';
    }
    return gameLogic.currentPlayer == 'X' 
        ? player1?.name ?? 'Player 1' 
        : player2?.name ?? 'Player 2';
  }

  // Common initialization logic
  GameLogic initializeGameLogic({
    required Player? player1,
    required Player? player2,
    required Function(String?) onGameEnd,
    required Function() onPlayerChanged,
    GameLogic? existingLogic,
    bool? player1GoesFirst,
  }) {
    final computerPlayer = player2 is ComputerPlayer ? player2  : null;

    return existingLogic ?? (computerPlayer != null
        ? GameLogicVsComputerHell(
            onGameEnd: onGameEnd,
            onPlayerChanged: onPlayerChanged,
            computerPlayer: computerPlayer,
            humanSymbol: player1?.symbol ?? 'X',
          )
        : GameLogic(
            onGameEnd: onGameEnd,
            onPlayerChanged: onPlayerChanged,
            player1Symbol: player1?.symbol ?? 'X',
            player2Symbol: player2?.symbol ?? 'O',
            player1GoesFirst: player1GoesFirst ?? player1?.symbol == 'X',
          ));
  }

  

  // Common grid building logic for Hell Mode main grid
  Widget buildHellGrid({
    required List<String> board,
    required bool isComputerTurn,
    required Function(int) onCellTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.red.withValues(alpha: 0.4),
            blurRadius: 20,
            spreadRadius: 5,
          ),
        ],
      ),
      child: GridView.count(
        shrinkWrap: true,
        crossAxisCount: 3,
        mainAxisSpacing: 15,
        crossAxisSpacing: 15,
        children: List.generate(9, (index) {
          final isVanishing = gameLogic.getNextToVanish() == index;
          
          return AbsorbPointer(
            absorbing: isComputerTurn,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 300),
              opacity: isComputerTurn && board[index].isEmpty ? 0.7 : 1.0,
              child: TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0.95, end: 1.0),
                duration: const Duration(milliseconds: 500),
                curve: Curves.elasticOut,
                builder: (context, value, child) {
                  return Transform.scale(
                    scale: value,
                    child: GridCell(
                      key: ValueKey('hell_cell_${index}_${board[index]}'),
                      value: board[index],
                      index: index,
                      isVanishing: isVanishing,
                      onTap: () => onCellTap(index),
                    ),
                  );
                },
              ),
            ),
          );
        }),
      ),
    );
  }

}
