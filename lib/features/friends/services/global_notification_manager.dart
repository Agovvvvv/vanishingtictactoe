import 'package:flutter/material.dart';
import 'dart:async';
import 'package:vanishingtictactoe/core/utils/app_logger.dart';
import 'package:vanishingtictactoe/features/friends/screens/challenge_waiting_screen.dart';
import 'package:vanishingtictactoe/features/friends/services/challenge_service.dart';
import 'package:vanishingtictactoe/core/navigation/navigation_service.dart';

/// Global key for the ScaffoldMessenger to show snackbars from anywhere in the app
final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

/// A singleton service that manages global notifications that can appear anywhere in the app
class GlobalNotificationManager {
  /// Singleton instance
  static GlobalNotificationManager? _instance;
  
  /// Challenge service for handling challenge-related operations
  final ChallengeService _challengeService = ChallengeService();
  
  /// Map to store timers for each notification
  final Map<String, Timer> _notificationTimers = {};
  
  /// Flag to track if we're currently in a game
  bool _isInGame = false;
  
  /// Factory constructor to return the singleton instance
  factory GlobalNotificationManager() {
    _instance ??= GlobalNotificationManager._internal();
    return _instance!;
  }
  
  /// Private constructor for singleton pattern
  GlobalNotificationManager._internal();
  
  /// Set the in-game status to prevent notifications during gameplay
  void setInGameStatus(bool isInGame) {
    _isInGame = isInGame;
  }
  
  /// Shows a challenge accepted notification with modern styling
  /// 
  /// Displays a sleek notification when a friend accepts a challenge,
  /// with options to join or decline the game
  void showChallengeAcceptedNotification({
    required BuildContext context,
    required String friendUsername,
    required String challengeId,
  }) {
    // Don't show notifications during gameplay
    if (_isInGame) {
      AppLogger.debug('Not showing challenge accepted notification because user is in a game');
      return;
    }
    
    AppLogger.debug('Showing challenge accepted notification for challenge ID: $challengeId');
    
    // Create a custom SnackBar with progress indicator and both decline and join options
    final customSnackBar = _buildCustomSnackBar(
      context: context,
      friendUsername: friendUsername,
      challengeId: challengeId,
    );
    
    // Try to show the snackbar using the global key first
    try {
      // Use the global ScaffoldMessengerKey if available
      if (scaffoldMessengerKey.currentState != null) {
        scaffoldMessengerKey.currentState!.showSnackBar(customSnackBar);
        AppLogger.debug('Showed snackbar using global ScaffoldMessengerKey');
      } 
      // Fall back to context if global key doesn't work
      else if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(customSnackBar);
        AppLogger.debug('Showed snackbar using provided context');
      } else {
        // Last resort: try using the navigator key's context
        final navigatorContext = navigatorKey.currentContext;
        if (navigatorContext != null) {
          ScaffoldMessenger.of(navigatorContext).showSnackBar(customSnackBar);
          AppLogger.debug('Showed snackbar using navigator context');
        } else {
          AppLogger.error('Failed to show snackbar: no valid context available');
        }
      }
    } catch (e) {
      AppLogger.error('Error showing snackbar: $e');
    }
  }
  
  /// Builds a modern, sleek custom SnackBar with progress indicator and action buttons
  ///
  /// Creates a visually appealing notification with gradient background, animated
  /// progress indicator, and stylish buttons for user interaction
  SnackBar _buildCustomSnackBar({
    required BuildContext context,
    required String friendUsername,
    required String challengeId,
  }) {
    // Create a controller for the progress indicator
    final progressController = ValueNotifier<double>(1.0);
    
    // Set up a timer to update the progress
    Timer? progressTimer;
    progressTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (progressController.value <= 0) {
        timer.cancel();
        scaffoldMessengerKey.currentState?.hideCurrentSnackBar();
      } else {
        // Decrease by 1/600 every 100ms (60 seconds total)
        progressController.value -= 1/600;
        if (progressController.value < 0) progressController.value = 0;
      }
    });
    
    // Store the timer for cleanup
    _notificationTimers[challengeId] = progressTimer;
    
    // Function to dismiss the SnackBar and cancel the timer
    void dismissSnackBar() {
      progressTimer?.cancel();
      _notificationTimers.remove(challengeId);
      scaffoldMessengerKey.currentState?.hideCurrentSnackBar();
    }
    
    // Define gradient colors for modern look
    final gradientColors = [
      const Color(0xFF2962FF), // Primary blue
      const Color(0xFF0039CB), // Darker blue
    ];
    
    return SnackBar(
      content: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: gradientColors,
          ),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                // Game icon with gradient background
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.white.withOpacity(0.3),
                        Colors.white.withOpacity(0.1),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.sports_esports,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                // Challenge text
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$friendUsername accepted your challenge!',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          letterSpacing: 0.3,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'You have 60 seconds to respond',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 14,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Action buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // Decline button with modern styling
                TextButton(
                  onPressed: () {
                    // Decline the challenge in Firestore
                    _challengeService.declineGameChallenge(challengeId).then((_) {
                      AppLogger.debug('Successfully declined challenge: $challengeId');
                      // Show a confirmation message
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'You declined ${friendUsername}"s challenge',
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                          backgroundColor: Colors.grey.shade800,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    }).catchError((error) {
                      AppLogger.error('Error declining challenge: $error');
                      // Show an error message
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text(
                            'Failed to decline challenge',
                            style: TextStyle(fontWeight: FontWeight.w500),
                          ),
                          backgroundColor: Colors.red.shade800,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    });
                    
                    // Dismiss the notification
                    dismissSnackBar();
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    backgroundColor: Colors.white.withOpacity(0.1),
                  ),
                  child: const Text(
                    'DECLINE',
                    style: TextStyle(fontWeight: FontWeight.w600, letterSpacing: 0.5),
                  ),
                ),
                const SizedBox(width: 12),
                // Join game button with gradient
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.white,
                        Colors.white.withOpacity(0.9),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: () {
                      dismissSnackBar();
                      // Navigate to the challenge waiting screen
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => ChallengeWaitingScreen(
                            challengeId: challengeId,
                            friendUsername: friendUsername,
                            isReceiver: false, // Sender, not receiver
                          ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      foregroundColor: const Color(0xFF2962FF),
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text(
                      'JOIN GAME',
                      style: TextStyle(fontWeight: FontWeight.w600, letterSpacing: 0.5),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Animated progress indicator
            Container(
              margin: const EdgeInsets.only(bottom: 4),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: ValueListenableBuilder<double>(
                  valueListenable: progressController,
                  builder: (context, progress, _) {
                    return LinearProgressIndicator(
                      value: progress,
                      backgroundColor: Colors.white.withOpacity(0.15),
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white.withOpacity(0.8)),
                      minHeight: 4,
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
      backgroundColor: Colors.transparent,
      elevation: 0,
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      padding: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      duration: const Duration(seconds: 60),
      dismissDirection: DismissDirection.horizontal,
    );
  }
  
  /// Clean up resources when the manager is no longer needed
  void dispose() {
    // Cancel all active timers
    for (final timer in _notificationTimers.values) {
      timer.cancel();
    }
    _notificationTimers.clear();
    AppLogger.debug('GlobalNotificationManager disposed');
  }
}
