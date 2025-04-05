import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:vanishingtictactoe/core/utils/app_logger.dart';
import 'package:vanishingtictactoe/features/tournament/models/tournament_game.dart';
import 'package:vanishingtictactoe/features/tournament/models/tournament_match.dart';
import 'package:vanishingtictactoe/features/tournament/models/tournament_model.dart';
import 'package:vanishingtictactoe/features/tournament/models/tournament_player.dart';
import 'package:vanishingtictactoe/features/tournament/services/tournament_service.dart';

/// Provider for managing tournament state
class TournamentProvider extends ChangeNotifier {
  final TournamentService _tournamentService = TournamentService();
  
  // Tournament state
  Tournament? _tournament;
  TournamentGame? _currentGame;
  bool _isLoading = false;
  String? _error;
  
  // Game readiness state
  String? _readyGameId;
  String? _readyMatchId;
  String? _readyTournamentId;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _gamesSubscription;
  
  // Stream subscriptions
  StreamSubscription<Tournament>? _tournamentSubscription;
  StreamSubscription<TournamentGame>? _gameSubscription;
  
  // Getters
  Tournament? get tournament => _tournament;
  TournamentGame? get currentGame => _currentGame;
  bool get isLoading => _isLoading;
  String? get error => _error;
  
  // Game readiness getters
  String? get readyGameId => _readyGameId;
  String? get readyMatchId => _readyMatchId;
  String? get readyTournamentId => _readyTournamentId;
  bool get hasReadyGame => _readyGameId != null && _readyMatchId != null && _readyTournamentId != null;
  
  // Current match getter - returns the match for the current game
  TournamentMatch? get currentMatch {
    if (_tournament == null || _currentGame == null) return null;
    
    try {
      return _tournament!.matches.firstWhere(
        (match) => match.gameIds.contains(_currentGame!.id),
      );
    } catch (e) {
      AppLogger.error('Current match not found for game: ${_currentGame!.id}');
      return null;
    }
  }
  
  // Tournament status helpers
  bool get isWaiting => _tournament?.status == 'waiting';
  bool get isInProgress => _tournament?.status == 'in_progress';
  bool get isCompleted => _tournament?.status == 'completed';
  
  // Player helpers
  bool get isCreator => _tournament?.creatorId == getCurrentUserId();
  bool get isTournamentFull => _tournament?.players.length == 4;
  
  // Match helpers
  List<TournamentMatch> get semifinalMatches => 
      _tournament?.matches.where((m) => m.round == 1).toList() ?? [];
  
  TournamentMatch? get finalMatch => 
      _tournament?.matches.firstWhere((m) => m.round == 2, orElse: () => TournamentMatch(
        id: '',
        tournamentId: '',
        player1Id: '',
        player2Id: '',
        status: '',
        round: 0,
        matchNumber: 0,
        gameIds: [],
      ));
  
  // Current user ID helper
  String? getCurrentUserId() {
    // Use Firebase Auth to get the current user ID
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      return currentUser.uid;
    }
    
    // Fallback logic if Firebase Auth is not available
    AppLogger.warning('Firebase Auth currentUser is null, using fallback logic');
    
    // If we're in a game, we can determine the current user
    if (_currentGame != null) {
      return _currentGame!.currentTurn == 'X' 
          ? _currentGame!.player1Id 
          : _currentGame!.player2Id;
    }
    
    // Otherwise, we'll assume it's one of the players
    if (_tournament != null && _tournament!.players.isNotEmpty) {
      return _tournament!.players[0].id;
    }
    
    return null;
  }
  
  /// Get tournaments where the current user is a participant
  Future<List<Map<String, dynamic>>> getMyTournaments() async {
    _setLoading(true);
    _clearError();
    
    try {
      final userId = getCurrentUserId();
      if (userId == null) {
        return [];
      }
      
      // The service now directly returns the tournament data we need
      final tournaments = await _tournamentService.getUserTournaments(userId);
      return tournaments;
    } catch (e) {
      _setError('Failed to get tournaments: ${e.toString()}');
      return [];
    } finally {
      _setLoading(false);
    }
  }
  
  /// Create a new tournament
  Future<String?> createTournament() async {
    _setLoading(true);
    _clearError();
    
    try {
      final tournamentId = await _tournamentService.createTournament(
      );
      _subscribeTournament(tournamentId);
      return tournamentId;
    } catch (e) {
      _setError('Failed to create tournament: ${e.toString()}');
      return null;
    } finally {
      _setLoading(false);
    }
  }
  
  /// Create a test tournament with computer players
  /// This is a convenience method for testing tournaments
  Future<String?> createTestTournament() async {
    return createTournament();
  }
  
  
  /// Join a tournament with a code
  Future<String?> joinTournamentByCode(String code) async {
    _setLoading(true);
    _clearError();
    
    try {
      final tournamentId = await _tournamentService.joinTournamentWithCode(code);
      _subscribeTournament(tournamentId);
      return tournamentId;
    } catch (e) {
      _setError('Failed to join tournament: ${e.toString()}');
      return null;
    } finally {
      _setLoading(false);
    }
  }
  
  /// Leave the current tournament
  Future<void> leaveTournament() async {
    if (_tournament == null) return;
    
    _setLoading(true);
    _clearError();
    
    try {
      final tournamentId = _tournament!.id;
      final isCreator = _tournament?.creatorId == getCurrentUserId();
      
      // First unsubscribe to prevent errors when the tournament is deleted
      _unsubscribeTournament();
      _tournament = null;
      notifyListeners();
      
      // Then leave the tournament
      await _tournamentService.leaveTournament(tournamentId);
      
      // Log the action
      if (isCreator) {
        AppLogger.info('Successfully left and deleted tournament: $tournamentId');
      } else {
        AppLogger.info('Successfully left tournament: $tournamentId');
      }
    } catch (e) {
      _setError('Failed to leave tournament: ${e.toString()}');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }
  
  /// Start the tournament (creator only)
  Future<void> startTournament() async {
    if (_tournament == null) return;
    
    _setLoading(true);
    _clearError();
    
    try {
      await _tournamentService.startTournament(_tournament!.id);
    } catch (e) {
      _setError('Failed to start tournament: ${e.toString()}');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }
  
  /// Mark player as ready for a match
  Future<void> markPlayerReady(String tournamentId, String matchId) async {
    _setLoading(true);
    _clearError();
    
    try {
      await _tournamentService.markPlayerReady(tournamentId, matchId);
      
      // Reload the tournament data to ensure UI reflects the latest state
      await loadTournament(tournamentId);
      
      // Start listening for new games in this match
      _listenForNewGames(tournamentId, matchId);
      
      AppLogger.info('Player marked as ready for match: $matchId');
    } catch (e) {
      _setError('Failed to mark player as ready: ${e.toString()}');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }
  
  /// Listen for new games in a match
  void _listenForNewGames(String tournamentId, String matchId) {
    AppLogger.info('Starting to listen for new games in match: $matchId');
    
    // Cancel any existing subscription
    _gamesSubscription?.cancel();
    
    try {
      // First check if there's already a game for this match in the tournament data
      if (_tournament != null) {
        final match = _tournament!.matches.firstWhere(
          (m) => m.id == matchId,
          orElse: () => TournamentMatch(
            id: '',
            tournamentId: '',
            player1Id: '',
            player2Id: '',
            status: '',
            round: 0,
            matchNumber: 0,
            gameIds: [],
          ),
        );
        
        if (match.id.isNotEmpty && match.gameIds.isNotEmpty) {
          // Game already exists, use it
          final gameId = match.gameIds.last;
          AppLogger.info('Using existing game: $gameId for match: $matchId');
          _setReadyGame(tournamentId, matchId, gameId);
          return;
        }
      }
      
      // Listen for games in this match
      _gamesSubscription = FirebaseFirestore.instance
          .collection('tournament_games')
          .where('tournament_id', isEqualTo: tournamentId)
          .where('match_id', isEqualTo: matchId)
          .orderBy('created_at', descending: true)
          .limit(1)
          .snapshots()
          .listen((snapshot) {
            if (snapshot.docs.isNotEmpty) {
              final gameDoc = snapshot.docs.first;
              final gameData = gameDoc.data();
              final gameId = gameData['id'] as String;
              
              AppLogger.info('New game detected: $gameId for match: $matchId');
              
              // Set this game as ready
              _setReadyGame(tournamentId, matchId, gameId);
            }
          }, onError: (error) {
            AppLogger.error('Error listening for new games: $error');
            // If there's an error with the subscription, fall back to checking tournament data
            _checkForExistingGamesInTournament(tournamentId, matchId);
          });
    } catch (e) {
      AppLogger.error('Error setting up game listener: $e');
      // If there's an error, fall back to checking tournament data
      _checkForExistingGamesInTournament(tournamentId, matchId);
    }
  }
  
  /// Set a game as ready
  void _setReadyGame(String tournamentId, String matchId, String gameId) {
    AppLogger.info('Setting game as ready - tournamentId: $tournamentId, matchId: $matchId, gameId: $gameId');
    
    // Reset navigation flag in case it was set to true previously
    // This ensures navigation can happen again if needed
    if (_tournament != null) {
      for (final match in _tournament!.matches) {
        if (match.id == matchId && match.gameIds.contains(gameId)) {
          AppLogger.info('Found match and game in tournament data, ready for navigation');
        }
      }
    }
    
    _readyTournamentId = tournamentId;
    _readyMatchId = matchId;
    _readyGameId = gameId;
    
    // Force a rebuild to trigger navigation
    notifyListeners();
    
    // Log the state after setting
    AppLogger.info('Game readiness state - hasReadyGame: $hasReadyGame, readyGameId: $_readyGameId');
  }
  
  /// Load a specific tournament
  Future<void> loadTournament(String tournamentId) async {
    _setLoading(true);
    _clearError();
    
    try {
      _subscribeTournament(tournamentId);
    } catch (e) {
      _setError('Failed to load tournament: ${e.toString()}');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }
  
  /// Load a specific game
  Future<void> loadGame(String gameId) async {
    _setLoading(true);
    _clearError();
    
    try {
      // First unsubscribe from any existing game to clean up properly
      _unsubscribeGame();
      
      // Clear the current game before loading a new one
      _currentGame = null;
      
      // Subscribe to the new game
      _subscribeGame(gameId);
      
      AppLogger.info('Loaded game: $gameId');
    } catch (e) {
      _setError('Failed to load game: ${e.toString()}');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }
  
  /// Get a match by ID
  TournamentMatch? getMatchById(String matchId) {
    if (_tournament == null) return null;
    
    try {
      return _tournament!.matches.firstWhere(
        (match) => match.id == matchId,
      );
    } catch (e) {
      AppLogger.error('Match not found: $matchId');
      return null;
    }
  }
  
  /// Get a player by ID
  TournamentPlayer? getPlayerById(String playerId) {
    if (_tournament == null || playerId.isEmpty) return null;
    
    try {
      return _tournament!.players.firstWhere(
        (player) => player.id == playerId,
      );
    } catch (e) {
      AppLogger.error('Player not found: $playerId');
      return null;
    }
  }
  
  /// Get the current user's match in the tournament
  TournamentMatch? getCurrentUserMatch() {
    if (_tournament == null) return null;
    final userId = getCurrentUserId();
    if (userId == null) return null;
    
    try {
      // First check for matches in progress
      final inProgressMatch = _tournament!.matches.firstWhere(
        (match) => match.status == 'in_progress' && 
                  (match.player1Id == userId || match.player2Id == userId),
        orElse: () => TournamentMatch(
          id: '',
          tournamentId: '',
          player1Id: '',
          player2Id: '',
          status: '',
          round: 0,
          matchNumber: 0,
          gameIds: [],
        ),
      );
      
      if (inProgressMatch.id.isNotEmpty) {
        return inProgressMatch;
      }
      
      // Then check for waiting matches
      return _tournament!.matches.firstWhere(
        (match) => match.status == 'waiting' && 
                  (match.player1Id == userId || match.player2Id == userId),
        orElse: () => TournamentMatch(
          id: '',
          tournamentId: '',
          player1Id: '',
          player2Id: '',
          status: '',
          round: 0,
          matchNumber: 0,
          gameIds: [],
        ),
      );
    } catch (e) {
      AppLogger.error('Error finding current user match: ${e.toString()}');
      return null;
    }
  }
  
  /// Check if the current user is ready for a match
  bool isCurrentUserReady(String matchId) {
    final match = getMatchById(matchId);
    if (match == null) return false;
    
    final userId = getCurrentUserId();
    if (userId == null) return false;
    
    if (match.player1Id == userId) {
      return match.player1Ready;
    } else if (match.player2Id == userId) {
      return match.player2Ready;
    }
    
    return false;
  }
  
  /// Subscribe to tournament updates
  void _subscribeTournament(String tournamentId) {
    // Unsubscribe from any existing tournament
    _unsubscribeTournament();
    
    // Subscribe to new tournament
    _tournamentSubscription = _tournamentService
        .getTournamentStream(tournamentId)
        .listen(
          _onTournamentUpdate,
          onError: (error) {
            _setError('Tournament update error: $error');
            // If tournament not found, clean up the state
            if (error.toString().contains('Tournament not found')) {
              _tournament = null;
              _unsubscribeTournament();
              notifyListeners();
            }
          },
        );
  }
  
  /// Subscribe to game updates
  void _subscribeGame(String gameId) {
    // Unsubscribe from any existing game
    _unsubscribeGame();
    
    // Subscribe to new game
    _gameSubscription = _tournamentService
        .getGameStream(gameId)
        .listen(
          _onGameUpdate,
          onError: (error) {
            _setError('Game update error: $error');
            AppLogger.error('Error in game subscription: $error');
          },
        );
    
    AppLogger.info('Subscribed to game updates for game: $gameId');
  }
  
  /// Handle tournament updates
  void _onTournamentUpdate(Tournament tournament) {
    final oldStatus = _tournament?.status;
    _tournament = tournament;
    
    AppLogger.info('Tournament update received: ${tournament.id}, status: ${tournament.status}');
    
    // Check if there's a current user match that might be ready for a game
    final currentUserMatch = getCurrentUserMatch();
    if (currentUserMatch != null) {
      AppLogger.info('Current user match: ${currentUserMatch.id}, player1Ready: ${currentUserMatch.player1Ready}, player2Ready: ${currentUserMatch.player2Ready}, gameIds: ${currentUserMatch.gameIds}');
      
      if (currentUserMatch.player1Ready && currentUserMatch.player2Ready) {
        AppLogger.info('Both players are ready for match: ${currentUserMatch.id}');
        
        if (currentUserMatch.gameIds.isNotEmpty) {
          // Game is ready
          final gameId = currentUserMatch.gameIds.last;
          AppLogger.info('Game is available for ready match: $gameId');
          _setReadyGame(tournament.id, currentUserMatch.id, gameId);
        } else {
          AppLogger.info('Both players ready but no game available yet for match: ${currentUserMatch.id}');
          
          // Start listening for new games in this match
          _listenForNewGames(tournament.id, currentUserMatch.id);
          
          // Also check if we need to manually create a game
          _checkAndCreateGameIfNeeded(tournament.id, currentUserMatch.id);
        }
      }
    } else {
      AppLogger.info('No current user match found in tournament');
    }
    
    notifyListeners();
    
    // Only log when status changes to reduce noise
    if (oldStatus != tournament.status) {
      AppLogger.info('Tournament status changed: ${tournament.id}, status: ${tournament.status}');
    }
  }
  
  /// Handle game updates
  void _onGameUpdate(TournamentGame game) {
    final oldStatus = _currentGame?.status;
    _currentGame = game;
    notifyListeners();
    
    // Only log when status changes to reduce noise
    if (oldStatus != game.status) {
      AppLogger.info('Game status changed: ${game.id}, status: ${game.status}');
    }
    
    // Don't immediately unsubscribe when a game is completed
    // This allows the UI to properly display the final game state
    // The subscription will be properly managed when loading the next game
  }
  
  /// Unsubscribe from tournament updates
  void _unsubscribeTournament() {
    _tournamentSubscription?.cancel();
    _tournamentSubscription = null;
  }
  
  /// Unsubscribe from game updates
  void _unsubscribeGame() {
    _gameSubscription?.cancel();
    _gameSubscription = null;
    // Don't set _currentGame to null here, as we want to preserve the game state
    // until a new game is explicitly loaded
    AppLogger.info('Unsubscribed from game updates');
  }
  
  /// Set loading state
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
  
  /// Set error message
  void _setError(String error) {
    _error = error;
    AppLogger.error(error);
    notifyListeners();
  }
  
  /// Clear error message
  void _clearError() {
    _error = null;
    notifyListeners();
  }
  
  
  /// Check for existing games in tournament data
  void _checkForExistingGamesInTournament(String tournamentId, String matchId) {
    if (_tournament == null) return;
    
    try {
      final match = _tournament!.matches.firstWhere(
        (m) => m.id == matchId,
        orElse: () => TournamentMatch(
          id: '',
          tournamentId: '',
          player1Id: '',
          player2Id: '',
          status: '',
          round: 0,
          matchNumber: 0,
          gameIds: [],
        ),
      );
      
      if (match.id.isNotEmpty && match.gameIds.isNotEmpty) {
        // Game already exists, use it
        final gameId = match.gameIds.last;
        AppLogger.info('Found existing game in tournament data: $gameId for match: $matchId');
        _setReadyGame(tournamentId, matchId, gameId);
      }
    } catch (e) {
      AppLogger.error('Error checking for existing games: $e');
    }
  }
  
  /// Check if we need to manually create a game when both players are ready
  Future<void> _checkAndCreateGameIfNeeded(String tournamentId, String matchId) async {
    try {
      // Wait a bit to see if the game is created automatically
      await Future.delayed(const Duration(seconds: 2));
      
      // Reload tournament data
      final tournamentDoc = await FirebaseFirestore.instance.collection('tournaments').doc(tournamentId).get();
      if (!tournamentDoc.exists) return;
      
      final tournamentData = tournamentDoc.data() as Map<String, dynamic>;
      final matches = (tournamentData['matches'] as List<dynamic>?) ?? [];
      final matchIndex = matches.indexWhere((match) => match['id'] == matchId);
      
      if (matchIndex == -1) return;
      
      final match = matches[matchIndex];
      final bothPlayersReady = match['player1_ready'] == true && match['player2_ready'] == true;
      final noGames = match['game_ids'] == null || (match['game_ids'] as List<dynamic>).isEmpty;
      
      if (bothPlayersReady && noGames) {
        AppLogger.info('Both players ready but no game created yet. Directly creating game for match: $matchId');
        
        // Directly create a game using the public method
        final gameId = await _tournamentService.createGameForMatch(tournamentId, matchId);
        
        // Update the match with the new game ID
        matches[matchIndex]['game_ids'] = [gameId];
        await FirebaseFirestore.instance.collection('tournaments').doc(tournamentId).update({
          'matches': matches,
        });
        
        // Set the game as ready to trigger navigation
        _setReadyGame(tournamentId, matchId, gameId);
        
        AppLogger.info('Game created successfully: $gameId');
      }
    } catch (e) {
      AppLogger.error('Error checking and creating game: $e');
    }
  }
  
  @override
  void dispose() {
    _unsubscribeTournament();
    _unsubscribeGame();
    _gamesSubscription?.cancel();
    super.dispose();
  }
}
