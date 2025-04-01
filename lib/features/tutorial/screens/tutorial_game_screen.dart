import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:vanishingtictactoe/core/navigation/navigation_service.dart';
import 'package:vanishingtictactoe/features/game/models/computer_player.dart';
import 'package:vanishingtictactoe/features/game/widgets/match/game_board_widget.dart';
import 'package:vanishingtictactoe/features/game/widgets/match/turn_indicator_widget.dart';
import 'package:vanishingtictactoe/features/home/screens/home_screen.dart';
import 'package:vanishingtictactoe/features/tutorial/models/tutorial_game_logic.dart';
import 'package:vanishingtictactoe/shared/models/player.dart';
import 'package:vanishingtictactoe/shared/providers/game_provider.dart';

class TutorialGameScreen extends StatefulWidget {
  const TutorialGameScreen({super.key});

  @override
  State<TutorialGameScreen> createState() => _TutorialGameScreenState();
}

class _TutorialGameScreenState extends State<TutorialGameScreen> {
  late TutorialGameLogic _gameLogic;
  late ComputerPlayer _computerPlayer;
  late Player _humanPlayer;
  late Player _aiPlayer;
  int _moveCount = 0;
  bool _showVanishingExplanation = false;
  bool _tutorialComplete = false;
  bool _isInteractionDisabled = false;
  late GameProvider _gameProvider;
  
  @override
  void initState() {
    super.initState();
    _initializeGame();
  }
  
  void _initializeGame() {
    // Create players
    _humanPlayer = Player(
      name: 'You',
      symbol: 'X',
    );
    
    _computerPlayer = ComputerPlayer(
      name: 'Tutorial AI',
      computerSymbol: 'O',
      playerSymbol: 'X',
      difficulty: GameDifficulty.hard,
    );
    
    _aiPlayer = Player(
      name: 'Tutorial AI',
      symbol: 'O',
    );
    
    // Initialize game logic with vanishing effect disabled initially
    _gameLogic = TutorialGameLogic(
      onGameEnd: _handleGameEnd,
      onPlayerChanged: _handlePlayerChanged,
      computerPlayer: _computerPlayer,
      humanSymbol: _humanPlayer.symbol,
      vanishingEffectEnabled: false, // Start with vanishing effect disabled
      onMoveCountUpdated: (count) {
        setState(() {
          _moveCount = count;
          
          // Check if we should show the vanishing explanation
          if (_moveCount == 6) { 
            _showVanishingExplanationDialog();
          }
        });
      },
    );
    
    // Initialize game provider
    _gameProvider = GameProvider(
      gameLogic: _gameLogic,
      onGameEnd: _handleGameEnd,
      onPlayAgain: () {
        // Reset the game for play again functionality
        _initializeGame();
      },
      paramPlayer1: _humanPlayer,
      paramPlayer2: _aiPlayer,
    );
  }
  
  void _handlePlayerChanged() {
    if (mounted) {
      setState(() {
        _isInteractionDisabled = _gameLogic.isComputerTurn;
      });
      _gameProvider.notifyPlayerChanged();
    }
  }
  
  void _handleGameEnd(String winner) {
    if (_tutorialComplete) return;
    
    setState(() {
      _tutorialComplete = true;
    });
    
    _completeTutorial();
  }
  
  void _handleCellTapped(int index) {
    if (_isInteractionDisabled || _showVanishingExplanation) return;
    
    // Use the makeMove method which handles both human and computer moves
    _gameLogic.makeMove(index);
  }
  
  void _showVanishingExplanationDialog() {
    setState(() {
      _showVanishingExplanation = true;
    });
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.auto_awesome, color: Colors.orange, size: 24),
            const SizedBox(width: 8),
            const Text('The Vanishing Effect!'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'This is where the game gets interesting! After the 3rd move, the oldest piece on the board will vanish when a new one is placed.',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 12),
            const Text(
              'This creates a dynamic game where you need to think ahead about which pieces will disappear!',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            // Add a visual demonstration of the vanishing effect
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildDemoCell('X', false),
                  _buildDemoCell('O', false),
                  _buildDemoCell('X', false),
                  const Icon(Icons.arrow_forward, color: Colors.grey),
                  _buildDemoCell('', true), // Flashing empty cell
                  _buildDemoCell('O', false),
                  _buildDemoCell('X', false),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: const Row(
                children: [
                  Icon(Icons.lightbulb_outline, color: Colors.orange, size: 18),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Watch for the flashing cell - it shows where a piece has vanished!',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.orange),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton.icon(
            onPressed: () {
              Navigator.of(context).pop();
              setState(() {
                _showVanishingExplanation = false;
                
                // Enable vanishing effect after explanation without recreating the game logic
                _gameLogic.enableVanishingEffect();
              });
            },
            icon: const Icon(Icons.check_circle_outline, size: 18, color: Colors.white),
            label: const Text('Got it!'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue.shade700,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Helper method to build a demo cell for the vanishing effect explanation
  Widget _buildDemoCell(String symbol, bool isFlashing) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 500),
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        color: isFlashing 
            ? (DateTime.now().millisecondsSinceEpoch % 1000 < 500 ? Colors.orange.withValues( alpha: 0.3) : Colors.white)
            : Colors.white,
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Center(
        child: Text(
          symbol,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: symbol == 'X' ? Colors.blue : Colors.red,
          ),
        ),
      ),
    );
  }

  void _completeTutorial() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('tutorial_completed', true);
    
    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Icon(Icons.celebration, color: Colors.blue.shade700, size: 24),
              const SizedBox(width: 8),
              const Text('Tutorial Complete!'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Great job! You now understand how Vanishing Tic Tac Toe works. Ready to play for real?',
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Column(
                  children: [
                    Icon(Icons.emoji_events, color: Colors.amber, size: 40),
                    SizedBox(height: 8),
                    Text(
                      'You\'re ready to play!',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).pop();
                NavigationService.instance.navigateToAndRemoveUntil('/main');

              },
              icon: const Icon(Icons.play_arrow, size: 18, color: Colors.white,),
              label: const Text('Let\'s Play!'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade700,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      );
    }
  }
  
  void _skipTutorial() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('tutorial_completed', true);
    
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
    }
  }
  
  // Add the missing build method
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _gameProvider,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.blue.shade700,
          elevation: 0,
          automaticallyImplyLeading: false, // This removes the back button
          title: const Text(
            'Tutorial Game',
            style: TextStyle(fontWeight: FontWeight.w600),
            selectionColor: Colors.white,
          ),
          actions: [
            TextButton.icon(
              onPressed: _skipTutorial,
              style: TextButton.styleFrom(foregroundColor: Colors.white),
              icon: const Icon(Icons.skip_next, size: 18),
              label: const Text('Skip', style: TextStyle(fontSize: 14)),
            ),
          ],
        ),
        body: Column(
          children: [
            // Tutorial instruction card
            Container(
              margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue.shade50, Colors.blue.shade100],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.shade200.withValues( alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _moveCount < 3 ? Icons.touch_app : Icons.remove_circle_outline,
                      color: Colors.blue.shade700,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _moveCount < 3 
                          ? 'Play normally - make your move!' 
                          : 'Watch for the vanishing effect!',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.blue.shade900,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Turn indicator
            Consumer<GameProvider>(
              builder: (context, gameProvider, _) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: TurnIndicatorWidget(
                    gameProvider: gameProvider,
                  ),
                );
              },
            ),
            
            // Game board
            Expanded(
              child: Center(
                child: AspectRatio(
                  aspectRatio: 1,
                  child: Container(
                    margin: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blue.shade200.withValues( alpha: 0.4),
                          blurRadius: 12,
                          spreadRadius: 2,
                          offset: const Offset(0, 4),
                        ),
                      ],
                      border: Border.all(
                        color: Colors.blue.shade50,
                        width: 1.5,
                      ),
                    ),
                    child: Consumer<GameProvider>(
                      builder: (context, gameProvider, _) {
                        return GameBoardWidget(
                          isInteractionDisabled: _isInteractionDisabled || 
                              _gameLogic.currentPlayer != _humanPlayer.symbol,
                          onCellTapped: _handleCellTapped,
                          gameLogic: _gameLogic,
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
            
            // Move counter
            Container(
              margin: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.history,
                    size: 18,
                    color: Colors.blue.shade700,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Your moves: ${(_moveCount + 1) ~/ 2}',
                    style: TextStyle(
                      fontSize: 14,
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
    );
  }
}