import 'dart:async';
import 'package:flutter/material.dart';
import 'package:vanishingtictactoe/core/utils/font_preloader.dart';
import 'package:vanishingtictactoe/core/constants/app_colors.dart';

/// A sliding notification that appears at the bottom of the screen when a friend accepts a challenge
class ChallengeAcceptedNotification extends StatefulWidget {
  final String friendUsername;
  final String challengeId;
  final VoidCallback onDismiss;
  final VoidCallback onDecline;
  final Function(String, String, bool) onJoin;

  const ChallengeAcceptedNotification({
    super.key,
    required this.friendUsername,
    required this.challengeId,
    required this.onDismiss,
    required this.onDecline,
    required this.onJoin,
  });

  @override
  State<ChallengeAcceptedNotification> createState() => _ChallengeAcceptedNotificationState();
}

class _ChallengeAcceptedNotificationState extends State<ChallengeAcceptedNotification> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<Offset> _offsetAnimation;
  late Timer _expirationTimer;
  int _secondsRemaining = 60; // 1 minute expiration
  bool _isDismissed = false;

  @override
  void initState() {
    super.initState();
    
    // Set up the animation controller
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    
    // Create a sliding animation from bottom to top
    _offsetAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));
    
    // Start the animation
    _animationController.forward();
    
    // Start the expiration timer
    _startExpirationTimer();
  }
  
  void _startExpirationTimer() {
    _expirationTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          if (_secondsRemaining > 0) {
            _secondsRemaining--;
          } else {
            _dismiss();
            timer.cancel();
          }
        });
      }
    });
  }
  
  void _dismiss() {
    if (_isDismissed) return;
    
    setState(() {
      _isDismissed = true;
    });
    
    _animationController.reverse().then((_) {
      widget.onDismiss();
    });
  }
  
  void _decline() {
    if (_isDismissed) return;
    
    setState(() {
      _isDismissed = true;
    });
    
    _animationController.reverse().then((_) {
      widget.onDecline();
    });
  }
  
  void _join() {
    if (_isDismissed) return;
    
    setState(() {
      _isDismissed = true;
    });
    
    _animationController.reverse().then((_) {
      widget.onJoin(widget.challengeId, widget.friendUsername, false);
    });
  }

  @override
  void dispose() {
    _expirationTimer.cancel();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _offsetAnimation,
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.primaryBlue.withOpacity(0.9),
                  AppColors.primaryBlue,
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryBlue.withOpacity(0.3),
                  blurRadius: 10,
                  spreadRadius: 0,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.sports_esports,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Challenge Accepted!',
                                style: FontPreloader.getTextStyle(
                                  fontFamily: 'Orbitron',
                                  fontSize: 16,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${widget.friendUsername} accepted your game challenge',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.white),
                          onPressed: _dismiss,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Timer progress bar
                    LinearProgressIndicator(
                      value: _secondsRemaining / 60,
                      backgroundColor: Colors.white.withOpacity(0.2),
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Expires in $_secondsRemaining seconds',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: _decline,
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.white70,
                          ),
                          child: const Text('Decline'),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: _join,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: AppColors.primaryBlue,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          ),
                          child: const Text('Join Game'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
