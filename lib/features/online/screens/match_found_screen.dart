import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:vanishingtictactoe/shared/providers/user_provider.dart';
import 'package:vanishingtictactoe/core/utils/app_logger.dart';
import 'package:vanishingtictactoe/shared/providers/hell_mode_provider.dart';
import 'package:vanishingtictactoe/features/online/services/matchmaking_service.dart';
import 'package:vanishingtictactoe/shared/models/match.dart';
import 'package:vanishingtictactoe/features/game/screens/game_screen.dart';
import 'package:vanishingtictactoe/features/game/screens/hell/hell_game_screen.dart';
import 'package:vanishingtictactoe/shared/models/player.dart';
import 'package:vanishingtictactoe/features/game/models/game_logic_online.dart';
import 'package:vanishingtictactoe/shared/widgets/online_coin_flip_screen.dart';


class MatchFoundScreen extends StatefulWidget {
  final String matchId;
  final bool isHellMode;
  
  const MatchFoundScreen({
    super.key,
    required this.matchId,
    this.isHellMode = false,
  });

  @override
  State<MatchFoundScreen> createState() => _MatchFoundScreenState();
}

class _MatchFoundScreenState extends State<MatchFoundScreen> with TickerProviderStateMixin {
  final MatchmakingService _matchmakingService = MatchmakingService();
  GameMatch? _match;
  bool _isLoading = true;
  String? _errorMessage;
  StreamSubscription? _matchSubscription;
  bool _isDisposed = false;
  
  // Animation controllers
  late AnimationController _flipController;
  late AnimationController _scaleController;
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _pulseController;
  
  // Animations - these will be used in the OnlineCoinFlipScreen and UI elements
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _pulseAnimation;
  
  // Animation state
  bool _showCoinFlip = false;
  bool _coinFlipComplete = false;
  
  // UI state
  final String _statusMessage = 'Preparing match...';
  
  @override
  void initState() {
    super.initState();
    
    // Initialize flip animation for coin flip
    _flipController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    
    // Initialize scale animation for coin flip
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    
    // Initialize fade animation for UI elements
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _fadeController,
        curve: Curves.easeOut,
      ),
    );
    
    // Initialize slide animation for UI elements
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutQuart,
    ));
    
    // Initialize pulse animation for UI elements
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: Curves.easeInOut,
      ),
    );
    
    // Start animations
    _fadeController.forward();
    _slideController.forward();
    
    // Load match data
    _loadMatch();
  }
  
  @override
  void dispose() {
    _isDisposed = true;
    
    // Dispose all animation controllers
    _flipController.dispose();
    _scaleController.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    _pulseController.dispose();
    
    // Cancel any active subscriptions
    _matchSubscription?.cancel();
    
    super.dispose();
  }
  
  Future<void> _loadMatch() async {
    try {
      // Subscribe to match updates
      _matchSubscription = _matchmakingService.joinMatch(widget.matchId).listen(
        (match) {
          if (!_isDisposed && mounted) {
            setState(() {
              _match = match;
              _isLoading = false;
              
              // Show coin flip animation after a short delay
              if (!_showCoinFlip) {
                _startCoinFlipSequence();
              }
            });
          }
        },
        onError: (error) {
          if (!_isDisposed && mounted) {
            setState(() {
              _isLoading = false;
              _errorMessage = error.toString();
            });
          }
        },
      );
    } catch (e) {
      if (!_isDisposed && mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString();
        });
      }
    }
  }
  
  void _startCoinFlipSequence() {
    // Start showing the coin with scale animation
    if (!_isDisposed && mounted) {
      setState(() {
        _showCoinFlip = true;
      });
    } else {
      return; // Don't proceed if we're disposed
    }
    
    // Instead of animating here, we'll navigate to the coin flip screen
    if (_match != null) {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final userId = userProvider.user?.id;
      
      if (userId == null) {
        setState(() {
          _errorMessage = 'You must be logged in to play online';
        });
        return;
      }
      
      // Determine local player and opponent
      final isPlayer1 = _match!.player1.id == userId;
      final localPlayer = isPlayer1 ? _match!.player1 : _match!.player2;
      final opponent = isPlayer1 ? _match!.player2 : _match!.player1;
      
      // Use the actual current turn from the match data
      final winningSymbol = _match!.currentTurn;
      AppLogger.info('Using actual current turn from match data: $winningSymbol');
      
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => OnlineCoinFlipScreen(
            player1: Player(
              name: localPlayer.name,
              symbol: localPlayer.symbol,
            ),
            player2: Player(
              name: opponent.name,
              symbol: opponent.symbol,
            ),
            // Pass the predetermined winning symbol
            predeterminedWinningSymbol: winningSymbol,
            onResult: (winningSymbol) {
              // When coin flip is done, mark as complete and navigate to game
              if (!_isDisposed && mounted) {
                setState(() {
                  _coinFlipComplete = true;
                });
                _navigateToGame(winningSymbol);
              }
            },
          ),
        ),
      );
    }
  }
  
  void _navigateToGame([String? firstPlayerSymbol]) {
    if (_match == null) return;
    
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final userId = userProvider.user?.id;
    
    if (userId == null) {
      setState(() {
        _errorMessage = 'You must be logged in to play online';
      });
      return;
    }
    
    // Create game logic for online play
    final gameLogic = GameLogicOnline(
      onGameEnd: (_) {},  // Will be handled by GameScreen
      onPlayerChanged: () {},  // Will be handled by GameScreen
      localPlayerId: userId,
      gameId: widget.matchId, // Ensure both players join the same game instance
      firstPlayerSymbol: firstPlayerSymbol, // Pass the winning symbol from coin flip
    );
    
    // Determine local player and opponent
    final isPlayer1 = _match!.player1.id == userId;
    final localPlayer = isPlayer1 ? _match!.player1 : _match!.player2;
    final opponent = isPlayer1 ? _match!.player2 : _match!.player1;
    
    // Update the HellModeProvider if needed
    if (widget.isHellMode) {
      final hellModeProvider = Provider.of<HellModeProvider>(context, listen: false);
      if (!hellModeProvider.isHellModeActive) {
        hellModeProvider.toggleHellMode();
      }
    }
    
    // Navigate to game screen based on mode
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => widget.isHellMode 
          ? HellGameScreen(
              player1: Player(
                name: localPlayer.name,
                symbol: localPlayer.symbol,
              ),
              player2: Player(
                name: opponent.name,
                symbol: opponent.symbol,
              ),
              logic: gameLogic
            )
          : GameScreen(
              player1: Player(
                name: localPlayer.name,
                symbol: localPlayer.symbol,
              ),
              player2: Player(
                name: opponent.name,
                symbol: opponent.symbol,
              ),
              logic: gameLogic,
              isOnlineGame: true,
            ),
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    final bool isHellMode = widget.isHellMode;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    // Set system UI overlay style
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: isDarkMode ? Brightness.light : Brightness.dark,
    ));
    
    return Scaffold(
      backgroundColor: isHellMode ? Colors.grey[50] : Colors.white,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, -0.2),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: _slideController,
              curve: Curves.easeOutQuart,
            )),
            child: Text(
              'Match Found',
              style: TextStyle(
                color: isHellMode ? Colors.red.shade900 : Colors.blue.shade900,
                fontSize: 26,
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
        automaticallyImplyLeading: false,
      ),
      body: Stack(
        children: [
          // Background gradient
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: isHellMode
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
          ),
          
          // Main content
          SafeArea(
            child: _isLoading
              ? _buildLoadingWidget()
              : _errorMessage != null
                  ? _buildErrorWidget()
                  : _buildMatchFoundContent(),
          ),
        ],
      ),
    );
  }
  
  // Loading widget with animations
  Widget _buildLoadingWidget() {
    final bool isHellMode = widget.isHellMode;
    final Color primaryColor = isHellMode ? Colors.red.shade700 : Colors.blue.shade700;
    
    return Center(
      child: SlideTransition(
        position: _slideAnimation,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Custom animated loading indicator
                AnimatedBuilder(
                  animation: _pulseController,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _pulseAnimation.value,
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: SweepGradient(
                            colors: isHellMode 
                              ? [Colors.red.shade300, Colors.red.shade700, Colors.deepOrange.shade900, Colors.red.shade300]
                              : [Colors.blue.shade300, Colors.blue.shade700, Colors.indigo.shade900, Colors.blue.shade300],
                            stops: const [0.0, 0.3, 0.6, 1.0],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: primaryColor.withValues( alpha: 0.3),
                              blurRadius: 15,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: Center(
                          child: Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white,
                              boxShadow: [
                                BoxShadow(
                                  color: primaryColor.withValues( alpha: 0.2),
                                  blurRadius: 10,
                                  spreadRadius: -5,
                                ),
                              ],
                            ),
                            child: Center(
                              child: Icon(
                                isHellMode ? Icons.local_fire_department_rounded : Icons.sports_esports_rounded,
                                size: 50,
                                color: primaryColor,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 30),
                
                // Status message with glass effect
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues( alpha: 0.8),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: primaryColor.withValues( alpha: 0.3),
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: primaryColor.withValues( alpha: 0.1),
                            blurRadius: 15,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          // Animated status message
                          TweenAnimationBuilder<double>(
                            tween: Tween<double>(begin: 0.9, end: 1.0),
                            duration: const Duration(milliseconds: 600),
                            curve: Curves.elasticOut,
                            builder: (context, value, child) {
                              return Transform.scale(
                                scale: value,
                                child: Text(
                                  _statusMessage,
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: primaryColor,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.5,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                
                // Hell mode indicator if active
                if (isHellMode) ...[  
                  const SizedBox(height: 40),
                  SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, 0.3),
                      end: Offset.zero,
                    ).animate(CurvedAnimation(
                      parent: _slideController,
                      curve: const Interval(0.3, 0.8, curve: Curves.easeOutQuart),
                    )),
                    child: AnimatedBuilder(
                      animation: _pulseController,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: 0.95 + (_pulseController.value * 0.05),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Colors.red.shade800, Colors.deepOrange.shade700],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.red.withValues( alpha: 0.4),
                                  blurRadius: 12,
                                  offset: const Offset(0, 6),
                                  spreadRadius: 0,
                                ),
                              ],
                              border: Border.all(
                                color: Colors.red.shade300,
                                width: 2,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                TweenAnimationBuilder<double>(
                                  tween: Tween<double>(begin: 0.8, end: 1.2),
                                  duration: const Duration(milliseconds: 600),
                                  curve: Curves.easeInOut,
                                  builder: (context, iconScale, _) {
                                    return Transform.scale(
                                      scale: iconScale,
                                      child: const Icon(
                                        Icons.local_fire_department_rounded, 
                                        color: Colors.yellow,
                                        size: 28,
                                      ),
                                    );
                                  },
                                ),
                                const SizedBox(width: 12),
                                const Text(
                                  'HELL MODE ACTIVE',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.5,
                                    shadows: [
                                      Shadow(
                                        color: Colors.black26,
                                        blurRadius: 4,
                                        offset: Offset(0, 2),
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
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorWidget() {
    final bool isHellMode = widget.isHellMode;
    final Color primaryColor = isHellMode ? Colors.red.shade700 : Colors.blue.shade700;
    final Color secondaryColor = isHellMode ? Colors.deepOrange.shade700 : Colors.blue.shade900;
    
    // Format error message for better readability
    String formattedError = _errorMessage?.replaceAll('Exception: ', '') ?? 'Unknown error';
    String errorTitle = 'Error Loading Match';
    String errorSuggestion = '';
    IconData errorIcon = Icons.error_outline_rounded;
    
    // Provide more specific error messages and suggestions
    if (formattedError.contains('not found') || formattedError.contains('does not exist')) {
      errorTitle = 'Match Not Found';
      formattedError = 'The match you were trying to join no longer exists.';
      errorSuggestion = 'Please return to the online menu and try again.';
      errorIcon = Icons.sports_esports_outlined;
    } else if (formattedError.contains('permission-denied')) {
      errorTitle = 'Connection Issue';
      formattedError = 'There was a problem connecting to the game server.';
      errorSuggestion = 'Please check your internet connection and try again.';
      errorIcon = Icons.wifi_off_rounded;
    }
    
    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Container(
          margin: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: primaryColor.withValues( alpha: 0.15),
                blurRadius: 20,
                spreadRadius: 0,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: Colors.white.withValues( alpha: 0.9),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: primaryColor.withValues( alpha: 0.3),
                    width: 2,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Animated error icon
                    TweenAnimationBuilder<double>(
                      tween: Tween<double>(begin: 0.8, end: 1.0),
                      duration: const Duration(milliseconds: 800),
                      curve: Curves.elasticOut,
                      builder: (context, value, child) {
                        return Transform.scale(
                          scale: value,
                          child: Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  primaryColor.withValues( alpha: 0.2),
                                  secondaryColor.withValues( alpha: 0.1),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: primaryColor.withValues( alpha: 0.3),
                                width: 2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: primaryColor.withValues( alpha: 0.2),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Icon(
                              errorIcon,
                              size: 60,
                              color: primaryColor,
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 24),
                    
                    // Error title with animation
                    TweenAnimationBuilder<double>(
                      tween: Tween<double>(begin: 0.9, end: 1.0),
                      duration: const Duration(milliseconds: 600),
                      curve: Curves.easeOut,
                      builder: (context, value, child) {
                        return Transform.scale(
                          scale: value,
                          child: Text(
                            errorTitle,
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: primaryColor,
                              letterSpacing: 0.5,
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    // Error message
                    Text(
                      formattedError,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
                        height: 1.5,
                        color: secondaryColor.withValues( alpha: 0.8),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    
                    // Error suggestion if available
                    if (errorSuggestion.isNotEmpty) ...[  
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: primaryColor.withValues( alpha: 0.1),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: primaryColor.withValues( alpha: 0.2),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          errorSuggestion,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            fontStyle: FontStyle.italic,
                            color: secondaryColor.withValues( alpha: 0.7),
                          ),
                        ),
                      ),
                    ],
                    
                    const SizedBox(height: 32),
                    
                    // Go back button
                    Container(
                      height: 56,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(28),
                        boxShadow: [
                          BoxShadow(
                            color: primaryColor.withValues( alpha: 0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 6),
                            spreadRadius: 0,
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(28),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.arrow_back_rounded, size: 22),
                            const SizedBox(width: 10),
                            const Text(
                              'Return to Menu',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
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
  
  Widget _buildMatchFoundContent() {
    if (_match == null) return const SizedBox.shrink();
    
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final userId = userProvider.user?.id;
    
    // Determine if current user is player1 or player2
    final isPlayer1 = _match!.player1.id == userId;
    final opponent = isPlayer1 ? _match!.player2 : _match!.player1;
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Opponent info
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                const Text(
                  'Playing Against',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  opponent.name,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 40),
          
          // Show loading or waiting message if coin flip hasn't started
          if (!_showCoinFlip)
            const Text(
              'Preparing game...',
              style: TextStyle(
                fontSize: 18,
                color: Colors.black54,
              ),
            ),
          
          // Show starting message if coin flip is complete
          if (_coinFlipComplete)
            const Padding(
              padding: EdgeInsets.only(top: 20),
              child: Text(
                'Starting game...',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.black54,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
