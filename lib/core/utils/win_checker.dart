class WinChecker {
  /// The list of all possible winning patterns in a tic-tac-toe game
  static const List<List<int>> winPatterns = [
    [0, 1, 2], [3, 4, 5], [6, 7, 8], // rows
    [0, 3, 6], [1, 4, 7], [2, 5, 8], // columns
    [0, 4, 8], [2, 4, 6]             // diagonals
  ];

  /// Checks if the given [symbol] has won the game.
  /// [board] is the current state of the board.
  /// [symbol] is the player's symbol ('X' or 'O').
  /// [nextToVanish] is the index of the next symbol to vanish (if any).
  static bool checkWin(List<String> board, String symbol, {int? nextToVanish}) {
    for (final pattern in winPatterns) {
      // Check if all cells in the pattern match the symbol
      if (board[pattern[0]] == symbol &&
          board[pattern[1]] == symbol &&
          board[pattern[2]] == symbol) {
        // If a cell in the pattern is about to vanish, ignore this pattern
        if (nextToVanish != null &&
            (pattern[0] == nextToVanish ||
             pattern[1] == nextToVanish ||
             pattern[2] == nextToVanish)) {
          continue; // Skip this pattern
        }
        return true; // Winning pattern found
      }
    }
    return false; // No winning pattern found
  }
  
  /// Returns the winning pattern for the given [symbol].
  /// [board] is the current state of the board.
  /// [symbol] is the player's symbol ('X' or 'O').
  /// Returns the indices of the winning pattern, or null if no winning pattern is found.
  static List<int>? getWinningPattern(List<String> board, String symbol) {
    for (final pattern in winPatterns) {
      // Check if all cells in the pattern match the symbol
      if (board[pattern[0]] == symbol &&
          board[pattern[1]] == symbol &&
          board[pattern[2]] == symbol) {
        return pattern; // Return the winning pattern
      }
    }
    return null; // No winning pattern found
  }
  
  /// Checks if the board is full (no empty cells).
  /// [board] is the current state of the board.
  /// Returns true if the board is full, false otherwise.
  static bool isBoardFull(List<String> board) {
    return !board.contains('');
  }
}