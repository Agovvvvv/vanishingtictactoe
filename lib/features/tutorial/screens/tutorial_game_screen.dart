import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:vanishingtictactoe/features/game/models/computer_player.dart';
import 'package:vanishingtictactoe/features/tutorial/models/tutorial_game_logic.dart';
import 'package:vanishingtictactoe/features/tutorial/widgets/game_tutorial/index.dart';
import 'package:vanishingtictactoe/features/tutorial/widgets/normal_tutorial/skip_button_widget.dart';
import 'package:vanishingtictactoe/shared/models/player.dart';
import 'package:vanishingtictactoe/shared/providers/game_provider.dart';

class TutorialGameScreen extends StatefulWidget {
  const TutorialGameScreen({super.key});

  @override
  State<TutorialGameScreen> createState() => _TutorialGameScreenState();
}

class _TutorialGameScreenState extends State<TutorialGameScreen> with SingleTickerProviderStateMixin {
  late TutorialGameLogic _gameLogic;
  late ComputerPlayer _computerPlayer;
  late Player _humanPlayer;
  late Player _aiPlayer;
  int _moveCount = 0;
  bool _showVanishingExplanation = false;
  bool _tutorialComplete = false;
  bool _isInteractionDisabled = false;
  late GameProvider _gameProvider;
  
  // Animation controller for the flashing effect
  late AnimationController _flashingController;
  late Animation<double> _flashingAnimation;
  
  @override
  void initState() {
    super.initState();
    
    // Initialize animation controller for flashing effect
    _flashingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..repeat(reverse: true);
    
    _flashingAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(_flashingController);
    
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
                  TutorialDemoCellWidget(symbol: 'X', isFlashing: false, flashingAnimation: _flashingAnimation),
                  TutorialDemoCellWidget(symbol: 'O', isFlashing: false, flashingAnimation: _flashingAnimation),
                  TutorialDemoCellWidget(symbol: 'X', isFlashing: false, flashingAnimation: _flashingAnimation),
                  const Icon(Icons.arrow_forward, color: Colors.grey),
                  TutorialDemoCellWidget(symbol: '', isFlashing: true, flashingAnimation: _flashingAnimation), 
                  TutorialDemoCellWidget(symbol: 'O', isFlashing: false, flashingAnimation: _flashingAnimation),
                  TutorialDemoCellWidget(symbol: 'X', isFlashing: false, flashingAnimation: _flashingAnimation),
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

  @override
  void dispose() {
    _flashingController.dispose();
    super.dispose();
  }

  void _completeTutorial() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('tutorial_completed', true);
    
    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => TutorialCompletionDialogWidget(),
      );
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _gameProvider,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: _buildAppBar(),
        body: SafeArea(
          child: Column(
          children: [
            // Tutorial instruction card
            TutorialInstructionCardWidget(moveCount: _moveCount),
            
            // Turn indicator
            TutorialTurnIndicatorWidget(),
            
            // Game board
            TutorialGameBoardWidget(
              isInteractionDisabled: _isInteractionDisabled,
              handleCellTapped: _handleCellTapped,
              gameLogic: _gameLogic,
              humanPlayer: _humanPlayer,
            ),
            
            // Move counter
            TutorialMoveCounterWidget(playerMoves: _moveCount),
          ],
        )),
      ),
    );
  }
  
  // Build the app bar with skip button
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.blue.shade700,
      elevation: 0,
      automaticallyImplyLeading: false, // This removes the back button
      title: const Text(
        'Tutorial Game',
        style: TextStyle(fontWeight: FontWeight.w600),
        selectionColor: Colors.white,
      ),
      actions: [
        TutorialSkipButtonWidget(),
      ],
    );
  }
}