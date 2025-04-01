import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vanishingtictactoe/features/game/models/game_logic_2players.dart';
import 'package:vanishingtictactoe/features/game/models/game_logic_vscomputer.dart';
import 'package:vanishingtictactoe/features/game/models/game_logic_online.dart';
import 'package:vanishingtictactoe/features/game/models/friendly_game_logic_online.dart';
import 'package:vanishingtictactoe/core/utils/app_logger.dart';
import 'package:vanishingtictactoe/features/game/widgets/match/grid_cell.dart';
import 'package:vanishingtictactoe/features/game/widgets/match/winning_line_widget.dart';
import 'package:vanishingtictactoe/shared/providers/game_provider.dart';

class GameBoardWidget extends StatefulWidget {
  final bool isInteractionDisabled;
  final Function(int) onCellTapped;
  final GameLogic gameLogic;
  final VoidCallback? onWinAnimationComplete;

  const GameBoardWidget({
    super.key,
    required this.isInteractionDisabled,
    required this.onCellTapped,
    required this.gameLogic,
    this.onWinAnimationComplete,
  });

  @override
  State<GameBoardWidget> createState() => _GameBoardWidgetState();
}

class _GameBoardWidgetState extends State<GameBoardWidget> with SingleTickerProviderStateMixin {
  bool _isInteractionEnabled = false;
  late AnimationController _appearController;
  late Animation<double> _appearAnimation;
  
  // Map to store references to grid cell keys for animation control
  final Map<int, GlobalKey<GridCellState>> _cellKeys = {};

  @override
  void initState() {
    super.initState();
    
    // Setup appearance animation
    _appearController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    
    _appearAnimation = CurvedAnimation(
      parent: _appearController,
      curve: Curves.easeOutQuart,
    );
    
    // Initialize cell keys
    for (int i = 0; i < 9; i++) {
      _cellKeys[i] = GlobalKey<GridCellState>();
    }
    
    // Start the appearance animation
    _appearController.forward();
    
    // Enable interaction after a short delay
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        setState(() => _isInteractionEnabled = true);
        AppLogger.info('GameBoardWidget: Interaction enabled after delay');
      }
    });
  }
  
  @override
  void dispose() {
    _appearController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return FadeTransition(
      opacity: _appearAnimation,
      child: ScaleTransition(
        scale: _appearAnimation,
        child: Consumer<GameProvider>(
          builder: (context, gameProvider, child) {
            final board = gameProvider.board;
            
            return Stack(
              children: [
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: colorScheme.shadow.withValues(alpha: 0.15),
                        blurRadius: 8,
                        spreadRadius: 1,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: GridView.count(
                      shrinkWrap: true,
                      crossAxisCount: 3,
                      mainAxisSpacing: 8,
                      crossAxisSpacing: 8,
                      padding: const EdgeInsets.all(8),
                      physics: const NeverScrollableScrollPhysics(),
                      children: List.generate(9, (index) {
                        final value = board[index];
                        final isVanishing = widget.gameLogic.vanishingEffectEnabled && 
                                           widget.gameLogic.getNextToVanish() == index;
                        
                        return AbsorbPointer(
                          absorbing: widget.isInteractionDisabled || !_isInteractionEnabled || gameProvider.winningPattern != null,
                          child: GridCell(
                            key: _cellKeys[index],
                            value: value,
                            index: index,
                            isVanishing: isVanishing,
                            onTap: () {
                              // Call the onCellTapped callback
                              widget.onCellTapped(index);
                            },
                          ),
                        );
                      }),
                    ),
                  ),
                ),
                
                // Display winning line animation if a winning pattern is available from the provider
                if (gameProvider.winningPattern != null)
                  Positioned.fill(
                    child: WinningLineWidget(
                      winningPattern: gameProvider.winningPattern!,
                      color: Colors.black, // This will be overridden by the isLocalPlayerWinner parameter
                      onAnimationComplete: () {
                        // Trigger animations for winning cells
                        if (gameProvider.winningPattern != null) {
                          for (final index in gameProvider.winningPattern!) {
                            final cellState = _cellKeys[index]?.currentState;
                            if (cellState != null && mounted) {
                              cellState.triggerGameEndAnimation();
                            }
                          }
                        }
                        
                        if (widget.onWinAnimationComplete != null) {
                          widget.onWinAnimationComplete!();
                        }
                      },
                      // Determine if local player is the winner based on the game state
                      isLocalPlayerWinner: _isLocalPlayerWinner(gameProvider),
                    ),
                  ),
              ],
            );
          },
          // Fallback widget in case the provider is not found
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: GridView.count(
              shrinkWrap: true,
              crossAxisCount: 3,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              padding: const EdgeInsets.all(8),
              physics: const NeverScrollableScrollPhysics(),
              children: List.generate(9, (index) {
                final value = widget.gameLogic.board[index];
                return AbsorbPointer(
                  absorbing: true,
                  child: GridCell(
                    key: GlobalKey<GridCellState>(),
                    value: value,
                    index: index,
                    isVanishing: false,
                    onTap: () {}, // No-op since interaction is disabled
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }

  // Helper method to determine if the local player is the winner
  bool _isLocalPlayerWinner(GameProvider gameProvider) {
    // Get the current winner from the game logic
    String winner = '';
    
    // For online games, check if the local player won
    if (gameProvider.gameLogic is GameLogicOnline) {
      final onlineLogic = gameProvider.gameLogic as GameLogicOnline;
      // Check if the winner matches the local player's symbol
      return onlineLogic.checkWinner() == onlineLogic.localPlayerSymbol;
    } 
    // For friendly online games, check if the local player won
    else if (gameProvider.gameLogic is FriendlyGameLogicOnline) {
      final friendlyLogic = gameProvider.gameLogic as FriendlyGameLogicOnline;
      // Check if the winner matches the local player's symbol
      return friendlyLogic.checkWinner() == friendlyLogic.localPlayerSymbol;
    }
    // For computer games, check if player 1 (human) won
    else if (gameProvider.gameLogic is GameLogicVsComputer) {
      final computerLogic = gameProvider.gameLogic as GameLogicVsComputer;
      // Player 1 is always the human player
      winner = computerLogic.checkWinner();
      return winner == computerLogic.player1Symbol;
    } 
    // For 2-player games, player 1 is considered the "local" player
    else {
      winner = gameProvider.gameLogic.checkWinner();
      return winner == gameProvider.gameLogic.player1Symbol;
    }
  }
}
