import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vanishingtictactoe/features/game/widgets/mode_selection/mode_section_widget.dart';
import 'package:vanishingtictactoe/features/game/widgets/shared/hell_pattern_painter_widget.dart';
import 'dart:math' as math; 
import 'package:vanishingtictactoe/shared/widgets/login_dialog.dart';
import 'Computer/difficulty_selection_screen.dart';
import 'package:vanishingtictactoe/features/online/screens/online_screen.dart';
import 'package:vanishingtictactoe/shared/providers/user_provider.dart';
import 'package:vanishingtictactoe/shared/providers/hell_mode_provider.dart';
import 'package:vanishingtictactoe/features/game/widgets/shared/hell_mode_toggle.dart';
import 'package:vanishingtictactoe/features/tournament/screens/tournament_selection_screen.dart';
import '2Players/two_players_screen.dart';
import 'Friendly_match/friendly_match_screen.dart';


enum GameMode {
  twoPlayers,
  vsComputer,
  online,
  friendlyMatch,
  //tournament,
  hellMode,
}

class ModeSelectionScreen extends StatefulWidget {
  const ModeSelectionScreen({super.key});

  @override
  State<ModeSelectionScreen> createState() => _ModeSelectionScreenState();
}

class _ModeSelectionScreenState extends State<ModeSelectionScreen> with TickerProviderStateMixin {  
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
  
  void _handleModeSelection(GameMode mode) async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final hellModeProvider = Provider.of<HellModeProvider>(context, listen: false);

    // If Hell Mode is selected, toggle it and return
    if (mode == GameMode.hellMode) {
      hellModeProvider.toggleHellMode();
      return;
    }

    switch (mode) {
      case GameMode.twoPlayers:
        if (context.mounted) {
          // Always go to the history screen regardless of hell mode status
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const TwoPlayersHistoryScreen(),
              settings: const RouteSettings(name: '/two-players-history'), // Use consistent route name with leading '/'
            ),
          );
        }
        break;

      case GameMode.vsComputer:
        if (context.mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const DifficultySelectionScreen(),
              settings: const RouteSettings(name: '/difficulty-selection'),
            ),
          );
        }
        break;

      case GameMode.online:
      case GameMode.friendlyMatch:
      //case GameMode.tournament:
        if (userProvider.user == null) {
          if (context.mounted) {
            LoginDialog.show(context);
          }
        } else {
          if (context.mounted) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) {
                  if (mode == GameMode.online) {
                    return const OnlineScreen();
                  // } else if (mode == GameMode.tournament) {
                  //   return const TournamentSelectionScreen();
                  } else {
                    return const FriendlyMatchScreen();
                  }
                },
                settings: RouteSettings(
                  name: mode == GameMode.online 
                      ? '/online'
                      // : mode == GameMode.tournament 
                      //     ? '/tournament'
                          : '/friendly-match'
                ),
              ),
            );
          }
        }
        break;
        
      case GameMode.hellMode:
        // This case is handled before the switch statement
        break;
    }
  }



  @override
  Widget build(BuildContext context) {
    // Get screen dimensions for responsive design
    final screenSize = MediaQuery.of(context).size;
    final hellModeProvider = Provider.of<HellModeProvider>(context);
    final bool isHellMode = hellModeProvider.isHellModeActive;
    
    return Scaffold(
      backgroundColor: isHellMode ? Colors.grey[50] : Colors.white,
      body: Stack(
        children: [
          // Background pattern or gradient
          if (isHellMode)
            Positioned.fill(
              child: Opacity(
                opacity: 0.05,
                child: CustomPaint(
                  painter: HellPatternPainter(),
                ),
              ),
            ),
            
          // Main content
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Animated title
                FadeTransition(
                  opacity: _fadeController,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, -0.2),
                      end: Offset.zero,
                    ).animate(CurvedAnimation(
                      parent: _slideController,
                      curve: Curves.easeOutQuart,
                    )),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Game Modes',
                            style: TextStyle(
                              fontSize: 34,
                              fontWeight: FontWeight.w800,
                              color: isHellMode ? Colors.red.shade900 : Colors.blue.shade900,
                              letterSpacing: 0.5,
                              shadows: [
                                Shadow(
                                  color: (isHellMode ? Colors.red : Colors.blue).withValues( alpha: 0.2),
                                  offset: const Offset(0, 2),
                                  blurRadius: 4,
                                ),
                              ],
                            ),
                          ),
                          if (isHellMode)
                            Padding(
                              padding: const EdgeInsets.only(left: 10),
                              child: GestureDetector(
                                onTap: () {
                                  Navigator.pushNamed(context, '/hell-tutorial');
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.red.shade700,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.red.shade300.withValues( alpha: 0.5),
                                        blurRadius: 8,
                                        spreadRadius: 1,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.help_outline_rounded,
                                    color: Colors.white,
                                    size: 18,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
                
                // Game mode options
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                    children: [
                      // Staggered animations for each mode card
                      ..._buildAnimatedModeCards(),
                      
                      // Hell mode toggle
                      SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0, 0.5),
                          end: Offset.zero,
                        ).animate(CurvedAnimation(
                          parent: _slideController,
                          curve: const Interval(0.7, 1.0, curve: Curves.easeOutQuart),
                        )),
                        child: FadeTransition(
                          opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
                            CurvedAnimation(
                              parent: _fadeController,
                              curve: const Interval(0.7, 1.0),
                            ),
                          ),
                          child: Consumer<HellModeProvider>(
                            builder: (context, hellModeProvider, child) {
                              return Center(
                                child: Container(
                                  width: screenSize.width * 0.75,
                                  margin: const EdgeInsets.only(top: 10, bottom: 10),
                                  padding: const EdgeInsets.symmetric(horizontal: 4),
                                  child: HellModeToggle(
                                    onToggle: () => _handleModeSelection(GameMode.hellMode),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Removed the standalone Hell Mode info icon as it's now integrated with the title
        ],
      ),
    );
  }
  
  // Build animated mode cards with staggered animations
  List<Widget> _buildAnimatedModeCards() {
    final List<Map<String, dynamic>> modes = [
      {
        'title': 'Two Players',
        'description': 'Play against a friend on the same device',
        'icon': Icons.people_rounded,
        'mode': GameMode.twoPlayers,
        'delay': 0.0,
      },
      {
        'title': 'vs Computer',
        'description': 'Challenge our AI with different difficulty levels',
        'icon': Icons.computer_rounded,
        'mode': GameMode.vsComputer,
        'delay': 0.1,
      },
      {
        'title': 'Online',
        'description': 'Play against other players online',
        'icon': Icons.public_rounded,
        'mode': GameMode.online,
        'delay': 0.2,
      },
      {
        'title': 'Friendly Match',
        'description': 'Play with a friend using a match code',
        'icon': Icons.people_alt_rounded,
        'mode': GameMode.friendlyMatch,
        'delay': 0.3,
      },
      // {
      //   'title': 'Tournament',
      //   'description': 'Compete in a bracket-style tournament',
      //   'icon': Icons.emoji_events_rounded,
      //   'mode': GameMode.tournament,
      //   'delay': 0.4,
      // },
    ];
    
    return modes.map((mode) {
      // Calculate safe interval values that won't exceed 1.0
      final double startInterval = 0.3 + mode['delay'];
      final double endInterval = math.min(0.8 + mode['delay'], 1.0);
      
      return SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0.3, 0),
          end: Offset.zero,
        ).animate(CurvedAnimation(
          parent: _slideController,
          curve: Interval(startInterval, endInterval, curve: Curves.easeOutQuart),
        )),
        child: FadeTransition(
          opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
            CurvedAnimation(
              parent: _fadeController,
              curve: Interval(startInterval, endInterval),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: ModeSectionWidget(
              title: mode['title'],
              description: mode['description'],
              icon: mode['icon'],
              mode: mode['mode'],
              handleModeSelection: _handleModeSelection,
            ),
          ),
        ),
      );
    }).toList();
  }

}
