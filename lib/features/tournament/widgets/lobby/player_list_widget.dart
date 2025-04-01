import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vanishingtictactoe/features/tournament/models/tournament_player.dart';
import 'package:vanishingtictactoe/features/tournament/widgets/lobby/empty_player_slot_widget.dart';
import 'package:vanishingtictactoe/features/tournament/widgets/lobby/player_item_widget.dart';
import 'package:vanishingtictactoe/shared/providers/hell_mode_provider.dart';

class PlayersListWidget extends StatelessWidget {
    final List<TournamentPlayer> players;
    final Color primaryColor;
    
    const PlayersListWidget({
      super.key,
      required this.players,
      required this.primaryColor,
    });
    
    @override
    Widget build(BuildContext context) {
      final hellModeProvider = Provider.of<HellModeProvider>(context);
      final isHellMode = hellModeProvider.isHellModeActive;
      
      return Card(
        elevation: 8,
      shadowColor: primaryColor.withValues(alpha: 0.3),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white,
              isHellMode ? Colors.red.shade50 : Colors.blue.shade50,
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Players header with animation
              TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0.0, end: 1.0),
                duration: const Duration(milliseconds: 600),
                curve: Curves.easeOutQuart,
                builder: (context, value, child) {
                  return Opacity(
                    opacity: value,
                    child: Transform.translate(
                      offset: Offset(0, 10 * (1 - value)),
                      child: child,
                    ),
                  );
                },
                child: Row(
                  children: [
                    Icon(
                      Icons.people_rounded, 
                      color: primaryColor,
                      size: 24
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Tournament Players',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade800,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              
              // Player slots with staggered animation
              ...List.generate(4, (index) {
                return AnimatedBuilder(
                  animation: TweenSequence<double>([
                    TweenSequenceItem(
                      tween: Tween<double>(begin: 0.0, end: 1.0)
                          .chain(CurveTween(curve: Curves.easeOutQuart)),
                      weight: 100,
                    ),
                  ]).animate(
                    CurvedAnimation(
                      parent: ModalRoute.of(context)!.animation!,
                      curve: Interval(
                        0.3 + (index * 0.1),
                        0.6 + (index * 0.1),
                        curve: Curves.easeOut,
                      ),
                    ),
                  ),
                  builder: (context, child) {
                    return Opacity(
                      opacity: ModalRoute.of(context)!.animation!.value,
                      child: Transform.translate(
                        offset: Offset(
                          0,
                          20 * (1 - ModalRoute.of(context)!.animation!.value),
                        ),
                        child: child,
                      ),
                    );
                  },
                  child: index < players.length
                      ? PlayerItemWidget(
                        player: players[index], 
                        primaryColor: primaryColor
                      )
                      : EmptyPlayerSlotWidget(),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}