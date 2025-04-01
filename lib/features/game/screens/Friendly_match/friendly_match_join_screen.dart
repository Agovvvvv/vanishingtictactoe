import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vanishingtictactoe/shared/models/player.dart';
import 'package:vanishingtictactoe/shared/providers/user_provider.dart';
import '../game_screen.dart';
import 'package:vanishingtictactoe/features/game/services/friendly_match_service.dart';
import 'package:vanishingtictactoe/core/utils/app_logger.dart';
import 'package:vanishingtictactoe/features/game/models/friendly_game_logic_online.dart';

class FriendlyMatchJoinScreen extends StatefulWidget {
  const FriendlyMatchJoinScreen({super.key});

  @override
  State<FriendlyMatchJoinScreen> createState() => _FriendlyMatchJoinScreenState();
}

class _FriendlyMatchJoinScreenState extends State<FriendlyMatchJoinScreen> with SingleTickerProviderStateMixin {
  final TextEditingController _codeController = TextEditingController();
  final FriendlyMatchService _matchService = FriendlyMatchService();
  bool _isLoading = false;
  String? _errorMessage;
  
  late AnimationController _animationController;
  late Animation<double> _fadeInAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeInAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _codeController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _joinMatch() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final code = _codeController.text.trim();
    if (code.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter a match code';
        _isLoading = false;
      });
      return;
    }

    if (code.length != 6 || int.tryParse(code) == null) {
      setState(() {
        _errorMessage = 'Invalid match code format';
        _isLoading = false;
      });
      return;
    }

    final userProvider = Provider.of<UserProvider>(context, listen: false);
    if (userProvider.user == null) {
      setState(() {
        _errorMessage = 'You need to be logged in to join a match';
        _isLoading = false;
      });
      return;
    }

    try {
      // Check if match exists
      final matchData = await _matchService.getMatch(code);
      
      if (matchData == null) {
        setState(() {
          _errorMessage = 'Match not found';
          _isLoading = false;
        });
        return;
      }

      if (matchData['guestId'] != null) {
        setState(() {
          _errorMessage = 'Match already has a player';
          _isLoading = false;
        });
        return;
      }

      // Join the match - this now returns the active match ID
      final activeMatchId = await _matchService.joinMatch(
        matchCode: code,
        guestId: userProvider.user!.id,
        guestName: userProvider.user!.username,
      );

      // Navigate to game using friendly match game logic
      if (mounted) {
        // Create friendly game logic for the friendly match
        final gameLogic = FriendlyGameLogicOnline(
          onGameEnd: (winner) {
            // The actual game end handling will be done by the GameScreen
            AppLogger.info('Game ended with winner: $winner. GameScreen will handle the dialog.');
          },
          onPlayerChanged: () {},
          localPlayerId: userProvider.user!.id,
          friendlyMatchService: _matchService,
        );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => GameScreen(
              isOnlineGame: true,
              player1: Player(name: matchData['hostName'] ?? 'Host', symbol: 'X'),
              player2: Player(name: matchData['guestName'] ?? userProvider.user!.username, symbol: 'O'),
              logic: gameLogic,
            ),
          ),
        );

        // Join the active match
        gameLogic.joinMatch(activeMatchId);
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error joining match: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Join Match', 
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
        child: FadeTransition(
          opacity: _fadeInAnimation,
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Icon with background
              Center(
                child: TweenAnimationBuilder<double>(
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
                          color: const Color(0xFF27AE60).withValues( alpha: 0.1),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF27AE60).withValues( alpha: 0.2 + 0.1 * (value - 0.8) * 5),
                              blurRadius: 12,
                              spreadRadius: 2,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.login,
                          size: 50,
                          color: Color(0xFF27AE60),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 32),
              Text(
                'Enter Match Code',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: Colors.blue.shade900,
                  letterSpacing: 0.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Ask your friend for the 6-digit code',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.blue.shade700,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              // Code input field with improved styling
              TextField(
                controller: _codeController,
                decoration: InputDecoration(
                  labelText: 'Match Code',
                  labelStyle: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.blue.shade700,
                  ),
                  hintText: '123456',
                  hintStyle: TextStyle(
                    color: Colors.grey.withValues( alpha: 0.5),
                    fontSize: 24,
                    letterSpacing: 8,
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: Color(0xFF27AE60), width: 2),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: Colors.red, width: 1),
                  ),
                  prefixIcon: const Icon(
                    Icons.numbers,
                    color: Color(0xFF27AE60),
                  ),
                  errorText: _errorMessage,
                  errorStyle: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.red,
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                ),
                keyboardType: TextInputType.number,
                maxLength: 6,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: Colors.blue.shade900,
                ),
              ),
              const SizedBox(height: 40),
              // Join button with improved styling
              SizedBox(
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _joinMatch,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF27AE60),
                    foregroundColor: Colors.white,
                    elevation: 5,
                    shadowColor: const Color(0xFF27AE60).withValues( alpha: 0.3),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          'JOIN MATCH',
                          style: TextStyle(
                            fontSize: 18,
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
