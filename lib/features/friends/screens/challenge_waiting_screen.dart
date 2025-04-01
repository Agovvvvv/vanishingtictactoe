import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:vanishingtictactoe/core/utils/app_logger.dart';
import 'package:vanishingtictactoe/features/friends/services/challenge_waiting_service.dart';
import 'package:vanishingtictactoe/features/friends/widgets/challenge/index.dart';
import 'package:vanishingtictactoe/core/navigation/navigation_service.dart';


class ChallengeWaitingScreen extends StatefulWidget {
  final String challengeId;
  final String friendUsername;
  final bool isReceiver;

  const ChallengeWaitingScreen({
    super.key,
    required this.challengeId,
    required this.friendUsername,
    this.isReceiver = false,
  });

  @override
  State<ChallengeWaitingScreen> createState() => _ChallengeWaitingScreenState();
}

class _ChallengeWaitingScreenState extends State<ChallengeWaitingScreen> {
  final ChallengeWaitingService _waitingService = ChallengeWaitingService();
  StreamSubscription? _challengeSubscription;
  bool _isLoading = false;
  bool _isExpired = false;
  bool _isCancelled = false; // Changed from final to allow setting it when sender doesn't join
  bool _isWaitingForSender = false; // True if this is the receiver waiting for the sender to join
  bool _isDeclined = false; // True if the challenge was declined
  String _declinedBy = ''; // Username of the person who declined
  Timer? _expirationTimer;
  int _secondsRemaining = 60; // 1 minute expiration
  Timer? _receiverWaitingTimer; // Timer for receiver waiting for sender to join

  @override
  void initState() {
    super.initState();
    _setupChallengeListener();
    
    // Only start the expiration timer if this is the sender waiting for acceptance
    // If this is the receiver waiting for the sender to join, we don't need the timer
    if (!widget.isReceiver) {
      _startExpirationTimer();
    }
    
    // If this is the receiver, check the challenge status immediately
    if (widget.isReceiver) {
      _checkInitialChallengeStatus();
    }
  }
  
  // Check the initial challenge status when the receiver opens the screen
  Future<void> _checkInitialChallengeStatus() async {
    try {
      final challengeData = await _waitingService.checkInitialChallengeStatus(widget.challengeId);
      
      if (challengeData == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Challenge no longer exists')),
          );
          NavigationService.instance.goBack(context);
        }
        return;
      }
      
      final status = challengeData['status'] as String?;
      
      // If the challenge is already accepted and this is the receiver,
      // show a different waiting message and start the receiver waiting timer
      if (status == 'accepted' && widget.isReceiver) {
        setState(() {
          _isWaitingForSender = true;
        });
        
        // Start a 1-minute timer for the receiver waiting for the sender to join
        _startReceiverWaitingTimer();
      }
    } catch (e) {
      // Handle error silently
      AppLogger.error('Error checking initial challenge status: $e');
    }
  }

  void _startExpirationTimer() {
    _expirationTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          if (_secondsRemaining > 0) {
            _secondsRemaining--;
          } else {
            _isExpired = true;
            timer.cancel();
          }
        });
      }
    });
  }
  
  // Start a timer for the receiver waiting for the sender to join
  void _startReceiverWaitingTimer() {
    AppLogger.debug('Starting receiver waiting timer for challenge ID: ${widget.challengeId}');
    
    // Cancel any existing timer first
    _receiverWaitingTimer?.cancel();
    
    // Create a new timer that will mark the challenge as cancelled after 1 minute
    _receiverWaitingTimer = Timer(const Duration(minutes: 1), () {
      if (mounted) {
        AppLogger.debug('Receiver waiting timer expired for challenge ID: ${widget.challengeId}');
        setState(() {
          _isCancelled = true;
        });
      }
    });
  }

  void _setupChallengeListener() {
    AppLogger.debug('Setting up challenge listener for challenge ID: ${widget.challengeId}, isReceiver: ${widget.isReceiver}');
    
    _challengeSubscription = _waitingService
        .listenForChallengeUpdates(widget.challengeId)
        .listen((challengeData) {
      if (challengeData == null) {
        // Challenge document doesn't exist
        AppLogger.debug('Challenge document doesn\'t exist for ID: ${widget.challengeId}');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Challenge no longer exists')),
          );
          NavigationService.instance.goBack(context);
        }
        return;
      }

      final status = challengeData['status'] as String?;
      AppLogger.debug('Challenge status update: $status for ID: ${widget.challengeId}');
      
      if (status == 'accepted') {
        AppLogger.debug('Challenge accepted! isReceiver: ${widget.isReceiver}');
        
        if (mounted) {
          if (!widget.isReceiver) {
            AppLogger.debug('Sender detected challenge acceptance, joining game');
            // Sender automatically joins the game when receiver accepts
            _joinGame();
          } else {
            AppLogger.debug('Updating UI for receiver to show waiting for sender');
            setState(() {
              _isWaitingForSender = true;
            });
            
            // Start a 1-minute timer for the receiver waiting for the sender to join
            _startReceiverWaitingTimer();
          }
        }
      } else if (status == 'declined') {
        AppLogger.debug('Challenge declined');
        // Friend declined the challenge
        if (mounted) {
          // Cancel any active timers to prevent them from triggering after decline
          _expirationTimer?.cancel();
          _receiverWaitingTimer?.cancel();
          
          final String declinedBy = widget.isReceiver ? 
              challengeData['senderUsername'] as String? ?? 'Friend' :
              challengeData['receiverUsername'] as String? ?? 'Friend';
              
          setState(() {
            _isDeclined = true;
            _declinedBy = declinedBy;
            // Ensure other states are reset
            _isExpired = false;
            _isCancelled = false;
            _isWaitingForSender = false;
          });
        }
      } else if (status == 'expired') {
        AppLogger.debug('Challenge expired');
        // Challenge expired
        if (mounted) {
          setState(() {
            _isExpired = true;
          });
        }
      } else if (status == 'joined' && challengeData['gameId'] != null) {
        AppLogger.debug('Challenge joined with game ID: ${challengeData['gameId']}');
        // The sender has joined the game, navigate to the game screen
        if (mounted) {
          _waitingService.navigateToGame(
            context: context,
            challengeData: challengeData,
            showSnackBar: (message) => ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(message)),
            ),
          );
        }
      }
    });
  }

  



  void _joinGame() async {
    try {
      await _waitingService.joinGame(
        widget.challengeId, 
        (isLoading) {
          if (mounted) {
            setState(() {
              _isLoading = isLoading;
            });
          }
        }
      );
    } catch (e) {
      AppLogger.error('Error joining game: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error joining game: ${e.toString()}')),
        );
      }
    }
  }

  @override
  void dispose() {
    _challengeSubscription?.cancel();
    _expirationTimer?.cancel();
    _receiverWaitingTimer?.cancel();
    _waitingService.dispose();
    super.dispose();
  }





  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          widget.isReceiver ? 'Waiting for Game' : 'Challenge Sent',
          style: const TextStyle(
            color: Colors.black87,
            fontSize: 20,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
        backgroundColor: Colors.white.withAlpha(204),
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          color: Colors.black87,
          onPressed: () {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Leave Game?'),
                content: const Text('Are you sure you want to leave?'),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                actions: [
                  TextButton(
                    onPressed: () => NavigationService.instance.goBack(context),
                    child: const Text('No'),
                  ),
                  GradientButton(
                    icon: Icons.exit_to_app_rounded,
                    label: 'Yes, Leave',
                    color: Colors.red.shade400,
                    onPressed: () {
                      NavigationService.instance.goBack(context);
                      NavigationService.instance.goBack(context);
                    },
                  ),
                ],
              ),
            );
          },
        ),
        flexibleSpace: ClipRRect(
          borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Colors.blue.shade50, Colors.white.withAlpha(204)],
                ),
              ),
            ),
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.white, Colors.blue.shade100],
          ),
        ),
        child: Stack(
          children: [
            // Add subtle background patterns
            Positioned.fill(
              child: Opacity(
                opacity: 0.05,
                child: CustomPaint(
                  painter: PatternPainter(),
                ),
              ),
            ),
            // Main content
            _isLoading
                ? _buildLoadingView()
                : _isExpired
                    ? _buildExpiredView()
                    : _isCancelled
                        ? _buildCancelledView()
                        : _isDeclined
                            ? _buildDeclinedView()
                            : _isWaitingForSender
                                ? _buildWaitingForSenderView()
                                : _buildWaitingView(),
          ],
        ),
      ),
    );
  }
  
  Widget _buildLoadingView() {
    return const LoadingView();
  }



  Widget _buildWaitingView() {
    return WaitingView(
      friendUsername: widget.friendUsername,
      secondsRemaining: _secondsRemaining,
      onCancel: () {
        NavigationService.instance.goBack(context);
      },
    );
  }
  
  Widget _buildWaitingForSenderView() {
    return WaitingForSenderView(
      friendUsername: widget.friendUsername,
      onCancel: () {
        NavigationService.instance.goBack(context);
      },
    );
  }

  Widget _buildExpiredView() {
    return ExpiredView(
      friendUsername: widget.friendUsername,
      onReturn: () {
        NavigationService.instance.goBack(context);
      },
    );
  }

  Widget _buildCancelledView() {
    return CancelledView(
      onReturn: () {
        NavigationService.instance.goBack(context);
      },
    );
  }
  
  Widget _buildDeclinedView() {
    return DeclinedView(
      friendUsername: _declinedBy,
      onReturn: () {
        NavigationService.instance.goBack(context);
      },
    );
  }
}
