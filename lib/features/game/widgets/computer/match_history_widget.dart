import 'package:vanishingtictactoe/features/game/models/computer_player.dart';
import 'package:vanishingtictactoe/features/game/widgets/computer/stat_column_widget.dart';
import 'package:vanishingtictactoe/features/history/services/match_history_service.dart';
import 'package:vanishingtictactoe/shared/providers/user_provider.dart';
import 'package:vanishingtictactoe/shared/providers/hell_mode_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';


class MatchHistoryWidget extends StatelessWidget {
    final UserProvider userProvider;
    final GameDifficulty selectedDifficulty;
    
    const MatchHistoryWidget({
      super.key,
      required this.userProvider,
      required this.selectedDifficulty,
    });
    
    @override
    Widget build(BuildContext context) {
      final isHellModeActive = Provider.of<HellModeProvider>(context).isHellModeActive;
      final primaryColor = isHellModeActive ? Colors.red : Colors.blue;
      final MatchHistoryService matchHistory = MatchHistoryService();
      return Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: primaryColor.withValues( alpha: 0.3),
          width: 2.0,
        ),
        gradient: LinearGradient(
          colors: isHellModeActive 
              ? [Colors.white.withValues( alpha: 0.9), Colors.red.shade50.withValues( alpha: 0.7)]
              : [Colors.white.withValues( alpha: 0.9), Colors.blue.shade50.withValues( alpha: 0.7)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withValues( alpha: 0.15),
            blurRadius: 20,
            offset: const Offset(0, 10),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        child: StreamBuilder<Map<String, int>>(
          stream: matchHistory.getMatchStats(
            userId: userProvider.user!.id,
            difficulty: selectedDifficulty,
            isHellMode: isHellModeActive,
          ),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return Center(
                child: SizedBox(
                  height: 40,
                  width: 40,
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      isHellModeActive ? Colors.red.shade600 : Colors.blue.shade600
                    ),
                    strokeWidth: 3,
                  ),
                ),
              );
            }
            
            if (snapshot.hasError) {
              return Container(
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, color: Colors.red.shade700),
                    const SizedBox(width: 8),
                    Text(
                      'Error loading match history',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.red.shade800,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
            }
            
            final stats = snapshot.data!;
            final wins = stats['win'] ?? 0;
            final losses = stats['loss'] ?? 0;
            final draws = stats['draw'] ?? 0;
            final total = wins + losses + draws;
            
            if (total == 0) {
              return Container(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Column(
                  children: [
                    Icon(
                      isHellModeActive ? Icons.local_fire_department_rounded : Icons.emoji_events_outlined,
                      color: isHellModeActive ? Colors.red.shade300 : Colors.blue.shade300,
                      size: 48,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      isHellModeActive 
                          ? 'No hell mode matches played yet'
                          : 'No matches played yet',
                      style: TextStyle(
                        fontSize: 16,
                        height: 1.5,
                        color: isHellModeActive ? Colors.red.shade800 : Colors.blue.shade800,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Play a game to see your stats!',
                      style: TextStyle(
                        fontSize: 14,
                        color: isHellModeActive ? Colors.red.shade600 : Colors.blue.shade600,
                        fontWeight: FontWeight.w400,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
            }
            
            return Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    StatColumn(
                      label: 'Wins',
                      value: wins,
                      color: isHellModeActive ? Colors.deepOrange : Colors.green,
                    ),
                    StatColumn(
                      label: 'Losses',
                      value: losses,
                      color: isHellModeActive ? Colors.purple : Colors.red,
                    ),
                    StatColumn(
                      label: 'Draws',
                      value: draws,
                      color: isHellModeActive ? Colors.amber.shade900 : Colors.orange,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                  decoration: BoxDecoration(
                    color: (isHellModeActive ? Colors.red : Colors.blue).withValues( alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: (isHellModeActive ? Colors.red : Colors.blue).withValues( alpha: 0.2),
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.bar_chart_rounded,
                        size: 18,
                        color: isHellModeActive ? Colors.red.shade700 : Colors.blue.shade700,
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          'Total: $total games',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: isHellModeActive ? Colors.red.shade900 : Colors.blue.shade900,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                          decoration: BoxDecoration(
                            color: (isHellModeActive ? Colors.red : Colors.blue).withValues( alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${(wins * 100 / total).toStringAsFixed(1)}% win rate',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: isHellModeActive ? Colors.red.shade700 : Colors.blue.shade700,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}