import 'package:flutter/material.dart';
import 'package:vanishingtictactoe/core/constants/app_colors.dart';
import 'package:vanishingtictactoe/features/tournament/models/tournament_match.dart';
import 'package:vanishingtictactoe/features/tournament/models/tournament_player.dart';
import 'package:vanishingtictactoe/features/tournament/widgets/bracket/match_card_widget.dart';

class TournamentBracketWidget extends StatelessWidget {
  final List<TournamentMatch> matches;
  final List<TournamentPlayer> players;
  final Function(TournamentMatch) onMatchTap;
  final bool isHellMode;

  const TournamentBracketWidget({
    Key? key,
    required this.matches,
    required this.players,
    required this.onMatchTap,
    this.isHellMode = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Filter matches by round
    final semifinalMatches = matches.where((match) => match.round == 1).toList();
    final finalMatch = matches.firstWhere(
      (match) => match.round == 2,
      orElse: () => TournamentMatch(
        id: 'placeholder',
        tournamentId: '',
        player1Id: '',
        player2Id: '',
        status: 'waiting',
        round: 2,
        matchNumber: 1,
        gameIds: [],
      ),
    );

    // Get screen dimensions for responsive layout
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isLandscape = screenWidth > screenHeight;
    
    return LayoutBuilder(
      builder: (context, constraints) {
        // Adjust layout based on orientation and screen size
        if (isLandscape) {
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: _buildLandscapeBracket(context, semifinalMatches, finalMatch),
          );
        } else {
          return SingleChildScrollView(
            child: _buildPortraitBracket(context, semifinalMatches, finalMatch),
          );
        }
      },
    );
  }

  Widget _buildPortraitBracket(
    BuildContext context, 
    List<TournamentMatch> semifinalMatches, 
    TournamentMatch finalMatch
  ) {
    return Column(
      children: [
        // Semifinals row
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            children: [
              Expanded(
                child: _buildMatchCard(context, semifinalMatches.isNotEmpty ? semifinalMatches[0] : null, 'Semifinal 1'),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildMatchCard(context, semifinalMatches.length > 1 ? semifinalMatches[1] : null, 'Semifinal 2'),
              ),
            ],
          ),
        ),
        
        // Connecting lines
        SizedBox(
          height: 60,
          child: CustomPaint(
            size: Size.infinite,
            painter: BracketLinesPainter(isHellMode: isHellMode),
          ),
        ),
        
        // Final match
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 80.0),
          child: _buildMatchCard(context, finalMatch, 'Final'),
        ),
        
        // Trophy icon for winner
        if (finalMatch.winnerId != null && finalMatch.winnerId!.isNotEmpty)
          _buildWinnerSection(finalMatch.winnerId!),
      ],
    );
  }

  Widget _buildLandscapeBracket(
    BuildContext context, 
    List<TournamentMatch> semifinalMatches, 
    TournamentMatch finalMatch
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Left semifinal
        Expanded(
          flex: 3,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: _buildMatchCard(context, semifinalMatches.isNotEmpty ? semifinalMatches[0] : null, 'Semifinal 1'),
          ),
        ),
        
        // Final and connecting lines
        Expanded(
          flex: 4,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Connecting lines
              Expanded(
                child: CustomPaint(
                  size: Size.infinite,
                  painter: BracketLinesHorizontalPainter(isHellMode: isHellMode),
                ),
              ),
              
              // Final match
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: _buildMatchCard(context, finalMatch, 'Final'),
              ),
              
              // Trophy icon for winner
              if (finalMatch.winnerId != null && finalMatch.winnerId!.isNotEmpty)
                _buildWinnerSection(finalMatch.winnerId!),
                
              const Spacer(),
            ],
          ),
        ),
        
        // Right semifinal
        Expanded(
          flex: 3,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: _buildMatchCard(context, semifinalMatches.length > 1 ? semifinalMatches[1] : null, 'Semifinal 2'),
          ),
        ),
      ],
    );
  }

  Widget _buildMatchCard(BuildContext context, TournamentMatch? match, String title) {
    if (match == null || match.id == 'placeholder') {
      // Return an empty placeholder card
      return MatchCardWidget.placeholder(
        title: title,
        isHellMode: isHellMode,
      );
    }
    
    // Find players for this match
    final player1 = players.firstWhere(
      (p) => p.id == match.player1Id,
      orElse: () => TournamentPlayer(id: '', name: 'TBD', seed: 0),
    );
    
    final player2 = players.firstWhere(
      (p) => p.id == match.player2Id,
      orElse: () => TournamentPlayer(id: '', name: 'TBD', seed: 0),
    );
    
    return MatchCardWidget(
      match: match,
      player1: player1,
      player2: player2,
      title: title,
      onTap: () => onMatchTap(match),
      isHellMode: isHellMode,
    );
  }

  Widget _buildWinnerSection(String winnerId) {
    final winner = players.firstWhere(
      (p) => p.id == winnerId,
      orElse: () => TournamentPlayer(id: '', name: 'Unknown', seed: 0),
    );
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24.0),
      child: Column(
        children: [
          Icon(
            Icons.emoji_events_rounded,
            size: 48,
            color: isHellMode ? Colors.red.shade700 : Colors.amber.shade700,
          ),
          const SizedBox(height: 8),
          Text(
            'WINNER',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isHellMode ? Colors.red.shade700 : AppColors.primaryBlue,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            winner.name,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class BracketLinesPainter extends CustomPainter {
  final bool isHellMode;
  
  BracketLinesPainter({this.isHellMode = false});
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = isHellMode ? Colors.red.shade700 : AppColors.primaryBlue
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    
    final double width = size.width;
    final double height = size.height;
    
    // Draw lines from semifinals to final
    final path = Path();
    
    // Left semifinal to center
    path.moveTo(width * 0.25, 0);
    path.lineTo(width * 0.25, height * 0.6);
    path.lineTo(width * 0.5, height * 0.6);
    
    // Right semifinal to center
    path.moveTo(width * 0.75, 0);
    path.lineTo(width * 0.75, height * 0.6);
    path.lineTo(width * 0.5, height * 0.6);
    
    // Connect to final match
    path.moveTo(width * 0.5, height * 0.6);
    path.lineTo(width * 0.5, height);
    
    canvas.drawPath(path, paint);
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class BracketLinesHorizontalPainter extends CustomPainter {
  final bool isHellMode;
  
  BracketLinesHorizontalPainter({this.isHellMode = false});
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = isHellMode ? Colors.red.shade700 : AppColors.primaryBlue
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    
    final double width = size.width;
    final double height = size.height;
    
    // Draw lines from semifinals to final
    final path = Path();
    
    // Left semifinal to center
    path.moveTo(0, height * 0.5);
    path.lineTo(width * 0.4, height * 0.5);
    
    // Right semifinal to center
    path.moveTo(width, height * 0.5);
    path.lineTo(width * 0.6, height * 0.5);
    
    canvas.drawPath(path, paint);
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
