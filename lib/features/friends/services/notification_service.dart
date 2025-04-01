
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:vanishingtictactoe/core/exceptions/friend_service_exception.dart';
import 'dart:async';
import 'package:flutter/material.dart';

import 'package:vanishingtictactoe/core/utils/app_logger.dart';
import 'package:vanishingtictactoe/features/friends/services/challenge_service.dart';
import 'package:vanishingtictactoe/features/friends/services/global_notification_manager.dart';
import 'package:vanishingtictactoe/core/navigation/navigation_service.dart';

class NotificationService {
  // Singleton instance
  static NotificationService? _instance;
  
  // Factory constructor to return the singleton instance
  factory NotificationService() {
    _instance ??= NotificationService._internal();
    return _instance!;
  }
  
  // Private constructor for singleton pattern
  NotificationService._internal() {
    // Set up a timer to periodically check for expired notifications
    // Check less frequently (5 minutes instead of 30 seconds)
    _expirationCheckTimer = Timer.periodic(const Duration(minutes: 5), (_) {
      _checkExpiredNotificationsIfNeeded();
    });
    
    // Also check immediately on initialization
    _checkExpiredNotificationsIfNeeded();
    
    AppLogger.debug('NotificationService initialized with expiration timer');
  }
  
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final ChallengeService _challengeService = ChallengeService();
  final GlobalNotificationManager _notificationManager = GlobalNotificationManager();
  Timer? _expirationCheckTimer;
  StreamSubscription? _challengeAcceptedSubscription;
  BuildContext? _globalContext;
  // Track the last time we checked for expired notifications to avoid excessive checks
  DateTime? _lastExpirationCheck;
  
  // Dispose method to clean up resources
  void dispose() {
    _expirationCheckTimer?.cancel();
    _challengeAcceptedSubscription?.cancel();
    _expirationCheckTimer = null;
    _challengeAcceptedSubscription = null;
    AppLogger.debug('NotificationService disposed');
  }
  
  // Set up the global context for showing notifications
  void setGlobalContext(BuildContext context) {
    // Store the context for showing notifications
    _globalContext = context;
    
    // Start listening for challenge acceptances
    _startListeningForChallengeAcceptances();
  }
  
  // Set the in-game status to prevent notifications during gameplay
  void setInGameStatus(bool isInGame) {
    _notificationManager.setInGameStatus(isInGame);
  }

  // Get all notifications for the current user with real-time expiration updates
  Stream<List<Map<String, dynamic>>> getNotifications({int limit = 15}) {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return Stream.value([]);

    // Get the base stream of notifications, limited to the specified number
    final notificationsStream = _firestore
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .snapshots()
        .handleError((error) {
          AppLogger.error('Error fetching notifications: $error');
          return [];
        })
        .map((snapshot) => snapshot.docs
            .map((doc) => {
                  'id': doc.id,
                  ...doc.data(),
                })
            .toList());
    
    // Transform the stream to check for expirations in real-time
    return notificationsStream.map((notifications) {
      final now = DateTime.now();
      
      // Process each notification to check for expiration
      return notifications.map((notification) {
        // Check if this is a notification type with an expiration time
        if ((notification['type'] == 'gameChallenge' || notification['type'] == 'challengeAccepted') && 
            notification['expirationTime'] != null && 
            notification['expired'] != true) {
          
          final expirationTime = notification['expirationTime'] as Timestamp;
          final expirationDateTime = expirationTime.toDate();
          final isExpired = now.isAfter(expirationDateTime);
          
          // If expired but not marked as such, update the database
          if (isExpired && notification['expired'] != true) {
            _markNotificationAsExpired(notification['id']);
            
            // Also update the challenge if it exists
            final challengeId = notification['challengeId'] as String?;
            if (challengeId != null) {
              _firestore.collection('challenges').doc(challengeId).get().then((doc) {
                if (doc.exists && doc.data()?['status'] == 'pending') {
                  _firestore.collection('challenges').doc(challengeId).update({
                    'status': 'expired'
                  });
                  AppLogger.debug('Updated challenge $challengeId status to expired');
                }
              }).catchError((e) {
                AppLogger.error('Error updating challenge status: $e');
              });
            }
            
            AppLogger.debug('Notification ${notification['id']} expired at ${expirationDateTime.toString()}');
          }
          
          // Calculate seconds remaining
          int secondsRemaining = 0;
          if (!isExpired) {
            secondsRemaining = _calculateSecondsRemaining(expirationDateTime);
            // Only log remaining time for notifications with less than 5 minutes remaining
            // This reduces log spam for notifications with a lot of time left
            if (secondsRemaining < 300) {
              AppLogger.debug('Notification ${notification['id']} has $secondsRemaining seconds remaining');
            }
          }
          
          // Update the notification object with current expiration status
          return {
            ...notification,
            'expired': isExpired,
            'secondsRemaining': secondsRemaining,
          };
        }
        return notification;
      }).toList();
    });
  }

  // Mark notification as read
  Future<void> markNotificationAsRead(String notificationId) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .doc(notificationId)
          .update({'read': true});
    } catch (e) {
      AppLogger.error('Error marking notification as read: $e');
    }
  }
  
  // Mark notification as expired
  Future<void> _markNotificationAsExpired(String notificationId) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    try {
      // First get the notification to check if it has a challenge ID
      final notificationDoc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .doc(notificationId)
          .get();
      
      if (!notificationDoc.exists) {
        AppLogger.error('Notification $notificationId not found');
        return;
      }
      
      // Update the notification
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .doc(notificationId)
          .update({'expired': true});
      
      // Also update the challenge if it exists
      final challengeId = notificationDoc.data()?['challengeId'] as String?;
      if (challengeId != null) {
        try {
          // Delegate the challenge status update to ChallengeService
          await _challengeService.updateChallengeStatus(challengeId, 'expired');
        } catch (e) {
          AppLogger.error('Error updating challenge status: $e');
        }
      }
      
      AppLogger.debug('Marked notification $notificationId as expired');
    } catch (e) {
      AppLogger.error('Error marking notification as expired: $e');
    }
  }
  
  // Calculate seconds remaining until expiration
  int _calculateSecondsRemaining(DateTime expirationTime) {
    final now = DateTime.now();
    if (now.isAfter(expirationTime)) return 0;
    
    final remaining = expirationTime.difference(now);
    return remaining.inSeconds;
  }
  
  // Check if we need to run the expiration check based on time since last check
  Future<void> _checkExpiredNotificationsIfNeeded() async {
    final now = DateTime.now();
    
    // Skip check if we've checked recently (within the last 2 minutes)
    if (_lastExpirationCheck != null && 
        now.difference(_lastExpirationCheck!).inMinutes < 2) {
      return;
    }
    
    // Update the last check time
    _lastExpirationCheck = now;
    
    // Proceed with the actual check
    await _checkExpiredNotifications();
  }

  // Check for and update expired notifications
  Future<void> _checkExpiredNotifications() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;
    
    try {
      final now = DateTime.now();
      
      // Get notifications that might be expired but aren't marked as such
      // Add a time filter to only check notifications that are close to expiration or already expired
      // This reduces the number of documents we need to check
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .where('expired', isEqualTo: false)
          .where('type', whereIn: ['gameChallenge', 'challengeAccepted'])
          // Only get notifications created within the last day to further limit results
          .where('timestamp', isGreaterThan: Timestamp.fromDate(
              now.subtract(const Duration(days: 1))))
          .get();
          
      // Filter locally for those with expiration time in the past
      final expiredDocs = snapshot.docs.where((doc) {
        final expirationTime = doc.data()['expirationTime'] as Timestamp?;
        return expirationTime != null && expirationTime.toDate().isBefore(now);
      }).toList();
      
      // Only log if we actually found expired notifications
      if (expiredDocs.isNotEmpty) {
        AppLogger.debug('Found ${expiredDocs.length} expired notifications to update');
      }
      
      // Mark them as expired
      for (final doc in expiredDocs) {
        final notificationId = doc.id;
        AppLogger.debug('Marking notification $notificationId as expired');
        
        // Update the notification in Firestore
        await doc.reference.update({'expired': true});
        
        // If this is a challenge notification, also update the challenge status
        final challengeId = doc.data()['challengeId'] as String?;
        if (challengeId != null) {
          try {
            // Delegate the challenge status update to ChallengeService
            await _challengeService.updateChallengeStatus(challengeId, 'expired');
          } catch (e) {
            AppLogger.error('Error updating challenge status: $e');
          }
        }
      }
    } catch (e) {
      // Error handling is silent to not disrupt the UI
      AppLogger.error('Error checking expired notifications: $e');
    }
  }

  // Accept game challenge
  Future<String> acceptGameChallenge(String notificationId, String senderId) async {
    try {
      // Delegate to ChallengeService
      return await _challengeService.acceptGameChallengeFromNotification(notificationId, senderId);
    } catch (e) {
      // Convert ChallengeServiceException to FriendServiceException for backward compatibility
      throw FriendServiceException(e.toString());
    }
  }
  
  // Start listening for all challenge acceptances
  void _startListeningForChallengeAcceptances() {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;
    
    AppLogger.debug('Starting to listen for all challenge acceptances');
    
    // Stop any existing subscription first
    _challengeAcceptedSubscription?.cancel();
    
    // Get the current timestamp minus 30 seconds
    final thirtySecondsAgo = DateTime.now().subtract(const Duration(seconds: 30));
    final timestampThreshold = Timestamp.fromDate(thirtySecondsAgo);
    
    // Listen for all challenges sent by the current user that were recently accepted
    // and haven't had notifications shown yet
    _challengeAcceptedSubscription = _firestore
        .collection('challenges')
        .where('senderId', isEqualTo: userId)
        .where('status', isEqualTo: 'accepted')
        .where('notificationShown', isEqualTo: false)
        .snapshots()
        .listen((snapshot) {
          for (final doc in snapshot.docChanges) {
            // Only process newly accepted challenges
            if (doc.type == DocumentChangeType.modified || doc.type == DocumentChangeType.added) {
              final data = doc.doc.data()!;
              final status = data['status'] as String?;
              final receiverId = data['receiverId'] as String?;
              final challengeId = doc.doc.id;
              final timestamp = data['timestamp'] as Timestamp?;
              
              // Skip challenges that were accepted more than 30 seconds ago
              if (timestamp == null || timestamp.compareTo(timestampThreshold) < 0) {
                AppLogger.debug('Skipping old challenge $challengeId');
                continue;
              }
              
              // Double-check that the challenge was accepted
              if (status == 'accepted' && receiverId != null) {
                AppLogger.debug('Challenge $challengeId was accepted');
                
                // Get the receiver's username
                _firestore.collection('users').doc(receiverId).get().then((userDoc) {
                  if (!userDoc.exists) return;
                  
                  final userData = userDoc.data()!;
                  final friendUsername = userData['username'] as String? ?? 'Friend';
                  
                  AppLogger.debug('Received challenge acceptance notification from $friendUsername');
                  
                  // Mark this challenge as notified to prevent showing it again
                  _firestore.collection('challenges').doc(challengeId).update({
                    'notificationShown': true
                  }).catchError((e) {
                    AppLogger.error('Error updating challenge notification status: $e');
                  });
                  
                  try {
                    // Use the NavigationService's navigator key context
                    final navigatorContext = navigatorKey.currentContext;
                    if (navigatorContext != null) {
                      _notificationManager.showChallengeAcceptedNotification(
                        context: navigatorContext,
                        friendUsername: friendUsername,
                        challengeId: challengeId,
                      );
                    } else if (_globalContext != null && _globalContext!.mounted) {
                      // Fall back to the stored context if it's still valid
                      _notificationManager.showChallengeAcceptedNotification(
                        context: _globalContext!,
                        friendUsername: friendUsername,
                        challengeId: challengeId,
                      );
                    } else {
                      // If no valid context is available, use a dummy context just to queue the notification
                      // The notification manager will handle showing it when a valid context is available
                      _notificationManager.showChallengeAcceptedNotification(
                        context: navigatorContext ?? (_globalContext ?? BuildContext as dynamic),
                        friendUsername: friendUsername,
                        challengeId: challengeId,
                      );
                      AppLogger.debug('No valid context available, notification queued');
                    }
                  } catch (e) {
                    AppLogger.error('Error showing notification: $e');
                  }
                });
              }
            }
          }
        }, onError: (error) {
          AppLogger.error('Error listening for challenge acceptances: $error');
        });
  }


  // Decline game challenge
  Future<void> declineGameChallenge(String notificationId, String senderId) async {
    try {
      AppLogger.debug('Declining game challenge from notification: $notificationId, sender: $senderId');
      
      // Delegate to ChallengeService
      await _challengeService.declineGameChallengeFromNotification(notificationId, senderId);
      
      // Mark the notification as read immediately to improve UX
      await markNotificationAsRead(notificationId);
      
      // Show a confirmation to the user
      if (_globalContext != null) {
        ScaffoldMessenger.of(_globalContext!).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.cancel_rounded, color: Colors.white),
                const SizedBox(width: 12),
                Text('Challenge declined', style: TextStyle(fontWeight: FontWeight.w500)),
              ],
            ),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            duration: const Duration(seconds: 2),
          ),
        );
      }
      
      AppLogger.debug('Successfully declined game challenge');
    } catch (e) {
      AppLogger.error('Error declining game challenge: $e');
      // Convert ChallengeServiceException to FriendServiceException for backward compatibility
      throw FriendServiceException(e.toString());
    }
  }
  
  /// Creates a game result notification for a player
  /// 
  /// This notification shows the outcome of a completed game, including win/loss/draw status,
  /// opponent information, game mode, and optional rank changes.
  Future<void> createGameResultNotification({
    required String recipientId,
    required String opponentUsername,
    required bool userWon,
    required bool isDraw,
    String gameMode = 'Standard',
    String? matchId,
    int? rankChange,
  }) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      AppLogger.error('Cannot create game result notification: User not authenticated');
      return;
    }
    
    try {
      // Get the current user's username
      final userDoc = await _firestore.collection('users').doc(userId).get();
      final userData = userDoc.data();
      if (userData == null) {
        AppLogger.error('Cannot create game result notification: User data not found');
        return;
      }
      
      final senderUsername = userData['username'] as String? ?? 'Unknown';
      
      // Create the notification document
      await _firestore
          .collection('users')
          .doc(recipientId)
          .collection('notifications')
          .add({
        'type': 'gameResult',
        'senderId': userId,
        'senderUsername': senderUsername,
        'timestamp': FieldValue.serverTimestamp(),
        'read': false,
        'userWon': userWon,
        'isDraw': isDraw,
        'gameMode': gameMode,
        'opponentUsername': opponentUsername,
        if (matchId != null) 'matchId': matchId,
        if (rankChange != null) 'rankChange': rankChange,
      });
      
      AppLogger.debug('Game result notification created for user $recipientId');
    } catch (e) {
      AppLogger.error('Error creating game result notification: $e');
    }
  }
}