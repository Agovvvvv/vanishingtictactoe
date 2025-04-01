import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vanishingtictactoe/core/constants/app_colors.dart';
import 'package:vanishingtictactoe/features/tournament/providers/tournament_provider.dart';
import 'package:vanishingtictactoe/shared/providers/hell_mode_provider.dart';
import 'package:vanishingtictactoe/shared/widgets/app_button.dart';

class ActionButtonsWidget extends StatelessWidget {
    final TournamentProvider provider;
    final bool isStartingTournament;
    final bool isLeavingTournament;
    final VoidCallback onStartTournament;
    final VoidCallback onLeaveTournament;
    
    const ActionButtonsWidget({
      super.key,
      required this.provider,
      required this.isStartingTournament,
      required this.isLeavingTournament,
      required this.onStartTournament,
      required this.onLeaveTournament,
    });
    
    @override
    Widget build(BuildContext context) {
        final isCreator = provider.isCreator;
        final isFull = provider.isTournamentFull;
        final hellModeProvider = Provider.of<HellModeProvider>(context, listen: false);
        final isHellMode = hellModeProvider.isHellModeActive;
        final primaryColor = AppColors.getPrimaryColor(isHellMode);
    
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
              // Title for action section
              Row(
                children: [
                  Icon(
                    isHellMode ? Icons.local_fire_department_rounded : Icons.emoji_events_rounded,
                    color: primaryColor,
                    size: 24,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Tournament Actions',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade800,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              
              // Creator-only actions
              if (isCreator) ...[          
                // Start tournament button
                TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 0.95, end: 1.0),
                  duration: const Duration(milliseconds: 1000),
                  curve: Curves.elasticOut,
                  builder: (context, value, child) {
                    return Transform.scale(
                      scale: value,
                      child: AppButton(
                        text: isHellMode ? 'START HELL TOURNAMENT' : 'START TOURNAMENT',
                        icon: isHellMode ? Icons.local_fire_department_rounded : Icons.play_arrow_rounded,
                        onPressed: (isFull && !isStartingTournament) ? onStartTournament : null,
                        isLoading: isStartingTournament,
                        customColor: isHellMode ? Colors.red.shade700 : primaryColor,
                        isFullWidth: true,
                      ),
                    );
                  },
                ),
                const SizedBox(height: 20),
                
                // Warning message if not enough players
                if (!isFull)
                  TweenAnimationBuilder<double>(
                    tween: Tween<double>(begin: 0.0, end: 1.0),
                    duration: const Duration(milliseconds: 800),
                    curve: Curves.easeOutQuart,
                    builder: (context, value, child) {
                      return Opacity(
                        opacity: value,
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                          decoration: BoxDecoration(
                            color: Colors.orange.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.orange.withValues(alpha: 0.1),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.orange.withValues(alpha: 0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.people_alt_rounded,
                                  size: 20,
                                  color: Colors.orange.shade800,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Need 4 players to start',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.orange.shade800,
                                        fontSize: 15,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Share the tournament code to invite more players',
                                      style: TextStyle(
                                        color: Colors.orange.shade700,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
              
              ],
              
              // Leave tournament button
              TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0.95, end: 1.0),
                duration: const Duration(milliseconds: 800),
                curve: Curves.easeOutQuart,
                builder: (context, value, child) {
                  return Transform.scale(
                    scale: value,
                    child: AppButton(
                      text: 'LEAVE TOURNAMENT',
                      icon: Icons.exit_to_app_rounded,
                      onPressed: isLeavingTournament ? null : onLeaveTournament,
                      isLoading: isLeavingTournament,
                      customColor: isHellMode ? Colors.red.shade900 : Colors.red.shade700,
                      isFullWidth: true,
                      isOutlined: true,
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}