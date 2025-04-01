import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vanishingtictactoe/features/tournament/models/tournament_model.dart';
import 'package:vanishingtictactoe/features/tournament/widgets/lobby/tournament_code_widget.dart';
import 'package:vanishingtictactoe/shared/providers/hell_mode_provider.dart';

class TournamentInfoWidget extends StatelessWidget{
  final Tournament tournament;
  final Color primaryColor;

  const TournamentInfoWidget ({
    super.key,
    required this.tournament,
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
            children: [
              // Trophy icon with animated glow
              TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0.8, end: 1.1),
                duration: const Duration(milliseconds: 2000),
                curve: Curves.easeInOut,
                builder: (context, value, child) {
                  return Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      color: primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(45),
                      boxShadow: [
                        BoxShadow(
                          color: primaryColor.withValues(alpha: 0.3 * value),
                          blurRadius: 20 * value,
                          spreadRadius: 2 * value,
                        ),
                      ],
                    ),
                    child: Icon(
                      isHellMode ? Icons.local_fire_department_rounded : Icons.emoji_events_rounded,
                      size: 54,
                      color: primaryColor,
                    ),
                  );
                },
              ),
              const SizedBox(height: 20),
              
              // Tournament title
              Text(
                'Tournament Lobby',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: primaryColor,
                  letterSpacing: 0.5,
                  shadows: [
                    Shadow(
                      color: primaryColor.withValues(alpha: 0.3),
                      offset: const Offset(0, 2),
                      blurRadius: 4,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              
              // Tournament code
              TournamentCodeWidget(
                code: tournament.code, 
                primaryColor: primaryColor,
              ),
              const SizedBox(height: 16),
              
              // Share instructions
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300, width: 1),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.share_rounded,
                      size: 18,
                      color: Colors.grey.shade700,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Share this code with your friends',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey.shade800,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              
              // Players count
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      primaryColor.withValues(alpha: 0.7),
                      primaryColor,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: primaryColor.withValues(alpha: 0.4),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.people_rounded,
                      size: 22,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      '${tournament.players.length}/4 players joined',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 0.5,
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