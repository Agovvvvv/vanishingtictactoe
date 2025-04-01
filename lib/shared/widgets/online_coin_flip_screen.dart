import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:vanishingtictactoe/shared/models/player.dart';
import 'package:vanishingtictactoe/core/utils/app_logger.dart';
import 'package:vanishingtictactoe/shared/widgets/online_coin_flip_widget.dart';

class OnlineCoinFlipScreen extends StatefulWidget {
  final Player player1;
  final Player player2;
  final Function(String winningSymbol) onResult;
  final String? predeterminedWinningSymbol; // Add this parameter

  const OnlineCoinFlipScreen({
    super.key,
    required this.player1,
    required this.player2,
    required this.onResult,
    this.predeterminedWinningSymbol, // Optional parameter for online games
  });

  @override
  State<OnlineCoinFlipScreen> createState() => _OnlineCoinFlipScreenState();
}

class _OnlineCoinFlipScreenState extends State<OnlineCoinFlipScreen> with TickerProviderStateMixin {
  late AnimationController _flipController;
  late AnimationController _scaleController;
  late Animation<double> _flipAnimation;
  late Animation<double> _scaleAnimation;

  bool _showCoinFlip = false;
  bool _coinFlipComplete = false;
  late String _winningSymbol;
  late Player _winningPlayer;

  @override
  void initState() {
    super.initState();
    
    AppLogger.info('\nOnline Coin Flip - Initial State:');
    AppLogger.info('Player1: ${widget.player1.name} (${widget.player1.symbol})');
    AppLogger.info('Player2: ${widget.player2.name} (${widget.player2.symbol})');
    AppLogger.info('Player symbols - P1: ${widget.player1.symbol}, P2: ${widget.player2.symbol}');

    // Initialize flip animation
    _flipController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
    
    _flipAnimation = Tween<double>(
      begin: 0,
      end: math.pi * 8, // 4 full rotations for more dramatic effect
    ).animate(CurvedAnimation(
      parent: _flipController,
      curve: Curves.easeOutQuart, // Smoother deceleration
    ));
    
    // Initialize scale animation
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    
    _scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut, // Bouncy effect
    ));

    // Use predetermined winning symbol if provided (for online games)
    // Otherwise randomly decide (for local games)
    if (widget.predeterminedWinningSymbol != null) {
      _winningSymbol = widget.predeterminedWinningSymbol!;
      AppLogger.info('Using predetermined winning symbol: $_winningSymbol');
    } else {
      final xGoesFirst = math.Random().nextBool();
      _winningSymbol = xGoesFirst ? widget.player1.symbol : widget.player2.symbol;
      AppLogger.info('Randomly selected winning symbol: $_winningSymbol');
    }
    
    // Determine which player goes first based on their assigned symbol
    // This ensures consistency between the coin flip and player symbols
    _winningPlayer = widget.player1.symbol == _winningSymbol 
        ? widget.player1 
        : widget.player2;
        
    AppLogger.info('Coin flip result:');
    AppLogger.info('- Winning symbol: $_winningSymbol');
    AppLogger.info('- Winning player: ${_winningPlayer.name}');
    AppLogger.info('- Player1 symbol: ${widget.player1.symbol}, Player2 symbol: ${widget.player2.symbol}');
    
    AppLogger.info('Online coin flip result: $_winningSymbol goes first (${_winningPlayer.name})');

    // Start the animation sequence
    _startCoinFlipSequence();
  }
  
  @override
  void dispose() {
    _flipController.dispose();
    _scaleController.dispose();
    super.dispose();
  }
  
  void _startCoinFlipSequence() {
    setState(() {
      _showCoinFlip = true;
    });
    
    _scaleController.forward().then((_) {
      Timer(const Duration(milliseconds: 500), () {
        _flipController.forward().then((_) {
          setState(() {
            _coinFlipComplete = true;
          });
          
          AppLogger.info('Coin flip animation complete. Final result:');
          AppLogger.info('- Winning symbol: $_winningSymbol');
          AppLogger.info('- Winning player: ${_winningPlayer.name}');
          
          Timer(const Duration(seconds: 2), () {
            if (mounted) {
              // Call the onResult callback with the winning symbol
              // This ensures the game provider sets the correct first player
              AppLogger.info('OnlineCoinFlipScreen: Passing winning symbol $_winningSymbol to game provider');
              widget.onResult(_winningSymbol);
            }
          });
        });
      });
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Starting Game',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        automaticallyImplyLeading: false,
      ),
      body: Container(
        color: Colors.white,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // VS Card with clean white design
              Container(
                padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 30),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.shade100.withValues( alpha: 0.7),
                      blurRadius: 15,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Player 1
                        Column(
                          children: [
                            Stack(
                              alignment: Alignment.bottomRight,
                              children: [
                                CircleAvatar(
                                  radius: 35,
                                  backgroundColor: Colors.blue.shade100,
                                  child: Text(
                                    widget.player1.name.isNotEmpty ? widget.player1.name[0].toUpperCase() : 'P1',
                                    style: TextStyle(
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue.shade700,
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.shade500,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white, width: 2),
                                  ),
                                  child: Text(
                                    widget.player1.symbol,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(
                              widget.player1.name,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        
                        // VS
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 24),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'VS',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ),
                        
                        // Player 2
                        Column(
                          children: [
                            Stack(
                              alignment: Alignment.bottomRight,
                              children: [
                                CircleAvatar(
                                  radius: 35,
                                  backgroundColor: Colors.red.shade100,
                                  child: Text(
                                    widget.player2.name.isNotEmpty ? widget.player2.name[0].toUpperCase() : 'P2',
                                    style: TextStyle(
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.red.shade700,
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: Colors.red.shade500,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white, width: 2),
                                  ),
                                  child: Text(
                                    widget.player2.symbol,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(
                              widget.player2.name,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 60),
              
              // Coin flip animation
              if (_showCoinFlip)
                OnlineCoinFlipWidget(
                  flipAnimation: _flipAnimation,
                  scaleAnimation: _scaleAnimation,
                  coinFlipComplete: _coinFlipComplete,
                  currentTurn: _winningSymbol,
                  player1Symbol: widget.player1.symbol,
                  player2Symbol: widget.player2.symbol,
                ),
              
              // Result text after coin flip
              if (_coinFlipComplete)
                Container(
                  margin: const EdgeInsets.only(top: 40),
                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue.shade100.withValues( alpha: 0.5),
                        blurRadius: 15,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Text(
                        '$_winningSymbol goes first!',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          '${_winningPlayer.name} (${_winningPlayer.symbol}) will start',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              
              // Starting game message
              if (_coinFlipComplete)
                Container(
                  margin: const EdgeInsets.only(top: 20),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Starting game...',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}