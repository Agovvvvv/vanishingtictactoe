import 'package:flutter/foundation.dart';
import 'package:vanishingtictactoe/core/utils/app_logger.dart';
import 'package:vanishingtictactoe/features/game/models/computer_player.dart';
import 'package:vanishingtictactoe/features/game/models/game_logic_2players.dart';

class TutorialGameLogic extends GameLogic {
  final ValueNotifier<List<String>> boardNotifier = ValueNotifier<List<String>>(List.filled(9, ''));
  final ComputerPlayer computerPlayer;
  bool isComputerTurn = false;
  final Function(int) onMoveCountUpdated;

  TutorialGameLogic({
    required super.onGameEnd,
    super.onPlayerChanged,
    required this.computerPlayer,
    required String humanSymbol,
    required this.onMoveCountUpdated,
    super.vanishingEffectEnabled = false,
  }) : super(
    player1Symbol: humanSymbol,
    player2Symbol: humanSymbol == 'X' ? 'O' : 'X',
  ) {
    
    currentPlayer = player1Symbol;
    boardNotifier.value = List<String>.from(board);
    AppLogger.info('TutorialGameLogic initialized: humanSymbol=$humanSymbol, currentPlayer=$currentPlayer');
  }

  @override
  void makeMove(int index) {
    if (isComputerTurn || board[index].isNotEmpty) return;

    // Process human move
    processMove(index, true);
    onMoveCountUpdated(xMoveCount + oMoveCount);

    // Check if game is over
    final winner = checkWinner();
    if (winner.isNotEmpty || xMoveCount + oMoveCount == 30) return;

    // Set up computer's turn
    isComputerTurn = true;
    onPlayerChanged?.call();
    
    // Get computer move - use easy difficulty after user's fourth move
    Future<int> movePromise;
    if (xMoveCount >= 4) {
      // Force easy difficulty after user's fourth move to let them win quickly
      movePromise = _getEasyMove(List<String>.from(board));
    } else {
      movePromise = computerPlayer.getMove(List<String>.from(board));
    }
    
    movePromise.then((move) {
      if (board[move].isEmpty) {
        // Process computer move
        board[move] = currentPlayer;
        boardNotifier.value = List<String>.from(board);
        onPlayerChanged?.call();

        oMoves.add(move);
        oMoveCount++;
        onMoveCountUpdated(xMoveCount + oMoveCount);

        int? vanishIndex;
        // Only apply vanishing effect if enabled
        if (vanishingEffectEnabled && oMoveCount > 3) {
          vanishIndex = oMoves.removeAt(0);
          board[vanishIndex] = '';
          boardNotifier.value = List<String>.from(board);
        }

        // Check for win after computer's move
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

        // Switch back to human player
        currentPlayer = player1Symbol;
        isComputerTurn = false;
        onPlayerChanged?.call();
      }
    }).catchError((e) {
      AppLogger.error('Error in computer move: $e');
      isComputerTurn = false;
    });
  }

  void processMove(int index, bool isHumanMove) {
    if (board[index].isNotEmpty) return;

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
  void resetGame() {
    super.resetGame();
    isComputerTurn = false;
    currentPlayer = player1Symbol;
    boardNotifier.value = List<String>.from(board);
  }

  // Add this method to enable the vanishing effect without resetting the game
  void enableVanishingEffect() {
    vanishingEffectEnabled = true;
  }

  /// Gets a random move for the computer player
  /// This is used to make the computer play at easy difficulty after the user's fourth move
  /// to let them win more easily during the tutorial
  Future<int> _getEasyMove(List<String> board) async {
    // Simply get all available moves and choose one randomly
    final List<int> availableMoves = [];
    for (int i = 0; i < board.length; i++) {
      if (board[i].isEmpty) {
        availableMoves.add(i);
      }
    }
    
    if (availableMoves.isEmpty) {
      throw StateError('No valid moves available');
    }
    
    // Add a 200ms delay to make the computer's move feel more natural
    await Future.delayed(const Duration(milliseconds: 500));
    
    availableMoves.shuffle();
    return availableMoves.first;
  }
}