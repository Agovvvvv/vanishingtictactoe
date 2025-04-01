import 'package:flutter/material.dart';
import 'package:vanishingtictactoe/core/constants/app_colors.dart';
import 'package:vanishingtictactoe/features/tournament/models/tournament_match.dart';
import 'package:vanishingtictactoe/features/tournament/models/tournament_player.dart';

class MatchCardWidget extends StatelessWidget {
  final TournamentMatch? match;
  final TournamentPlayer player1;
  final TournamentPlayer player2;
  final String title;
  final VoidCallback? onTap;
  final bool isHellMode;

  const MatchCardWidget({
    Key? key,
    required this.match,
    required this.player1,
    required this.player2,
    required this.title,
    this.onTap,
    this.isHellMode = false,
  }) : super(key: key);

  // Factory constructor for placeholder cards
  factory MatchCardWidget.placeholder({
    Key? key,
    required String title,
    bool isHellMode = false,
  }) {
    return MatchCardWidget(
      match: null,
      player1: TournamentPlayer(id: '', name: 'TBD', seed: 0),
      player2: TournamentPlayer(id: '', name: 'TBD', seed: 0),
      title: title,
      isHellMode: isHellMode,
    );
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = AppColors.getPrimaryColor(isHellMode);
    final isCompleted = match?.status == 'completed';
    final isInProgress = match?.status == 'in_progress';
    final isWaiting = match?.status == 'waiting' || match == null;
    
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isCompleted 
              ? Colors.green.shade300 
              : isInProgress 
                  ? primaryColor 
                  : Colors.grey.shade300,
          width: 2,
        ),
      ),
      child: InkWell(
        onTap: isWaiting ? null : onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isHellMode
                  ? [Colors.white, Colors.red.shade50]
                  : [Colors.white, Colors.blue.shade50],
            ),
          ),
          child: Column(
            children: [
              // Match title
              Container(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                decoration: BoxDecoration(
                  color: primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: primaryColor,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              // Player 1
              _buildPlayerInfo(
                player1, 
                match?.player1Wins ?? 0, 
                match?.winnerId == player1.id,
                isHellMode,
              ),
              
              // VS divider
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Divider(
                        color: Colors.grey.shade300,
                        thickness: 1,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        'VS',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: primaryColor,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Divider(
                        color: Colors.grey.shade300,
                        thickness: 1,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Player 2
              _buildPlayerInfo(
                player2, 
                match?.player2Wins ?? 0, 
                match?.winnerId == player2.id,
                isHellMode,
              ),
              
              // Match status
              const SizedBox(height: 12),
              _buildMatchStatus(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlayerInfo(
    TournamentPlayer player, 
    int wins, 
    bool isWinner,
    bool isHellMode,
  ) {
    final primaryColor = isHellMode ? Colors.red.shade700 : AppColors.primaryBlue;
    
    return Row(
      children: [
        // Player avatar/initial
        CircleAvatar(
          backgroundColor: isWinner 
              ? Colors.amber.shade600 
              : primaryColor.withValues(alpha: 0.7),
          radius: 20,
          child: isWinner
              ? const Icon(Icons.emoji_events, color: Colors.white, size: 20)
              : Text(
                  player.name.isNotEmpty ? player.name[0].toUpperCase() : '?',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
        ),
        const SizedBox(width: 12),
        
        // Player name and seed
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                player.name,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: isWinner ? FontWeight.bold : FontWeight.normal,
                  color: isWinner ? Colors.amber.shade800 : Colors.black87,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (player.seed > 0)
                Text(
                  'Seed #${player.seed}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
            ],
          ),
        ),
        
        // Win count
        if (match != null && match!.status != 'waiting')
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: wins > 0 ? Colors.green.shade100 : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: wins > 0 ? Colors.green.shade300 : Colors.grey.shade300,
              ),
            ),
            child: Text(
              '$wins',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: wins > 0 ? Colors.green.shade700 : Colors.grey.shade700,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildMatchStatus(BuildContext context) {
    if (match == null) {
      return _buildStatusChip(
        'Waiting for players',
        Icons.hourglass_empty,
        Colors.grey.shade700,
      );
    }
    
    switch (match!.status) {
      case 'completed':
        return _buildStatusChip(
          'Match Complete',
          Icons.check_circle_outline,
          Colors.green.shade700,
        );
      case 'in_progress':
        return _buildStatusChip(
          'In Progress',
          Icons.sports_esports,
          isHellMode ? Colors.red.shade700 : AppColors.primaryBlue,
        );
      case 'waiting':
      default:
        return _buildStatusChip(
          'Waiting to Start',
          Icons.hourglass_empty,
          Colors.grey.shade700,
        );
    }
  }

  Widget _buildStatusChip(String label, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: color,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
