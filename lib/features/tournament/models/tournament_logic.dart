import 'package:vanishingtictactoe/core/utils/app_logger.dart';
import 'package:vanishingtictactoe/core/utils/win_checker.dart';
import 'package:vanishingtictactoe/features/tournament/models/tournament_game.dart';
import 'package:vanishingtictactoe/features/tournament/models/tournament_match.dart';
import 'package:vanishingtictactoe/features/game/models/game_logic_2players.dart';
import 'package:vanishingtictactoe/features/tournament/models/tournament_player.dart';

/// A class that handles the logic for tournament games.
/// This is a simplified version of the game logic used for tournament matches.
class TournamentGameLogic extends GameLogic {
  final List<String> _gameBoard;
  final String _currentTurn;
  final Function(int position) onMakeMove;
  final Function(int? vanishedPosition)? onVanish;
  
  // Lists to track moves for vanishing effect
  final List<int> _xMoves = [];
  final List<int> _oMoves = [];
  int _xMoveCount = 0;
  int _oMoveCount = 0;

  TournamentGameLogic({
    required List<String> board,
    required String currentTurn,
    required this.onMakeMove,
    this.onVanish,
  }) : _gameBoard = board,
       _currentTurn = currentTurn,
       super(
         onGameEnd: (_) {}, // Empty callback as this is handled by tournament logic
         onPlayerChanged: () {}, // Empty callback as this is handled by tournament logic
         player1Symbol: 'X',
         player2Symbol: 'O',
       ) {
    // Override the currentPlayer from the parent class
    super.currentPlayer = _currentTurn;
    
    // Initialize move tracking based on current board state
    _initializeMoveTracking(board);
  }

  /// Initialize move tracking based on the current board state
  void _initializeMoveTracking(List<String> board) {
    for (int i = 0; i < board.length; i++) {
      if (board[i] == 'X') {
        _xMoves.add(i);
        _xMoveCount++;
      } else if (board[i] == 'O') {
        _oMoves.add(i);
        _oMoveCount++;
      }
    }
    AppLogger.info('Initialized move tracking: X moves: $_xMoveCount, O moves: $_oMoveCount');
  }

  @override
  List<String> get board => _gameBoard;
  
  @override
  String get currentPlayer => _currentTurn;
  
  /// Checks if a move is valid
  bool isValidMove(int position) {
    if (position < 0 || position >= board.length) {
      return false;
    }
    return board[position].isEmpty;
  }

  /// Makes a move on the board with vanishing effect
  @override
  void makeMove(int position) {
    if (isValidMove(position)) {
      // Track the move for vanishing effect
      if (currentPlayer == 'X') {
        _xMoves.add(position);
        _xMoveCount++;
      } else {
        _oMoves.add(position);
        _oMoveCount++;
      }
      
      // Calculate if we need to vanish a move
      int? vanishedPosition = _calculateVanishingMove();
      
      // Call the onMakeMove callback with the position
      onMakeMove(position);
      
      // Notify about vanished position if applicable
      if (vanishedPosition != null && onVanish != null) {
        onVanish!(vanishedPosition);
      }
    }
  }
  
  /// Calculate which move should vanish based on the vanishing effect rules
  int? _calculateVanishingMove() {
    // Apply vanishing effect after 6 total moves (3 per player)
    if ((_xMoveCount + _oMoveCount) > 6) {
      if (currentPlayer == 'X' && _xMoves.length > 3) {
        return _xMoves[0]; // Oldest X move
      } else if (currentPlayer == 'O' && _oMoves.length > 3) {
        return _oMoves[0]; // Oldest O move
      }
    }
    return null;
  }

  /// Gets the symbol at a specific position
  String getSymbolAt(int position) {
    if (position < 0 || position >= board.length) {
      return '';
    }
    return board[position];
  }

  /// Checks if the game is over
  bool isGameOver() {
    return WinChecker.checkWin(board, 'X') || 
           WinChecker.checkWin(board, 'O') || 
           WinChecker.isBoardFull(board);
  }

  /// Gets the winner of the game
  String? getWinner() {
    if (WinChecker.checkWin(board, 'X')) {
      return 'X';
    } else if (WinChecker.checkWin(board, 'O')) {
      return 'O';
    } else if (WinChecker.isBoardFull(board)) {
      return 'draw';
    }
    return null;
  }
}

/// A class that handles the logic for tournament matches.
/// This manages the best-of-3 games in a tournament match.
class TournamentMatchLogic {
  final TournamentMatch match;
  final TournamentPlayer player1;
  final TournamentPlayer player2;
  final List<TournamentGame> games;
  final String currentPlayerId;
  final Function(int gameIndex, int position) onMakeMove;
  final Function(String winnerId) onMatchComplete;
  final Function(TournamentGame game, String? winnerId)? onGameComplete;
  final Function(int gameIndex, int vanishedPosition)? onVanishMove;

  TournamentMatchLogic({
    required this.match,
    required this.player1,
    required this.player2,
    required this.games,
    required this.currentPlayerId,
    required this.onMakeMove,
    required this.onMatchComplete,
    this.onGameComplete,
    this.onVanishMove,
  });

  /// Gets the current game in the match
  TournamentGame? getCurrentGame() {
    if (games.isEmpty) {
      return null;
    }
    
    // Find the first game that is not completed
    for (var game in games) {
      if (game.status != 'completed') {
        return game;
      }
    }
    
    // If all games are completed, return the last game
    return games.last;
  }

  /// Checks if the match is over
  bool isMatchOver() {
    return match.player1Wins >= 2 || match.player2Wins >= 2;
  }

  /// Gets the winner of the match
  String? getMatchWinner() {
    if (match.player1Wins >= 2) {
      return match.player1Id;
    } else if (match.player2Wins >= 2) {
      return match.player2Id;
    }
    return null;
  }

  /// Checks if it's the current player's turn
  bool isCurrentPlayerTurn() {
    final currentGame = getCurrentGame();
    if (currentGame == null) {
      return false;
    }
    
    final playerSymbol = getPlayerSymbol(currentPlayerId);
    return currentGame.currentTurn == playerSymbol;
  }

  /// Gets the symbol for a player
  String getPlayerSymbol(String playerId) {
    if (playerId == player1.id) {
      return 'X';
    } else if (playerId == player2.id) {
      return 'O';
    }
    return '';
  }

  /// Gets the player by their symbol
  TournamentPlayer? getPlayerBySymbol(String symbol) {
    if (symbol == 'X') {
      return player1;
    } else if (symbol == 'O') {
      return player2;
    }
    return null;
  }

  /// Makes a move in the current game
  void makeMove(int position) {
    final currentGame = getCurrentGame();
    if (currentGame == null) {
      return;
    }
    
    final gameIndex = games.indexOf(currentGame);
    if (gameIndex == -1) {
      return;
    }
    
    onMakeMove(gameIndex, position);
  }

  /// Handles game completion and updates match state
  void handleGameCompletion(TournamentGame game, String? winnerId) {
    // Notify about game completion
    if (onGameComplete != null) {
      onGameComplete!(game, winnerId);
    }
    
    if (winnerId == null || winnerId == 'draw') {
      // Handle draw - typically replay the game
      AppLogger.info('Game ended in a draw, will need to replay');
      return;
    }
    
    // Update match state based on game winner
    if (winnerId == player1.id) {
      AppLogger.info('Player 1 won the game, wins: ${match.player1Wins + 1}');
      if (match.player1Wins + 1 >= 2) {
        // Player 1 won the match (best of 3)
        AppLogger.info('Player 1 won the match (best of 3)');
        onMatchComplete(player1.id);
      }
    } else if (winnerId == player2.id) {
      AppLogger.info('Player 2 won the game, wins: ${match.player2Wins + 1}');
      if (match.player2Wins + 1 >= 2) {
        // Player 2 won the match (best of 3)
        AppLogger.info('Player 2 won the match (best of 3)');
        onMatchComplete(player2.id);
      }
    }
  }
  
  /// Handle vanishing move in a specific game
  void handleVanishingMove(int gameIndex, int position) {
    if (onVanishMove != null) {
      onVanishMove!(gameIndex, position);
    }
  }
}
