import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:vanishingtictactoe/features/game/widgets/shared/hell_pattern_painter_widget.dart';
import 'package:vanishingtictactoe/shared/models/player.dart';
import 'package:vanishingtictactoe/features/game/widgets/2players/player_setup_modal.dart';
import 'package:vanishingtictactoe/features/game/screens/coin_flip_screen.dart';
import 'package:vanishingtictactoe/features/history/services/local_match_history_service.dart';
import 'package:vanishingtictactoe/features/history/services/match_history_updates.dart';
import 'package:vanishingtictactoe/core/utils/app_logger.dart';
import 'package:vanishingtictactoe/shared/providers/hell_mode_provider.dart';
import 'package:vanishingtictactoe/features/game/widgets/2players/match_history_item.dart';
import 'package:vanishingtictactoe/features/game/widgets/2players/empty_history_state.dart';
import 'package:vanishingtictactoe/features/game/widgets/2players/mode_toggle_tabs.dart';
import 'package:vanishingtictactoe/features/game/widgets/shared/play_game_button.dart';
import 'package:vanishingtictactoe/features/game/widgets/shared/hell_mode_button.dart';
import '../hell/hell_game_screen.dart';


class TwoPlayersHistoryScreen extends StatefulWidget {
  const TwoPlayersHistoryScreen({super.key});

  @override
  State<TwoPlayersHistoryScreen> createState() => _TwoPlayersHistoryScreenState();
}

class _TwoPlayersHistoryScreenState extends State<TwoPlayersHistoryScreen> 
    with WidgetsBindingObserver, SingleTickerProviderStateMixin {
  final LocalMatchHistoryService _matchHistoryService = LocalMatchHistoryService();
  List<Map<String, dynamic>> recentMatches = [];
  List<Map<String, dynamic>> hellMatches = [];
  StreamSubscription? _updateSubscription;
  bool _showHellMatches = false;
  
  // Animation controllers
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    
    // Initialize animations
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutQuart,
    ));
    
    // Listen for updates
    _updateSubscription = MatchHistoryUpdates.updates.stream.listen((_) {
      AppLogger.info('Received update notification, refreshing matches...');
      _loadRecentMatches();
    });
    
    _loadRecentMatches();
    
    // Start animations
    _animationController.forward();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _updateSubscription?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadRecentMatches();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadRecentMatches();
  }

  Future<void> _loadRecentMatches() async {
    if (!mounted) return;

    try {
      final matches = await _matchHistoryService.getRecentMatches();
      AppLogger.info('Loaded ${matches.length} total matches');
      
      if (mounted) {
        // Check the key used for hell mode
        final regularMatches = matches.where((match) => match['is_hell_mode'] != true).toList();
        final hellModeMatches = matches.where((match) => match['is_hell_mode'] == true).toList();
        
        AppLogger.info('Regular matches: ${regularMatches.length}, Hell matches: ${hellModeMatches.length}');
        
        setState(() {
          recentMatches = regularMatches;
          hellMatches = hellModeMatches;
        });
      }
    } catch (e) {
      AppLogger.error('Error loading matches: $e');
    }
  }


  void _startNewGame() async {
    final hellModeProvider = Provider.of<HellModeProvider>(context, listen: false);
    final isHellModeActive = hellModeProvider.isHellModeActive;
    
    // Update this line to handle the Map return type
    final result = await showDialog(
      context: context,
      builder: (context) => const PlayerSetupModal(),
    );
    
    // Check if result is not null and extract players and vanishingEffectEnabled
    if (result != null && context.mounted) {
      final players = result['players'] as List<Player>;
      final vanishingEffectEnabled = result['vanishingEffectEnabled'] as bool;
      
      if (isHellModeActive) {
        // If hell mode is active, go to hell game screen
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => HellGameScreen(
              player1: players[0],
              player2: players[1],
              // Pass vanishingEffectEnabled if HellGameScreen supports it
              // vanishingEffectEnabled: vanishingEffectEnabled,
            ),
          ),
        );
        
        // If we have a result from the hell game, save it
        if (result != null && result is Map<String, dynamic>) {
          await _saveHellModeMatch(result);
        }
      } else {
        // Normal flow - go to coin flip screen
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CoinFlipScreen(
              player1: players[0],
              player2: players[1],
              // Pass vanishingEffectEnabled if CoinFlipScreen supports it
              vanishingEffectEnabled: vanishingEffectEnabled,
            ),
          ),
        );
      }
      
      // Refresh match history when returning from the game
      _loadRecentMatches();
    }
  }
  
  // Save a hell mode match to history
  Future<void> _saveHellModeMatch(Map<String, dynamic> result) async {
    // Add debug logging to see what's being received
    AppLogger.info('Saving hell mode match with data: ${result.toString()}');
    
    // Check if we have all required fields
    if (result['player1'] == null || result['player2'] == null) {
      AppLogger.error('Missing player data in hell mode match result');
      return;
    }
    
    try {
      // Extract player names - they might be Player objects or strings
      final player1 = result['player1'] is Player 
          ? (result['player1'] as Player).name 
          : result['player1'].toString();
      
      final player2 = result['player2'] is Player 
          ? (result['player2'] as Player).name 
          : result['player2'].toString();
      
      // Extract winner - might be a Player object, string, or null for draw
      String winner = "";
      if (result['winner'] != null) {
        if (result['winner'] is Player) {
          winner = (result['winner'] as Player).name;
        } else if (result['winner'] == 'Draw') {
          winner = 'Draw';
        } else {
          winner = result['winner'].toString();
        }
      }
      
      await _matchHistoryService.saveMatch(
        player1: player1,
        player2: player2,
        winner: winner,
        player1WentFirst: result['player1WentFirst'] ?? true,
        player1Symbol: result['player1Symbol'] ?? 'X',
        player2Symbol: result['player2Symbol'] ?? 'O',
        isHellMode: true, // Ensure this is set to true
      );
      
      // Add more debug logging
      AppLogger.info('Hell mode match saved successfully');
      
      // Force UI to show hell matches tab
      setState(() {
        _showHellMatches = true;
      });
      
      // Notify listeners that match history has been updated
      MatchHistoryUpdates.notifyUpdate();
      
      // Force refresh the matches immediately
      if (mounted) {
        await _loadRecentMatches();
      }
    } catch (e) {
      AppLogger.error('Error saving hell mode match: $e');
    }
  }

  void _rematch(Map<String, dynamic> match) async {
    if (context.mounted) {
      final isHellMode = match['is_hell_mode'] == true;
      final hellModeProvider = Provider.of<HellModeProvider>(context, listen: false);
      
      // Ensure hell mode is active if needed
      if (isHellMode && !hellModeProvider.isHellModeActive) {
        hellModeProvider.toggleHellMode();
      } else if (!isHellMode && hellModeProvider.isHellModeActive) {
        hellModeProvider.toggleHellMode();
      }
      
      if (isHellMode) {
        // Rematch in hell mode
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => HellGameScreen(
              player1: Player(name: match['player1'], symbol: match['player1_symbol'] ?? 'X'),
              player2: Player(name: match['player2'], symbol: match['player2_symbol'] ?? 'O'),
            ),
          ),
        );
        
        // If we have a result from the hell game, save it
        if (result != null && result is Map<String, dynamic>) {
          await _saveHellModeMatch(result);
        }
      } else {
        // Regular rematch
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CoinFlipScreen(
              player1: Player(name: match['player1'], symbol: match['player1_symbol'] ?? 'X'),
              player2: Player(name: match['player2'], symbol: match['player2_symbol'] ?? 'O'),
            ),
          ),
        );
      }
      
      // Refresh match history when returning from the game
      _loadRecentMatches();
    }
  }

  @override
  Widget build(BuildContext context) {
    final hellModeProvider = Provider.of<HellModeProvider>(context);
    final isHellMode = hellModeProvider.isHellModeActive;
    
    return PopScope(
      onPopInvokedWithResult: (didPop, result) async {
        await _loadRecentMatches();
      },
      child: Scaffold(
        backgroundColor: isHellMode ? Colors.grey[50] : Colors.white,
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isHellMode ? Colors.red.shade50 : Colors.blue.shade50,
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
                color: isHellMode ? Colors.red.shade800 : Colors.blue.shade800,
                size: 20,
              ),
              onPressed: () async {
                await _loadRecentMatches();
                if (context.mounted) Navigator.pop(context);
              },
            ),
          ),
          title: FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: Text(
              '2 Players',
              style: TextStyle(
                color: isHellMode ? Colors.red.shade900 : Colors.blue.shade900,
                fontSize: 28,
                fontWeight: FontWeight.w800,
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
            ),
          ),
          centerTitle: true,
        ),
        body: Stack(
          children: [
            // Background pattern for hell mode
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
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    isHellMode ? Colors.grey[50]! : Colors.white,
                    isHellMode ? Colors.red.shade50.withValues( alpha: 0.3) : const Color(0xFFECF0F1),
                  ],
                ),
              ),
              child: SafeArea(
                child: Column(
                  children: [
                    // Toggle between regular and hell mode matches
                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: SlideTransition(
                        position: _slideAnimation,
                        child: Consumer<HellModeProvider>(
                          builder: (context, hellModeProvider, child) {
                            return ModeToggleTabs(
                              showHellMatches: _showHellMatches,
                              onToggle: (showHell) {
                                HapticFeedback.lightImpact();
                                setState(() {
                                  _showHellMatches = showHell;
                                });
                              },
                            );
                          }
                        ),
                      ),
                    ),
                    
                    // Match history list
                    Expanded(
                      child: FadeTransition(
                        opacity: _fadeAnimation,
                        child: SlideTransition(
                          position: _slideAnimation,
                          child: _showHellMatches
                            ? (hellMatches.isEmpty
                              ? EmptyHistoryState(
                                  accentColor: const Color(0xFFE74C3C),
                                )
                              : _buildMatchList(hellMatches, true)
                            )
                            : (recentMatches.isEmpty
                              ? const EmptyHistoryState()
                              : _buildMatchList(recentMatches, false)
                            ),
                        ),
                      ),
                    ),
                      
                    // Bottom controls
                    Consumer<HellModeProvider>(
                      builder: (context, hellModeProvider, child) {
                        final isHellModeActive = hellModeProvider.isHellModeActive;
                        
                        return Column(
                          children: [
                            // Container for the hell mode button, aligned to the right
                            Padding(
                              padding: const EdgeInsets.only(right: 20.0, bottom: 0.0),
                              child: Align(
                                alignment: Alignment.centerRight,
                                child: const HellModeButton(),
                              ),
                            ),
                            
                            // Play button with reduced top padding
                            Padding(
                              padding: const EdgeInsets.only(left: 20.0, right: 20.0, bottom: 20.0, top: 5.0),
                              child: PlayGameButton(
                                onPressed: () {
                                  HapticFeedback.mediumImpact();
                                  _startNewGame();
                                },
                                isHellMode: isHellModeActive,
                              ),
                            ),
                          ],
                        );
                      }
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildMatchList(List<Map<String, dynamic>> matches, bool isHellMode) {
    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: matches.length,
      itemBuilder: (context, index) {
        // Apply staggered animation to list items
        return AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            final delay = index * 0.1;
            final startValue = math.max(0.0, _animationController.value - delay);
            final animationValue = math.min(1.0, startValue / (1.0 - delay));
            
            return FadeTransition(
              opacity: AlwaysStoppedAnimation(animationValue),
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.2),
                  end: Offset.zero,
                ).animate(
                  CurvedAnimation(
                    parent: AlwaysStoppedAnimation(animationValue),
                    curve: Curves.easeOutQuad,
                  ),
                ),
                child: child,
              ),
            );
          },
          child: MatchHistoryItem(
            match: matches[index],
            onRematch: _rematch,
            isHellMode: isHellMode,
          ),
        );
      },
    );
  }
}
