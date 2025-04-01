import 'game_logic_2players.dart';
import 'package:vanishingtictactoe/features/game/models/computer_player.dart';
import 'package:flutter/foundation.dart';
import 'package:vanishingtictactoe/core/utils/app_logger.dart';

class GameLogicVsComputer extends GameLogic {
  final ValueNotifier<List<String>> boardNotifier = ValueNotifier<List<String>>(List.filled(9, ''));
  final ComputerPlayer computerPlayer;
  bool isComputerTurn = false;

  GameLogicVsComputer({
    required super.onGameEnd,
    super.onPlayerChanged,
    required this.computerPlayer,
    required String humanSymbol,
    super.vanishingEffectEnabled,
  }) : super(
    player1Symbol: humanSymbol,
    player2Symbol: humanSymbol == 'X' ? 'O' : 'X',
  ) {
    currentPlayer = player1Symbol;
    boardNotifier.value = List<String>.from(board);
    AppLogger.info('GameLogicVsComputer initialized: humanSymbol=$humanSymbol, currentPlayer=$currentPlayer');
  }

  void checkAndNotifyGameEnd() {
    final winner = checkWinner();
    if (winner.isNotEmpty || xMoveCount + oMoveCount == 30) {
      Future.delayed(const Duration(milliseconds: 100), () => onGameEnd(winner.isEmpty ? 'draw' : winner));
    }
  }

  void processMove(int index, bool isHumanMove) {
    if (isComputerTurn || board[index].isNotEmpty) return;

    board[index] = currentPlayer;
    boardNotifier.value = List<String>.from(board);

    if (isHumanMove) {
      xMoves.add(index);
      xMoveCount++;
    } else {
      oMoves.add(index);
      oMoveCount++;
    }

    int? vanishIndex;
    // Only apply vanishing effect if enabled and enough moves have been made
    if (vanishingEffectEnabled && ((isHumanMove && xMoveCount >= 4) || (!isHumanMove && oMoveCount >= 4))) {
      final moves = isHumanMove ? xMoves : oMoves;
      if (moves.length > 3) {
        vanishIndex = moves.removeAt(0);
        board[vanishIndex] = '';
        boardNotifier.value = List<String>.from(board);
      }
    }
    if (xMoveCount + oMoveCount == 30) {
      Future.delayed(const Duration(milliseconds: 100), () => onGameEnd('draw'));
      return;
    }

    final winner = checkWinner();
    if (winner.isNotEmpty) {
      Future.delayed(const Duration(milliseconds: 100), () => onGameEnd(winner));
      return;
    }

    currentPlayer = isHumanMove ? player2Symbol : player1Symbol;
    isComputerTurn = isHumanMove;
  }


  @override
  void makeMove(int index) {
    if (isComputerTurn || board[index].isNotEmpty) return;

    processMove(index, true);

    final winner = checkWinner();
    if (winner.isNotEmpty || xMoveCount + oMoveCount == 30) return;

    isComputerTurn = true;
    computerPlayer.getMove(List<String>.from(board)).then((move) {
      if (board[move].isEmpty) {
        board[move] = currentPlayer;
        boardNotifier.value = List<String>.from(board);
        onPlayerChanged?.call();

        oMoves.add(move);
        oMoveCount++;

        int? vanishIndex;
        // Only apply vanishing effect if enabled
        if (vanishingEffectEnabled && oMoveCount > 3) {
          vanishIndex = oMoves.removeAt(0);
          board[vanishIndex] = '';
          boardNotifier.value = List<String>.from(board);
        }

        // Check for win after computer's move, ignoring the vanished piece
        final winner = checkWinner(vanishIndex);

        if (winner.isNotEmpty) {
          AppLogger.info('Computer wins with symbol $winner');
          Future.delayed(const Duration(milliseconds: 100), () => onGameEnd(winner));
          return;
        }

        if (xMoveCount + oMoveCount == 30) {
          Future.delayed(const Duration(milliseconds: 100), () => onGameEnd('draw'));
          return;
        }

        //onPlayerChanged?.call();
        currentPlayer = player1Symbol;
        isComputerTurn = false;
        onPlayerChanged?.call();
      }
    }).catchError((e) {
      AppLogger.error('Error in computer move: $e');
      isComputerTurn = false;
    });
  }

  @override
  void resetGame() {
    super.resetGame();
    isComputerTurn = false;
    currentPlayer = player1Symbol;
    boardNotifier.value = List<String>.from(board);
  }
}