import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:vanishingtictactoe/core/utils/app_logger.dart';
import 'package:vanishingtictactoe/features/friends/services/challenge_service.dart';
import 'package:vanishingtictactoe/features/friends/services/friend_service.dart';
import 'package:vanishingtictactoe/features/game/models/game_logic_online.dart';
import 'package:vanishingtictactoe/features/game/screens/game_screen.dart';
import 'package:vanishingtictactoe/shared/models/player.dart';
import 'package:vanishingtictactoe/shared/widgets/online_coin_flip_screen.dart';

/// Service responsible for handling the waiting state of game challenges
/// This includes listening for challenge updates, joining games, and navigating to the game screen
class ChallengeWaitingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FriendService _friendService = FriendService();
  final ChallengeService _challengeService = ChallengeService();
  
  StreamSubscription? _challengeSubscription;
  bool _hasNavigatedToGame = false;

  // Getters to access Firebase instances
  FirebaseFirestore get firestore => _firestore;
  FirebaseAuth get auth => _auth;

  /// Sets up a listener for challenge status updates
  Stream<Map<String, dynamic>?> listenForChallengeUpdates(String challengeId) {
    AppLogger.debug('Setting up challenge listener for challenge ID: $challengeId');
    return _challengeService.listenForChallengeUpdates(challengeId);
  }

  /// Checks the initial challenge status when the receiver opens the screen
  Future<Map<String, dynamic>?> checkInitialChallengeStatus(String challengeId) async {
    try {
      final challengeDoc = await _friendService.firestore
          .collection('challenges')
          .doc(challengeId)
          .get();
      
      if (!challengeDoc.exists) {
        AppLogger.debug('Challenge document doesn\'t exist for ID: $challengeId');
        return null;
      }
      
      final challengeData = challengeDoc.data();
      if (challengeData == null) return null;
      
      AppLogger.debug('Initial challenge status: ${challengeData['status']} for ID: $challengeId');
      return {
        'id': challengeDoc.id,
        ...challengeData,
      };
    } catch (e) {
      AppLogger.error('Error checking initial challenge status: $e');
      return null;
    }
  }

  /// Joins an accepted game challenge
  Future<void> joinGame(String challengeId, Function(bool) setLoading) async {
    setLoading(true);

    try {
      AppLogger.debug('Joining game for challenge ID: $challengeId');
      final gameId = await _challengeService.joinAcceptedChallenge(challengeId);
      AppLogger.debug('Game ID received: $gameId');
    } catch (e) {
      AppLogger.error('Error joining game: $e');
      throw Exception('Error joining game: ${e.toString()}');
    } finally {
      setLoading(false);
    }
  }

  /// Navigate to the game screen when the game is created
  Future<void> navigateToGame({
    required BuildContext context,
    required Map<String, dynamic> challengeData,
    required Function(String) showSnackBar,
  }) async {
    // Prevent multiple navigation attempts
    if (_hasNavigatedToGame) {
      AppLogger.debug('Already navigated to game, preventing duplicate navigation');
      return;
    }
    
    final gameId = challengeData['gameId'] as String?;
    
    if (gameId == null) {
      AppLogger.error('Game ID is null in challenge data');
      showSnackBar('Error: Game ID not found');
      _hasNavigatedToGame = false; // Reset flag if navigation failed
      return;
    }
    
    // Set flag to prevent duplicate navigation
    _hasNavigatedToGame = true;
    
    try {
      // Get player information
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        AppLogger.error('User not authenticated');
        return;
      }
      
      final senderId = challengeData['senderId'] as String?;
      final receiverId = challengeData['receiverId'] as String?;
      
      if (senderId == null || receiverId == null) {
        AppLogger.error('Sender or receiver ID is null in challenge data');
        return;
      }
      
      final isSender = currentUser.uid == senderId;
      
      AppLogger.debug('Current user is ${isSender ? "sender" : "receiver"} in this challenge');
      
      // Create player objects based on whether this is the sender or receiver
      final player1 = Player(
        name: challengeData['senderUsername'] ?? 'Player 1',
        symbol: 'X',
      );
      
      final player2 = Player(
        name: challengeData['receiverUsername'] ?? 'Player 2',
        symbol: 'O',
      );
      
      // Check if the game document exists in the active_matches collection
      try {
        final activeMatchDoc = await _firestore.collection('active_matches').doc(gameId).get();
        
        if (!activeMatchDoc.exists) {
          AppLogger.error('Game document does not exist in active_matches for game ID: $gameId');
          showSnackBar('Game not found. Please try again.');
          return;
        } else {
          AppLogger.info('Game document exists in active_matches for game ID: $gameId');
        }
      } catch (e) {
        AppLogger.error('Error checking game document: $e');
        showSnackBar('Error accessing game: ${e.toString()}');
        return;
      }
      
      // Create online game logic with proper online match integration
      final gameLogic = GameLogicOnline(
        gameId: gameId,
        localPlayerId: currentUser.uid,
        onGameEnd: (_) {},  // Will be set by GameScreen
        onPlayerChanged: () {},  // Will be set by GameScreen
        matchType: 'challenge',  // Explicitly set this as a challenge game
      );
      
      AppLogger.info('Game logic initialized with proper online match integration');
      AppLogger.debug('Navigating to game screen with game ID: $gameId');
      
      // Use the navigateToGameWithCoinFlip function
      return navigateToGameWithCoinFlip(
        context: context,
        player1: player1,
        player2: player2,
        gameLogic: gameLogic,
        gameId: gameId,
      );
    } catch (e) {
      AppLogger.error('Error navigating to game: $e');
      showSnackBar('Error joining game: ${e.toString()}');
      _hasNavigatedToGame = false; // Reset flag if navigation failed
    }
  }

  // Note: The showDeclinedDialog method has been removed as we now use the DeclinedView widget
  // directly in the ChallengeWaitingScreen

  /// Cancels any active subscriptions
  void dispose() {
    _challengeSubscription?.cancel();
  }

  /// Resets the navigation flag
  void resetNavigationFlag() {
    _hasNavigatedToGame = false;
  }
}

/// Navigates to the game screen with a coin flip animation to determine who goes first
Future<void> navigateToGameWithCoinFlip({
  required BuildContext context,
  required Player player1,
  required Player player2,
  required GameLogicOnline gameLogic,
  required String gameId,
}) async {
  // Show a coin flip animation before starting the game
  AppLogger.info('Showing coin flip animation before starting the game');
  Navigator.pushReplacement(
    context,
    MaterialPageRoute(
      builder: (context) => OnlineCoinFlipScreen(
        player1: player1,
        player2: player2,
        onResult: (winningSymbol) {
          AppLogger.info('Coin flip completed with result: $winningSymbol');
          
          // Update player symbols based on coin flip result
          if (winningSymbol == 'X') {
            // X goes first
            player1.symbol = 'X';
            player2.symbol = 'O';
          } else {
            // O goes first
            player1.symbol = 'O';
            player2.symbol = 'X';
          }
          
          AppLogger.info('Player1 (${player1.name}) has ${player1.symbol} and goes ${player1.symbol == winningSymbol ? "first" : "second"}');
          AppLogger.info('Player2 (${player2.name}) has ${player2.symbol} and goes ${player2.symbol == winningSymbol ? "first" : "second"}');
          
          // Update the game document with player symbols
          FirebaseFirestore.instance.collection('active_matches').doc(gameId).update({
            'player1Symbol': player1.symbol,
            'player2Symbol': player2.symbol,
            'currentTurn': winningSymbol,
          }).then((_) {
            AppLogger.info('Updated game document with player symbols');
            
            // After animation, navigate to the actual game using the online flow
            // This ensures both players are connected to the same match instance
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => GameScreen(
                  player1: player1,
                  player2: player2,
                  logic: gameLogic,
                  isOnlineGame: true,
                ),
              ),
            );
          }).catchError((error) {
            AppLogger.error('Error updating game document: $error');
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error updating game: ${error.toString()}'))
            );
          });
        },
      ),
    ),
  );
}
