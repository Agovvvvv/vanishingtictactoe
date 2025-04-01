import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:vanishingtictactoe/shared/models/player.dart';
import 'package:vanishingtictactoe/shared/providers/user_provider.dart';
import '../game_screen.dart';
import 'package:vanishingtictactoe/features/game/services/friendly_match_service.dart';
import 'package:vanishingtictactoe/core/utils/app_logger.dart';
import 'package:vanishingtictactoe/features/game/models/friendly_game_logic_online.dart';

class FriendlyMatchWaitingScreen extends StatefulWidget {
  final String matchCode;

  const FriendlyMatchWaitingScreen({
    super.key,
    required this.matchCode,
  });

  @override
  State<FriendlyMatchWaitingScreen> createState() => _FriendlyMatchWaitingScreenState();
}

class _FriendlyMatchWaitingScreenState extends State<FriendlyMatchWaitingScreen> {
  bool _isCodeCopied = false;
  late FriendlyMatchService _matchService;
  StreamSubscription? _matchSubscription;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _matchService = FriendlyMatchService();
    _setupMatch();
  }

  Future<void> _setupMatch() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    if (userProvider.user == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('You need to be logged in to create a match')),
        );
        Navigator.pop(context);
      }
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Log user info for debugging
      AppLogger.info('Creating match with user ID: ${userProvider.user!.id}');
      AppLogger.info('User name: ${userProvider.user!.username}');
      
      // Create the match in Firebase
      await _matchService.createMatch(
        matchCode: widget.matchCode,
        hostId: userProvider.user!.id,
        hostName: userProvider.user!.username,
      );

      // Listen for a player to join
      _matchSubscription = _matchService.listenForMatchUpdates(widget.matchCode).listen((matchData) {
        if (matchData != null && matchData['guestId'] != null) {
          // A player has joined, start the game
          _navigateToGame(matchData);
        }
      });

      setState(() => _isLoading = false);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error setting up match: ${e.toString()}')),
        );
        Navigator.pop(context);
      }
    }
  }

  void _navigateToGame(Map<String, dynamic> matchData) {
    _matchSubscription?.cancel();

    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final currentUser = userProvider.user;
    
    if (currentUser == null || !mounted) return;

    // Get the active match ID
    final activeMatchId = matchData['activeMatchId'];
    if (activeMatchId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error: No active match found')),
      );
      return;
    }

    // Create friendly game logic for the friendly match
    final gameLogic = FriendlyGameLogicOnline(
      onGameEnd: (winner) {
        // The actual game end handling will be done by the GameScreen
        AppLogger.info('Game ended with winner: $winner. GameScreen will handle the dialog.');
      },
      onPlayerChanged: () {},
      localPlayerId: currentUser.id,
      friendlyMatchService: _matchService,
    );

    // Navigate to the game screen with online logic
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => GameScreen(
          isOnlineGame: true,
          player1: Player(name: matchData['hostName'], symbol: 'X'),
          player2: Player(name: matchData['guestName'], symbol: 'O'),
          logic: gameLogic,
        ),
      ),
    );

    // Join the active match
    gameLogic.joinMatch(activeMatchId);
  }

  @override
  void dispose() {
    _matchSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Waiting for Player', 
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: Colors.blue.shade900,
            letterSpacing: 0.5,
          )
        ),
        backgroundColor: Colors.white,
        elevation: 2,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.white,
              const Color(0xFFECF0F1),
            ],
          ),
        ),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Icon with background
                      TweenAnimationBuilder<double>(
                        tween: Tween<double>(begin: 0.8, end: 1.0),
                        duration: const Duration(milliseconds: 1500),
                        curve: Curves.easeInOut,
                        builder: (context, value, child) {
                          return Transform.scale(
                            scale: value,
                            child: Container(
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                color: const Color(0xFF2E86DE).withValues( alpha: 0.1),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF2E86DE).withValues( alpha: 0.2 + 0.1 * (value - 0.8) * 5),
                                    blurRadius: 12,
                                    spreadRadius: 2,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.people_alt,
                                size: 50,
                                color: Color(0xFF2E86DE),
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 32),
                      Text(
                        'Waiting for a player to join',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: Colors.blue.shade900,
                          letterSpacing: 0.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Share this code with a friend to start playing',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.blue.shade700,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 40),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 16,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues( alpha: 0.05),
                              blurRadius: 10,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Text(
                              'Your Match Code',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: Colors.blue.shade700,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF2E86DE).withValues( alpha: 0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    widget.matchCode,
                                    style: TextStyle(
                                      fontSize: 32,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.blue.shade900,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Container(
                                  decoration: BoxDecoration(
                                    color: _isCodeCopied 
                                        ? const Color(0xFF27AE60).withValues( alpha: 0.1) 
                                        : const Color(0xFF2E86DE).withValues( alpha: 0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: IconButton(
                                    icon: Icon(
                                      _isCodeCopied ? Icons.check : Icons.copy,
                                      color: _isCodeCopied 
                                          ? const Color(0xFF27AE60) 
                                          : const Color(0xFF2E86DE),
                                      size: 24,
                                    ),
                                    onPressed: () {
                                      Clipboard.setData(ClipboardData(text: widget.matchCode));
                                      setState(() => _isCodeCopied = true);
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('Code copied to clipboard'),
                                          backgroundColor: Color(0xFF27AE60),
                                          behavior: SnackBarBehavior.floating,
                                        ),
                                      );
                                      Future.delayed(const Duration(seconds: 2), () {
                                        if (mounted) {
                                          setState(() => _isCodeCopied = false);
                                        }
                                      });
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 40),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2E86DE).withValues( alpha: 0.1),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  const Color(0xFF2E86DE),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Text(
                              'Waiting for opponent...',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.blue.shade700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 40),
                      SizedBox(
                        height: 50,
                        width: 200,
                        child: ElevatedButton(
                          onPressed: () {
                            _matchSubscription?.cancel();
                            _matchService.deleteMatch(widget.matchCode);
                            Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red.shade400,
                            foregroundColor: Colors.white,
                            elevation: 5,
                            shadowColor: Colors.red.withValues( alpha: 0.3),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: Text(
                            'CANCEL',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}
