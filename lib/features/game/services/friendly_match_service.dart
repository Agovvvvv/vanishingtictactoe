import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:vanishingtictactoe/core/utils/app_logger.dart';
import 'dart:developer' as developer;
import 'package:vanishingtictactoe/shared/models/match.dart';
import 'package:vanishingtictactoe/core/utils/win_checker.dart';

class FriendlyMatchService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final CollectionReference _friendlyMatches;
  final CollectionReference _activeMatches;

  FriendlyMatchService() 
    : _friendlyMatches = FirebaseFirestore.instance.collection('friendlyMatches'),
      _activeMatches = FirebaseFirestore.instance.collection('active_matches');

  // Create a new match with a given code
  Future<void> createMatch({
    required String matchCode,
    required String hostId,
    required String hostName,
  }) async {
    try {
      // Check if match already exists
      final existingMatch = await _friendlyMatches.doc(matchCode).get();
      if (existingMatch.exists) {
        // If match exists but is old, we can overwrite it
        final data = existingMatch.data() as Map<String, dynamic>?;
        if (data != null) {
          final createdAt = data['createdAt'] as Timestamp?;
          final now = Timestamp.now();
          
          // If match is less than 1 hour old and not created by this user, don't overwrite
          if (createdAt != null && 
              now.seconds - createdAt.seconds < 3600 && 
              data['hostId'] != hostId) {
            throw Exception('Match code already in use');
          }
        }
      }
      
      // Create or update the match
      await _friendlyMatches.doc(matchCode).set({
        'hostId': hostId,
        'hostName': hostName,
        'guestId': null,
        'guestName': null,
        'createdAt': FieldValue.serverTimestamp(),
        'status': 'waiting',
        'matchCode': matchCode,
      });
      AppLogger.debug('Created match with code: $matchCode');
    } catch (e) {
      AppLogger.error('Error creating match: $e');
      throw Exception('Failed to create match: ${e.toString()}');
    }
  }

  // Join an existing match
  Future<String> joinMatch({
    required String matchCode,
    required String guestId,
    required String guestName,
  }) async {
    try {
      // Check if match exists and is waiting
      final matchDoc = await _friendlyMatches.doc(matchCode).get();
      
      if (!matchDoc.exists) {
        throw Exception('Match not found');
      }
      
      final matchData = matchDoc.data() as Map<String, dynamic>?;
      if (matchData == null || matchData['status'] != 'waiting') {
        throw Exception('Match is not available');
      }

      final hostId = matchData['hostId'] as String;
      final hostName = matchData['hostName'] as String;
      
      // Create an active match in the same format as online matches
      final activeMatchRef = _activeMatches.doc();
      final activeMatchId = activeMatchRef.id;
      
      // Randomly decide who plays X (goes first)
      // Host always plays X for simplicity
      
      // Create the active match
      await activeMatchRef.set({
        'player1': {
          'id': hostId,
          'name': hostName,
          'symbol': 'X'
        },
        'player2': {
          'id': guestId,
          'name': guestName,
          'symbol': 'O'
        },
        'board': List.filled(9, ''),
        'currentTurn': 'X', // X always goes first
        'status': 'active',
        'winner': '',
        'createdAt': FieldValue.serverTimestamp(),
        'lastMoveAt': FieldValue.serverTimestamp(),
        'matchType': 'friendly',
        'matchCode': matchCode,
      });
      
      // Update the friendly match to point to the active match
      await _friendlyMatches.doc(matchCode).update({
        'guestId': guestId,
        'guestName': guestName,
        'status': 'active',
        'joinedAt': FieldValue.serverTimestamp(),
        'activeMatchId': activeMatchId,
      });
      
      AppLogger.debug('Joined match with code: $matchCode, active match ID: $activeMatchId');
      return activeMatchId;
    } catch (e) {
      AppLogger.error('Error joining match: $e');
      throw Exception('Failed to join match: ${e.toString()}');
    }
  }

  // Get match data
  Future<Map<String, dynamic>?> getMatch(String matchCode) async {
    try {
      final matchDoc = await _friendlyMatches.doc(matchCode).get();
      
      if (!matchDoc.exists) {
        return null;
      }
      
      return matchDoc.data() as Map<String, dynamic>?;
    } catch (e) {
      AppLogger.error('Error getting match: $e');
      throw Exception('Failed to get match: ${e.toString()}');
    }
  }

  // Get active match data
  Future<GameMatch?> getActiveMatch(String activeMatchId) async {
    try {
      final matchDoc = await _activeMatches.doc(activeMatchId).get();
      
      if (!matchDoc.exists) {
        return null;
      }
      
      return GameMatch.fromFirestore(matchDoc.data() as Map<String, dynamic>?, activeMatchId);
    } catch (e) {
      AppLogger.error('Error getting active match: $e');
      throw Exception('Failed to get active match: ${e.toString()}');
    }
  }

  // Make a move in an active match
  Future<Map<String, dynamic>> makeMove(String activeMatchId, String playerId, int position) async {
    try {
      // Get the current match state first (outside transaction for optimistic updates)
      final matchDoc = await _activeMatches.doc(activeMatchId).get();
      if (!matchDoc.exists) {
        throw Exception('Match not found');
      }
      
      final matchData = matchDoc.data() as Map<String, dynamic>?;
      if (matchData == null) {
        throw Exception('Match data is null');
      }
      
      // Check if it's the player's turn
      final player1 = matchData['player1'] as Map<String, dynamic>;
      final player2 = matchData['player2'] as Map<String, dynamic>;
      final board = List<String>.from((matchData['board'] as List).map((e) => (e ?? '').toString()));
      final currentTurn = matchData['currentTurn'] as String;
      final status = matchData['status'] as String;
      
      // Validate move
      if (status != 'active') {
        throw Exception('Game is not active');
      }
      
      final playerSymbol = player1['id'] == playerId ? player1['symbol'] : player2['symbol'];
      if (playerSymbol != currentTurn) {
        throw Exception('Not your turn');
      }
      
      if (position < 0 || position >= 9) {
        throw Exception('Invalid position');
      }
      
      if (board[position].isNotEmpty) {
        throw Exception('Position already taken');
      }
      
      // Make the move
      board[position] = playerSymbol;
      
      // Check for win or draw BEFORE any vanishing effect
      String winner = '';
      bool isDraw = false;
      
      if (WinChecker.checkWin(board, 'X')) {
        winner = 'X';
      } else if (WinChecker.checkWin(board, 'O')) {
        winner = 'O';
      } 
      
      // Check for draw if no winner
      if (winner.isEmpty && !board.contains('')) {
        isDraw = true;
        developer.log('Draw detected - board is full with no winner');
      }
      
      // Calculate next turn
      final nextTurn = currentTurn == 'X' ? 'O' : 'X';
      
      // Create update data map
      final Map<String, dynamic> updateData = {
        'board': board,
        'currentTurn': nextTurn,
        'lastMoveAt': FieldValue.serverTimestamp(),
      };
      
      // If we have a winner or draw, update the status and winner fields
      if (winner.isNotEmpty || isDraw) {
        updateData['status'] = 'completed';
        updateData['winner'] = isDraw ? 'draw' : winner;
        developer.log('Setting game as completed with winner: ${isDraw ? "draw" : winner}');
      } else {
        updateData['status'] = 'active';
        updateData['winner'] = '';
      }
      
      // Create an optimistic update for immediate UI feedback
      // Replace FieldValue.serverTimestamp() with Timestamp.now() for client-side updates
      final clientUpdateData = Map<String, dynamic>.from(updateData);
      // Replace any FieldValue instances with actual values for client-side
      if (clientUpdateData.containsKey('lastMoveAt')) {
        clientUpdateData['lastMoveAt'] = Timestamp.now();
      }
      
      final optimisticUpdate = GameMatch.fromFirestore({
        ...matchData,
        ...clientUpdateData,
      }, activeMatchId);
      
      // Use a transaction to ensure atomic updates and prevent race conditions
      await _firestore.runTransaction((transaction) async {
        // Get the fresh match state
        final freshMatchDoc = await transaction.get(_activeMatches.doc(activeMatchId));
        if (!freshMatchDoc.exists) {
          throw Exception('Match not found');
        }
        
        final freshMatchData = freshMatchDoc.data() as Map<String, dynamic>?;
        if (freshMatchData == null) {
          throw Exception('Match data is null');
        }
        
        // Validate again with fresh data
        if (freshMatchData['status'] != 'active') {
          throw Exception('Game is no longer active');
        }
        
        final freshBoard = List<String>.from((freshMatchData['board'] as List).map((e) => (e ?? '').toString()));
        if (freshBoard[position].isNotEmpty) {
          throw Exception('Position already taken');
        }
        
        if (freshMatchData['currentTurn'] != playerSymbol) {
          throw Exception('Not your turn');
        }
        
        // Update the match in the transaction
        transaction.update(_activeMatches.doc(activeMatchId), updateData);
        
        developer.log('Move made in match $activeMatchId by player $playerId at position $position');
        developer.log('Game status: ${winner.isNotEmpty || isDraw ? "completed" : "active"}, Winner: ${isDraw ? "draw" : winner}');
      });
      
      // Return the optimistic update for immediate UI feedback
      return {
        'optimisticMatch': optimisticUpdate,
        'isCompleted': winner.isNotEmpty || isDraw
      };
    } catch (e) {
      developer.log('Error making move: $e', error: e);
      throw Exception('Failed to make move: ${e.toString()}');
    }
  }

  // Listen for updates to an active match
  Stream<GameMatch?> listenForActiveMatchUpdates(String activeMatchId) {
    return _activeMatches
        .doc(activeMatchId)
        .snapshots()
        .map((snapshot) => snapshot.exists
            ? GameMatch.fromFirestore(snapshot.data() as Map<String, dynamic>?, activeMatchId)
            : null);
  }

  // Listen for updates to a friendly match
  Stream<Map<String, dynamic>?> listenForMatchUpdates(String matchCode) {
    return _friendlyMatches
        .doc(matchCode)
        .snapshots()
        .map((snapshot) => snapshot.data() as Map<String, dynamic>?);
  }

  // Delete a match
  Future<void> deleteMatch(String matchCode) async {
    try {
      // Get the match to check if there's an active match to delete
      final matchDoc = await _friendlyMatches.doc(matchCode).get();
      if (matchDoc.exists) {
        final matchData = matchDoc.data() as Map<String, dynamic>?;
        if (matchData != null && matchData['activeMatchId'] != null) {
          // Delete the active match first
          await _activeMatches.doc(matchData['activeMatchId']).delete();
        }
      }
      
      // Delete the friendly match
      await _friendlyMatches.doc(matchCode).delete();
      developer.log('Deleted match with code: $matchCode');
    } catch (e) {
      developer.log('Error deleting match: $e', error: e);
      throw Exception('Failed to delete match: ${e.toString()}');
    }
  }

  // Clean up old matches (can be called periodically)
  Future<void> cleanupOldMatches() async {
    try {
      // Get matches older than 1 hour
      final cutoff = DateTime.now().subtract(const Duration(hours: 1));
      final snapshot = await _friendlyMatches
          .where('createdAt', isLessThan: cutoff)
          .get();
      
      // Delete old matches
      final batch = _firestore.batch();
      for (final doc in snapshot.docs) {
        final matchData = doc.data() as Map<String, dynamic>?;
        if (matchData != null && matchData['activeMatchId'] != null) {
          // Delete the active match first
          batch.delete(_activeMatches.doc(matchData['activeMatchId']));
        }
        batch.delete(doc.reference);
      }
      
      await batch.commit();
      developer.log('Cleaned up ${snapshot.docs.length} old matches');
    } catch (e) {
      developer.log('Error cleaning up old matches: $e', error: e);
    }
  }
  
  // Update match status (for game completion, surrender, etc.)
  Future<void> updateMatchStatus(
    String activeMatchId, {
    required String status,
    required String winner,
    bool surrendered = false,
  }) async {
    try {
      // Get the current match data
      final matchDoc = await _activeMatches.doc(activeMatchId).get();
      if (!matchDoc.exists) {
        throw Exception('Match not found');
      }
      
      // Update the match status
      final updateData = {
        'status': status,
        'winner': winner,
        'surrendered': surrendered,
        'lastMoveAt': FieldValue.serverTimestamp(),
      };
      
      await _activeMatches.doc(activeMatchId).update(updateData);
      
      // If this is a friendly match, also update the friendly match status
      final matchData = matchDoc.data() as Map<String, dynamic>?;
      if (matchData != null && matchData['matchType'] == 'friendly' && matchData['matchCode'] != null) {
        final matchCode = matchData['matchCode'] as String;
        await _friendlyMatches.doc(matchCode).update({
          'status': status == 'completed' ? 'completed' : 'active',
        });
      }
      
      AppLogger.debug('Updated match status: $activeMatchId, status=$status, winner=$winner, surrendered=$surrendered');
    } catch (e) {
      AppLogger.error('Error updating match status: $e');
      throw Exception('Failed to update match status: ${e.toString()}');
    }
  }
  
  // Restart a friendly match with the same players
  Future<String> restartFriendlyMatch(String matchCode) async {
    try {
      // Get the existing match data
      final matchDoc = await _friendlyMatches.doc(matchCode).get();
      if (!matchDoc.exists) {
        throw Exception('Match not found');
      }
      
      final matchData = matchDoc.data() as Map<String, dynamic>?;
      if (matchData == null) {
        throw Exception('Match data is null');
      }
      
      // Extract player information
      final hostId = matchData['hostId'] as String?;
      final hostName = matchData['hostName'] as String?;
      final guestId = matchData['guestId'] as String?;
      final guestName = matchData['guestName'] as String?;
      
      if (hostId == null || hostName == null || guestId == null || guestName == null) {
        throw Exception('Missing player information');
      }
      
      // Create a new active match with the same players
      final activeMatchId = _firestore.collection('active_matches').doc().id;
      // Randomly assign X or O to player1
      final random = Random();
      final player1Symbol = random.nextBool() ? 'X' : 'O';
      final player2Symbol = player1Symbol == 'X' ? 'O' : 'X';
      
      // Create a new active match
      await _activeMatches.doc(activeMatchId).set({
        'player1': {
          'id': hostId,
          'name': hostName,
          'symbol': player1Symbol,
        },
        'player2': {
          'id': guestId,
          'name': guestName,
          'symbol': player2Symbol,
        },
        'board': List.filled(9, ''),
        'currentTurn': 'X', // X always goes first
        'status': 'active',
        'winner': '',
        'createdAt': FieldValue.serverTimestamp(),
        'lastMoveAt': FieldValue.serverTimestamp(),
        'matchType': 'friendly',
        'matchCode': matchCode,
      });
      
      // Update the friendly match to point to the new active match
      await _friendlyMatches.doc(matchCode).update({
        'status': 'active',
        'activeMatchId': activeMatchId,
      });
      
      AppLogger.debug('Restarted match with code: $matchCode, new active match ID: $activeMatchId');
      return activeMatchId;
    } catch (e) {
      AppLogger.error('Error restarting match: $e');
      throw Exception('Failed to restart match: ${e.toString()}');
    }
  }
}
