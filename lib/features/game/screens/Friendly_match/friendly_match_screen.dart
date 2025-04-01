import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vanishingtictactoe/features/game/widgets/friendly/animated_option_card_widget.dart';
import 'package:vanishingtictactoe/shared/providers/user_provider.dart';
import 'friendly_match_waiting_screen.dart';
import 'friendly_match_join_screen.dart';
import 'package:vanishingtictactoe/core/utils/app_logger.dart';
import '../../../../shared/widgets/login_dialog.dart';

class FriendlyMatchScreen extends StatefulWidget {
  const FriendlyMatchScreen({super.key});

  @override
  State<FriendlyMatchScreen> createState() => _FriendlyMatchScreenState();
}

class _FriendlyMatchScreenState extends State<FriendlyMatchScreen> with SingleTickerProviderStateMixin {
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
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Friendly Match', 
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: Colors.blue.shade900,
            letterSpacing: 0.5,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 2,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: FadeTransition(
        opacity: _fadeInAnimation,
        child: Container(
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
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Play with a friend',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: Colors.blue.shade900,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Text(
                      'Create a match and share the code with a friend, or join a match with a code',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.blue.shade700,
                      ),
                    ),
                  ),
                  const SizedBox(height: 60),
                  AnimatedOptionCardWidget(
                    title: 'Create Match',
                    description: 'Generate a code and wait for a friend to join',
                    icon: Icons.add_circle_outline,
                    onTap: () => _handleCreateMatch(context),
                    color: const Color(0xFF2E86DE),
                    delay: 0.2,
                  ),
                  const SizedBox(height: 24),
                  AnimatedOptionCardWidget(
                    title: 'Join Match',
                    description: 'Enter a code to join a friend\'s match',
                    icon: Icons.login,
                    onTap: () => _handleJoinMatch(context),
                    color: const Color(0xFF27AE60),
                    delay: 0.4,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  

  void _handleCreateMatch(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    
    // Debug user authentication status
    AppLogger.info('User authenticated: ${userProvider.isLoggedIn}');
    if (userProvider.user != null) {
      AppLogger.info('User ID: ${userProvider.user!.id}');
      AppLogger.info('Username: ${userProvider.user!.username}');
    }
    
    if (userProvider.user == null) {
      LoginDialog.show(context);
      return;
    }

    // Generate a random 6-digit code
    final code = _generateMatchCode();
    
    // Unfocus any active input before navigation
    FocusManager.instance.primaryFocus?.unfocus();
    if (!mounted) return;
    
    // Add slight delay to ensure proper event handling
    Future.delayed(const Duration(milliseconds: 50), () {
      if (!mounted || !context.mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => FriendlyMatchWaitingScreen(matchCode: code),
        ),
      );
    });
  }

  void _handleJoinMatch(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    if (userProvider.user == null) {
      LoginDialog.show(context);
      return;
    }
    
    // Unfocus any active input before navigation
    FocusManager.instance.primaryFocus?.unfocus();
    if (!mounted) return;
    
    // Add slight delay to ensure proper event handling
    Future.delayed(const Duration(milliseconds: 50), () {
      if (!mounted || !context.mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const FriendlyMatchJoinScreen(),
        ),
      );
    });
  }

  String _generateMatchCode() {
    final random = Random();
    return (100000 + random.nextInt(900000)).toString(); // 6-digit code
  }
}
