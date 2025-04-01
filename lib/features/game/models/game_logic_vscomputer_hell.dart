import 'game_logic_2players.dart';
import 'package:vanishingtictactoe/features/game/models/computer_player.dart';
import 'package:flutter/foundation.dart';
import 'package:vanishingtictactoe/core/utils/app_logger.dart';

/// Specialized game logic for playing against a computer in Hell Mode
class GameLogicVsComputerHell extends GameLogic {
  final ValueNotifier<List<String>> boardNotifier = ValueNotifier<List<String>>(List.filled(9, ''));
  final ComputerPlayer computerPlayer;
  bool isComputerTurn = false;
  
  // Track moves separately from parent class
  final List<int> _humanMoves = [];
  final List<int> _computerMoves = [];
  int _humanMoveCount = 0;
  int _computerMoveCount = 0;

  GameLogicVsComputerHell({
    required super.onGameEnd,
    super.onPlayerChanged,
    required this.computerPlayer,
    required String humanSymbol,
  }) : super(
    player1Symbol: humanSymbol,
    player2Symbol: humanSymbol == 'X' ? 'O' : 'X',
  ) {
    currentPlayer = player1Symbol;
    boardNotifier.value = List<String>.from(board);
    AppLogger.info('GameLogicVsComputerHell initialized: humanSymbol=$humanSymbol, currentPlayer=$currentPlayer');
  }

  void checkAndNotifyGameEnd(int? vanishIndex) {
    final winner = checkWinner(vanishIndex);
    AppLogger.info('checkAndNotifyGameEnd: Checking for winner: $winner');
    
    if (winner.isNotEmpty || _humanMoveCount + _computerMoveCount == 30) {
      AppLogger.info(winner.isNotEmpty ? 'checkAndNotifyGameEnd: Winner detected: $winner' : 'checkAndNotifyGameEnd: Draw detected');
      Future.delayed(Duration(milliseconds: 100), () => onGameEnd(winner.isNotEmpty ? winner : 'draw'));
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
    isComputerTurn = isHumanMove;  }

  @override
  bool makeMove(int index) {
    AppLogger.info('GameLogicVsComputerHell.makeMove called for index $index, isComputerTurn=$isComputerTurn, currentPlayer=$currentPlayer');
    
    if (isComputerTurn || board[index].isNotEmpty) {
      AppLogger.info('GameLogicVsComputerHell.makeMove: Rejected move at $index - isComputerTurn=$isComputerTurn, cell empty=${board[index].isEmpty}');
      return false;
    }

    processMove(index, true);

    if (checkWinner().isNotEmpty || _humanMoveCount + _computerMoveCount == 30) {
      return true;
    }

    isComputerTurn = true;
    onPlayerChanged?.call();
    return true;
  }
  
  @override
  void resetGame() {
    super.resetGame();
    isComputerTurn = false;
    currentPlayer = player1Symbol;
    _humanMoves.clear();
    _computerMoves.clear();
    _humanMoveCount = 0;
    _computerMoveCount = 0;
    boardNotifier.value = List<String>.from(board);
  }
}