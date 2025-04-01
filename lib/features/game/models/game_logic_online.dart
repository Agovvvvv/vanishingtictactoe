import 'dart:async';
import 'package:vanishingtictactoe/features/online/services/matchmaking_service.dart';
import 'package:vanishingtictactoe/shared/models/match.dart';
import 'package:vanishingtictactoe/features/game/models/game_logic_2players.dart'; // Updated import path
import 'package:flutter/material.dart'; 
import 'package:vanishingtictactoe/core/utils/app_logger.dart';
import 'package:vanishingtictactoe/core/utils/win_checker.dart';
import 'package:vanishingtictactoe/core/utils/move_validator.dart';
import 'package:vanishingtictactoe/core/utils/error_handler.dart';
import 'package:vanishingtictactoe/core/network/connection_manager.dart';

class GameLogicOnline extends GameLogic {
  final MatchmakingService _matchmakingService;
  StreamSubscription? _matchSubscription;
  final String _localPlayerId;
  GameMatch? _currentMatch;

  // Flag to track if we've already called onGameEnd
  bool _gameEndCalled = false;

  // Callbacks for error handling and connection status
  Function(String message)? onError;
  Function(bool isConnected)? onConnectionStatusChanged;
  
  // Track retry attempts for connection issues
  int _connectionRetryCount = 0;
  static const int _maxRetryAttempts = 3;

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
  GameLogicOnline({
    required super.onGameEnd,
    required Function() super.onPlayerChanged,
    required String localPlayerId,
    this.onError,
    this.onConnectionStatusChanged,
    String? gameId,
    String? matchType, // Add matchType parameter to identify challenge games
    String? firstPlayerSymbol, // Add parameter for coin flip result
  }) : _matchmakingService = MatchmakingService(),
       _localPlayerId = localPlayerId,
       super(
         player1Symbol: 'X',
         player2Symbol: 'O',
         player1GoesFirst: firstPlayerSymbol == null || firstPlayerSymbol == 'X',
       ) {
    
    if (matchType == 'challenge') {
      AppLogger.info('Initializing challenge game with ID: $gameId');
    }
    
    // Set the current player based on the coin flip result
    if (firstPlayerSymbol != null) {
      currentPlayer = firstPlayerSymbol;
      AppLogger.info('Setting initial player from coin flip: $firstPlayerSymbol');
    }
    
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
    turnNotifier.value = currentPlayer; // Initialize with the correct first player

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
      AppLogger.info('Attempting to reconnect to match: ${_currentMatch!.id}');
      // Reset retry count for a fresh reconnection attempt
      _connectionRetryCount = 0;
      await joinMatch(_currentMatch!.id);
    } else {
      AppLogger.info('Skipping reconnection attempt as game is no longer active');
    }
  }

  // Join an existing match
  Future<void> joinMatch(String matchId) async {
    try {
      if (_matchSubscription != null) await _matchSubscription!.cancel();
      
      // Reset connection retry count when starting a new connection
      _connectionRetryCount = 0;
      
      AppLogger.info('Joining match with ID: $matchId');
      _matchSubscription = _matchmakingService.joinMatch(matchId).listen(
        (match) async {
          try {
            // Reset retry count on successful connection
            _connectionRetryCount = 0;
            
            // Update connection status and last activity time
            if (!_isConnected) {
              _isConnected = true;
              onConnectionStatusChanged?.call(true);
              AppLogger.info('Connection established to match: $matchId');
            }
            _connectionManager.updateLastActivityTime();

            final previousMatch = _currentMatch;
            _currentMatch = match;
            
            // Log match type for debugging
            if (previousMatch == null) {
              AppLogger.info('Match type: ${match.matchType}');
            }

            // Check for win condition
            final hasWinner = WinChecker.checkWin(match.board, match.currentTurn);

            if (hasWinner || match.status == 'completed') {
              if (match.status == 'completed' && match.board.every((cell) => cell.isEmpty)) {
                AppLogger.warning('Match marked as completed with empty board - likely an error');
                try {
                  await _matchmakingService.makeMove(match.id, -1);
                  AppLogger.info('Attempted to reset match to active state');
                  return;
                } catch (e) {
                  AppLogger.error('Failed to reset match: $e');
                }
              }

              if (!_gameEndCalled) {
                _gameEndCalled = true;
                onGameEnd(match.winner);
              }

              boardNotifier.value = match.board;
              turnNotifier.value = match.currentTurn;
              onPlayerChanged?.call();
              return;
            }

            // Update board and turn notifiers
            boardNotifier.value = match.board;
            
            // Only update turn notifier if it's different from the current one
            // This prevents overriding the coin flip result
            if (turnNotifier.value != match.currentTurn) {
              AppLogger.info('Updating turn from match data: ${match.currentTurn}');
              turnNotifier.value = match.currentTurn;
            }

            // Handle game completion or abandonment
            if (match.status == 'completed' && previousMatch?.status != 'completed' && !_gameEndCalled) {
              _gameEndCalled = true;
              // Stop connection monitoring when game is completed
              _connectionManager.shouldMonitor = false;
              onGameEnd(match.winner);
            } else if (match.status == 'abandoned' && previousMatch?.status != 'abandoned' && !_gameEndCalled) {
              _gameEndCalled = true;
              // Stop connection monitoring when game is abandoned
              _connectionManager.shouldMonitor = false;
              onError?.call('Opponent left the game');
              onGameEnd('abandoned');
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
          
          // Implement retry logic for connection errors
          if (_connectionRetryCount < _maxRetryAttempts) {
            _connectionRetryCount++;
            AppLogger.info('Retry attempt $_connectionRetryCount/$_maxRetryAttempts for match: $matchId');
            
            // Delay before retry with exponential backoff
            Future.delayed(Duration(seconds: 1 * _connectionRetryCount), () {
              if (!_gameEndCalled) { // Only retry if game hasn't ended
                AppLogger.info('Attempting to reconnect to match: $matchId');
                joinMatch(matchId);
              }
            });
          } else {
            // Max retries reached, provide clear error to user
            AppLogger.error('Max retry attempts reached for match: $matchId');
            ErrorHandler.handleError(
              'Unable to connect after multiple attempts. Please check your network connection or permissions.',
              onError: onError
            );
          }
        },
      );
    } catch (e, stackTrace) {
      ErrorHandler.handleError('Error joining match: $e', onError: onError);
      AppLogger.error('Stack trace: $stackTrace');
      
      // Also implement retry for initial connection errors
      if (_connectionRetryCount < _maxRetryAttempts) {
        _connectionRetryCount++;
        AppLogger.info('Retry attempt $_connectionRetryCount/$_maxRetryAttempts for match: $matchId');
        
        Future.delayed(Duration(seconds: 1 * _connectionRetryCount), () {
          if (!_gameEndCalled) {
            joinMatch(matchId);
          }
        });
      }
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

    if (!MoveValidator.validateMove(matchSnapshot, index, localPlayerSymbol)) {
      return;
    }

    try {
      // Check if this is a challenge game and pass the appropriate parameter
      final bool isChallenge = matchSnapshot.matchType == 'challenge';
      if (isChallenge) {
        AppLogger.info('Making move in challenge game: ${matchSnapshot.id}, isChallenge: $isChallenge');
      }
      
      // For challenge games, we need to ensure we're using the active_matches collection
      // This ensures consistent behavior regardless of which collection the game was created in
      await _matchmakingService.makeMove(matchSnapshot.id, index);
      

    } catch (e, stackTrace) {
      AppLogger.error('Error making move: $e');
      AppLogger.error('Stack trace: $stackTrace');
      
      // Handle permission errors that might occur in challenge games
      if (e.toString().contains('permission-denied')) {
        AppLogger.warning('Permission denied when making move. This might be a collection mismatch issue.');
        ErrorHandler.handleError(
          'Permission error. The game may need to be restarted. Please try again.',
          onError: onError
        );
        
        // Attempt to recover by refreshing the connection
        _attemptReconnect();
      } else {
        ErrorHandler.handleError('Failed to submit your move: $e', onError: onError);
      }
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
    _matchmakingService.dispose();
    AppLogger.info('Game logic resources disposed');
  }
}