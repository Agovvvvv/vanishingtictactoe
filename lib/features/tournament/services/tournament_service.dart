import 'dart:async';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:vanishingtictactoe/core/utils/app_logger.dart';
import 'package:vanishingtictactoe/core/utils/win_checker.dart';
import 'package:vanishingtictactoe/features/tournament/models/tournament_game.dart';
import 'package:vanishingtictactoe/features/tournament/models/tournament_match.dart';
import 'package:vanishingtictactoe/features/tournament/models/tournament_model.dart';
import 'package:vanishingtictactoe/features/tournament/models/tournament_player.dart';
import 'package:vanishingtictactoe/features/tournament/services/tournament_game_end_service.dart';

/// Service for managing tournaments
class TournamentService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Collection references
  final CollectionReference _tournamentsCollection;
  
  // Constructor
  TournamentService() 
    : _tournamentsCollection = FirebaseFirestore.instance.collection('tournaments');
  
  /// Create a new tournament
  Future<String> createTournament({bool addComputerPlayers = false}) async {
    if (_auth.currentUser == null) {
      throw Exception('You must be logged in to create a tournament');
    }

    try {
      final userId = _auth.currentUser!.uid;
      final username = _auth.currentUser!.displayName ?? 'Player';
      
      // Generate a random 6-character code
      final code = _generateTournamentCode();
      
      // Create tournament document
      final tournamentRef = _tournamentsCollection.doc();
      final tournamentId = tournamentRef.id;
      
      // Create initial player (creator)
      final creator = TournamentPlayer(
        id: userId,
        name: username,
        seed: 1, // Creator is always seed 1
        isReady: false,
      );
      
      // Initialize players list with creator
      final List<Map<String, dynamic>> players = [creator.toMap()];
      
      
      // Create tournament data
      final tournamentData = {
        'creator_id': userId,
        'status': 'waiting',
        'created_at': FieldValue.serverTimestamp(),
        'code': code,
        'players': players,
        'matches': [],
      };
      
      // Save to Firestore
      await tournamentRef.set(tournamentData);
      
      AppLogger.info('Created tournament with ID: $tournamentId and code: $code');
      return tournamentId;
    } catch (e) {
      AppLogger.error('Error creating tournament: $e');
      throw Exception('Failed to create tournament: ${e.toString()}');
    }
  }
  
  /// Join a tournament using a code
  Future<String> joinTournamentWithCode(String code) async {
    if (_auth.currentUser == null) {
      throw Exception('You must be logged in to join a tournament');
    }
    
    try {
      final userId = _auth.currentUser!.uid;
      final username = _auth.currentUser!.displayName ?? 'Player';
      
      // Find tournament with this code
      final querySnapshot = await _tournamentsCollection
          .where('code', isEqualTo: code)
          .where('status', isEqualTo: 'waiting')
          .limit(1)
          .get();
      
      if (querySnapshot.docs.isEmpty) {
        throw Exception('Tournament not found or already started');
      }
      
      final tournamentDoc = querySnapshot.docs.first;
      final tournamentId = tournamentDoc.id;
      final tournamentData = tournamentDoc.data() as Map<String, dynamic>;
      
      // Check if tournament is full (max 4 players)
      final players = (tournamentData['players'] as List<dynamic>?) ?? [];
      if (players.length >= 4) {
        throw Exception('Tournament is already full');
      }
      
      // Check if player is already in the tournament
      final isPlayerAlreadyJoined = players.any((player) => player['id'] == userId);
      if (isPlayerAlreadyJoined) {
        AppLogger.info('Player already joined tournament: $tournamentId');
        return tournamentId;
      }
      
      // Create new player
      final newPlayer = TournamentPlayer(
        id: userId,
        name: username,
        seed: players.length + 1, // Assign next seed number
        isReady: false,
      );
      
      // Add player to tournament
      await tournamentDoc.reference.update({
        'players': FieldValue.arrayUnion([newPlayer.toMap()]),
      });
      
      AppLogger.info('Joined tournament with ID: $tournamentId');
      return tournamentId;
    } catch (e) {
      AppLogger.error('Error joining tournament: $e');
      throw Exception('Failed to join tournament: ${e.toString()}');
    }
  }
  
  /// Leave a tournament
  Future<void> leaveTournament(String tournamentId) async {
    if (_auth.currentUser == null) {
      throw Exception('You must be logged in to leave a tournament');
    }
    
    try {
      final userId = _auth.currentUser!.uid;
      
      // Get tournament
      final tournamentDoc = await _tournamentsCollection.doc(tournamentId).get();
      if (!tournamentDoc.exists) {
        throw Exception('Tournament not found');
      }
      
      final tournamentData = tournamentDoc.data() as Map<String, dynamic>;
      
      // Check tournament status
      if (tournamentData['status'] != 'waiting') {
        throw Exception('Cannot leave a tournament that has already started');
      }
      
      // Check if player is the creator
      if (tournamentData['creator_id'] == userId) {
        // If creator leaves, delete the tournament
        await tournamentDoc.reference.delete();
        AppLogger.info('Creator left and deleted tournament: $tournamentId');
      } else {
        // Remove player from tournament
        final players = (tournamentData['players'] as List<dynamic>?) ?? [];
        final updatedPlayers = players.where((player) => player['id'] != userId).toList();
        
        // Update seeds if necessary
        for (int i = 0; i < updatedPlayers.length; i++) {
          updatedPlayers[i]['seed'] = i + 1;
        }
        
        await tournamentDoc.reference.update({
          'players': updatedPlayers,
        });
        
        AppLogger.info('Left tournament: $tournamentId');
      }
    } catch (e) {
      AppLogger.error('Error leaving tournament: $e');
      throw Exception('Failed to leave tournament: ${e.toString()}');
    }
  }
  
  /// Get tournaments where the user is a participant
  Future<List<Map<String, dynamic>>> getUserTournaments(String userId) async {
    try {
      List<Map<String, dynamic>> allTournaments = [];
      
      // First query tournaments where user is a participant in the players array
      final playerQuerySnapshot = await _tournamentsCollection
          .where('players', arrayContains: {'id': userId})
          .orderBy('created_at', descending: true)
          .get();
      
      // Then query tournaments where user is the creator
      final creatorQuerySnapshot = await _tournamentsCollection
          .where('creator_id', isEqualTo: userId)
          .orderBy('created_at', descending: true)
          .get();
      
      // Process player tournaments
      for (var doc in playerQuerySnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        allTournaments.add({
          'id': doc.id,
          'status': data['status'] ?? 'unknown',
          'playerCount': (data['players'] as List<dynamic>?)?.length ?? 0,
          'createdAt': data['created_at']?.toDate().toString() ?? 'Unknown',
          'code': data['code'] ?? '',
          'creator_id': data['creator_id'] ?? '',
          'players': data['players'] ?? [],
        });
      }
      
      // Process creator tournaments (avoid duplicates)
      for (var doc in creatorQuerySnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final tournamentId = doc.id;
        
        // Check if we already added this tournament
        if (!allTournaments.any((t) => t['id'] == tournamentId)) {
          allTournaments.add({
            'id': tournamentId,
            'status': data['status'] ?? 'unknown',
            'playerCount': (data['players'] as List<dynamic>?)?.length ?? 0,
            'createdAt': data['created_at']?.toDate().toString() ?? 'Unknown',
            'code': data['code'] ?? '',
            'creator_id': data['creator_id'] ?? '',
            'players': data['players'] ?? [],
          });
        }
      }
      
      // Sort by created date (most recent first)
      allTournaments.sort((a, b) {
        final aDate = DateTime.tryParse(a['createdAt'] ?? '') ?? DateTime(1970);
        final bDate = DateTime.tryParse(b['createdAt'] ?? '') ?? DateTime(1970);
        return bDate.compareTo(aDate);
      });
      
      AppLogger.info('Found ${allTournaments.length} tournaments for user $userId');
      return allTournaments;
    } catch (e) {
      AppLogger.error('Error getting user tournaments: $e');
      return [];
    }
  }
  
  /// Start a tournament (creator only)
  Future<void> startTournament(String tournamentId) async {
    if (_auth.currentUser == null) {
      throw Exception('You must be logged in to start a tournament');
    }
    
    try {
      final userId = _auth.currentUser!.uid;
      
      // Get tournament
      final tournamentDoc = await _tournamentsCollection.doc(tournamentId).get();
      if (!tournamentDoc.exists) {
        throw Exception('Tournament not found');
      }
      
      final tournamentData = tournamentDoc.data() as Map<String, dynamic>;
      
      // Check if user is the creator
      if (tournamentData['creator_id'] != userId) {
        throw Exception('Only the tournament creator can start the tournament');
      }
      
      // Check tournament status
      if (tournamentData['status'] != 'waiting') {
        throw Exception('Tournament has already started or is completed');
      }
      
      // Check if there are exactly 4 players
      final players = (tournamentData['players'] as List<dynamic>?) ?? [];
      if (players.length != 4) {
        throw Exception('Tournament requires exactly 4 players to start');
      }
      
      // Randomize player seeds for bracket positioning
      final List<Map<String, dynamic>> randomizedPlayers = List.from(players);
      randomizedPlayers.shuffle(Random());
      
      // Reassign seeds
      for (int i = 0; i < randomizedPlayers.length; i++) {
        randomizedPlayers[i]['seed'] = i + 1;
      }
      
      // Create semifinal matches
      final List<Map<String, dynamic>> matches = [];
      
      // Semifinal 1: Seed 1 vs Seed 4
      final semifinal1 = TournamentMatch(
        id: '${tournamentId}_sf1',
        tournamentId: tournamentId,
        player1Id: randomizedPlayers[0]['id'],
        player2Id: randomizedPlayers[3]['id'],
        status: 'waiting',
        round: 1,
        matchNumber: 1,
        gameIds: [],
      ).toMap();
      
      // Semifinal 2: Seed 2 vs Seed 3
      final semifinal2 = TournamentMatch(
        id: '${tournamentId}_sf2',
        tournamentId: tournamentId,
        player1Id: randomizedPlayers[1]['id'],
        player2Id: randomizedPlayers[2]['id'],
        status: 'waiting',
        round: 1,
        matchNumber: 2,
        gameIds: [],
      ).toMap();
      
      matches.add(semifinal1);
      matches.add(semifinal2);
      
      // Create final match (players will be filled in later)
      final final1 = TournamentMatch(
        id: '${tournamentId}_final',
        tournamentId: tournamentId,
        player1Id: '',  // To be determined
        player2Id: '',  // To be determined
        status: 'waiting',
        round: 2,
        matchNumber: 1,
        gameIds: [],
      ).toMap();
      
      matches.add(final1);
      
      // Update tournament
      await tournamentDoc.reference.update({
        'status': 'in_progress',
        'started_at': FieldValue.serverTimestamp(),
        'players': randomizedPlayers,
        'matches': matches,
      });
      
      AppLogger.info('Started tournament: $tournamentId');
    } catch (e) {
      AppLogger.error('Error starting tournament: $e');
      throw Exception('Failed to start tournament: ${e.toString()}');
    }
  }
  
  /// Mark a player as ready for a match
  Future<void> markPlayerReady(String tournamentId, String matchId) async {
    if (_auth.currentUser == null) {
      throw Exception('You must be logged in to play in a tournament');
    }
    
    try {
      final userId = _auth.currentUser!.uid;
      
      // Use a transaction to prevent race conditions
      await _firestore.runTransaction((transaction) async {
        // Get the latest tournament data
        final tournamentDoc = await transaction.get(_tournamentsCollection.doc(tournamentId));
        
        if (!tournamentDoc.exists) {
          throw Exception('Tournament not found');
        }
        
        final tournamentData = tournamentDoc.data() as Map<String, dynamic>;
        
        // Check tournament status
        if (tournamentData['status'] != 'in_progress') {
          throw Exception('Tournament is not in progress');
        }
        
        // Find the match
        final matches = (tournamentData['matches'] as List<dynamic>?) ?? [];
        final matchIndex = matches.indexWhere((match) => match['id'] == matchId);
        
        if (matchIndex == -1) {
          throw Exception('Match not found');
        }
        
        final match = matches[matchIndex];
        
        // Check if player is part of this match
        final isPlayer1 = match['player1_id'] == userId;
        final isPlayer2 = match['player2_id'] == userId;
        
        if (!isPlayer1 && !isPlayer2) {
          throw Exception('You are not a participant in this match');
        }
        
        // Mark player as ready
        if (isPlayer1) {
          matches[matchIndex]['player1_ready'] = true;
        } else {
          matches[matchIndex]['player2_ready'] = true;
        }
        
        // Check if both players are ready
        final bothPlayersReady = matches[matchIndex]['player1_ready'] == true && 
                               matches[matchIndex]['player2_ready'] == true;
        
        // Update match status if both players are ready
        if (bothPlayersReady && match['status'] == 'waiting') {
          matches[matchIndex]['status'] = 'in_progress';
        }
        
        // Update tournament with the new match data
        transaction.update(_tournamentsCollection.doc(tournamentId), {
          'matches': matches,
        });
        
        // Return whether we need to create a game
        return bothPlayersReady && match['status'] == 'waiting';
      });
      
      // If both players are ready, create a new game (outside the transaction)
      final tournamentDoc = await _tournamentsCollection.doc(tournamentId).get();
      final tournamentData = tournamentDoc.data() as Map<String, dynamic>;
      final matches = (tournamentData['matches'] as List<dynamic>?) ?? [];
      final matchIndex = matches.indexWhere((match) => match['id'] == matchId);
      
      if (matchIndex != -1) {
        final match = matches[matchIndex];
        final bothPlayersReady = match['player1_ready'] == true && match['player2_ready'] == true;
        
        if (bothPlayersReady && (match['game_ids'] == null || (match['game_ids'] as List<dynamic>).isEmpty)) {
          // Create a new game for this match
          final gameId = await _createGame(tournamentId, matchId);
          
          // Add game to match by updating the entire matches array
          // This is safer with Firestore security rules
          matches[matchIndex]['game_ids'] = [...(match['game_ids'] as List<dynamic>? ?? []), gameId];
          
          await _tournamentsCollection.doc(tournamentId).update({
            'matches': matches,
          });
        }
      }
      
      AppLogger.info('Player $userId marked as ready for match $matchId');
    } catch (e) {
      AppLogger.error('Error marking player ready: $e');
      throw Exception('Failed to mark player as ready: ${e.toString()}');
    }
  }
  
  /// Create a new game within a match
  Future<String> _createGame(String tournamentId, String matchId) async {
    try {
      // Get tournament
      final tournamentDoc = await _tournamentsCollection.doc(tournamentId).get();
      if (!tournamentDoc.exists) {
        throw Exception('Tournament not found');
      }
      
      final tournamentData = tournamentDoc.data() as Map<String, dynamic>;
      
      // Find the match
      final matches = (tournamentData['matches'] as List<dynamic>?) ?? [];
      final matchIndex = matches.indexWhere((match) => match['id'] == matchId);
      
      if (matchIndex == -1) {
        throw Exception('Match not found');
      }
      
      final match = matches[matchIndex];
      
      // Create game document
      final gameRef = _firestore.collection('tournament_games').doc();
      final gameId = gameRef.id;
      
      // Randomly decide who goes first
      final player1GoesFirst = Random().nextBool();
      final firstPlayerSymbol = player1GoesFirst ? 'X' : 'O';
      
      // Create game data with winner tracking
      final gameData = {
        'id': gameId,
        'match_id': matchId,
        'tournament_id': tournamentId,
        'player1_id': match['player1_id'],
        'player2_id': match['player2_id'],
        'status': 'in_progress',
        'board': List.filled(9, ''),
        'current_turn': firstPlayerSymbol,
        'created_at': FieldValue.serverTimestamp(),
        'winner_id': null,
        'winning_cells': [],
        'is_draw': false,
        'x_moves': [],
        'o_moves': [],
      };
      
      // Save to Firestore
      await gameRef.set(gameData);
      
      AppLogger.info('Created game $gameId for match $matchId');
      return gameId;
    } catch (e) {
      AppLogger.error('Error creating game: $e');
      throw Exception('Failed to create game: ${e.toString()}');
    }
  }
  
  /// Make a move in a tournament game
  Future<Map<String, dynamic>> makeMove(String gameId, int position) async {
    if (_auth.currentUser == null) {
      throw Exception('You must be logged in to play in a tournament');
    }
    
    try {
      final userId = _auth.currentUser!.uid;
      
      // Get game
      final gameDoc = await _firestore.collection('tournament_games').doc(gameId).get();
      if (!gameDoc.exists) {
        throw Exception('Game not found');
      }
      
      final gameData = gameDoc.data() as Map<String, dynamic>;
      
      // Check game status
      if (gameData['status'] != 'in_progress') {
        throw Exception('Game is not in progress');
      }
      
      // Check if it's the player's turn
      final player1Id = gameData['player1_id'];
      final player2Id = gameData['player2_id'];
      final currentTurn = gameData['current_turn'];
      final tournamentId = gameData['tournament_id'];
      final matchId = gameData['match_id'];
      
      final isPlayer1 = player1Id == userId;
      final isPlayer2 = player2Id == userId;
      
      if (!isPlayer1 && !isPlayer2) {
        throw Exception('You are not a participant in this game');
      }
      
      final playerSymbol = isPlayer1 ? 'X' : 'O';
      
      if (currentTurn != playerSymbol) {
        throw Exception('It is not your turn');
      }
      
      // Check if position is valid
      final board = List<String>.from(gameData['board']);
      if (position < 0 || position >= board.length || board[position].isNotEmpty) {
        throw Exception('Invalid move');
      }
      
      // Make the move
      board[position] = playerSymbol;
      
      // Track moves for vanishing effect
      List<int> xMoves = List<int>.from(gameData['x_moves'] ?? []);
      List<int> oMoves = List<int>.from(gameData['o_moves'] ?? []);
      
      // Add current move to the appropriate list
      if (playerSymbol == 'X') {
        xMoves.add(position);
      } else {
        oMoves.add(position);
      }
      
      // Apply vanishing effect after 6 total moves
      int? vanishedPosition;
      if ((xMoves.length + oMoves.length) > 6) {
        if (playerSymbol == 'X' && xMoves.length > 3) {
          vanishedPosition = xMoves.removeAt(0); // Remove oldest X move
          board[vanishedPosition] = ''; // Clear the position on the board
          AppLogger.info('Vanishing X move at position $vanishedPosition');
        } else if (playerSymbol == 'O' && oMoves.length > 3) {
          vanishedPosition = oMoves.removeAt(0); // Remove oldest O move
          board[vanishedPosition] = ''; // Clear the position on the board
          AppLogger.info('Vanishing O move at position $vanishedPosition');
        }
      }
      
      // Check for win or draw
      final isWin = WinChecker.checkWin(board, playerSymbol);
      final winner = isWin ? (playerSymbol == 'X' ? player1Id : player2Id) : null;
      final isDraw = WinChecker.isBoardFull(board) && winner == null;
      
      // Prepare result for UI notifications
      Map<String, dynamic> result = {
        'vanishedPosition': vanishedPosition,
        'gameCompleted': false,
        'matchCompleted': false,
        'tournamentCompleted': false,
        'winner': null,
        'isDraw': isDraw,
      };
      
      // Update game
      final updates = {
        'board': board,
        'last_move_at': FieldValue.serverTimestamp(),
        'x_moves': xMoves,
        'o_moves': oMoves,
      };
      
      if (winner != null || isDraw) {
        updates['status'] = 'completed';
        if (winner != null) {
          updates['winner_id'] = winner;
          result['winner'] = winner;
        }
        
        result['gameCompleted'] = true;
        
        // Get tournament and match data to check completion status
        final tournamentDoc = await _tournamentsCollection.doc(tournamentId).get();
        final tournamentData = tournamentDoc.data() as Map<String, dynamic>;
        final matches = (tournamentData['matches'] as List<dynamic>?) ?? [];
        final matchIndex = matches.indexWhere((match) => match['id'] == matchId);
        
        if (matchIndex != -1) {
          final match = matches[matchIndex];
          
          // Calculate new win counts
          int player1Wins = (match['player1_wins'] ?? 0) + (winner == player1Id ? 1 : 0);
          int player2Wins = (match['player2_wins'] ?? 0) + (winner == player2Id ? 1 : 0);
          
          // Check if match will be completed
          if (player1Wins >= 2 || player2Wins >= 2) {
            result['matchCompleted'] = true;
            String matchWinnerId = player1Wins > player2Wins ? player1Id : player2Id;
            result['matchWinner'] = matchWinnerId;
            
            // Check if this is a final match
            if (match['round'] == 2) {
              result['tournamentCompleted'] = true;
              result['tournamentWinner'] = matchWinnerId;
            }
          }
        }
        
        // Handle game completion
        await TournamentGameEndService().handleGameEnd(
          tournamentId: tournamentId,
          matchId: matchId,
          gameId: gameId,
          winnerId: winner, // This will be null for draws
        );
      } else {
        // Switch turns
        updates['current_turn'] = currentTurn == 'X' ? 'O' : 'X';
        
      }
      
      // Save to Firestore
      await gameDoc.reference.update(updates);
      
      AppLogger.info('Move made in game $gameId at position $position');
      return result;
    } catch (e) {
      AppLogger.error('Error making move: $e');
      throw Exception('Failed to make move: ${e.toString()}');
    }
  }
  
  /// Get tournament details stream
  Stream<Tournament> getTournamentStream(String tournamentId) {
    return _tournamentsCollection.doc(tournamentId).snapshots().map((snapshot) {
      if (!snapshot.exists) {
        throw Exception('Tournament not found');
      }
      
      final data = snapshot.data() as Map<String, dynamic>;
      return Tournament.fromMap(snapshot.id, data);
    });
  }
  
  /// Get game stream
  Stream<TournamentGame> getGameStream(String gameId) {
    return _firestore.collection('tournament_games').doc(gameId).snapshots().map((snapshot) {
      if (!snapshot.exists) {
        throw Exception('Game not found');
      }
      
      final data = snapshot.data() as Map<String, dynamic>;
      return TournamentGame.fromMap(data);
    });
  }
  
  /// Generate a random 6-character tournament code
  String _generateTournamentCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random();
    return List.generate(6, (index) => chars[random.nextInt(chars.length)]).join();
  }
}
