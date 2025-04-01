import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vanishingtictactoe/core/constants/app_colors.dart';
import 'package:vanishingtictactoe/core/utils/app_logger.dart';
import 'package:vanishingtictactoe/features/tournament/models/tournament_match.dart';
import 'package:vanishingtictactoe/features/tournament/providers/tournament_provider.dart';
import 'package:vanishingtictactoe/features/tournament/widgets/bracket/tournament_bracket_widget.dart';
import 'package:vanishingtictactoe/shared/providers/hell_mode_provider.dart';
import 'package:vanishingtictactoe/shared/widgets/app_button.dart';
import 'package:vanishingtictactoe/shared/widgets/app_scaffold.dart';
import 'package:vanishingtictactoe/shared/widgets/loading_indicator.dart';

class TournamentBracketScreen extends StatefulWidget {
  static const routeName = '/tournament-bracket';
  final String tournamentId;

  const TournamentBracketScreen({
    Key? key,
    required this.tournamentId,
  }) : super(key: key);

  @override
  State<TournamentBracketScreen> createState() => _TournamentBracketScreenState();
}

class _TournamentBracketScreenState extends State<TournamentBracketScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadTournament();
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadTournament() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final provider = context.read<TournamentProvider>();
      await provider.loadTournament(widget.tournamentId);
      
      if (!mounted) return;
      
      setState(() {
        _isLoading = false;
      });
      
      // Set up a refresh timer for in-progress tournaments
      if (provider.tournament?.status == 'in_progress') {
        _refreshTimer = Timer.periodic(const Duration(seconds: 10), (_) {
          if (mounted) {
            provider.loadTournament(widget.tournamentId);
          }
        });
      }
    } catch (e) {
      AppLogger.error('Error loading tournament: $e');
      if (!mounted) return;
      
      setState(() {
        _errorMessage = 'Failed to load tournament: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  void _handleMatchTap(TournamentMatch match) {
    // This will be implemented later to navigate to match details or game screen
    AppLogger.info('Match tapped: ${match.id}');
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Match details will be implemented in the future'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // Track if we've already navigated to avoid duplicate navigation
  bool _hasNavigated = false;
  
  @override
  Widget build(BuildContext context) {
    final hellModeProvider = Provider.of<HellModeProvider>(context);
    final isHellMode = hellModeProvider.isHellModeActive;
    final primaryColor = AppColors.getPrimaryColor(isHellMode);
    
    return Consumer<TournamentProvider>(
      builder: (context, provider, _) {
        // Check if there's a game ready to play
        if (provider.hasReadyGame && !_hasNavigated) {
          _hasNavigated = true; // Prevent multiple navigations
          
          // Navigate to the game screen
          WidgetsBinding.instance.addPostFrameCallback((_) {
            AppLogger.info('Navigating to ready game: ${provider.readyGameId}');
            
            // Use pushReplacement to replace the current screen
            Navigator.of(context).pushReplacementNamed(
              '/tournament/match', // Using string route name for consistency
              arguments: {
                'tournamentId': provider.readyTournamentId,
                'matchId': provider.readyMatchId,
                'gameId': provider.readyGameId,
              },
            );
          });
        }
        
        return AppScaffold(
          title: 'Tournament Bracket',
          body: _isLoading
              ? const Center(child: LoadingIndicator())
              : _errorMessage != null
                  ? _buildErrorView(primaryColor)
                  : _buildBracketView(context, isHellMode, primaryColor),
        );
      },
    );
  }

  Widget _buildErrorView(Color primaryColor) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(24),
        margin: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.red.shade200),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, color: Colors.red.shade700, size: 48),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.red.shade700, fontSize: 16),
            ),
            const SizedBox(height: 24),
            AppButton(
              text: 'Try Again',
              icon: Icons.refresh,
              onPressed: _loadTournament,
              customColor: Colors.red.shade700,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBracketView(BuildContext context, bool isHellMode, Color primaryColor) {
    return Consumer<TournamentProvider>(
      builder: (context, provider, child) {
        final tournament = provider.tournament;
        
        if (tournament == null) {
          return Center(
            child: Text(
              'Tournament not found',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey.shade700,
              ),
            ),
          );
        }
        
        return Column(
          children: [
            // Tournament header
            _buildTournamentHeader(tournament.status, isHellMode, primaryColor),
            
            // Bracket
            Expanded(
              child: TournamentBracketWidget(
                matches: tournament.matches,
                players: tournament.players,
                onMatchTap: _handleMatchTap,
                isHellMode: isHellMode,
              ),
            ),
            
            // Tournament info footer
            _buildTournamentFooter(tournament, isHellMode, primaryColor),
          ],
        );
      },
    );
  }

  Widget _buildTournamentHeader(String status, bool isHellMode, Color primaryColor) {
    String statusText;
    IconData statusIcon;
    Color statusColor;
    
    switch (status) {
      case 'waiting':
        statusText = 'Waiting to Start';
        statusIcon = Icons.hourglass_empty;
        statusColor = Colors.orange;
        break;
      case 'in_progress':
        statusText = 'Tournament in Progress';
        statusIcon = Icons.sports_esports;
        statusColor = primaryColor;
        break;
      case 'completed':
        statusText = 'Tournament Complete';
        statusIcon = Icons.emoji_events;
        statusColor = Colors.green;
        break;
      default:
        statusText = 'Unknown Status';
        statusIcon = Icons.help_outline;
        statusColor = Colors.grey;
    }
    
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            statusColor.withValues(alpha: 0.7),
            statusColor,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: statusColor.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              statusIcon,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  statusText,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isHellMode 
                      ? 'Hell Mode Tournament Bracket' 
                      : 'Tournament Bracket',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
              ],
            ),
          ),
          if (status == 'in_progress')
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.refresh,
                    color: Colors.white,
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Live',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // Handle play match button press
  Future<void> _handlePlayMatch(TournamentMatch match) async {
    setState(() => _isLoading = true);
    
    try {
      final provider = context.read<TournamentProvider>();
      final userId = provider.getCurrentUserId();
      
      // Only mark the current user as ready
      if (userId != null) {
        final isPlayer1 = match.player1Id == userId;
        final isPlayer2 = match.player2Id == userId;
        
        // Only proceed if the user is a participant in this match
        if (isPlayer1 || isPlayer2) {
          // Check if the current user is already ready
          final isCurrentUserReady = isPlayer1 ? match.player1Ready : match.player2Ready;
          
          if (!isCurrentUserReady) {
            AppLogger.info('Marking player $userId ready for match: ${match.id}');
            await provider.markPlayerReady(match.tournamentId, match.id);
            
            // Show a message to the user
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Waiting for other player to be ready...')),
            );
          } else {
            AppLogger.info('Player $userId is already ready for match: ${match.id}');
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('You are already ready for this match')),
            );
          }
        } else {
          AppLogger.warning('User $userId attempted to join match ${match.id} but is not a participant');
          throw Exception('You are not a participant in this match');
        }
      }
      
      // The provider will handle checking if both players are ready and setting up the game
      // The build method will handle navigation when the game is ready via the Consumer
      
    } catch (e) {
      AppLogger.error('Error marking player ready: $e');
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to join match: ${e.toString()}'),
          backgroundColor: Colors.red.shade700,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
  
  
  
  Widget _buildTournamentFooter(tournament, bool isHellMode, Color primaryColor) {
    // Use Consumer to ensure UI updates when tournament data changes
    return Consumer<TournamentProvider>(
      builder: (context, provider, _) {
        final userId = provider.getCurrentUserId();
        final currentUserMatch = provider.getCurrentUserMatch();
        final isUserInActiveTournament = currentUserMatch != null && 
                                       currentUserMatch.id.isNotEmpty &&
                                       tournament.status == 'in_progress';
        
        // Check if user is a participant in the match
        bool isUserParticipant = false;
        if (currentUserMatch != null && userId != null) {
          isUserParticipant = currentUserMatch.player1Id == userId || currentUserMatch.player2Id == userId;
        }
        
        // Determine if current user is ready and if opponent is ready
        bool isUserReady = false;
        bool isOpponentReady = false;
        String? opponentId;
        
        if (currentUserMatch != null && userId != null) {
          // Check if user is player1 or player2 in this match
          final isPlayer1 = currentUserMatch.player1Id == userId;
          final isPlayer2 = currentUserMatch.player2Id == userId;
          
          if (isPlayer1) {
            // Current user is player1, so opponent is player2
            isUserReady = currentUserMatch.player1Ready;
            isOpponentReady = currentUserMatch.player2Ready;
            opponentId = currentUserMatch.player2Id;
          } else if (isPlayer2) {
            // Current user is player2, so opponent is player1
            isUserReady = currentUserMatch.player2Ready;
            isOpponentReady = currentUserMatch.player1Ready;
            opponentId = currentUserMatch.player1Id;
          }
          
          // Log for debugging
          AppLogger.info('Match ${currentUserMatch.id}: User $userId ready: $isUserReady, Opponent $opponentId ready: $isOpponentReady');
        }
        
        // Determine button text and state based on user and opponent readiness
        String buttonText = 'Play Match';
        bool buttonEnabled = true;
        IconData buttonIcon = Icons.sports_esports;
        
        if (isUserReady && isOpponentReady) {
          buttonText = 'Starting Match...';
          buttonEnabled = false;
          buttonIcon = Icons.hourglass_empty;
        } else if (isUserReady && !isOpponentReady) {
          buttonText = 'Waiting for Opponent';
          buttonEnabled = false;
          buttonIcon = Icons.hourglass_empty;
        } else if (!isUserReady && isOpponentReady) {
          buttonText = 'Opponent is Ready - Join Now';
          buttonEnabled = true;
          buttonIcon = Icons.sports_esports;
        } else {
          buttonText = 'Play Match';
          buttonEnabled = true;
          buttonIcon = Icons.sports_esports;
        }
    
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Play button - only show if user is in an active match and not eliminated
              if (isUserInActiveTournament && isUserParticipant)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: SizedBox(
                    width: double.infinity, // Make button full width
                    height: 56, // Make button taller
                    child: AppButton(
                      text: buttonText,
                      icon: buttonIcon,
                      onPressed: buttonEnabled ? () => _handlePlayMatch(currentUserMatch) : null,
                      customColor: isHellMode ? AppColors.hellRed : primaryColor,
                      isLoading: provider.isLoading,
                      isFullWidth: true, // Use the built-in full width property
                    ),
                  ),
                ),
              // Show match status for spectators
              if (isUserInActiveTournament && !isUserParticipant)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.visibility, color: Colors.grey.shade700),
                        const SizedBox(width: 8),
                        Text(
                          'Spectating Match',
                          style: TextStyle(color: Colors.grey.shade700, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
  
}