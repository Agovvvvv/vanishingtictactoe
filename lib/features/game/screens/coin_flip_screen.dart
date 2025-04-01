import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vanishingtictactoe/core/constants/app_colors.dart';
import 'package:vanishingtictactoe/core/utils/app_logger.dart';
import 'package:vanishingtictactoe/features/game/models/game_logic_2players.dart';
import 'package:vanishingtictactoe/features/game/screens/game_screen.dart';
import 'package:vanishingtictactoe/features/game/widgets/match/coin_flip_effect.dart';
import 'package:vanishingtictactoe/shared/models/player.dart';

class CoinFlipScreen extends StatefulWidget {
  final Player player1;
  final Player player2;
  final Function(Player firstPlayer)? onResult;
  final bool vanishingEffectEnabled;

  const CoinFlipScreen({
    super.key,
    required this.player1,
    required this.player2,
    this.onResult,
    // Default to true to maintain backward compatibility
    this.vanishingEffectEnabled = true,
  });

  @override
  State<CoinFlipScreen> createState() => _CoinFlipScreenState();
}

class _CoinFlipScreenState extends State<CoinFlipScreen> with TickerProviderStateMixin {
  // Animation controllers
  late final AnimationController _flipController;
  late final AnimationController _scaleController;
  late final AnimationController _backgroundController;
  late final AnimationController _textAnimationController;
  late final AnimationController _resultAnimationController;
  late final AnimationController _particleController;
  
  // Animation values
  late final Animation<double> _flipAnimation;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _textScaleAnimation;
  late final Animation<double> _resultScaleAnimation;
  late final Animation<double> _resultOpacityAnimation;
  late final Animation<double> _backgroundAnimation;

  // State variables
  bool _showCoinFlip = false;
  bool _coinFlipComplete = false;
  bool _showResult = false;
  late bool _player1GoesFirst;
  late String _player1Symbol;
  late String _player2Symbol;
  
  // Colors for particles and effects
  late Color _winnerColor;
  late Color _winnerSecondaryColor;

  @override
  void initState() {
    super.initState();
    
    // Initialize player symbols
    _initializePlayerSymbols();
    
    // Initialize animations
    _initializeAnimations();

    // Determine who goes first
    _determineFirstPlayer();
    
    // Set winner colors based on who goes first
    _setWinnerColors();

    // Start the animation sequence with a short delay
    Future.delayed(const Duration(milliseconds: 300), () {
      _startCoinFlipSequence();
    });
  }
  
  // Initialize player symbols with random assignment
  void _initializePlayerSymbols() {
    // Clear any existing symbols
    widget.player1.symbol = '';
    widget.player2.symbol = '';

    // Do random symbol assignment
    final random = math.Random();
    _player1Symbol = random.nextBool() ? 'X' : 'O';
    _player2Symbol = _player1Symbol == 'X' ? 'O' : 'X';
    
    // Update player symbols
    widget.player1.symbol = _player1Symbol;
    widget.player2.symbol = _player2Symbol;
  }

  // Initialize all animations
  void _initializeAnimations() {
    // Initialize flip animation with improved timing
    _flipController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );
    
    _flipAnimation = Tween<double>(
      begin: 0,
      end: math.pi * 10, // 5 full rotations for more dramatic effect
    ).animate(CurvedAnimation(
      parent: _flipController,
      curve: Curves.easeOutQuart, // Smoother deceleration
    ));
    
    // Initialize scale animation with improved timing
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    
    _scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut, // Bouncy effect
    ));
    
    // Text animation for instructions
    _textAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    
    _textScaleAnimation = CurvedAnimation(
      parent: _textAnimationController,
      curve: Curves.easeOutBack,
    );
    
    // Result animation for winner announcement
    _resultAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    
    _resultScaleAnimation = CurvedAnimation(
      parent: _resultAnimationController,
      curve: Curves.elasticOut,
    );
    
    _resultOpacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _resultAnimationController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    ));
    
    // Background animation
    _backgroundController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 15000),
    )..repeat(reverse: true);
    
    _backgroundAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _backgroundController,
      curve: Curves.easeInOut,
    ));
    
    // Particle animation controller
    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat();
  }

  // Determine which player goes first
  void _determineFirstPlayer() {
    AppLogger.info('\nCoin Flip - Determining First Player:');
    // Randomly decide if X or O goes first
    final xGoesFirst = math.Random().nextBool();
    final winningSymbol = xGoesFirst ? 'X' : 'O';
    AppLogger.info('Coin flip result: $winningSymbol goes first');
    
    // Set player1GoesFirst based on who has the winning symbol
    _player1GoesFirst = widget.player1.symbol == winningSymbol;
    AppLogger.info('Player1 (${widget.player1.name}) has ${widget.player1.symbol} and ${_player1GoesFirst ? "goes first" : "goes second"}');
    AppLogger.info('Player2 (${widget.player2.name}) has ${widget.player2.symbol} and ${!_player1GoesFirst ? "goes first" : "goes second"}');
  }

  @override
  void dispose() {
    _flipController.dispose();
    _scaleController.dispose();
    _backgroundController.dispose();
    _textAnimationController.dispose();
    _resultAnimationController.dispose();
    _particleController.dispose();
    super.dispose();
  }
  
  // Set winner colors based on who goes first
  void _setWinnerColors() {
    if (_player1GoesFirst) {
      _winnerColor = AppColors.player1Dark;
      _winnerSecondaryColor = AppColors.player1Light;
    } else {
      _winnerColor = AppColors.player2Dark;
      _winnerSecondaryColor = AppColors.player2Light;
    }
  }
  
  // Start the coin flip animation sequence
  void _startCoinFlipSequence() {
    // Show the coin with scale animation
    setState(() {
      _showCoinFlip = true;
    });
    
    // Animate text instructions
    _textAnimationController.forward();
    
    // Scale in the coin
    _scaleController.forward().then((_) {
      // Wait a moment before flipping
      Timer(const Duration(milliseconds: 600), () {
        // Start the flip animation
        _flipController.forward().then((_) {
          // Show the result
          setState(() {
            _coinFlipComplete = true;
            _showResult = true;
          });
          
          // Animate in the result text
          _resultAnimationController.forward();
          
          // Wait before navigating to the game
          Timer(const Duration(milliseconds: 2500), () {
            if (mounted) {
              _navigateToGame();
            }
          });
        });
      });
    });
  }
  
  void _navigateToGame() {
    AppLogger.info('\nCoin Flip - Starting Game:');
    final gameLogic = GameLogic(
      onGameEnd: (_) {},
      onPlayerChanged: () {},
      player1Symbol: widget.player1.symbol,
      player2Symbol: widget.player2.symbol,
      player1GoesFirst: _player1GoesFirst,
    );
    
    AppLogger.info('CoinFlipScreen: Replacing with GameScreen');
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => GameScreen(
          player1: widget.player1,
          player2: widget.player2,
          logic: gameLogic,
          vanishingEffectEnabled: widget.vanishingEffectEnabled,
        ),
        settings: const RouteSettings(name: '/game-screen'),
      ),
    );
    AppLogger.info('CoinFlipScreen: Replacement complete');
  }
  
  @override
  Widget build(BuildContext context) {
    // Set winner colors based on current state
    final primaryColor = _player1GoesFirst ? AppColors.player1Dark : AppColors.player2Dark;
    final secondaryColor = _player1GoesFirst ? AppColors.player1Light : AppColors.player2Light;
    
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Coin Flip',
          style: GoogleFonts.pressStart2p(
            fontSize: 18,
            color: Colors.white,
            shadows: [
              Shadow(
                color: Colors.black.withValues(alpha: 0.5),
                blurRadius: 4,
                offset: const Offset(1, 1),
              ),
            ],
          ),
        ),
        automaticallyImplyLeading: false,
      ),
      body: AnimatedBuilder(
        animation: _backgroundAnimation,
        builder: (context, child) {
          return Stack(
            children: [
              // Gradient background
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    stops: [
                      0.0,
                      _backgroundAnimation.value * 0.3 + 0.3,
                      _backgroundAnimation.value * 0.2 + 0.6,
                      1.0
                    ],
                    colors: [
                      Color.lerp(Colors.grey.shade100, primaryColor.withValues(alpha: 0.05), _backgroundAnimation.value) ?? Colors.grey.shade100,
                      Color.lerp(Colors.white, primaryColor.withValues(alpha: 0.1), _backgroundAnimation.value) ?? Colors.white,
                      Color.lerp(Colors.grey.shade50, secondaryColor.withValues(alpha: 0.1), _backgroundAnimation.value) ?? Colors.grey.shade50,
                      Color.lerp(Colors.white.withValues(alpha: 0.9), secondaryColor.withValues(alpha: 0.05), _backgroundAnimation.value) ?? Colors.white.withValues(alpha: 0.9),
                    ],
                  ),
                ),
              ),
              
              
              // Main content
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // VS Card with enhanced design
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 30),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildPlayerInfo(widget.player1.name, _player1Symbol, AppColors.player1Dark),
                          const SizedBox(width: 20),
                          Container(
                            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Colors.grey.shade200,
                                  Colors.grey.shade300,
                                ],
                              ),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.05),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Text(
                              'VS',
                              style: GoogleFonts.pressStart2p(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey.shade800,
                              ),
                            ),
                          ),
                          const SizedBox(width: 20),
                          _buildPlayerInfo(widget.player2.name, _player2Symbol, AppColors.player2Dark),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 50),
                    
                    // Instruction text with animation
                    if (_showCoinFlip)
                      ScaleTransition(
                        scale: _textScaleAnimation,
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.8),
                            borderRadius: BorderRadius.circular(30),
                            boxShadow: [
                              BoxShadow(
                                color: primaryColor.withValues(alpha: 0.2),
                                blurRadius: 10,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                          child: Text(
                            'Flipping coin to decide who goes first...',
                            style: GoogleFonts.roboto(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey.shade800,
                            ),
                          ),
                        ),
                      ),
                    
                    const SizedBox(height: 40),
                    
                    // Enhanced coin flip animation
                    if (_showCoinFlip)
                      ScaleTransition(
                        scale: _scaleAnimation,
                        child: CoinFlipEffect(
                          frontSymbol: _player1Symbol,
                          backSymbol: _player2Symbol,
                          showFront: _player1GoesFirst,
                          isFlipping: !_coinFlipComplete,
                          flipAnimation: _flipAnimation,
                          isComplete: _coinFlipComplete,
                        ),
                      ),
                    
                    const SizedBox(height: 40),
                    
                    // Result announcement with animation
                    if (_showResult)
                      AnimatedBuilder(
                        animation: Listenable.merge([_resultScaleAnimation, _resultOpacityAnimation]),
                        builder: (context, child) {
                          return Transform.scale(
                            scale: _resultScaleAnimation.value,
                            child: Opacity(
                              opacity: _resultOpacityAnimation.value,
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      _winnerColor.withValues(alpha: 0.8),
                                      _winnerSecondaryColor.withValues(alpha: 0.8),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: _winnerColor.withValues(alpha: 0.3),
                                      blurRadius: 15,
                                      spreadRadius: 2,
                                      offset: const Offset(0, 5),
                                    ),
                                  ],
                                ),
                                child: Text(
                                  _player1GoesFirst 
                                      ? '${widget.player1.name} ($_player1Symbol) goes first!'
                                      : '${widget.player2.name} ($_player2Symbol) goes first!',
                                  style: GoogleFonts.pressStart2p(
                                    fontSize: 16,
                                    color: Colors.white,
                                    shadows: [
                                      Shadow(
                                        color: Colors.black.withValues(alpha: 0.5),
                                        blurRadius: 4,
                                        offset: const Offset(1, 1),
                                      ),
                                    ],
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    
                    // Game starting indicator
                    if (_coinFlipComplete)
                      Padding(
                        padding: const EdgeInsets.only(top: 30),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(_winnerColor),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Starting game...',
                              style: GoogleFonts.roboto(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey.shade800,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
    }
    
    Widget _buildPlayerInfo(String name, String symbol, Color color) {
      return Column(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              shape: BoxShape.circle,
              border: Border.all(color: color, width: 2),
            ),
            child: Center(
              child: Text(
                symbol,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            name,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      );
    }
}
