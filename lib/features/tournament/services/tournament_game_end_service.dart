import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:vanishingtictactoe/core/utils/app_logger.dart';

/// Service responsible for handling tournament game completion
class TournamentGameEndService {  
  final FirebaseFirestore _firestore;

  TournamentGameEndService({
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Handle the end of a tournament game
  /// Updates the match status, advances winners, and handles bot progression
  Future<void> handleGameEnd({
    required String tournamentId,
    required String matchId,
    required String gameId,
    required String winnerId,
  }) async {
    try {
      AppLogger.info('Handling game end for tournament: $tournamentId, match: $matchId, winner: $winnerId');
      
      // Get the tournament document
      final tournamentDoc = await _firestore.collection('tournaments').doc(tournamentId).get();
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
      
      // Update match with the winner
      matches[matchIndex]['winner_id'] = winnerId;
      matches[matchIndex]['status'] = 'completed';
      
      // Find the next match where this player should advance to
      final nextMatchIndex = _findNextMatchIndex(matches, matchIndex);
      
      if (nextMatchIndex != -1) {
        AppLogger.info('Advancing winner to next match at index: $nextMatchIndex');
        
        // Determine if the winner goes to player1 or player2 slot in the next match
        final isLeftBranch = _isLeftBranch(matchIndex);
        
        if (isLeftBranch) {
          matches[nextMatchIndex]['player1_id'] = winnerId;
        } else {
          matches[nextMatchIndex]['player2_id'] = winnerId;
        }
        
        // If the next match now has both players, update its status
        if (matches[nextMatchIndex]['player1_id'] != null && 
            matches[nextMatchIndex]['player2_id'] != null) {
          matches[nextMatchIndex]['status'] = 'waiting';
          
          // If one of the players is a bot, we can automatically handle its readiness
          final nextPlayer1Id = matches[nextMatchIndex]['player1_id'];
          final nextPlayer2Id = matches[nextMatchIndex]['player2_id'];
          
          
        }
      } else {
        // This was the final match
        AppLogger.info('Tournament completed. Winner: $winnerId');
        tournamentData['status'] = 'completed';
        tournamentData['winner_id'] = winnerId;
        tournamentData['completed_at'] = FieldValue.serverTimestamp();
      }
      
      // Update the tournament
      await _firestore.collection('tournaments').doc(tournamentId).update({
        'matches': matches,
        'status': tournamentData['status'],
        'winner_id': tournamentData['winner_id'],
        'completed_at': tournamentData['completed_at'],
      });
      
      AppLogger.info('Tournament updated successfully after game end');
    } catch (e) {
      AppLogger.error('Error handling game end: $e');
      throw Exception('Failed to handle game end: ${e.toString()}');
    }
  }
  
  /// Find the index of the next match where the winner should advance to
  int _findNextMatchIndex(List<dynamic> matches, int currentMatchIndex) {
    // In a tournament bracket, the next match is determined by the formula:
    // For match at index i, the next match is at index (i-1)/2 (integer division)
    // This only works if the matches are properly ordered in the array
    
    // Skip if this is the final match (index 0)
    if (currentMatchIndex == 0) return -1;
    
    final nextMatchIndex = (currentMatchIndex - 1) ~/ 2;
    return nextMatchIndex;
  }
  
  /// Determine if a match is in the left branch of its parent match
  bool _isLeftBranch(int matchIndex) {
    // In a tournament bracket, matches with odd indices are in the right branch
    // and matches with even indices are in the left branch
    return matchIndex % 2 == 1;
  }
  
  
  /// Create a new game for a match
  Future<String> _createGame(String tournamentId, String matchId) async {
    try {
      // Get the match details
      final tournamentDoc = await _firestore.collection('tournaments').doc(tournamentId).get();
      final tournamentData = tournamentDoc.data() as Map<String, dynamic>;
      
      final matches = tournamentData['matches'] as List<dynamic>;
      final match = matches.firstWhere((m) => m['id'] == matchId);
      
      final player1Id = match['player1_id'];
      final player2Id = match['player2_id'];
      
      // Create a new game document
      final gameRef = _firestore.collection('tournament_games').doc();
      
      final gameData = {
        'id': gameRef.id,
        'tournament_id': tournamentId,
        'match_id': matchId,
        'player_x': player1Id,
        'player_o': player2Id,
        'current_turn': 'X', // X always starts
        'board': List.filled(9, null),
        'moves': <Map<String, dynamic>>[],
        'winner': null,
        'status': 'in_progress',
        'created_at': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
      };
      
      await gameRef.set(gameData);
      
      AppLogger.info('Created new game ${gameRef.id} for match $matchId');
      return gameRef.id;
    } catch (e) {
      AppLogger.error('Error creating game: $e');
      throw Exception('Failed to create game: ${e.toString()}');
    }
  }
}
