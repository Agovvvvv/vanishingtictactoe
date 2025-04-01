import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vanishingtictactoe/core/constants/app_colors.dart';
import 'package:vanishingtictactoe/features/tournament/providers/tournament_provider.dart';
import 'package:vanishingtictactoe/features/tournament/screens/tournament_bracket_screen.dart';
import 'package:vanishingtictactoe/features/tournament/screens/tournament_lobby_screen.dart';
import 'package:vanishingtictactoe/features/tournament/services/tournament_service.dart';
import 'package:vanishingtictactoe/shared/providers/hell_mode_provider.dart';
import 'package:vanishingtictactoe/shared/widgets/app_button.dart';

/// A widget that displays active tournaments for the user
class ActiveTournamentsWidget extends StatelessWidget {
  final List<Map<String, dynamic>> tournaments;
  final VoidCallback onRefresh;
  final TournamentService _tournamentService = TournamentService();

  ActiveTournamentsWidget({
    super.key,
    required this.tournaments,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final hellModeProvider = Provider.of<HellModeProvider>(context);
    final isHellMode = hellModeProvider.isHellModeActive;
    final primaryColor = AppColors.getPrimaryColor(isHellMode);
    
    // Filter active tournaments (waiting or in_progress)
    final activeTournaments = tournaments
        .where((t) => t['status'] == 'waiting' || t['status'] == 'in_progress')
        .toList();
    
    if (activeTournaments.isEmpty) {
      return const SizedBox.shrink();
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            'Active Tournaments',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: primaryColor,
            ),
          ),
        ),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: activeTournaments.length,
          itemBuilder: (context, index) {
            final tournament = activeTournaments[index];
            return _buildTournamentCard(context, tournament);
          },
        ),
      ],
    );
  }

  Widget _buildTournamentCard(BuildContext context, Map<String, dynamic> tournament) {
    final hellModeProvider = Provider.of<HellModeProvider>(context);
    final isHellMode = hellModeProvider.isHellModeActive;
    final primaryColor = AppColors.getPrimaryColor(isHellMode);
    
    final tournamentId = tournament['id'] as String;
    final status = tournament['status'] as String;
    final code = tournament['code'] as String;
    final players = tournament['players'] as List<dynamic>;
    final isCreator = tournament['creator_id'] == Provider.of<TournamentProvider>(context, listen: false).getCurrentUserId();
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: primaryColor.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        status == 'waiting' ? 'Waiting for Players' : 'Tournament in Progress',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: status == 'waiting' 
                              ? Colors.orange.shade700 
                              : Colors.green.shade700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Code: $code',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
                _buildStatusBadge(context, status),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Players (${players.length}/4):',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: List.generate(
                players.length,
                (index) => Chip(
                  backgroundColor: primaryColor.withValues(alpha: 0.1),
                  label: Text(
                    players[index]['name'] as String,
                    style: TextStyle(
                      color: primaryColor,
                    ),
                  ),
                  avatar: CircleAvatar(
                    backgroundColor: primaryColor,
                    child: Text(
                      '${players[index]['seed']}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Adjust layout based on whether creator and waiting status
            if (isCreator && status == 'waiting') ...[  
              // Three button layout with flexible sizing
              Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: AppButton(
                          text: 'Enter',
                          icon: Icons.login,
                          onPressed: () => _navigateToTournament(context, tournamentId, status),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: AppButton(
                          text: 'Leave',
                          icon: Icons.exit_to_app,
                          customColor: Colors.red.shade700,
                          onPressed: () => _leaveTournament(context, tournamentId),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  AppButton(
                    text: players.length == 4 ? 'Start Tournament' : 'Need ${4 - players.length} more players',
                    icon: Icons.play_arrow,
                    customColor: players.length == 4 ? Colors.green.shade700 : Colors.grey,
                    onPressed: players.length == 4 
                        ? () => _startTournament(context, tournamentId) 
                        : null,
                    isFullWidth: true,
                  ),
                ],
              )
            ] else ...[  
              // Two button layout
              Row(
                children: [
                  Expanded(
                    child: AppButton(
                      text: 'Enter',
                      icon: Icons.login,
                      onPressed: () => _navigateToTournament(context, tournamentId, status),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: AppButton(
                      text: 'Leave',
                      icon: Icons.exit_to_app,
                      customColor: Colors.red.shade700,
                      onPressed: () => _leaveTournament(context, tournamentId),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(BuildContext context, String status) {
    Color color;
    String text;
    IconData icon;
    
    switch (status) {
      case 'waiting':
        color = Colors.orange.shade700;
        text = 'Waiting';
        icon = Icons.hourglass_empty;
        break;
      case 'in_progress':
        color = Colors.green.shade700;
        text = 'Active';
        icon = Icons.sports_esports;
        break;
      default:
        color = Colors.grey.shade700;
        text = 'Unknown';
        icon = Icons.question_mark;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToTournament(BuildContext context, String tournamentId, String status) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => status == 'waiting'
            ? TournamentLobbyScreen(tournamentId: tournamentId)
            : TournamentBracketScreen(tournamentId: tournamentId),
      ),
    );
  }

  void _leaveTournament(BuildContext context, String tournamentId) async {
    try {
      // Call the service directly to leave the tournament
      await _tournamentService.leaveTournament(tournamentId);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Successfully left the tournament')),
        );
        // Refresh the tournament list
        onRefresh();
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error leaving tournament: ${e.toString()}')),
        );
      }
    }
  }

  void _startTournament(BuildContext context, String tournamentId) async {
    try {
      // Call the service directly to start the tournament
      await _tournamentService.startTournament(tournamentId);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tournament started successfully')),
        );
        
        // Navigate to bracket screen
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => TournamentBracketScreen(tournamentId: tournamentId),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error starting tournament: ${e.toString()}')),
        );
      }
    }
  }
}
