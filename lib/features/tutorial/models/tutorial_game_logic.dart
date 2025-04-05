import 'package:flutter/foundation.dart';
import 'package:vanishingtictactoe/core/utils/app_logger.dart';
import 'package:vanishingtictactoe/core/utils/win_checker.dart';
import 'package:vanishingtictactoe/features/game/models/computer_player.dart';
import 'package:vanishingtictactoe/features/game/models/game_logic_2players.dart';

class TutorialGameLogic extends GameLogic {
  final ValueNotifier<List<String>> boardNotifier = ValueNotifier<List<String>>(List.filled(9, ''));
  final ComputerPlayer computerPlayer;
  bool isComputerTurn = false;
  final Function(int) onMoveCountUpdated;
  
  // Tutorial-specific flags

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
    if (winner.isNotEmpty) {
      Future.delayed(const Duration(milliseconds: 100), () => onGameEnd(winner));
      return;
    }
    
    if (xMoveCount + oMoveCount == 30) {
      Future.delayed(const Duration(milliseconds: 100), () => onGameEnd('draw'));
      return;
    }

    // Set up computer's turn
    isComputerTurn = true;
    onPlayerChanged?.call();
    
    // Add a 500ms delay after human move before computer makes its move
    Future.delayed(const Duration(milliseconds: 500), () {
      _makeComputerMove();
    });
  }

  /// Handles the computer's move logic
  void _makeComputerMove() {
    // For the first two moves, make perfect strategic moves
    // For the third move, make a non-winning move
    // After that, use easy difficulty to let the player win
    Future<int> movePromise;
    
    if (oMoveCount < 2) {
      // First two moves: Use strategic moves to avoid losing
      movePromise = _getStrategicMove();
    } else if (oMoveCount == 2) {
      // Third move: Make a non-winning move
      movePromise = _getNonWinningStrategicMove();
    } else if (xMoveCount >= 4) {
      // After user's fourth move: Use easy difficulty
      movePromise = _getEasyMove(List<String>.from(board));
    } else {
      // Default behavior
      movePromise = computerPlayer.getMove(List<String>.from(board));
    }
    
    movePromise.then((move) {
      if (board[move].isEmpty) {
        // Process computer move
        _processComputerMove(move);
      }
    }).catchError((e) {
      AppLogger.error('Error in computer move: $e');
      isComputerTurn = false;
    });
  }
  
  /// Process the computer's move at the given index
  void _processComputerMove(int move) {
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
    // Tutorial-specific flags are now controlled by move count
  }

  // Add this method to enable the vanishing effect without resetting the game
  void enableVanishingEffect() {
    vanishingEffectEnabled = true;
  }
  
  // This method is kept for API compatibility but is no longer needed
  // as the computer's move strategy is now controlled directly in _makeComputerMove
  void allowComputerToWin() {
    // No-op - strategy is now controlled by move count
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
    
    availableMoves.shuffle();
    return availableMoves.first;
  }

  /// Gets a strategic move for the computer's first two moves
  /// This ensures the computer doesn't lose early in the tutorial
  Future<int> _getStrategicMove() async {
    // Check if center is available - best first move
    if (board[4].isEmpty && oMoveCount == 0) {
      return 4; // Center position
    }
    
    // If player took center, take a corner
    if (oMoveCount == 0 && board[4].isNotEmpty) {
      final corners = [0, 2, 6, 8];
      corners.shuffle();
      return corners.first;
    }
    
    // For second move, first check if we can block player from winning
    final blockingMove = _findBlockingMove(player1Symbol);
    if (blockingMove != -1) {
      return blockingMove;
    }
    
    // If no blocking move needed, take strategic position
    final availableCorners = [0, 2, 6, 8].where((pos) => board[pos].isEmpty).toList();
    if (availableCorners.isNotEmpty) {
      availableCorners.shuffle();
      return availableCorners.first;
    }
    
    // If no corners available, take any available side
    final availableSides = [1, 3, 5, 7].where((pos) => board[pos].isEmpty).toList();
    if (availableSides.isNotEmpty) {
      availableSides.shuffle();
      return availableSides.first;
    }
    
    // Fallback to any available move
    return _getEasyMove(board);
  }
  
  /// Finds a move that blocks the opponent from winning
  int _findBlockingMove(String opponentSymbol) {
    // Check rows, columns, and diagonals for potential wins to block
    final lines = [
      [0, 1, 2], [3, 4, 5], [6, 7, 8], // rows
      [0, 3, 6], [1, 4, 7], [2, 5, 8], // columns
      [0, 4, 8], [2, 4, 6]             // diagonals
    ];
    
    for (final line in lines) {
      final opponentCount = line.where((pos) => board[pos] == opponentSymbol).length;
      final emptyCount = line.where((pos) => board[pos].isEmpty).length;
      
      // If opponent has two in a row and there's one empty spot, block it
      if (opponentCount == 2 && emptyCount == 1) {
        return line.firstWhere((pos) => board[pos].isEmpty);
      }
    }
    
    return -1; // No blocking move found
  }
  
  /// Gets a strategic move that doesn't result in a win for the third move
  Future<int> _getNonWinningStrategicMove() async {
    
    // First check if we need to block player from winning
    final blockingMove = _findBlockingMove(player1Symbol);
    if (blockingMove != -1) {
      // Verify this blocking move doesn't result in computer winning
      final simulatedBoard = List<String>.from(board);
      simulatedBoard[blockingMove] = currentPlayer;
      
      if (!WinChecker.checkWin(simulatedBoard, currentPlayer)) {
        return blockingMove;
      }
    }
    
    // Get all available moves
    final List<int> availableMoves = [];
    for (int i = 0; i < board.length; i++) {
      if (board[i].isEmpty) {
        availableMoves.add(i);
      }
    }
    
    if (availableMoves.isEmpty) {
      throw StateError('No valid moves available');
    }
    
    // Find a non-winning move
    for (final move in availableMoves) {
      final simulatedBoard = List<String>.from(board);
      simulatedBoard[move] = currentPlayer;
      
      if (!WinChecker.checkWin(simulatedBoard, currentPlayer)) {
        return move;
      }
    }
    
    // If all moves lead to a win (unlikely in tic-tac-toe), just make a random move
    availableMoves.shuffle();
    return availableMoves.first;
  }
}