import 'dart:async';
import 'package:flutter/material.dart';
import 'package:vanishingtictactoe/core/utils/app_logger.dart';
import 'package:vanishingtictactoe/core/utils/error_handler.dart';
import 'package:vanishingtictactoe/core/utils/win_checker.dart';
import 'package:vanishingtictactoe/features/game/models/game_logic_2players.dart';
import 'package:vanishingtictactoe/features/game/services/friendly_match_service.dart';
import 'package:vanishingtictactoe/shared/models/match.dart';
import 'package:vanishingtictactoe/core/network/connection_manager.dart';

/// A specialized game logic class for handling friendly matches
/// This extends the base GameLogic class but uses FriendlyMatchService instead of MatchmakingService
class FriendlyGameLogicOnline extends GameLogic {
  final FriendlyMatchService _friendlyMatchService;
  StreamSubscription? _matchSubscription;
  final String _localPlayerId;
  GameMatch? _currentMatch;
  final String _matchCode;

  // Flag to track if we've already called onGameEnd
  bool _gameEndCalled = false;

  // Callbacks for error handling and connection status
  Function(String message)? onError;
  Function(bool isConnected)? onConnectionStatusChanged;

  // Connection manager for handling connection monitoring
  late final ConnectionManager _connectionManager;
  bool _isConnected = false;

  // Value notifiers for reactive UI updates
  final ValueNotifier<List<String>> boardNotifier = ValueNotifier<List<String>>(List.filled(9, ''));
  final ValueNotifier<String> turnNotifier = ValueNotifier<String>('');

  // Getters
  @override
  String get currentPlayer => _currentMatch?.currentTurn ?? super.currentPlayer;
  String get localPlayerId => _localPlayerId;
  GameMatch? get currentMatch => _currentMatch;
  String get matchCode => _matchCode;
  
  // Setter for currentPlayer to ensure it's updated properly
  @override
  set currentPlayer(String player) {
    super.currentPlayer = player;
    // This is just for local state - the actual turn is controlled by _currentMatch.currentTurn
  }

  @override
  List<String> get board => _currentMatch?.board ?? List.filled(9, '');

  String get opponentName {
    if (_currentMatch == null || _localPlayerId.isEmpty) return 'Opponent';
    final match = _currentMatch!;
    return match.player1.id == _localPlayerId ? match.player2.name : match.player1.name;
  }

  bool get isLocalPlayerTurn {
    if (_currentMatch == null) return false;
    return localPlayerSymbol.isNotEmpty && _currentMatch!.currentTurn == localPlayerSymbol;
  }

  bool get isConnected => _isConnected;

  String get turnDisplay {
    if (!_isConnected) return 'Connecting...';
    if (_currentMatch == null) return 'Waiting for game...';

    if (_currentMatch?.status == 'completed') {
      final winner = _currentMatch!.winner;
      if (winner.isEmpty || winner == 'draw') {
        return 'Game Over - Draw!';
      }
      return winner == localPlayerSymbol ? 'You Won!' : 'Opponent Won!';
    }

    if (_currentMatch?.status == 'abandoned') return 'Game Abandoned';
    if (localPlayerSymbol.isEmpty) return 'Waiting for game to start...';
    return isLocalPlayerTurn ? 'Your turn' : 'Opponent\'s turn';
  }

  String get localPlayerSymbol {
    if (_currentMatch == null || _localPlayerId.isEmpty) {
      AppLogger.warning('Cannot get local player symbol: match or player ID is null');
      return '';
    }
    if (_currentMatch!.player1.id == _localPlayerId) return _currentMatch!.player1.symbol;
    if (_currentMatch!.player2.id == _localPlayerId) return _currentMatch!.player2.symbol;
    AppLogger.warning('Local player ID not found in match players');
    return '';
  }

  bool get isDraw => _currentMatch?.isDraw ?? false;

  // Constructor
  FriendlyGameLogicOnline({
    required super.onGameEnd,
    required Function() super.onPlayerChanged,
    required String localPlayerId,
    required FriendlyMatchService friendlyMatchService,
    this.onError,
    this.onConnectionStatusChanged,
    String? gameId,
    String? matchCode,
  }) : _friendlyMatchService = friendlyMatchService,
       _localPlayerId = localPlayerId,
       _matchCode = matchCode ?? '',
       super(
         player1Symbol: 'X',
         player2Symbol: 'O',
         player1GoesFirst: true,
       ) {
    // Initialize connection manager
    _connectionManager = ConnectionManager(
      onConnectionStatusChanged: (isConnected) {
        _isConnected = isConnected;
        onConnectionStatusChanged?.call(isConnected);
      },
      onReconnectAttempt: _attemptReconnect,
    );
    _connectionManager.startMonitoring();
    
    boardNotifier.value = List.filled(9, '');
    turnNotifier.value = '';

    if (gameId != null) joinMatch(gameId);
  }

  // Check if the game is active and should be monitored for connection
  bool get _shouldMonitorConnection {
    final shouldMonitor = !_gameEndCalled && 
           _currentMatch != null && 
           _currentMatch!.status != 'completed' && 
           _currentMatch!.status != 'abandoned';
    
    // Update the connection manager's monitoring state
    if (!shouldMonitor) {
      _connectionManager.shouldMonitor = false;
    }
    
    return shouldMonitor;
  }

  // Attempt to reconnect to the match
  Future<void> _attemptReconnect() async {
    // Only attempt reconnection if the game is still active
    if (_shouldMonitorConnection) {
      AppLogger.info('Attempting to reconnect to friendly match: ${_currentMatch!.id}');
      await joinMatch(_currentMatch!.id);
    } else {
      AppLogger.info('Skipping reconnection attempt as friendly game is no longer active');
    }
  }
  
  // Join an existing match
  Future<void> joinMatch(String matchId) async {
    try {
      if (_matchSubscription != null) await _matchSubscription!.cancel();
      
      // Use the friendly match service to listen for match updates
      _matchSubscription = _friendlyMatchService.listenForActiveMatchUpdates(matchId).listen(
        (match) async {
          try {
            if (match == null) {
              AppLogger.warning('Received null match from stream');
              return;
            }
            
            if (!_isConnected) {
              _isConnected = true;
              onConnectionStatusChanged?.call(true);
            }
            _connectionManager.updateLastActivityTime();

            final previousMatch = _currentMatch;
            _currentMatch = match;

            // Check for win condition
            final currentSymbol = match.currentTurn == 'X' ? 'O' : 'X'; // Check for the player who just moved
            final hasWinner = WinChecker.checkWin(match.board, currentSymbol);

            if (hasWinner || match.status == 'completed') {
              if (match.status == 'completed' && match.board.every((cell) => cell.isEmpty)) {
                AppLogger.warning('Match marked as completed with empty board - likely an error');
                return;
              }

              if (!_gameEndCalled) {
                _gameEndCalled = true;
                onGameEnd(match.winner.isEmpty ? 'draw' : match.winner);
              }

              boardNotifier.value = match.board;
              turnNotifier.value = match.currentTurn;
              onPlayerChanged?.call();
              return;
            }

            // Update board and turn notifiers
            boardNotifier.value = match.board;
            turnNotifier.value = match.currentTurn;
            
            // Update the currentPlayer to match the current turn
            // This is critical for proper turn handling
            super.currentPlayer = match.currentTurn;
            
            AppLogger.debug('Match updated: turn=${match.currentTurn}, isLocalPlayerTurn=$isLocalPlayerTurn');

            // Handle game completion or abandonment
            if (match.status == 'completed' && previousMatch?.status != 'completed' && !_gameEndCalled) {
              _gameEndCalled = true;
              // Stop connection monitoring when game is completed
              _connectionManager.shouldMonitor = false;
              onGameEnd(match.winner);
            }

            onPlayerChanged?.call();
          } catch (e, stackTrace) {
            ErrorHandler.handleError('Error in match update handler: $e', onError: onError);
            AppLogger.error('Stack trace: $stackTrace');
          }
        },
        onError: (error, stackTrace) {
          ErrorHandler.handleError('Error in match subscription: $error', onError: onError);
          AppLogger.error('Stack trace: $stackTrace');
          _isConnected = false;
          onConnectionStatusChanged?.call(false);
        },
      );
    } catch (e) {
      ErrorHandler.handleError('Error joining match: $e', onError: onError);
    }
  }

  // Make a move
  @override
  Future<void> makeMove(int index) async {
    if (!_isConnected) {
      ErrorHandler.handleError('No connection to the game server', onError: onError);
      return;
    }

    if (_currentMatch == null) {
      ErrorHandler.handleError('No active game', onError: onError);
      return;
    }

    final matchSnapshot = _currentMatch!;

    if (matchSnapshot.status == 'completed') {
      if (!_gameEndCalled) {
        _gameEndCalled = true;
        onGameEnd(matchSnapshot.winner);
      }
      return;
    }

    // Validate the move
    if (!isLocalPlayerTurn) {
      ErrorHandler.handleError('Not your turn', onError: onError);
      return;
    }

    if (index < 0 || index >= 9) {
      ErrorHandler.handleError('Invalid position', onError: onError);
      return;
    }

    if (matchSnapshot.board[index].isNotEmpty) {
      ErrorHandler.handleError('Position already taken', onError: onError);
      return;
    }

    try {
      // Apply optimistic update immediately for responsive UI
      final currentBoard = List<String>.from(matchSnapshot.board);
      currentBoard[index] = localPlayerSymbol;
      
      // Update UI immediately with optimistic changes
      boardNotifier.value = currentBoard;
      turnNotifier.value = localPlayerSymbol == 'X' ? 'O' : 'X';
      
      // Use the friendly match service to make the move
      final result = await _friendlyMatchService.makeMove(matchSnapshot.id, _localPlayerId, index);
      
      // Apply optimistic update from service
      if (result.containsKey('optimisticMatch')) {
        final optimisticMatch = result['optimisticMatch'] as GameMatch;
        _currentMatch = optimisticMatch;
        
        // Update UI with optimistic match data
        boardNotifier.value = optimisticMatch.board;
        turnNotifier.value = optimisticMatch.currentTurn;
        
        // Update the currentPlayer to match the current turn
        // This is critical for proper turn handling
        super.currentPlayer = optimisticMatch.currentTurn;
        
        // Check for game completion
        if (result['isCompleted'] == true && !_gameEndCalled) {
          _gameEndCalled = true;
          onGameEnd(optimisticMatch.winner);
        }
        
        // Notify listeners that the player has changed
        onPlayerChanged?.call();
        
        AppLogger.debug('Turn updated to: ${optimisticMatch.currentTurn}, isLocalPlayerTurn: $isLocalPlayerTurn');
      }
      
      AppLogger.info('Move made at position $index');
    } catch (e) {
      // Revert optimistic updates on error
      if (_currentMatch != null) {
        boardNotifier.value = _currentMatch!.board;
        turnNotifier.value = _currentMatch!.currentTurn;
      }
      ErrorHandler.handleError('Failed to submit your move: $e', onError: onError);
    }
  }

  // Dispose resources
  @override
  void dispose() {
    _gameEndCalled = true; // Mark as ended to prevent reconnection attempts
    _connectionManager.shouldMonitor = false; // Stop monitoring before disposing
    _connectionManager.dispose();
    _matchSubscription?.cancel();
    _currentMatch = null;
    boardNotifier.value = List.filled(9, '');
    turnNotifier.value = '';
    _isConnected = false;
    AppLogger.info('Friendly game logic resources disposed');
  }
}
