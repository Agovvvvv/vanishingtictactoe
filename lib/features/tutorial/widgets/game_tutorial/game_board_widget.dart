import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vanishingtictactoe/features/game/widgets/match/game_board_widget.dart';
import 'package:vanishingtictactoe/features/tutorial/models/tutorial_game_logic.dart';
import 'package:vanishingtictactoe/shared/models/player.dart';
import 'package:vanishingtictactoe/shared/providers/game_provider.dart';

class TutorialGameBoardWidget extends StatelessWidget {
  final bool isInteractionDisabled;
  final void Function(int) handleCellTapped;
  final TutorialGameLogic gameLogic;
  final Player humanPlayer;
  
  const TutorialGameBoardWidget({
    super.key,
    required this.isInteractionDisabled,
    required this.handleCellTapped,
    required this.gameLogic,
    required this.humanPlayer,
  });
  
  @override
  Widget build(BuildContext context) {
    return Expanded(
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
                  color: Colors.blue.shade200.withOpacity(0.4),
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
                  isInteractionDisabled: isInteractionDisabled || 
                      gameLogic.currentPlayer != humanPlayer.symbol,
                  onCellTapped: handleCellTapped,
                  gameLogic: gameLogic,
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}