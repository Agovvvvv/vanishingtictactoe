import 'package:flutter/foundation.dart';
import 'package:vanishingtictactoe/core/utils/app_logger.dart';
import 'package:vanishingtictactoe/features/game/models/game_logic_2players.dart';
import 'package:vanishingtictactoe/features/game/models/game_logic_vscomputer.dart';
import 'package:vanishingtictactoe/features/game/models/game_logic_online.dart';
import 'package:vanishingtictactoe/features/game/models/friendly_game_logic_online.dart';
import 'package:vanishingtictactoe/shared/models/player.dart';
import 'package:vanishingtictactoe/features/game/controllers/game_controller.dart';

class GameProvider extends ChangeNotifier {
  final GameLogic _gameLogic;
  late GameController gameController;
  bool _isConnecting = false;
  final Player paramPlayer1;
  final Player paramPlayer2;
  final bool paramIsOnlineGame;
  bool paramVanishingEffectEnabled;
  // In GameProvider class
  VoidCallback onPlayAgain;

  GameProvider({
    required GameLogic gameLogic,
    required Function(String) onGameEnd,
    required this.onPlayAgain,
    required this.paramPlayer1,
    required this.paramPlayer2,
    this.paramIsOnlineGame = false,
    this.paramVanishingEffectEnabled = true, // Default to true
    String? firstPlayerSymbol, // Add parameter for coin flip result
  }) : _gameLogic = gameLogic {
    // Set the vanishing effect on the game logic if it's a 2-player game
    _gameLogic.vanishingEffectEnabled = paramVanishingEffectEnabled;
    
    // Only set the first player symbol if it's not an online game
    // For online games, this is handled by GameLogicOnline directly
    if (firstPlayerSymbol != null &&  _gameLogic is! GameLogicOnline && _gameLogic is! FriendlyGameLogicOnline) {
      _gameLogic.currentPlayer = firstPlayerSymbol;
      AppLogger.info('GameProvider initialized with coin flip result: $firstPlayerSymbol');
    }
    
    gameController = GameController(
      gameLogic: _gameLogic,
      onGameEnd: onGameEnd,
      onPlayerChanged: () {
        notifyListeners();
      },
    );
    AppLogger.info('GameProvider initialized with initial currentPlayer: ${_gameLogic.currentPlayer}');
    _setupGameListeners();
  }
  GameLogic get gameLogic => _gameLogic;
  List<String> get board => _gameLogic.board;
  bool get isConnecting => _isConnecting;
  Player get player1 => paramPlayer1;
  Player get player2 => paramPlayer2;
  bool get isOnlineGame => paramIsOnlineGame;
  bool get vanishingEffectEnabled => paramVanishingEffectEnabled;

  void makeMove(int index) {
    AppLogger.debug('Making move at index $index, currentPlayer: ${_gameLogic.currentPlayer}');
    gameController.makeMove(index);
    notifyListeners();
  }

  void resetGame() {
    gameController.resetGame();
    // Clear the winning pattern to remove the winning line animation
    _winningPattern = null;
    notifyListeners(); // Notify UI of reset
    AppLogger.debug('Game reset, winning pattern cleared');
  }

  String getCurrentPlayerName() {
    return gameController.getCurrentPlayerName(paramPlayer1, paramPlayer2);
  }

  String getOnlinePlayerTurnText() {
    // The updated GameController can handle both GameLogicOnline and FriendlyGameLogicOnline
    if (_gameLogic is GameLogicOnline || _gameLogic is FriendlyGameLogicOnline) {
      return gameController.getOnlinePlayerTurnText(_gameLogic, _isConnecting);
    }
    return '';
  }

  bool isInteractionDisabled() {
    return gameController.isInteractionDisabled(_isConnecting);
  }

  String? determineSurrenderWinner() {
    return gameController.determineSurrenderWinner();
  }

  void notifyPlayerChanged() {
    notifyListeners(); // Explicit method to notify of player changes
  }
  
  // Method to handle vanishing moves and notify listeners
  void notifyVanishingMove(int position) {
    AppLogger.info('Vanishing move at position: $position');
    // If the game logic has a specific method to handle vanishing, call it
    if (_gameLogic.vanishingEffectEnabled) {
      // Clear the position on the board
      if (position >= 0 && position < _gameLogic.board.length) {
        _gameLogic.board[position] = '';
      }
      notifyListeners(); // Notify UI to update the board
    }
  }

  void _setupGameListeners() {
    if (_gameLogic is GameLogicVsComputer) {
      final computerLogic = _gameLogic;
      computerLogic.boardNotifier.addListener(() {
        notifyListeners(); // Notify UI of board changes from computer moves
      });
    }

    if (_gameLogic is GameLogicOnline) {
      final onlineLogic = _gameLogic;
      onlineLogic.boardNotifier.addListener(() {
        notifyListeners(); // Notify UI of board changes from online updates
      });
      onlineLogic.turnNotifier.addListener(() {
        AppLogger.debug('Online turn changed to: ${onlineLogic.turnNotifier.value}');
        notifyListeners(); // Notify UI of turn changes
      });
      onlineLogic.onError = (message) {
        AppLogger.error('Online game error: $message');
        // Optionally, notify UI of errors via a state variable
      };
      onlineLogic.onConnectionStatusChanged = (isConnected) {
        _isConnecting = !isConnected;
        notifyListeners(); // Notify UI of connection status changes
      };
    }
    
    // Add specific listeners for FriendlyGameLogicOnline
    if (_gameLogic is FriendlyGameLogicOnline) {
      final friendlyLogic = _gameLogic;
      
      // Listen for board changes
      friendlyLogic.boardNotifier.addListener(() {
        AppLogger.debug('Friendly match board updated');
        notifyListeners(); // Notify UI of board changes
      });
      
      // Listen for turn changes - critical for turn-based UI updates
      friendlyLogic.turnNotifier.addListener(() {
        AppLogger.debug('Friendly match turn changed to: ${friendlyLogic.turnNotifier.value}, ' 'isLocalPlayerTurn: ${friendlyLogic.isLocalPlayerTurn}');
        notifyListeners(); // Notify UI of turn changes
      });
      
      // Handle errors
      friendlyLogic.onError = (message) {
        AppLogger.error('Friendly match error: $message');
      };
      
      // Handle connection status changes
      friendlyLogic.onConnectionStatusChanged = (isConnected) {
        _isConnecting = !isConnected;
        notifyListeners(); // Notify UI of connection status changes
      };
    }
  }

  

  @override
  void dispose() {
    // Avoid double disposal by checking type first
    if (_gameLogic is GameLogicOnline || _gameLogic is FriendlyGameLogicOnline) {
      // These classes have their own dispose methods that handle cleanup
      _gameLogic.dispose();
    } else {
      // For other game logic types
      _gameLogic.dispose();
    }
    
    // Remove any listeners or clean up resources if added in _setupGameListeners
    super.dispose();
  }
  
  // Winning pattern for animation
  List<int>? _winningPattern;
  
  // Getter for the winning pattern
  List<int>? get winningPattern => _winningPattern;
  
  // Setter for the winning pattern - used to trigger the winning line animation
  void setWinningPattern(List<int> pattern) {
    _winningPattern = pattern;
    notifyListeners();
    AppLogger.debug('Set winning pattern in GameProvider: $pattern');
  }
}