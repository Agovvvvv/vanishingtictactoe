import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vanishingtictactoe/features/game/widgets/computer/difficulty_selector_widget.dart';
import 'package:vanishingtictactoe/features/game/widgets/computer/login_prompt_widget.dart';
import 'package:vanishingtictactoe/features/game/widgets/computer/match_history_widget.dart';
import 'package:vanishingtictactoe/features/game/widgets/shared/hell_pattern_painter_widget.dart';
import 'package:vanishingtictactoe/shared/models/player.dart';
import 'package:vanishingtictactoe/features/game/models/computer_player.dart';
import 'package:vanishingtictactoe/features/game/models/game_logic_vscomputer.dart';
import 'package:vanishingtictactoe/features/game/models/game_logic_vscomputer_hell.dart';
import 'package:vanishingtictactoe/features/game/widgets/shared/play_game_button.dart';
import '../game_screen.dart';
import '../hell/hell_game_screen.dart';
import 'package:vanishingtictactoe/shared/providers/user_provider.dart';
import 'package:vanishingtictactoe/shared/providers/hell_mode_provider.dart';
import 'package:vanishingtictactoe/core/utils/app_logger.dart';
import 'package:vanishingtictactoe/features/game/widgets/shared/hell_mode_button.dart';
import 'package:flutter/services.dart';


class DifficultySelectionScreen extends StatefulWidget {
  const DifficultySelectionScreen({super.key});

  @override
  State<DifficultySelectionScreen> createState() => _DifficultySelectionScreenState();
}

class _DifficultySelectionScreenState extends State<DifficultySelectionScreen> with TickerProviderStateMixin {
  GameDifficulty _selectedDifficulty = GameDifficulty.easy;
  
  // Animation controllers for staggered animations
  late AnimationController _fadeController;
  late AnimationController _slideController;

  
  
  @override
  void initState() {
    super.initState();
    
    // Initialize animation controllers
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    
      
    // Start animations when screen loads
    _fadeController.forward();
    _slideController.forward();
  }
  
  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  String _getDifficultyName(GameDifficulty difficulty) {
    return switch (difficulty) {
      GameDifficulty.easy => 'Easy',
      GameDifficulty.medium => 'Medium',
      GameDifficulty.hard => 'Hard',
    };
  }

  void _startGame(GameDifficulty difficulty) {
    const playerSymbol = 'X';
    const computerSymbol = 'O';

    final computerPlayer = ComputerPlayer(
      difficulty: difficulty,
      computerSymbol: computerSymbol,
      playerSymbol: playerSymbol,
      name: 'Computer (${_getDifficultyName(difficulty)})',
    );
    
    // Check if hell mode is active
    final hellModeProvider = Provider.of<HellModeProvider>(context, listen: false);
    final isHellModeActive = hellModeProvider.isHellModeActive;
    
    // Create the appropriate game logic based on the game mode
    final gameLogic = isHellModeActive
      ? GameLogicVsComputerHell(
          onGameEnd: (winner) {
            // Use a simpler callback that doesn't directly access providers
            AppLogger.info('Game ended with winner: $winner');
            // The actual end game handling will be done by the GameScreen
          },
          computerPlayer: computerPlayer,
          humanSymbol: playerSymbol,
        )
      : GameLogicVsComputer(
          onGameEnd: (winner) {
            // Use a simpler callback that doesn't directly access providers
            AppLogger.info('Game ended with winner: $winner');
            // The actual end game handling will be done by the GameScreen
          },
          computerPlayer: computerPlayer,
          humanSymbol: playerSymbol,
        );
    
    // Create player objects
    final player1 = Player(name: 'You', symbol: playerSymbol);
    // Use the computerPlayer as player2 (it's already a Player since it extends Player)
    final player2 = computerPlayer;

    // Navigate to the appropriate screen based on hell mode status
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => isHellModeActive
          ? HellGameScreen(
              player1: player1,
              player2: player2,
              logic: gameLogic,
            )
          : GameScreen(
              player1: player1,
              player2: player2,
              logic: gameLogic,
            ),
            settings: const RouteSettings(name: '/game-screen'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Get system overlay style based on brightness
    final hellModeActive = Provider.of<HellModeProvider>(context).isHellModeActive;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: isDarkMode ? Brightness.light : Brightness.dark,
    ));
    
    return Scaffold(
      backgroundColor: hellModeActive ? Colors.grey[50] : Colors.white,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: FadeTransition(
          opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
            CurvedAnimation(
              parent: _fadeController,
              curve: const Interval(0.3, 0.8),
            ),
          ),
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, -0.2),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: _slideController,
              curve: Curves.easeOutQuart,
            )),
            child: Text(
              'Select Difficulty',
              style: TextStyle(
                color: hellModeActive ? Colors.red.shade900 : Colors.blue.shade900,
                fontSize: 28,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
                shadows: [
                  Shadow(
                    color: (hellModeActive ? Colors.red : Colors.blue).withValues( alpha: 0.2),
                    offset: const Offset(0, 2),
                    blurRadius: 4,
                  ),
                ],
              ),
            ),
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: hellModeActive ? Colors.red.shade50 : Colors.blue.shade50,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues( alpha: 0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: IconButton(
            icon: Icon(
              Icons.arrow_back_ios_new_rounded, 
              color: hellModeActive ? Colors.red.shade800 : Colors.blue.shade800,
              size: 20,
            ),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        
      ),
      body: Stack(
        children: [
          // Background pattern or gradient for Hell Mode
          if (hellModeActive)
            Positioned.fill(
              child: Opacity(
                opacity: 0.05,
                child: CustomPaint(
                  painter: HellPatternPainter(),
                ),
              ),
            ),
            
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: hellModeActive
                  ? [
                      Colors.grey[50]!,
                      Colors.grey[50]!.withValues( alpha: 0.9),
                      Colors.red.shade50.withValues( alpha: 0.3),
                    ]
                  : [
                      Colors.white,
                      Colors.white.withValues( alpha: 0.9),
                      Colors.blue.shade50.withValues( alpha: 0.3),
                    ],
              ),
            ),
            child: Consumer<UserProvider>(
              builder: (context, userProvider, child) {
                final isLoggedIn = userProvider.user != null;
                final defaultMessage = isLoggedIn 
                    ? 'No matches played yet'
                    : 'Log in to see match history';
    
                return SafeArea(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                      // Animated difficulty selector
                      SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0, -0.1),
                          end: Offset.zero,
                        ).animate(CurvedAnimation(
                          parent: _slideController,
                          curve: const Interval(0.1, 0.5, curve: Curves.easeOutQuart),
                        )),
                        child: FadeTransition(
                          opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
                            CurvedAnimation(
                              parent: _fadeController,
                              curve: const Interval(0.1, 0.5),
                            ),
                          ),
                          child: DifficultySelector(
                            selectedDifficulty: _selectedDifficulty,
                            onDifficultyChanged: (difficulty) {
                              setState(() {
                                _selectedDifficulty = difficulty;
                              });
                            },
                          ),
                        ),
                      ),
                      
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              
                              const SizedBox(height: 24),
                              
                              // Match history header
                              SlideTransition(
                                position: Tween<Offset>(
                                  begin: const Offset(0, 0.3),
                                  end: Offset.zero,
                                ).animate(CurvedAnimation(
                                  parent: _slideController,
                                  curve: const Interval(0.4, 0.8, curve: Curves.easeOutQuart),
                                )),
                                child: FadeTransition(
                                  opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
                                    CurvedAnimation(
                                      parent: _fadeController,
                                      curve: const Interval(0.4, 0.8),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.history_rounded,
                                        color: hellModeActive ? Colors.red.shade700 : Colors.blue.shade700,
                                        size: 22,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Match History',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w600,
                                          color: hellModeActive ? Colors.red.shade900 : Colors.blue.shade900,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              
                              const SizedBox(height: 16),
                              
                              // Match history content
                              SlideTransition(
                                position: Tween<Offset>(
                                  begin: const Offset(0, 0.4),
                                  end: Offset.zero,
                                ).animate(CurvedAnimation(
                                  parent: _slideController,
                                  curve: const Interval(0.5, 0.9, curve: Curves.easeOutQuart),
                                )),
                                child: FadeTransition(
                                  opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
                                    CurvedAnimation(
                                      parent: _fadeController,
                                      curve: const Interval(0.5, 0.9),
                                    ),
                                  ),
                                  // Wrap in SingleChildScrollView to prevent overflow
                                  child: Container(
                                    constraints: BoxConstraints(
                                      maxHeight: MediaQuery.of(context).size.height * 0.35,
                                    ),
                                    child: SingleChildScrollView(
                                      physics: const BouncingScrollPhysics(),
                                      child: isLoggedIn
                                        ? MatchHistoryWidget(
                                          userProvider: userProvider,
                                          selectedDifficulty: _selectedDifficulty,
                                        )
                                        : LoginPromptWidget(
                                          message: defaultMessage
                                        ),
                                    ),
                                  ),
                                ),
                              ),
                              
                              const SizedBox(height: 24),
                              
                              // Bottom action buttons area with gradient background
                              SlideTransition(
                                position: Tween<Offset>(
                                  begin: const Offset(0, 0.5),
                                  end: Offset.zero,
                                ).animate(CurvedAnimation(
                                  parent: _slideController,
                                  curve: const Interval(0.6, 1.0, curve: Curves.easeOutQuart),
                                )),
                                child: FadeTransition(
                                  opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
                                    CurvedAnimation(
                                      parent: _fadeController,
                                      curve: const Interval(0.6, 1.0),
                                    ),
                                  ),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                        colors: [
                                          (hellModeActive ? Colors.red : Colors.blue).withValues( alpha: 0.0),
                                          (hellModeActive ? Colors.red : Colors.blue).withValues( alpha: 0.05),
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(24),
                                    ),
                                    child: Column(
                                      children: [
                                        // Hell mode button, aligned to the right
                                        Align(
                                          alignment: Alignment.centerRight,
                                          child: const HellModeButton(),
                                        ),
                                        const SizedBox(height: 12),
                                        // Play game button
                                        PlayGameButton(
                                          onPressed: () => _startGame(_selectedDifficulty),
                                          isHellMode: Provider.of<HellModeProvider>(context).isHellModeActive,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
