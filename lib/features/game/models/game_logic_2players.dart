import 'package:vanishingtictactoe/core/utils/win_checker.dart';

/// GameLogic class for handling two-player Tic Tac Toe game
class GameLogic {
  /// Game board represented as a list of strings ('X', 'O', or empty)
  final List<String> board = List.filled(9, '', growable: false);
  
  /// List to track X's moves in order
  List<int> xMoves = [];
  
  /// List to track O's moves in order
  List<int> oMoves = [];
  
  /// Current player's symbol ('X' or 'O')
  late String currentPlayer;
  
  /// Symbol for player 1 (default 'X')
  late final String player1Symbol;
  
  /// Symbol for player 2 (default 'O')
  late final String player2Symbol;
  
  /// Counter for X's total moves
  int xMoveCount = 0;
  
  /// Counter for O's total moves
  int oMoveCount = 0;
  
  /// Callback function when game ends
  Function(String) onGameEnd;
  
  /// Callback function when player changes
  final Function()? onPlayerChanged;

  /// Store who goes first
  final bool _player1GoesFirst;

  /// Flag to enable/disable the vanishing effect
  bool vanishingEffectEnabled;
  
  /// Get the total number of moves made in the game
  int get moveCount => xMoveCount + oMoveCount;

  GameLogic({
    required this.onGameEnd,
    required this.player1Symbol,
    required this.player2Symbol,
    this.onPlayerChanged,
    bool player1GoesFirst = true,
    this.vanishingEffectEnabled = true, // Default to true
  }) : _player1GoesFirst = player1GoesFirst {
    currentPlayer = _player1GoesFirst ? player1Symbol : player2Symbol;
  }

  void makeMove(int index) {
    if (board[index].isEmpty) {
      // Update the board
      board[index] = currentPlayer;

      // Update move history
      if (currentPlayer == 'X') {
        xMoves.add(index);
        xMoveCount++;
      } else {
        oMoves.add(index);
        oMoveCount++;
      }

      int? nextToVanish;
      // Only apply vanishing effect if enabled
      if ((xMoveCount + oMoveCount) > 6) {
        nextToVanish = getNextToVanish();
        if (nextToVanish != null) {
          board[nextToVanish] = ''; // Remove the symbol
          if (currentPlayer == 'X') {
            xMoves.removeAt(0); // Remove the oldest X move
          } else {
            oMoves.removeAt(0); // Remove the oldest O move
          }
        }
      }
      // Check for win before vanishing
      if (xMoveCount + oMoveCount > 3) {
        final winner = checkWinner();
        if (winner.isNotEmpty) {
          onGameEnd(winner);
          return;
        }
      }
        


      // Switch turns
      currentPlayer = currentPlayer == 'X' ? 'O' : 'X';
      onPlayerChanged!();
    }
  }

  String checkWinner([int? nextToVanish]) {
    if (WinChecker.checkWin(board, 'X', nextToVanish: nextToVanish)) {
      return 'X';
    }
    if (WinChecker.checkWin(board, 'O', nextToVanish: nextToVanish)) {
      return 'O';
    }
    if (!board.contains('')) {
      return 'draw';
    }
    return '';
  }

  int? getNextToVanish() {
    
    if (xMoveCount + oMoveCount > 5) {
      if (currentPlayer == 'X' && xMoves.isNotEmpty) {
        return xMoves[0];
      } else if (currentPlayer == 'O' && oMoves.isNotEmpty) {
        return oMoves[0];
      }
    }
    return null;
  }

  /// Reset the game to its initial state
  void resetGame() {
    board.fillRange(0, 9, '');
    xMoves.clear();
    oMoves.clear();
    xMoveCount = 0;
    oMoveCount = 0;
    currentPlayer = _player1GoesFirst ? player1Symbol : player2Symbol;
  }

  // No need for dispose if ValueNotifier is removed
  void dispose() {}
}