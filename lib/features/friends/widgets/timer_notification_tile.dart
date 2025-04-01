import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:vanishingtictactoe/core/utils/app_logger.dart';

/// A notification tile with a self-contained timer for countdown functionality.
/// Used for time-sensitive notifications like game challenges.
class TimerNotificationTile extends StatefulWidget {
  final Map<String, dynamic> notification;
  final IconData icon;
  final String title;
  final String content;
  final Color color;
  final List<Widget> actions;
  final bool isRead;
  final String initialTimeRemaining;
  final int initialSecondsRemaining;

  const TimerNotificationTile({
    super.key,
    required this.notification,
    required this.icon,
    required this.title,
    required this.content,
    required this.color,
    required this.actions,
    required this.isRead,
    required this.initialTimeRemaining,
    required this.initialSecondsRemaining,
  });
  

  @override
  TimerNotificationTileState createState() => TimerNotificationTileState();
}

class TimerNotificationTileState extends State<TimerNotificationTile> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  // Don't create a new NotificationService instance for each tile

  late int secondsRemaining;
  late String timeRemaining;
  bool hasExpired = false;
  Timer? _timer;
  bool _disposed = false;

  @override
  void initState() {
    super.initState();
    secondsRemaining = widget.initialSecondsRemaining;
    timeRemaining = widget.initialTimeRemaining;
    
    // Check if already expired based on the initial seconds
    if (secondsRemaining <= 0) {
      hasExpired = true;
      timeRemaining = '';
    } else {
      startTimer();
    }
  }

  @override
  void dispose() {
    // Mark as disposed and cancel the timer
    _disposed = true;
    _timer?.cancel();
    _timer = null;
    super.dispose();
  }
  
  @override
  void didUpdateWidget(TimerNotificationTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // If the notification data changed (like secondsRemaining), update our state
    if (oldWidget.initialSecondsRemaining != widget.initialSecondsRemaining) {
      secondsRemaining = widget.initialSecondsRemaining;
      timeRemaining = widget.initialTimeRemaining;
      
      if (secondsRemaining <= 0 && !hasExpired) {
        hasExpired = true;
        _timer?.cancel();
        _timer = null;
      }
    }
  }

  void startTimer() {
    // Don't start a timer if we're already expired or disposed
    if (hasExpired || _disposed) return;
    
    // Cancel any existing timer before starting a new one
    _timer?.cancel();
    
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      // Check if the widget is still mounted before calling setState
      if (_disposed) {
        timer.cancel();
        return;
      }

      // Use a safe setState pattern
      if (mounted) {
        setState(() {
          secondsRemaining -= 1;
          if (secondsRemaining <= 0) {
            timer.cancel();
            hasExpired = true;
            timeRemaining = '';
            // Update in Firestore that this notification has expired
            _markAsExpired();
          } else {
            timeRemaining = '$secondsRemaining ${secondsRemaining == 1 ? 'second' : 'seconds'}';
          }
        });
      } else {
        // If not mounted, cancel the timer
        timer.cancel();
      }
    });
  }
  
  // Separate method to mark notification as expired
  void _markAsExpired() {
    if (widget.notification['id'] != null && !_disposed) {
      try {
        final userId = _auth.currentUser?.uid;
        if (userId == null) return;
        
        _firestore
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .doc(widget.notification['id'])
          .update({'expired': true});
          
        // Also update the challenge if it exists
        final challengeId = widget.notification['challengeId'] as String?;
        if (challengeId != null) {
          _firestore.collection('challenges').doc(challengeId).get().then((doc) {
            if (doc.exists && doc.data()?['status'] == 'pending') {
              _firestore.collection('challenges').doc(challengeId).update({
                'status': 'expired'
              });
              AppLogger.debug('Updated challenge $challengeId status to expired from timer tile');
            }
          });
        }
      } catch (e) {
        // Use AppLogger instead of print
        AppLogger.error('Error marking notification as expired: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.all(16),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: widget.color.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(widget.icon, color: widget.color),
      ),
      title: Text(
        widget.title,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          Text(widget.content),
          const SizedBox(height: 4),
          Row(
            children: [
              Text(
                widget.notification['timeAgo'] ?? 'Just now',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 12,
                ),
              ),
              if (!hasExpired && secondsRemaining > 0) ...[  
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: secondsRemaining < 10 ? Colors.red.shade100 : Colors.orange.shade100,
                    borderRadius: BorderRadius.circular(4),
                    border: secondsRemaining < 10 ? Border.all(color: Colors.red.shade300, width: 1) : null,
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
                        style: TextStyle(
                          color: secondsRemaining < 10 ? Colors.red.shade800 : Colors.orange.shade800,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
          if (widget.actions.isNotEmpty && !hasExpired) ...[  
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: widget.actions,
            ),
          ],
        ],
      ),
      onTap: () {
        if (!widget.isRead) {
          // Mark notification as read directly instead of using NotificationService
          final userId = _auth.currentUser?.uid;
          if (userId != null) {
            _firestore
              .collection('users')
              .doc(userId)
              .collection('notifications')
              .doc(widget.notification['id'])
              .update({'read': true})
              .catchError((e) => AppLogger.error('Error marking notification as read: $e'));
          }
        }
      },
    );
  }
}
