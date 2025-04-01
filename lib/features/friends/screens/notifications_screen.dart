import 'package:flutter/material.dart';
import 'package:vanishingtictactoe/features/friends/services/notification_service.dart';
import 'package:vanishingtictactoe/features/friends/services/challenge_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import 'package:vanishingtictactoe/features/friends/screens/challenge_waiting_screen.dart';
import 'package:vanishingtictactoe/core/utils/app_logger.dart';
import 'package:vanishingtictactoe/features/friends/widgets/timer_notification_tile.dart';
import 'package:vanishingtictactoe/core/utils/font_preloader.dart';
import 'package:vanishingtictactoe/core/constants/app_colors.dart';
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  late final NotificationService _notificationService;
  late final ChallengeService _challengeService;
  bool _isLoading = false;
  
  @override
  void initState() {
    super.initState();
    // Initialize the services
    _notificationService = NotificationService();
    _challengeService = ChallengeService();
    // No need to call _checkExpiredNotifications() here as the service now does it automatically
  }
  
  @override
  void dispose() {
    // Dispose the notification service to cancel any timers
    _notificationService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Notifications',
          style: FontPreloader.getTextStyle(
            fontFamily: 'Orbitron',
            fontSize: 22,
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.background, AppColors.primaryBlueLight],
          ),
        ),
        child: _isLoading
            ? Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryBlue)))
            : StreamBuilder<List<Map<String, dynamic>>>(
                stream: _notificationService.getNotifications(limit: 15),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryBlue)));
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        'Error loading notifications: ${snapshot.error}',
                        style: TextStyle(color: AppColors.error),
                      ),
                    );
                  }

                  final notifications = snapshot.data ?? [];

                  if (notifications.isEmpty) {
                    return _buildEmptyState();
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: notifications.length,
                    itemBuilder: (context, index) {
                      final notification = notifications[index];
                      return _buildNotificationCard(notification);
                    },
                  );
                },
              ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.primaryBlueLight,
                  AppColors.primaryBlue.withOpacity(0.3),
                ],
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryBlue.withOpacity(0.2),
                  blurRadius: 10,
                  spreadRadius: 0,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Icon(
              Icons.notifications_none,
              size: 60,
              color: AppColors.primaryBlue,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No notifications yet',
            style: FontPreloader.getTextStyle(
              fontFamily: 'Poppins',
              fontSize: 18,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  
  Widget _buildNotificationCard(Map<String, dynamic> notification) {
    final type = notification['type'] as String? ?? '';
    final senderUsername = notification['senderUsername'] as String? ?? 'Unknown';
    final timestamp = notification['timestamp'] as Timestamp?;
    final isRead = notification['read'] as bool? ?? false;
    final senderId = notification['senderId'] as String? ?? '';
    final expirationTime = notification['expirationTime'] as Timestamp?;
    final isExpired = notification['expired'] as bool? ?? false;

    // Add timeAgo to the notification object for use in TimerNotificationTile
    String timeAgo = 'Just now';
    if (timestamp != null) {
      final now = DateTime.now();
      final difference = now.difference(timestamp.toDate());
      if (difference.inMinutes < 1) {
        timeAgo = 'Just now';
      } else if (difference.inMinutes < 60) {
        timeAgo = '${difference.inMinutes}m ago';
      } else if (difference.inHours < 24) {
        timeAgo = '${difference.inHours}h ago';
      } else {
        timeAgo = '${difference.inDays}d ago';
      }
    }
    notification['timeAgo'] = timeAgo;

    // Get time remaining from the notification or calculate it
    String timeRemaining = '';
    bool hasExpired = isExpired;
    int secondsRemaining = 0;
    
    // Handle time remaining for both game challenge and challenge accepted notifications
    if ((type == 'gameChallenge' || type == 'challengeAccepted') && expirationTime != null) {
      // Check if we have pre-calculated seconds remaining from the service
      if (notification['secondsRemaining'] != null) {
        secondsRemaining = notification['secondsRemaining'] as int;
      } else {
        // Calculate manually if not provided
        final now = DateTime.now();
        final expiration = expirationTime.toDate();
        if (now.isBefore(expiration)) {
          final remaining = expiration.difference(now);
          secondsRemaining = remaining.inSeconds;
        }
      }
      
      // Format the time remaining string
      if (secondsRemaining > 0) {
        timeRemaining = '$secondsRemaining ${secondsRemaining == 1 ? 'second' : 'seconds'}';
      } else {
        hasExpired = true;
      }
    }

    // Determine icon and content based on notification type
    IconData icon;
    String title;
    String content;
    Color color;
    List<Widget> actions = [];

    switch (type) {
      case 'gameChallenge':
        icon = Icons.sports_esports;
        title = 'Game Challenge';
        
        // Handle different states of game challenge notifications
        if (hasExpired) {
          content = '$senderUsername challenged you to a game (expired)';
          color = Colors.grey.shade700;
        } else if (notification['accepted'] == true) {
          content = 'You accepted $senderUsername\'s game challenge';
          color = Colors.green.shade700;
          
          // Show a button to view the game if there's a challenge ID
          final challengeId = notification['challengeId'] as String?;
          if (challengeId != null) {
            actions = [
              ElevatedButton(
                onPressed: () {
                  _notificationService.markNotificationAsRead(notification['id']);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ChallengeWaitingScreen(
                        challengeId: challengeId,
                        friendUsername: senderUsername,
                        isReceiver: true,
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade500,
                ),
                child: const Text('View Game'),
              ),
            ];
          } else if (notification['gameId'] != null) {
            // Handle legacy game ID if present
            // This would navigate to the game screen
          }
        } else if (notification['accepted'] == false) {
          content = 'You declined $senderUsername\'s game challenge';
          color = Colors.red.shade700;
        } else {
          // New notification that hasn't been handled yet
          content = '$senderUsername has challenged you to a game!';
          color = Colors.blue.shade700;
          
          // Only show accept/decline buttons if not already handled and not expired
          actions = [
            TextButton(
              onPressed: () => _declineChallenge(notification['id'], senderId),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(
                'Decline',
                style: FontPreloader.getTextStyle(
                  fontFamily: 'Orbitron',
                  fontSize: 14,
                  color: Colors.grey.shade700,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () => _acceptChallenge(notification['id'], senderId),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade500,
                foregroundColor: Colors.white,
                elevation: 2,
                shadowColor: Colors.blue.shade300.withValues( alpha: 0.5),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(
                'Accept',
                style: FontPreloader.getTextStyle(
                  fontFamily: 'Orbitron',
                  fontSize: 14,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ];
        }
        break;
      case 'challengeAccepted':
        icon = Icons.check_circle;
        title = 'Challenge Accepted';
        content = '$senderUsername accepted your game challenge!';
        color = Colors.green.shade700;
        
        // We already calculated time remaining and expiration status above
        // No need to recalculate here
        
        // Add status indicator for older notifications
        final acceptedTimestamp = notification['timestamp'] as Timestamp?;
        if (acceptedTimestamp != null && (hasExpired || secondsRemaining == 0)) {
          final now = DateTime.now();
          final difference = now.difference(acceptedTimestamp.toDate());
          if (difference.inMinutes > 60) {
            // If it's been more than an hour, show it as a past event
            content = '$senderUsername accepted your game challenge (completed)';
          } else {
            content = '$senderUsername accepted your game challenge (expired)';
          }
        }
        
        // Add button to navigate to the challenge waiting screen if not expired
        final challengeId = notification['challengeId'] as String?;
        if (challengeId != null && !hasExpired && secondsRemaining > 0) {
          actions = [
            ElevatedButton(
              onPressed: () {
                // Mark notification as read
                _notificationService.markNotificationAsRead(notification['id']);
                
                // Navigate to the challenge waiting screen as the sender
                AppLogger.debug('Navigating to ChallengeWaitingScreen from notification with challengeId: $challengeId');
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ChallengeWaitingScreen(
                      challengeId: challengeId,
                      friendUsername: senderUsername,
                      isReceiver: false, // This user is the sender of the challenge
                    ),
                  ),
                ).then((_) {
                  AppLogger.debug('Returned from ChallengeWaitingScreen after accepting challenge');
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade500,
                foregroundColor: Colors.white,
                elevation: 2,
                shadowColor: Colors.green.shade300.withValues( alpha: 0.5),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(
                'Join Game',
                style: FontPreloader.getTextStyle(
                  fontFamily: 'Orbitron',
                  fontSize: 14,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ];
        }
        
        // Timer display is now handled by the useTimerTile condition at the end of the method
        break;
      case 'challengeDeclined':
        icon = Icons.cancel;
        title = 'Challenge Declined';
        content = '$senderUsername declined your game challenge';
        color = Colors.red.shade700;
        
        // Add status indicator for older notifications
        final declinedTimestamp = notification['timestamp'] as Timestamp?;
        if (declinedTimestamp != null) {
          final now = DateTime.now();
          final difference = now.difference(declinedTimestamp.toDate());
          if (difference.inMinutes > 60) {
            // If it's been more than an hour, show it as a past event
            content = '$senderUsername declined your game challenge (past)';
          }
        }
        break;
      case 'gameResult':
        // Determine if the user won or lost
        final bool userWon = notification['userWon'] as bool? ?? false;
        final bool isDraw = notification['isDraw'] as bool? ?? false;
        final String gameMode = notification['gameMode'] as String? ?? 'Standard';
        final String opponentUsername = notification['opponentUsername'] as String? ?? 'Opponent';
        
        // Set appropriate icon and colors based on game result
        if (isDraw) {
          icon = Icons.handshake;
          title = 'Game Draw';
          content = 'Your game with $opponentUsername ended in a draw';
          color = Colors.amber.shade700;
        } else if (userWon) {
          icon = Icons.emoji_events;
          title = 'Victory!';
          content = 'You won against $opponentUsername in $gameMode mode';
          color = Colors.green.shade700;
        } else {
          icon = Icons.sentiment_dissatisfied;
          title = 'Defeat';
          content = 'You lost to $opponentUsername in $gameMode mode';
          color = Colors.purple.shade700;
        }
        
        // Add any rank changes if available
        final int? rankChange = notification['rankChange'] as int?;
        if (rankChange != null && rankChange != 0) {
          final String rankChangeText = rankChange > 0 ? '+$rankChange' : '$rankChange';
          content += ' ($rankChangeText points)';
        }
        
        // Add button to view match details if match ID is available
        final String? matchId = notification['matchId'] as String?;
        if (matchId != null) {
          actions = [
            ElevatedButton(
              onPressed: () {
                _notificationService.markNotificationAsRead(notification['id']);
                // Navigate to match history detail screen
                // This would need to be implemented in your app
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Match details coming soon!'))
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                foregroundColor: Colors.white,
                elevation: 2,
                shadowColor: color.withValues(alpha: 0.5),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(
                'View Details',
                style: FontPreloader.getTextStyle(
                  fontFamily: 'Orbitron',
                  fontSize: 14,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ];
        }
        break;
      default:
        icon = Icons.notifications;
        title = 'Notification';
        content = 'You have a new notification.';
        color = Colors.blue.shade700;
    }

    // Check if this notification should use the timer tile
    final bool useTimerTile = !hasExpired && timeRemaining.isNotEmpty && 
                            (type == 'gameChallenge' || type == 'challengeAccepted');
                            
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 3,
      shadowColor: AppColors.primaryBlue.withOpacity(0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              isRead ? AppColors.background : AppColors.primaryBlueLight,
              isRead ? Colors.grey.shade50 : AppColors.primaryBlue.withOpacity(0.2),
            ],
          ),
        ),
        child: useTimerTile
            ? TimerNotificationTile(
                notification: notification, 
                icon: icon, 
                title: title, 
                content: content, 
                color: color, 
                actions: actions, 
                isRead: isRead, 
                initialTimeRemaining: timeRemaining, 
                initialSecondsRemaining: secondsRemaining,)
            : ListTile(
          contentPadding: const EdgeInsets.all(16),
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  color.withValues( alpha: 0.2),
                  color.withValues( alpha: 0.4),
                ],
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withValues( alpha: 0.2),
                  blurRadius: 6,
                  spreadRadius: 0,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(icon, color: color),
          ),
          title: Text(
            title,
            style: FontPreloader.getTextStyle(
              fontFamily: 'Orbitron',
              fontSize: 16,
              color: Colors.black87,
              fontWeight: FontWeight.bold,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              Text(
                content,
                style: FontPreloader.getTextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 14,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Text(
                    timeAgo,
                    style: FontPreloader.getTextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  if (timeRemaining.isNotEmpty) ...[  
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            secondsRemaining < 10 ? Colors.red.shade100 : Colors.orange.shade100,
                            secondsRemaining < 10 ? Colors.red.shade200 : Colors.orange.shade200,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(8),
                        border: secondsRemaining < 10 ? Border.all(color: Colors.red.shade300, width: 1) : null,
                        boxShadow: [
                          BoxShadow(
                            color: (secondsRemaining < 10 ? Colors.red.shade300 : Colors.orange.shade300).withValues( alpha: 0.3),
                            blurRadius: 4,
                            spreadRadius: 0,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.timer,
                            size: 12,
                            color: secondsRemaining < 10 ? Colors.red.shade800 : Colors.orange.shade800,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            timeRemaining,
                            style: FontPreloader.getTextStyle(
                              fontFamily: 'Orbitron',
                              fontSize: 12,
                              color: secondsRemaining < 10 ? Colors.red.shade800 : Colors.orange.shade800,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
              if (actions.isNotEmpty) ...[  
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: actions,
                ),
              ],
            ],
          ),
          onTap: () {
            if (!isRead) {
              _notificationService.markNotificationAsRead(notification['id']);
            }
          },
        ),
      ),
    );
  }
 

  Future<void> _acceptChallenge(String notificationId, String senderId) async {
    // Use the ChallengeService to handle the complete challenge acceptance flow
    await _challengeService.handleChallengeAcceptance(
      notificationId: notificationId,
      senderId: senderId,
      setLoading: (isLoading) {
        if (mounted) {
          setState(() => _isLoading = isLoading);
        }
      },
      showSnackBar: (message) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(message),
              backgroundColor: message.contains('Error') ? Colors.red : Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      },
      navigateToChallengeWaiting: (challengeId, senderUsername, isReceiver) {
        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ChallengeWaitingScreen(
                challengeId: challengeId,
                friendUsername: senderUsername,
                isReceiver: isReceiver,
              ),
            ),
          ).then((_) {
            AppLogger.debug('Returned from ChallengeWaitingScreen');
          });
        }
      },
    );
  }

  Future<void> _declineChallenge(String notificationId, String senderId) async {
    // Use the ChallengeService to handle the complete challenge decline flow
    await _challengeService.handleChallengeDecline(
      notificationId: notificationId,
      senderId: senderId,
      setLoading: (isLoading) {
        if (mounted) {
          setState(() => _isLoading = isLoading);
        }
      },
      showSnackBar: (message) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(message),
              backgroundColor: message.contains('Error') ? Colors.red : Colors.grey,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      },
    );
  }
  
  
}