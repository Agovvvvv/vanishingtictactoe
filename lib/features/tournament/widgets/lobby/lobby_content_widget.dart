import 'package:flutter/material.dart';
import 'package:vanishingtictactoe/features/tournament/providers/tournament_provider.dart';
import 'package:vanishingtictactoe/features/tournament/widgets/lobby/action_buttons_widget.dart';
import 'package:vanishingtictactoe/features/tournament/widgets/lobby/player_list_widget.dart';
import 'package:vanishingtictactoe/features/tournament/widgets/lobby/tournament_info_widget.dart';

class LobbyContentWidget extends StatelessWidget {
  final TournamentProvider provider;
  final Color primaryColor;
  final bool isStartingTournament;
  final bool isLeavingTournament;
  final VoidCallback onStartTournament;
  final VoidCallback onLeaveTournament;

  const LobbyContentWidget ({
    super.key,
    required this.provider,
    required this.primaryColor,
    required this.isStartingTournament,
    required this.isLeavingTournament,
    required this.onStartTournament,
    required this.onLeaveTournament,
  });

  @override
  Widget build(BuildContext context, ) {
    final tournament = provider.tournament!;
    
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Animated title
            TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 800),
              curve: Curves.easeOutQuart,
              builder: (context, value, child) {
                return Opacity(
                  opacity: value,
                  child: Transform.translate(
                    offset: Offset(0, 20 * (1 - value)),
                    child: child,
                  ),
                );
              },
              child: TournamentInfoWidget(tournament: tournament, primaryColor: primaryColor),
            ),
            const SizedBox(height: 32),
            
            // Players list with animation
            TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 800),
              curve: Curves.easeOutQuart,
              builder: (context, value, child) {
                return Opacity(
                  opacity: value,
                  child: Transform.translate(
                    offset: Offset(0, 20 * (1 - value)),
                    child: child,
                  ),
                );
              },
              child: PlayersListWidget(
                      players: tournament.players, 
                      primaryColor: primaryColor
                    ),
            ),
            const SizedBox(height: 32),
            
            // Action buttons with animation
            TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 800),
              curve: Curves.easeOutQuart,
              builder: (context, value, child) {
                return Opacity(
                  opacity: value,
                  child: Transform.translate(
                    offset: Offset(0, 20 * (1 - value)),
                    child: child,
                  ),
                );
              },
              child: ActionButtonsWidget(
                provider: provider,
                isStartingTournament: isStartingTournament,
                isLeavingTournament: isLeavingTournament,
                onStartTournament: onStartTournament,
                onLeaveTournament: onLeaveTournament,
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}