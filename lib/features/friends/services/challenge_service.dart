import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:vanishingtictactoe/core/exceptions/challenge_service_exception.dart';
import 'package:vanishingtictactoe/core/utils/app_logger.dart';
import 'dart:developer' as developer;

class ChallengeService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Constructor
  ChallengeService();

  // Getters to access Firebase instances
  FirebaseFirestore get firestore => _firestore;
  FirebaseAuth get auth => _auth;

  // Send a game challenge to a friend
  Future<String> sendGameChallenge(String friendId, String friendUsername) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) throw ChallengeServiceException('Not authenticated');

    try {
      developer.log('Sending game challenge to friend: $friendId ($friendUsername)');
      
      // Get current user's username
      final currentUserDoc = await _firestore.collection('users').doc(userId).get();
      final currentUserData = currentUserDoc.data();
      if (currentUserData == null) {
        developer.log('User data not found for $userId');
        throw ChallengeServiceException('User data not found');
      }
      
      final username = currentUserData['username'] ?? 'Unknown';
      final photoUrl = currentUserData['photoUrl'] as String?;

      // Calculate expiration time (1 minute from now)
      final now = DateTime.now();
      final expirationTime = now.add(const Duration(minutes: 1));
      
      developer.log('Creating challenge with expiration: ${expirationTime.toString()}');
      
      // Create a challenge document
      final challengeRef = await _firestore.collection('challenges').add({
        'senderId': userId,
        'senderUsername': username,
        'senderPhotoUrl': photoUrl,
        'receiverId': friendId,
        'receiverUsername': friendUsername,
        'status': 'pending',
        'timestamp': FieldValue.serverTimestamp(),
        'expirationTime': Timestamp.fromDate(expirationTime),
        'gameId': null, // Will be set when a game is created
        'notificationShown': false, // Flag to track if notification has been shown
      });

      // Create a notification for the friend
      final notificationRef = await _firestore
          .collection('users')
          .doc(friendId)
          .collection('notifications')
          .add({
        'type': 'gameChallenge',
        'senderId': userId,
        'senderUsername': username,
        'senderPhotoUrl': photoUrl,
        'timestamp': FieldValue.serverTimestamp(),
        'expirationTime': Timestamp.fromDate(expirationTime),
        'expired': false,
        'read': false,
        'accepted': null,
        'challengeId': challengeRef.id,
      });

      developer.log('Game challenge sent to $friendUsername with ID: ${challengeRef.id} and notification ID: ${notificationRef.id}');
      return challengeRef.id;
    } catch (e) {
      developer.log('Error sending game challenge: $e', error: e);
      throw ChallengeServiceException('Failed to send game challenge: ${e.toString()}');
    }
  }
  
  // Accept a game challenge
  Future<String> acceptGameChallenge(String challengeId) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) throw ChallengeServiceException('Not authenticated');

    try {
      developer.log('Accepting game challenge with ID: $challengeId');
      
      // Get the challenge document
      final challengeDoc = await _firestore.collection('challenges').doc(challengeId).get();
      if (!challengeDoc.exists) {
        developer.log('Challenge not found: $challengeId');
        throw ChallengeServiceException('Challenge not found');
      }
      
      final challengeData = challengeDoc.data();
      if (challengeData == null) {
        developer.log('Challenge data not found for ID: $challengeId');
        throw ChallengeServiceException('Challenge data not found');
      }
      
      // Verify this user is the receiver
      if (challengeData['receiverId'] != userId) {
        developer.log('User $userId is not authorized to accept challenge $challengeId');
        throw ChallengeServiceException('You are not authorized to accept this challenge');
      }
      
      // Check if challenge is still pending
      final status = challengeData['status'] as String;
      if (status != 'pending') {
        developer.log('Challenge $challengeId is not pending (status: $status)');
        throw ChallengeServiceException('This challenge is no longer pending');
      }
      
      // Check if challenge has expired
      final expirationTime = challengeData['expirationTime'] as Timestamp?;
      if (expirationTime != null) {
        final expirationDateTime = expirationTime.toDate();
        final now = DateTime.now();
        
        if (now.isAfter(expirationDateTime)) {
          developer.log('Challenge $challengeId has expired at ${expirationDateTime.toString()}');
          // Update challenge status to expired
          await _firestore.collection('challenges').doc(challengeId).update({
            'status': 'expired'
          });
          throw ChallengeServiceException('This challenge has expired');
        }
        
        developer.log('Challenge $challengeId is valid, expires at ${expirationDateTime.toString()}');
      }
      
      // Get current user's data
      final currentUserDoc = await _firestore.collection('users').doc(userId).get();
      final currentUserData = currentUserDoc.data();
      if (currentUserData == null) {
        developer.log('User data not found for $userId');
        throw ChallengeServiceException('User data not found');
      }
      
      final username = currentUserData['username'] ?? 'Unknown';
      
      // Update challenge status to accepted
      await _firestore.collection('challenges').doc(challengeId).update({
        'status': 'accepted',
        'acceptedAt': FieldValue.serverTimestamp(),
        'notificationShown': false // Reset notification flag when accepting
      });
      
      developer.log('Updated challenge $challengeId status to accepted');
      
      // Create a notification for the challenger
      final senderId = challengeData['senderId'] as String;
      final notificationRef = await _firestore
          .collection('users')
          .doc(senderId)
          .collection('notifications')
          .add({
        'type': 'challengeAccepted',
        'senderId': userId,
        'senderUsername': username,
        'timestamp': FieldValue.serverTimestamp(),
        'read': false,
        'challengeId': challengeId,
        'receiverUsername': challengeData['receiverUsername'], // Add receiver username for display
      });
      
      developer.log('Game challenge accepted: $challengeId, notification sent: ${notificationRef.id}');
      return challengeId;
    } catch (e) {
      developer.log('Error accepting game challenge: $e', error: e);
      throw ChallengeServiceException('Failed to accept challenge: ${e.toString()}');
    }
  }
  
  // Decline a game challenge
  Future<void> declineGameChallenge(String challengeId) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) throw ChallengeServiceException('Not authenticated');

    try {
      // Get the challenge document
      final challengeDoc = await _firestore.collection('challenges').doc(challengeId).get();
      if (!challengeDoc.exists) {
        throw ChallengeServiceException('Challenge not found');
      }
      
      final challengeData = challengeDoc.data();
      if (challengeData == null) {
        throw ChallengeServiceException('Challenge data not found');
      }
      
      // Verify this user is either the sender or receiver of the challenge
      final bool isSender = challengeData['senderId'] == userId;
      final bool isReceiver = challengeData['receiverId'] == userId;
      
      if (!isSender && !isReceiver) {
        throw ChallengeServiceException('You are not authorized to decline this challenge');
      }
      
      // For pending challenges, only the receiver can decline
      // For accepted challenges, only the sender can decline
      final String status = challengeData['status'] as String;
      
      if (status == 'pending' && !isReceiver) {
        throw ChallengeServiceException('Only the challenge receiver can decline a pending challenge');
      }
      
      if (status == 'accepted' && !isSender) {
        throw ChallengeServiceException('Only the challenge sender can decline an accepted challenge');
      }
      
      // Check if challenge is in a valid state to decline
      if (status != 'pending' && status != 'accepted') {
        throw ChallengeServiceException('This challenge cannot be declined in its current state');
      }
      
      // Get current user's data
      final currentUserDoc = await _firestore.collection('users').doc(userId).get();
      final currentUserData = currentUserDoc.data();
      if (currentUserData == null) {
        throw ChallengeServiceException('User data not found');
      }
      
      final username = currentUserData['username'] ?? 'Unknown';
      
      // Update challenge status to declined
      await _firestore.collection('challenges').doc(challengeId).update({
        'status': 'declined',
        'declinedAt': FieldValue.serverTimestamp()
      });
      
      // Create a notification for the challenger
      final senderId = challengeData['senderId'] as String;
      await _firestore
          .collection('users')
          .doc(senderId)
          .collection('notifications')
          .add({
        'type': 'challengeDeclined',
        'senderId': userId,
        'senderUsername': username,
        'timestamp': FieldValue.serverTimestamp(),
        'read': false,
        'challengeId': challengeId,
      });
      
      developer.log('Game challenge declined: $challengeId');
    } catch (e) {
      developer.log('Error declining game challenge: $e', error: e);
      throw ChallengeServiceException('Failed to decline challenge: ${e.toString()}');
    }
  }
  
  // Join a game after challenge was accepted
  Future<String> joinAcceptedChallenge(String challengeId) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) throw ChallengeServiceException('Not authenticated');

    try {
      // Get the challenge document
      final challengeDoc = await _firestore.collection('challenges').doc(challengeId).get();
      if (!challengeDoc.exists) {
        throw ChallengeServiceException('Challenge not found');
      }
      
      final challengeData = challengeDoc.data();
      if (challengeData == null) {
        throw ChallengeServiceException('Challenge data not found');
      }
      
      // Check if a game already exists for this challenge
      if (challengeData['gameId'] != null) {
        final gameId = challengeData['gameId'] as String;
        developer.log('Game already exists for challenge: $challengeId, returning gameId: $gameId');
        
        // If the status is not 'joined', update it to prevent duplicate game creation
        if (challengeData['status'] != 'joined') {
          await _firestore.collection('challenges').doc(challengeId).update({
            'status': 'joined',
            'joinedAt': FieldValue.serverTimestamp()
          });
          developer.log('Updated challenge status to joined for existing game: $gameId');
        }
        
        return gameId;
      }
      
      // Verify this user is the sender or receiver
      final senderId = challengeData['senderId'] as String;
      final receiverId = challengeData['receiverId'] as String;
      
      if (userId != senderId && userId != receiverId) {
        throw ChallengeServiceException('You are not authorized to join this challenge');
      }
      
      // Check if challenge is accepted
      if (challengeData['status'] != 'accepted') {
        throw ChallengeServiceException('This challenge has not been accepted');
      }
      
      // Create a new game directly in active_matches collection with proper structure for GameLogicOnline
      // Generate a unique ID for the game
      final gameId = _firestore.collection('active_matches').doc().id;
      
      // Add game to active_matches collection
      await _firestore.collection('active_matches').doc(gameId).set({
        'player1': {
          'id': senderId,
          'name': challengeData['senderUsername'],
          'symbol': 'X'
        },
        'player2': {
          'id': receiverId,
          'name': challengeData['receiverUsername'],
          'symbol': 'O'
        },
        'board': List.filled(9, ''),
        'currentTurn': 'X', // X always goes first
        'status': 'active',
        'winner': '',
        'createdAt': FieldValue.serverTimestamp(),
        'lastMoveAt': FieldValue.serverTimestamp(),
        'matchType': 'challenge',
        'challengeId': challengeId
      });
      
      developer.log('Created new game for challenge: $challengeId, game ID: $gameId');
      
      // Update challenge with game ID
      await _firestore.collection('challenges').doc(challengeId).update({
        'status': 'joined',
        'joinedAt': FieldValue.serverTimestamp(),
        'gameId': gameId
      });
      
      // Create a notification for the other player that game is starting
      final otherPlayerId = userId == senderId ? receiverId : senderId;
      final currentUsername = userId == senderId ? challengeData['senderUsername'] : challengeData['receiverUsername'];
      
      await _firestore
          .collection('users')
          .doc(otherPlayerId)
          .collection('notifications')
          .add({
        'type': 'gameStarting',
        'senderId': userId,
        'senderUsername': currentUsername,
        'timestamp': FieldValue.serverTimestamp(),
        'read': false,
        'gameId': gameId,
        'challengeId': challengeId,
      });
      
      developer.log('Joined accepted challenge: $challengeId, game created: $gameId');
      return gameId;
    } catch (e) {
      developer.log('Error joining accepted challenge: $e', error: e);
      throw ChallengeServiceException('Failed to join challenge: ${e.toString()}');
    }
  }
  
  // Cancel joining a game after challenge was accepted
  Future<void> cancelJoiningChallenge(String challengeId) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) throw ChallengeServiceException('Not authenticated');

    try {
      // Get the challenge document
      final challengeDoc = await _firestore.collection('challenges').doc(challengeId).get();
      if (!challengeDoc.exists) {
        throw ChallengeServiceException('Challenge not found');
      }
      
      final challengeData = challengeDoc.data();
      if (challengeData == null) {
        throw ChallengeServiceException('Challenge data not found');
      }
      
      // Verify this user is the sender
      if (challengeData['senderId'] != userId) {
        throw ChallengeServiceException('You are not authorized to cancel this challenge');
      }
      
      // Check if challenge is accepted
      if (challengeData['status'] != 'accepted') {
        throw ChallengeServiceException('This challenge has not been accepted');
      }
      
      // Update challenge status to cancelled
      await _firestore.collection('challenges').doc(challengeId).update({
        'status': 'cancelled',
        'cancelledAt': FieldValue.serverTimestamp()
      });
      
      // Create a notification for the receiver
      final receiverId = challengeData['receiverId'] as String;
      await _firestore
          .collection('users')
          .doc(receiverId)
          .collection('notifications')
          .add({
        'type': 'challengeCancelled',
        'senderId': userId,
        'senderUsername': challengeData['senderUsername'],
        'timestamp': FieldValue.serverTimestamp(),
        'read': false,
        'challengeId': challengeId,
      });
      
      developer.log('Challenge joining cancelled: $challengeId');
    } catch (e) {
      developer.log('Error cancelling challenge join: $e', error: e);
      throw ChallengeServiceException('Failed to cancel challenge: ${e.toString()}');
    }
  }
  
  // Listen for challenge status updates
  Stream<Map<String, dynamic>?> listenForChallengeUpdates(String challengeId) {
    return _firestore.collection('challenges').doc(challengeId).snapshots()
      .map((snapshot) {
        if (!snapshot.exists) return null;
        return {
          'id': snapshot.id,
          ...snapshot.data()!,
        };
      });
  }
  
  // Accept a game challenge from a notification
  Future<String> acceptGameChallengeFromNotification(String notificationId, String senderId) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) throw ChallengeServiceException('Not authenticated');

    try {
      AppLogger.debug('Accepting game challenge from $senderId');
      
      // Get the notification to find the challenge ID
      final notificationDoc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .doc(notificationId)
          .get();
      
      if (!notificationDoc.exists) {
        throw ChallengeServiceException('Notification not found');
      }
      
      final notificationData = notificationDoc.data();
      if (notificationData == null) {
        throw ChallengeServiceException('Notification data not found');
      }
      
      // Check if the notification is expired
      final expirationTime = notificationData['expirationTime'] as Timestamp?;
      final bool isExpired = notificationData['expired'] == true || 
          (expirationTime != null && DateTime.now().isAfter(expirationTime.toDate()));
      
      if (isExpired) {
        AppLogger.error('Cannot accept expired challenge');
        throw ChallengeServiceException('This challenge has expired');
      }
      
      // Check if this notification has already been processed
      final bool alreadyAccepted = notificationData['accepted'] == true;
      if (alreadyAccepted) {
        // If the notification was already accepted, return the existing game or challenge ID
        final existingGameId = notificationData['gameId'] as String?;
        final existingChallengeId = notificationData['challengeId'] as String?;
        
        if (existingGameId != null) {
          AppLogger.debug('Notification already accepted with game ID: $existingGameId');
          return existingGameId;
        } else if (existingChallengeId != null) {
          AppLogger.debug('Notification already accepted with challenge ID: $existingChallengeId');
          return existingChallengeId;
        }
      }
      
      final challengeId = notificationData['challengeId'] as String;

      // Mark notification as read and accepted
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .doc(notificationId)
          .update({
        'read': true,
        'accepted': true,
      });
      
      // Use acceptGameChallenge to accept the challenge
      // This will update the challenge status in the database
      await acceptGameChallenge(challengeId);
      
      // Get current user's username to notify the sender
      final currentUserDoc = await _firestore.collection('users').doc(userId).get();
      final username = currentUserDoc.data()?['username'] ?? 'Unknown';
      final photoUrl = currentUserDoc.data()?['photoUrl'] as String?;
      
      // Calculate expiration time (1 minute from now)
      final acceptedTime = DateTime.now();
      final notificationExpirationTime = acceptedTime.add(const Duration(minutes: 1));
      
      // Create a notification for the sender that their challenge was accepted
      await _firestore
          .collection('users')
          .doc(senderId)
          .collection('notifications')
          .add({
        'type': 'challengeAccepted',
        'senderId': userId,
        'senderUsername': username,
        'senderPhotoUrl': photoUrl,
        'timestamp': FieldValue.serverTimestamp(),
        'expirationTime': Timestamp.fromDate(notificationExpirationTime),
        'expired': false,
        'read': false,
        'challengeId': challengeId,
      });
      
      AppLogger.debug('Challenge accepted with ID: $challengeId, notification sent to sender');
      
      // Return the challenge ID instead of game ID
      // The game ID doesn't exist yet - it will be created when the sender joins
      return challengeId;
    } catch (e) {
      developer.log('Error accepting game challenge: $e', error: e);
      throw ChallengeServiceException('Failed to accept challenge: ${e.toString()}');
    }
  }
  
  // Get the sender username from a notification
  Future<String> getSenderUsernameFromNotification(String notificationId) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) throw ChallengeServiceException('Not authenticated');
    
    try {
      final notification = await _firestore
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .doc(notificationId)
          .get();
      
      final notificationData = notification.data();
      return notificationData?['senderUsername'] as String? ?? 'Friend';
    } catch (e) {
      AppLogger.error('Error getting sender username: $e');
      return 'Friend';
    }
  }
  
  // Handle the complete challenge acceptance flow with UI feedback and navigation
  Future<void> handleChallengeAcceptance({
    required String notificationId,
    required String senderId,
    required Function(String) showSnackBar,
    required Function(bool) setLoading,
    required Function(String, String, bool) navigateToChallengeWaiting,
  }) async {
    setLoading(true);
    AppLogger.debug('Starting challenge acceptance process for notification: $notificationId from sender: $senderId');
    
    try {
      // Use the existing method to accept the game challenge
      final challengeId = await acceptGameChallengeFromNotification(notificationId, senderId);
      AppLogger.debug('Challenge accepted successfully with ID: $challengeId');
      
      // Show a confirmation message
      showSnackBar('Challenge accepted!');
      
      // Get the sender username
      final senderUsername = await getSenderUsernameFromNotification(notificationId);
      
      // Navigate to the ChallengeWaitingScreen
      AppLogger.debug('Navigating to ChallengeWaitingScreen with challengeId: $challengeId');
      navigateToChallengeWaiting(challengeId, senderUsername, true);
    } catch (e) {
      AppLogger.error('Error accepting challenge: $e');
      showSnackBar('Error accepting challenge: ${e.toString()}');
    } finally {
      setLoading(false);
      AppLogger.debug('Challenge acceptance process completed');
    }
  }
  
  
  // Decline a game challenge from a notification
  Future<void> declineGameChallengeFromNotification(String notificationId, String senderId) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) throw ChallengeServiceException('Not authenticated');

    try {
      // Get the notification to find the challenge ID
      final notificationDoc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .doc(notificationId)
          .get();
      
      if (!notificationDoc.exists) {
        throw ChallengeServiceException('Notification not found');
      }
      
      final notificationData = notificationDoc.data();
      if (notificationData == null) {
        throw ChallengeServiceException('Notification data not found');
      }
      
      // Mark the notification as read and declined
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .doc(notificationId)
          .update({
        'read': true,
        'accepted': false,
      });
      
      // Get the challenge ID if it exists
      final challengeId = notificationData['challengeId'] as String?;
      if (challengeId != null) {
        // Update the challenge status to declined
        await _firestore.collection('challenges').doc(challengeId).update({
          'status': 'declined'
        });
      }
      
      // Get current user's username for the notification
      final currentUserDoc = await _firestore.collection('users').doc(userId).get();
      final username = currentUserDoc.data()?['username'] ?? 'Unknown';
      
      // Create a notification for the sender that their challenge was declined
      await _firestore
          .collection('users')
          .doc(senderId)
          .collection('notifications')
          .add({
        'type': 'challengeDeclined',
        'senderId': userId,
        'senderUsername': username,
        'timestamp': FieldValue.serverTimestamp(),
        'read': false,
      });
      
      AppLogger.debug('Challenge declined, notification sent to sender');
    } catch (e) {
      developer.log('Error declining game challenge: $e', error: e);
      throw ChallengeServiceException('Failed to decline challenge: ${e.toString()}');
    }
  }
  
  // Handle the complete challenge decline flow with UI feedback
  Future<void> handleChallengeDecline({
    required String notificationId,
    required String senderId,
    required Function(String) showSnackBar,
    required Function(bool) setLoading,
  }) async {
    AppLogger.debug('Starting challenge decline process for notification: $notificationId from sender: $senderId');
    setLoading(true);
    
    try {
      // Use the existing method to decline the game challenge
      await declineGameChallengeFromNotification(notificationId, senderId);
      AppLogger.debug('Challenge declined successfully');
      
      // Show success message
      showSnackBar('Challenge declined');
    } catch (e) {
      AppLogger.error('Error declining challenge: $e');
      showSnackBar('Error declining challenge: ${e.toString()}');
    } finally {
      setLoading(false);
      AppLogger.debug('Challenge decline process completed');
    }
  }

  // Update the status of a challenge
  Future<void> updateChallengeStatus(String challengeId, String status) async {
    try {
      final challengeDoc = await _firestore.collection('challenges').doc(challengeId).get();
      if (challengeDoc.exists) {
        AppLogger.debug('Updating challenge $challengeId status to $status');
        await _firestore.collection('challenges').doc(challengeId).update({
          'status': status
        });
      } else {
        AppLogger.error('Challenge $challengeId not found');
      }
    } catch (e) {
      AppLogger.error('Error updating challenge status: $e');
      throw ChallengeServiceException('Failed to update challenge status: ${e.toString()}');
    }
  }
}