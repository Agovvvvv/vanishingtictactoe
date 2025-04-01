import 'dart:async';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:vanishingtictactoe/shared/models/match.dart';
import 'package:vanishingtictactoe/core/utils/app_logger.dart';
import 'package:vanishingtictactoe/core/utils/win_checker.dart';

class MatchmakingService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final CollectionReference _activeMatches;
  final CollectionReference _matchmakingQueue;
  StreamSubscription? _matchSubscription;

  MatchmakingService() :
    // Use both 'matches' and 'active_matches' collections to support both matchmaking and challenges
    _activeMatches = FirebaseFirestore.instance.collection('active_matches'),
    _matchmakingQueue = FirebaseFirestore.instance.collection('matchmaking_queue');

  DocumentReference? _currentQueueRef;
  StreamSubscription? _queueSubscription;
  Timer? _matchmakingTimer;


  // Find a match
  Future<String> findMatch({bool isHellMode = false}) async {
    if (_auth.currentUser == null) {
      throw Exception('You must be logged in to play online');
    }

    try {
      final userId = _auth.currentUser!.uid;
      final username = _auth.currentUser!.displayName ?? 'Player';

      AppLogger.info('Starting matchmaking for user: $userId ($username), isHellMode: $isHellMode');      

      final wantsX = Random().nextBool();
      _currentQueueRef = await _matchmakingQueue.add({
        'userId': userId,
        'username': username,
        'timestamp': FieldValue.serverTimestamp(),
        'status': 'waiting',
        'wantsX': wantsX,
        'isHellMode': isHellMode,
      });

      AppLogger.info('Added to matchmaking queue with ID: ${_currentQueueRef!.id}');

      try {
        final matchId = await _findOpponent(_currentQueueRef!, userId, isHellMode);
        AppLogger.info('Match found with ID: $matchId');
        _currentQueueRef = null;
        return matchId;
      } catch (e) {
        AppLogger.error('Error finding opponent: $e');
        await _cleanupMatchmaking();
        if (_currentQueueRef != null) {
          try {
            await _currentQueueRef!.delete();
            _currentQueueRef = null;
          } catch (deleteError) {
            AppLogger.error('Error deleting queue entry: $deleteError');
          }
        }
        throw Exception('Failed to find a match: ${e.toString()}');
      }
    } catch (e) {
      AppLogger.error('Error in findMatch: $e');
      await _cleanupMatchmaking();
      throw Exception('Error starting matchmaking: ${e.toString()}');
    }
  }

  // Find an opponent in the queue
  Future<String> _findOpponent(DocumentReference queueRef, String userId, bool isHellMode) async {
    Completer<String> completer = Completer<String>();

    _matchmakingTimer = Timer(const Duration(minutes: 3), () {
      if (!completer.isCompleted) {
        AppLogger.info('Matchmaking timeout reached');
        _cleanupMatchmaking();
        completer.completeError('Matchmaking timeout');
      }
    });

    _queueSubscription = queueRef.snapshots().listen((snapshot) async {
      if (!completer.isCompleted) {
        final data = snapshot.data() as Map<String, dynamic>?;

        if (data != null) {
          if (data['status'] == 'matched' && data['matchId'] != null) {
            final matchId = data['matchId'] as String;
            await _cleanupMatchmaking();
            completer.complete(matchId);
          } else if (data['status'] == 'waiting') {
            try {
              final querySnapshot = await _matchmakingQueue
                  .where('status', isEqualTo: 'waiting')
                  .where('isHellMode', isEqualTo: isHellMode)
                  .limit(10)
                  .get();

              final filteredDocs = querySnapshot.docs.where((doc) => doc['userId'] != userId).toList();

              AppLogger.info('Found ${filteredDocs.length} potential opponents with matching preferences');

              if (filteredDocs.isNotEmpty) {
                filteredDocs.sort((a, b) {
                  final aTime = a['timestamp'] as Timestamp;
                  final bTime = b['timestamp'] as Timestamp;
                  return aTime.compareTo(bTime);
                });
              }

              if (filteredDocs.isNotEmpty) {
                final opponentQueueRef = filteredDocs.first.reference;
                final opponentQueueData = filteredDocs.first.data() as Map<String, dynamic>;
                final opponentUserId = opponentQueueData['userId'] as String;
                final opponentUsername = opponentQueueData['username'] as String;

                AppLogger.info('Found potential opponent: $opponentUsername ($opponentUserId)');

                late final DocumentReference matchRef;
                late final String matchId;
                bool matchCreated = false;
                
                try {
                  final myQueueDoc = await queueRef.get();
                  final myData = myQueueDoc.data() as Map<String, dynamic>?;
                  
                  if (myData == null) {
                    throw Exception('Queue data is null');
                  }

                  // First prepare the match data outside the transaction
                  matchRef = _activeMatches.doc();
                  matchId = matchRef.id;
                  AppLogger.info('Creating new match with ID: $matchId');

                  final Map<String, dynamic> matchData = await _prepareMatchData(
                    userId,
                    myData['username'] as String,
                    opponentUserId,
                    opponentUsername,
                    isHellMode,
                  );

                  // Create the match document first
                  await matchRef.set(matchData);
                  matchCreated = true;
                  AppLogger.info('Match document created successfully');

                  // Now run the transaction for queue updates
                  await FirebaseFirestore.instance.runTransaction((transaction) async {
                    final freshMyQueueDoc = await transaction.get(queueRef);
                    final freshOpponentQueueDoc = await transaction.get(opponentQueueRef);

                    if (!freshMyQueueDoc.exists || !freshOpponentQueueDoc.exists) {
                      throw Exception('One or both players no longer available');
                    }

                    final freshMyData = freshMyQueueDoc.data() as Map<String, dynamic>?;
                    final freshOpponentData = freshOpponentQueueDoc.data() as Map<String, dynamic>?;

                    if (freshMyData == null || freshOpponentData == null) {
                      throw Exception('One or both players have null data');
                    }

                    if (freshMyData['status'] != 'waiting' || freshOpponentData['status'] != 'waiting') {
                      throw Exception('One or both players are not in waiting status');
                    }

                    // Update queue entries
                    final queueUpdate = {
                      'status': 'matched',
                      'matchId': matchId,
                      'matchTimestamp': FieldValue.serverTimestamp(),
                    };

                    transaction.update(queueRef, queueUpdate);
                    transaction.update(opponentQueueRef, queueUpdate);

                    AppLogger.info('Queue entries updated successfully');
                  });

                  AppLogger.info('Match created successfully with ID: $matchId');
                  _queueSubscription?.cancel();
                  completer.complete(matchId);
                } catch (e) {
                  AppLogger.error('Transaction failed: $e');
                  // Clean up the match document if it was created
                  if (matchCreated) {
                    try {
                      await matchRef.delete();
                      AppLogger.info('Successfully cleaned up failed match');
                    } catch (deleteError) {
                      AppLogger.error('Error cleaning up failed match: $deleteError');
                    }
                  }
                }
              }
            } catch (e) {
              AppLogger.error('Error finding opponent: ${e.toString()}');
            }
          }
        }
      }
    }, onError: (error) {
      if (!completer.isCompleted) {
        completer.completeError('Queue error: ${error.toString()}');
      }
    });

    return completer.future;
  }

  // Prepare match data
  Future<Map<String, dynamic>> _prepareMatchData(
    String player1Id,
    String player1Name,
    String player2Id,
    String player2Name,
    bool isHellMode,
  ) async {
    final player1GoesFirst = Random().nextBool();
    final String firstPlayerSymbol = player1GoesFirst ? 'X' : 'O';
    
    AppLogger.info('Match initialization: ${player1GoesFirst ? "Player 1" : "Player 2"} goes first with symbol $firstPlayerSymbol');
    
    final Map<String, dynamic> matchData = {
      'player1': {
        'id': player1Id,
        'name': player1Name,
        'symbol': player1GoesFirst ? 'X' : 'O',
      },
      'player2': {
        'id': player2Id,
        'name': player2Name,
        'symbol': player1GoesFirst ? 'O' : 'X',
      },
      'xMoves': [],
      'oMoves': [],
      'xMoveCount': 0,
      'oMoveCount': 0,
      'board': List.generate(9, (_) => ''),
      'currentTurn': firstPlayerSymbol, // Use the correct first player symbol
      'status': 'active',
      'winner': null,
      'moveCount': 0,
      'isHellMode': isHellMode,
      'matchType': 'casual',
      'createdAt': FieldValue.serverTimestamp(),
      'lastMoveAt': FieldValue.serverTimestamp(),
      'lastAction': {
        'type': 'game_start',
        'timestamp': FieldValue.serverTimestamp(),
      },
    };

    return matchData;
  }

  // Join an existing match
  Stream<GameMatch> joinMatch(String matchId) {
    _matchSubscription?.cancel();

    if (_auth.currentUser == null) {
      throw Exception('You must be logged in to join a match');
    }

    final controller = StreamController<GameMatch>();

    // Only fetch from active_matches collection
    _matchSubscription = _activeMatches.doc(matchId).snapshots().listen(
      (snapshot) {
        if (!snapshot.exists) {
          AppLogger.info('Match not found in active_matches: $matchId');
          controller.addError('Match not found');
          return;
        }

          Map<String, dynamic>? data;
          try {
            data = snapshot.data() as Map<String, dynamic>?;
          } catch (e) {
            AppLogger.error('Error casting match data: $e');
            controller.addError('Invalid match data format');
            return;
          }

          if (data == null) {
            AppLogger.warning('Match data is null: $matchId');
            controller.addError('Match data is null');
            return;
          }

          try {
            // Handle challenge games which might have a different structure
            if (data['matchType'] == 'challenge' || !data.containsKey('board')) {
              // Convert challenge game format to match format if needed
              data = _convertChallengeToMatchFormat(data, matchId);
            }
            
            final match = GameMatch.fromFirestore(data, matchId);
            if (match.board.length != 9) {
              controller.addError('Invalid board state');
              return;
            }
            controller.add(match);
          } catch (e) {
            AppLogger.error('Error parsing match data: $e');
            controller.addError('Invalid match data: ${e.toString()}');
          }
        },
        onError: (error) {
          // If permission error and we're in active_matches, try games collection
          if (error.toString().contains('permission-denied')) {
            AppLogger.warning('Permission denied in active_matches, trying games collection: $matchId');
            _matchSubscription?.cancel();
            return;
          }
          
          AppLogger.error('Error in match stream: $error');
          controller.addError('Failed to connect to match: $error');
        },
        cancelOnError: false,
      );
    

    controller.onCancel = () {
      _matchSubscription?.cancel();
      _matchSubscription = null;
    };

    return controller.stream;
  }
  
  // Helper method to convert challenge game format to match format
  Map<String, dynamic> _convertChallengeToMatchFormat(Map<String, dynamic> data, String matchId) {
    if (data.containsKey('board') && data.containsKey('player1') && data.containsKey('player2')) {
      return data;
    }
    
    AppLogger.info('Converting challenge game to match format for ID: $matchId');
    
    final now = Timestamp.now();
    
    data['player1'] = {
      'id': data['players']?[0] ?? '',
      'name': data['playerNames']?[0] ?? 'Player 1',
      'symbol': 'X',
    };
    
    data['player2'] = {
      'id': data['players']?[1] ?? '',
      'name': data['playerNames']?[1] ?? 'Player 2',
      'symbol': 'O',
    };
    
    data['xMoves'] = <int>[];
    data['oMoves'] = <int>[];
    data['xMoveCount'] = 0;
    data['oMoveCount'] = 0;
    data['board'] = List.filled(9, '');
    data['currentTurn'] = 'X';
    data['status'] = 'active';
    data['winner'] = '';
    data['moveCount'] = 0;
    data['isHellMode'] = data['isHellMode'] ?? false;
    data['matchType'] = 'challenge';
    data['createdAt'] = data['createdAt'] is Timestamp ? data['createdAt'] : now;
    data['lastMoveAt'] = data['lastActivity'] is Timestamp ? data['lastActivity'] : now;
    data['lastAction'] = {'type': 'game_start', 'timestamp': now};
    data['challengeId'] = data['challengeId'];
    
    return data;
  }

  Future<Map<String, dynamic>> makeMove(String matchId, int position) async {
    if (_auth.currentUser == null) {
      throw Exception('You must be logged in to play');
    }

    AppLogger.info('Making move in match: $matchId, position: $position');
    final userId = _auth.currentUser!.uid;
    // Always use active_matches collection for all game types
    final matchRef = _activeMatches.doc(matchId);

    try {
      final matchData = await matchRef.get();
      if (!matchData.exists) {
        throw Exception('Match not found');
      }

      final data = matchData.data() as Map<String, dynamic>?;
      if (data == null) {
        throw Exception('Match data is null');
      }

      final match = GameMatch.fromFirestore(data, matchId);

      if (position == -1) {
        await matchRef.update({
          'status': 'active',
          'winner': '',
          'currentTurn': 'X',
          'moveCount': 0,
          'board': List.filled(9, ''),
          'xMoves': [],
          'oMoves': [],
          'xMoveCount': 0,
          'oMoveCount': 0,
          'lastMoveAt': FieldValue.serverTimestamp(),
          'lastAction': {
            'type': 'game_reset',
            'timestamp': FieldValue.serverTimestamp(),
          },
        });
        AppLogger.info('Resetting game state to active with player 1 (${match.player1.name}) starting');
        return {
          'matchId': matchId,
          'isCompleted': false
        };
      }

      if (match.status == 'completed' && !match.board.every((cell) => cell.isEmpty)) {
        throw Exception('Cannot modify a completed game');
      }

      final playerSymbol = match.player1.id == userId ? match.player1.symbol : match.player2.symbol;
      if (match.currentTurn != playerSymbol) {
        throw Exception('It is not your turn');
      }

      if (data['status'] != 'active') {
        throw Exception('Game is not active');
      }

      if (position < 0 || position >= 9) {
        throw Exception('Invalid position');
      }

      final List<String> newBoard = List<String>.from(data['board'] as List);
      if (newBoard[position].isNotEmpty) {
        throw Exception('Position already taken');
      }

      final int moveCount = (data['moveCount'] as int?) ?? 0;

      List<int> xMoves = List<int>.from(data['xMoves'] as List? ?? []);
      List<int> oMoves = List<int>.from(data['oMoves'] as List? ?? []);
      int xMoveCount = (data['xMoveCount'] as int?) ?? 0;
      int oMoveCount = (data['oMoveCount'] as int?) ?? 0;

      if (playerSymbol == 'X') {
        xMoves.add(position);
        xMoveCount++;
      } else {
        oMoves.add(position);
        oMoveCount++;
      }

      newBoard[position] = playerSymbol;

      if (playerSymbol == 'X' && xMoveCount > 3) {
        newBoard[xMoves[0]] = '';
        xMoves.removeAt(0);
      } else if (playerSymbol == 'O' && oMoveCount > 3) {
        newBoard[oMoves[0]] = '';
        oMoves.removeAt(0);
      }

      bool hasWinner = WinChecker.checkWin(newBoard, playerSymbol);

      final nextTurn = playerSymbol == 'X' ? 'O' : 'X';
      final newMoveCount = moveCount + 1;

      final Map<String, dynamic> updateData = {
        'xMoves': xMoves,
        'oMoves': oMoves,
        'xMoveCount': xMoveCount,
        'oMoveCount': oMoveCount,
        'board': newBoard,
        'currentTurn': nextTurn,
        'lastMoveAt': FieldValue.serverTimestamp(),
        'moveCount': newMoveCount,
        'lastMove': {
          'position': position,
          'symbol': playerSymbol,
          'timestamp': FieldValue.serverTimestamp(),
        },
      };

      if (hasWinner) {
        updateData['status'] = 'completed';
        updateData['winner'] = playerSymbol;
        updateData['completedAt'] = FieldValue.serverTimestamp();
      } else if (newMoveCount >= 30) {
        updateData['status'] = 'completed';
        updateData['winner'] = 'draw';
        updateData['completedAt'] = FieldValue.serverTimestamp();
      }

      await matchRef.update(updateData);

      AppLogger.info('Move successfully applied: position=$position, symbol=$playerSymbol, hasWinner=$hasWinner, moveCount=$newMoveCount');

      return {
        'matchId': matchId,
        'isCompleted': hasWinner || newMoveCount >= 30
      };
    } catch (e) {
      AppLogger.error('Error in makeMove: $e');
      throw Exception('Error making move: ${e.toString()}');
    }
  }

  // Cancel matchmaking
  Future<void> cancelMatchmaking() async {
    if (_currentQueueRef == null) return;

    AppLogger.info('Canceling matchmaking...');
    final deleteRef = _currentQueueRef;
    _currentQueueRef = null;

    try {
      await deleteRef!.delete();
      AppLogger.info('Matchmaking canceled successfully');
    } catch (e) {
      AppLogger.error('Error canceling matchmaking: $e');
      throw Exception('Failed to cancel matchmaking: ${e.toString()}');
    } finally {
      await _cleanupMatchmaking();
    }
  }

  // Cleanup matchmaking resources
  Future<void> _cleanupMatchmaking() async {
    if (_queueSubscription != null) {
      await _queueSubscription!.cancel();
      _queueSubscription = null;
    }

    if (_matchmakingTimer != null) {
      _matchmakingTimer!.cancel();
      _matchmakingTimer = null;
    }

    if (_matchSubscription != null) {
      await _matchSubscription!.cancel();
      _matchSubscription = null;
    }
  }

  // Dispose method to clean up resources
  void dispose() {
    _cleanupMatchmaking();
    _currentQueueRef?.delete().ignore();
    _currentQueueRef = null;
  }

  // Add a method to check connection without making changes
  Future<void> pingMatch(String matchId) async {
    try {
      AppLogger.info('Pinging match connection: $matchId');
      
      // Try to get the match document from active_matches first
      var docSnapshot = await _activeMatches.doc(matchId).get();
      
      // If not found in active_matches, try the games collection (for challenges)
      if (!docSnapshot.exists) {
        AppLogger.info('Match not found in active_matches, trying games collection');
        docSnapshot = await FirebaseFirestore.instance.collection('games').doc(matchId).get();
        
        if (!docSnapshot.exists) {
          AppLogger.warning('Match not found in any collection during ping: $matchId');
          throw Exception('Match not found');
        }
      }
      
      AppLogger.info('Ping successful for match: $matchId');
    } catch (e) {
      AppLogger.error('Error pinging match: $e');
      rethrow;
    }
  }

  Future<void> leaveMatch(String matchId) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      throw Exception('User not authenticated');
    }

    try {
      final updateData = {
        'status': 'completed',
        'winner': null,
        'endReason': 'player_left',
        'endTimestamp': FieldValue.serverTimestamp(),
      };

      await _activeMatches.doc(matchId).update(updateData);
      AppLogger.info('Player ${currentUser.uid} left match $matchId');
    } catch (e) {
      AppLogger.error('Error leaving match: $e');
      rethrow;
    }
  }



}