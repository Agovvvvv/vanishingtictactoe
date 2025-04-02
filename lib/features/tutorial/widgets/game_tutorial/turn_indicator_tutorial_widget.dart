import 'package:flutter/widgets.dart';
import 'package:vanishingtictactoe/features/game/widgets/match/turn_indicator_widget.dart';
import 'package:vanishingtictactoe/shared/providers/game_provider.dart';
import 'package:provider/provider.dart';

// Build the turn indicator
class TutorialTurnIndicatorWidget extends StatelessWidget {
  const TutorialTurnIndicatorWidget({super.key});
  
  @override
  Widget build(BuildContext context) {
    return Consumer<GameProvider>(
      builder: (context, gameProvider, _) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: TurnIndicatorWidget(
            gameProvider: gameProvider,
          ),
        );
      },
    );
  }
}