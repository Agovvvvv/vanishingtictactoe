import 'dart:math';
import 'package:vanishingtictactoe/shared/models/player.dart';

/// Represents the difficulty level of the computer player.
/// Each level implements a different strategy for move selection.
enum GameDifficulty {
  /// Makes completely random moves
  easy,
  
  /// Makes a mix of random and perfect moves
  medium,
  
  /// Makes mostly perfect moves
  hard,
}

/// A computer player that can make moves in the game with varying levels of difficulty.
/// Uses different strategies based on the selected difficulty level.
class ComputerPlayer extends Player {
  /// The win patterns for a 3x3 tic-tac-toe board
  static const List<List<int>> _winPatterns = [
    [0, 1, 2], [3, 4, 5], [6, 7, 8], // Rows
    [0, 3, 6], [1, 4, 7], [2, 5, 8], // Columns
    [0, 4, 8], [2, 4, 6]             // Diagonals
  ];
  
  /// The positions of corners on the board
  static const List<int> _corners = [0, 2, 6, 8];
  
  /// The positions of edges on the board
  static const List<int> _edges = [1, 3, 5, 7];
  
  /// Random number generator for probability-based decisions
  final Random _random = Random();
  
  /// The difficulty level that determines the computer's playing strategy
  final GameDifficulty difficulty;
  
  /// The symbol (X or O) used by the computer player
  final String computerSymbol;
  
  /// The symbol (X or O) used by the human player
  final String playerSymbol;
  
  /// The delay before making a move (for better UX)
  final Duration moveDelay;
  
  /// The probability of making an optimal move in hard difficulty (0.0 to 1.0)
  final double optimalMoveChance;
  
  /// The probability of making a strategic move in medium difficulty (0.0 to 1.0)
  final double mediumStrategicChance;

  /// Creates a computer player with the specified difficulty and symbols.
  /// 
  /// [difficulty] determines how the computer will play
  /// [computerSymbol] is the symbol (X or O) used by the computer
  /// [playerSymbol] is the symbol (X or O) used by the human player
  /// [name] is the display name of the computer player
  /// [moveDelay] is the time to wait before making a move (default: 500ms)
  /// [optimalMoveChance] is the probability of making an optimal move in hard mode (default: 0.8)
  /// [mediumStrategicChance] is the probability of making a strategic move in medium mode (default: 0.7)
  ComputerPlayer({
    required this.difficulty,
    required this.computerSymbol,
    required this.playerSymbol,
    required super.name,
    this.moveDelay = const Duration(milliseconds: 500),
    this.optimalMoveChance = 0.8,
    this.mediumStrategicChance = 0.7,
  }) : super(symbol: computerSymbol);

  /// Gets the computer's next move based on the current board state and difficulty level.
  /// 
  /// [board] is the current game board state
  /// 
  /// Returns the index where the computer will place its symbol
  /// 
  /// Throws [StateError] if there are no valid moves available
  Future<int> getMove(List<String> board) async {
    // Check if there are any available moves
    final availableMoves = _getAvailableMoves(board);
    if (availableMoves.isEmpty) {
      throw StateError('No valid moves available: board is full');
    }

    // Add delay for better UX
    await Future.delayed(moveDelay);
    
    // Get the best move based on difficulty
    return _getBestMove(board);
  }

  /// Determines the best move based on the current difficulty level
  /// 
  /// [board] is the current game board state
  /// 
  /// Returns the index of the best move according to the difficulty level
  int _getBestMove(List<String> board) {
    switch (difficulty) {
      case GameDifficulty.easy:
        return _getRandomMove(board);
      case GameDifficulty.medium:
        return _getMediumMove(board);
      case GameDifficulty.hard:
        return _getHardMove(board);
    }
  }

  /// Makes a completely random move from the available positions
  /// 
  /// [board] is the current game board state
  /// 
  /// Returns a random valid move index
  /// 
  /// Throws [StateError] if there are no valid moves available
  int _getRandomMove(List<String> board) {
    final List<int> availableMoves = _getAvailableMoves(board);
    if (availableMoves.isEmpty) {
      throw StateError('No valid moves available');
    }
    availableMoves.shuffle(_random);
    return availableMoves.first;
  }

  /// Gets a list of all empty positions on the board
  /// 
  /// [board] is the current game board state
  /// 
  /// Returns a list of indices representing empty positions
  List<int> _getAvailableMoves(List<String> board) {
    final List<int> moves = [];
    for (int i = 0; i < board.length; i++) {
      if (board[i].isEmpty) {
        moves.add(i);
      }
    }
    return moves;
  }

  /// Makes a strategic move with medium difficulty
  /// - Blocks opponent's winning moves
  /// - Takes winning moves when available
  /// - Makes strategic moves with a certain probability
  /// - Otherwise makes a random move
  /// 
  /// [board] is the current game board state
  /// 
  /// Returns the index of the selected move
  int _getMediumMove(List<String> board) {
    // First, check if we can win in the next move
    final winningMove = _findWinningMove(board, computerSymbol);
    if (winningMove != -1) return winningMove;

    // Then, check if we need to block opponent's winning move
    final blockingMove = _findWinningMove(board, playerSymbol);
    if (blockingMove != -1) return blockingMove;

    // Make a strategic move with a certain probability
    if (_random.nextDouble() < mediumStrategicChance) {
      return _getStrategicMove(board);
    }
    
    // Otherwise make a random move
    return _getRandomMove(board);
  }

  /// Makes a strategic move with hard difficulty
  /// - Always takes winning moves
  /// - Always blocks opponent's winning moves
  /// - Makes optimal moves with a configurable probability
  /// - Otherwise makes a strategic but suboptimal move to be beatable
  /// 
  /// [board] is the current game board state
  /// 
  /// Returns the index of the selected move
  int _getHardMove(List<String> board) {
    // First, check if we can win in the next move
    final winningMove = _findWinningMove(board, computerSymbol);
    if (winningMove != -1) return winningMove;

    // Then, check if we need to block opponent's winning move
    final blockingMove = _findWinningMove(board, playerSymbol);
    if (blockingMove != -1) return blockingMove;

    // Make an optimal move with a configurable probability
    if (_random.nextDouble() < optimalMoveChance) {
      return _getOptimalMove(board);
    } else {
      // Make a suboptimal but still strategic move
      return _getSuboptimalMove(board);
    }
  }

  /// Finds a winning move for the given symbol if one exists
  /// 
  /// [board] is the current game board state
  /// [symbol] is the player symbol to find a winning move for
  /// 
  /// Returns the index of a winning move, or -1 if no winning move is available
  int _findWinningMove(List<String> board, String symbol) {
    // Check each pattern for a potential winning move
    for (final pattern in _winPatterns) {
      final p1 = board[pattern[0]];
      final p2 = board[pattern[1]];
      final p3 = board[pattern[2]];
      
      // If two positions have our symbol and one is empty, that's a winning move
      if (p1 == symbol && p2 == symbol && p3.isEmpty) return pattern[2];
      if (p1 == symbol && p3 == symbol && p2.isEmpty) return pattern[1];
      if (p2 == symbol && p3 == symbol && p1.isEmpty) return pattern[0];
    }
    return -1;
  }

  /// Makes an optimal move that prioritizes center, then corners, then edges
  /// 
  /// [board] is the current game board state
  /// 
  /// Returns the index of the optimal move
  int _getOptimalMove(List<String> board) {
    // Try to take center if available
    if (board[4].isEmpty) return 4;
    
    // Try to take a corner
    final shuffledCorners = List<int>.from(_corners)..shuffle(_random);
    for (final corner in shuffledCorners) {
      if (board[corner].isEmpty) return corner;
    }
    
    // Take any available edge
    final shuffledEdges = List<int>.from(_edges)..shuffle(_random);
    for (final edge in shuffledEdges) {
      if (board[edge].isEmpty) return edge;
    }
    
    // Fallback to random move
    return _getRandomMove(board);
  }
  
  /// Makes a strategic but suboptimal move
  /// This is used to make the hard difficulty beatable
  /// 
  /// [board] is the current game board state
  /// 
  /// Returns the index of a suboptimal but still strategic move
  int _getSuboptimalMove(List<String> board) {
    // If center is available, 50% chance to take it
    if (board[4].isEmpty && _random.nextBool()) {
      return 4;
    }
    
    // Prioritize edges over corners (opposite of optimal strategy)
    final shuffledEdges = List<int>.from(_edges)..shuffle(_random);
    for (final edge in shuffledEdges) {
      if (board[edge].isEmpty) return edge;
    }
    
    final shuffledCorners = List<int>.from(_corners)..shuffle(_random);
    for (final corner in shuffledCorners) {
      if (board[corner].isEmpty) return corner;
    }
    
    // Fallback to random move
    return _getRandomMove(board);
  }
  
  /// Makes a strategic move that prioritizes center and corners
  /// Used by medium difficulty and as a fallback
  /// 
  /// [board] is the current game board state
  /// 
  /// Returns the index of a strategic move
  int _getStrategicMove(List<String> board) {
    // Try to take center if available
    if (board[4].isEmpty) return 4;
    
    // Try to take a corner
    final shuffledCorners = List<int>.from(_corners)..shuffle(_random);
    for (final corner in shuffledCorners) {
      if (board[corner].isEmpty) return corner;
    }
    
    // Take any available edge
    final shuffledEdges = List<int>.from(_edges)..shuffle(_random);
    for (final edge in shuffledEdges) {
      if (board[edge].isEmpty) return edge;
    }
    
    // Fallback to random move
    return _getRandomMove(board);
  }
}
