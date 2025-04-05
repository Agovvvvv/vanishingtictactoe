import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vanishingtictactoe/core/constants/app_colors.dart';
import 'package:vanishingtictactoe/core/utils/app_logger.dart';
import 'package:vanishingtictactoe/features/tournament/models/tournament_game.dart';
import 'package:vanishingtictactoe/features/tournament/models/tournament_match.dart';
import 'package:vanishingtictactoe/features/tournament/providers/tournament_provider.dart';
import 'package:vanishingtictactoe/features/tournament/services/tournament_service.dart';
import 'package:vanishingtictactoe/shared/providers/hell_mode_provider.dart';
import 'package:vanishingtictactoe/shared/widgets/app_scaffold.dart';
import 'package:vanishingtictactoe/features/game/widgets/match/grid_cell.dart';
import 'package:vanishingtictactoe/shared/widgets/loading_indicator.dart';

/// Screen for playing a tournament match
class TournamentMatchScreen extends StatefulWidget {
  static const routeName = '/tournament/match';
  final String tournamentId;
  final String matchId;
  final String gameId;

  const TournamentMatchScreen({
    Key? key,
    required this.tournamentId,
    required this.matchId,
    required this.gameId,
  }) : super(key: key);

  @override
  State<TournamentMatchScreen> createState() => _TournamentMatchScreenState();
}

class _TournamentMatchScreenState extends State<TournamentMatchScreen> {
  final TournamentService _tournamentService = TournamentService();
  bool _isLoading = true;
  String? _errorMessage;
  bool _isGameOver = false;
  bool _isLocalPlayerTurn = false;
  int? _lastVanishedPosition;
  
  // Animation controllers
  Timer? _vanishTimer;
  Timer? _winnerTimer;
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadGame();
    });
  }
  
  @override
  void dispose() {
    _vanishTimer?.cancel();
    _winnerTimer?.cancel();
    super.dispose();
  }
  
  Future<void> _loadGame() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      final provider = context.read<TournamentProvider>();
      await provider.loadGame(widget.gameId);
      
      if (!mounted) return;
      
      setState(() {
        _isLoading = false;
        _updateGameState(provider);
      });
    } catch (e) {
      AppLogger.error('Error loading game: $e');
      if (!mounted) return;
      
      setState(() {
        _errorMessage = 'Failed to load game: ${e.toString()}';
        _isLoading = false;
      });
    }
  }
  
  void _updateGameState(TournamentProvider provider) {
    final game = provider.currentGame;
    final match = provider.currentMatch;
    
    if (game == null || match == null) return;
    
    final userId = provider.getCurrentUserId();
    if (userId == null) return;
    
    // Determine if the current user is player1 (X) or player2 (O)
    final isPlayer1 = game.player1Id == userId;
    final isPlayer2 = game.player2Id == userId;
    
    // Only proceed if the user is a participant in this game
    if (!isPlayer1 && !isPlayer2) {
      AppLogger.warning('User $userId is not a participant in game ${game.id}');
      return;
    }
    
    // Determine the local player's symbol
    final localPlayerSymbol = isPlayer1 ? 'X' : 'O';
    
    // Update local state
    setState(() {
      _isLocalPlayerTurn = game.currentTurn == localPlayerSymbol;
      _isGameOver = game.status == 'completed';
      
      // Log the current state for debugging
      AppLogger.info('Game ${game.id} state updated: '
          'Player: $userId, '
          'Symbol: $localPlayerSymbol, '
          'Is turn: $_isLocalPlayerTurn, '
          'Game over: $_isGameOver');
    });
  }
  
  Future<void> _makeMove(int position) async {
    // Validate move conditions
    if (_isLoading || _isGameOver || !_isLocalPlayerTurn) {
      AppLogger.warning('Invalid move attempt: '
          'Loading: $_isLoading, '
          'Game over: $_isGameOver, '
          'Is player turn: $_isLocalPlayerTurn');
      return;
    }
    
    setState(() => _isLoading = true);
    
    try {
      // Get current provider and game state
      final provider = context.read<TournamentProvider>();
      final game = provider.currentGame;
      final match = provider.currentMatch;
      
      if (game == null || match == null) {
        throw Exception('Game or match not found');
      }
      
      // Make the move through the service
      final result = await _tournamentService.makeMove(widget.gameId, position);
      
      if (!mounted) return;
      
      // Handle vanishing effect with animation
      if (result['vanishedPosition'] != null) {
        _lastVanishedPosition = result['vanishedPosition'];
        _vanishTimer = Timer(const Duration(milliseconds: 300), () {
          if (mounted) {
            setState(() => _lastVanishedPosition = null);
          }
        });
      }
      
      // Handle game completion
      if (result['gameCompleted']) {
        setState(() {
          _isGameOver = true;
        });
        
        // Show game result dialog
        final userId = provider.getCurrentUserId();
        final isWinner = result['winner'] == userId;
        final isDraw = result['isDraw'] == true;
        
        if (mounted) {
          _showGameCompletionDialog(isWinner, isDraw);
        }
        
        // Handle match completion after a delay
        if (result['matchCompleted']) {
          _winnerTimer = Timer(const Duration(seconds: 3), () {
            if (mounted) {
              // Navigate back to tournament bracket
              Navigator.pop(context);
            }
          });
        } else {
          // If match is not completed, wait for the next game to be created
          _winnerTimer = Timer(const Duration(seconds: 3), () {
            if (mounted) {
              // Check if a new game has been created for this match
              final updatedMatch = provider.getMatchById(match.id);
              if (updatedMatch != null && updatedMatch.gameIds.isNotEmpty) {
                final latestGameId = updatedMatch.gameIds.last;
                if (latestGameId != widget.gameId) {
                  // Navigate to the new game
                  Navigator.pushReplacementNamed(
                    context,
                    '/tournament/match',
                    arguments: {
                      'tournamentId': widget.tournamentId,
                      'matchId': widget.matchId,
                      'gameId': latestGameId,
                    },
                  );
                }
              }
            }
          });
        }
      }
      
      // Refresh game state
      setState(() {
        _isLoading = false;
        _updateGameState(provider);
      });
    } catch (e) {
      AppLogger.error('Error making move: $e');
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to make move: ${e.toString()}'),
          backgroundColor: Colors.red.shade700,
        ),
      );
      
      setState(() => _isLoading = false);
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final hellModeProvider = Provider.of<HellModeProvider>(context);
    final isHellMode = hellModeProvider.isHellModeActive;
    final primaryColor = AppColors.getPrimaryColor(isHellMode);
    
    return AppScaffold(
      title: 'Tournament Match',
      body: _isLoading && context.read<TournamentProvider>().currentGame == null
          ? const Center(child: LoadingIndicator())
          : _errorMessage != null
              ? _buildErrorView(primaryColor)
              : _buildGameView(context, isHellMode, primaryColor),
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
            ElevatedButton.icon(
              onPressed: _loadGame,
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade700,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildGameView(BuildContext context, bool isHellMode, Color primaryColor) {
    return Consumer<TournamentProvider>(builder: (context, provider, child) {
      final game = provider.currentGame;
      final match = provider.currentMatch;
      
      if (game == null || match == null) {
        return const Center(child: Text('Game not found'));
      }
      
      final userId = provider.getCurrentUserId();
      if (userId == null) {
        return const Center(child: Text('User not found'));
      }
      
      final isPlayer1 = game.player1Id == userId;
      
      if (!isPlayer1 && game.player2Id != userId) {
        return const Center(child: Text('You are not a participant in this game'));
      }
      
      final localPlayerSymbol = isPlayer1 ? 'X' : 'O';
      
      final player1 = provider.getPlayerById(game.player1Id);
      final player2 = provider.getPlayerById(game.player2Id);
      
      final localPlayerName = isPlayer1 ? player1?.name ?? 'Player 1' : player2?.name ?? 'Player 2';
      final opponentName = isPlayer1 ? player2?.name ?? 'Player 2' : player1?.name ?? 'Player 1';
      
      return Column(
        children: [
          // Game status
          _buildGameStatus(game, localPlayerSymbol, localPlayerName, opponentName, isHellMode, primaryColor),
          
          // Game board
          Expanded(
            child: Center(
              child: AspectRatio(
                aspectRatio: 1,
                child: Container(
                  margin: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: primaryColor.withValues(alpha: 0.2),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: _buildGrid(game.board, primaryColor),
                ),
              ),
            ),
          ),
          
          // Match info
          _buildMatchInfo(match, primaryColor),
        ],
      );
    });
  }
  
  Widget _buildGameStatus(TournamentGame game, String localPlayerSymbol, String localPlayerName, 
                           String opponentName, bool isHellMode, Color primaryColor) {
    String statusText;
    Color statusColor;
    IconData statusIcon;
    
    if (game.status == 'completed') {
      if (game.winnerId != null) {
        final isLocalPlayerWinner = 
            (localPlayerSymbol == 'X' && game.winnerId == game.player1Id) ||
            (localPlayerSymbol == 'O' && game.winnerId == game.player2Id);
        
        if (isLocalPlayerWinner) {
          statusText = 'You Won!';
          statusColor = Colors.green;
          statusIcon = Icons.emoji_events;
        } else {
          statusText = 'You Lost';
          statusColor = Colors.red;
          statusIcon = Icons.sentiment_dissatisfied;
        }
      } else {
        statusText = 'Draw Game';
        statusColor = Colors.orange;
        statusIcon = Icons.balance;
      }
    } else {
      final isLocalPlayerTurn = game.currentTurn == localPlayerSymbol;
      
      if (isLocalPlayerTurn) {
        statusText = 'Your Turn';
        statusColor = primaryColor;
        statusIcon = Icons.touch_app;
      } else {
        statusText = '$opponentName\'s Turn';
        statusColor = Colors.grey.shade700;
        statusIcon = Icons.hourglass_empty;
      }
    }
    
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: statusColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(
            statusIcon,
            color: statusColor,
            size: 24,
          ),
          const SizedBox(width: 12),
          Text(
            statusText,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: statusColor,
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: isHellMode ? AppColors.hellRed.withValues(alpha: 0.1) : primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'You: $localPlayerSymbol',
                  style: TextStyle(
                    color: isHellMode ? AppColors.hellRed : primaryColor,
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
  
  Widget _buildGrid(List<String> board, Color primaryColor) {
    return GridView.builder(
      padding: const EdgeInsets.all(8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 1,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: 9,
      itemBuilder: (context, index) {
        // Only allow moves if it's the player's turn and the cell is empty
        final canMakeMove = !_isGameOver && _isLocalPlayerTurn && board[index].isEmpty;
        return GridCell(
          value: board[index],
          index: index,
          isVanishing: _lastVanishedPosition == index,
          onTap: canMakeMove ? () => _makeMove(index) : () {}, // Only allow valid moves
        );
      },
    );
  }
  
  // Show game completion dialog
  void _showGameCompletionDialog(bool isWinner, bool isDraw) {
    if (!mounted) return;
    
    final provider = context.read<TournamentProvider>();
    final match = provider.currentMatch;
    if (match == null) return;
    
    final hellModeProvider = Provider.of<HellModeProvider>(context, listen: false);
    final isHellMode = hellModeProvider.isHellModeActive;
    final primaryColor = AppColors.getPrimaryColor(isHellMode);
    
    String title;
    String message;
    Color color;
    IconData icon;
    
    if (isDraw) {
      title = 'Draw Game';
      message = 'The game ended in a draw!';
      color = Colors.orange;
      icon = Icons.balance;
    } else if (isWinner) {
      title = 'You Won!';
      message = 'Congratulations, you won this game!';
      color = Colors.green;
      icon = Icons.emoji_events;
    } else {
      title = 'You Lost';
      message = 'Better luck next time!';
      color = Colors.red;
      icon = Icons.sentiment_dissatisfied;
    }
    
    // Add match score to the message
    if (match.player1Wins > 0 || match.player2Wins > 0) {
      final player1 = provider.getPlayerById(match.player1Id);
      final player2 = provider.getPlayerById(match.player2Id);
      message += '\n\nMatch Score: ${player1?.name ?? 'Player 1'} ${match.player1Wins} - ${match.player2Wins} ${player2?.name ?? 'Player 2'}';
    }
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(icon, color: color),
              const SizedBox(width: 8),
              Text(title, style: TextStyle(color: color)),
            ],
          ),
          content: Text(message),
          actions: [
            TextButton(
              child: Text('OK', style: TextStyle(color: primaryColor)),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
  
  Widget _buildMatchInfo(TournamentMatch match, Color primaryColor) {
    final provider = context.read<TournamentProvider>();
    final player1 = provider.getPlayerById(match.player1Id);
    final player2 = provider.getPlayerById(match.player2Id);
    
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(
            'Tournament Match',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: primaryColor,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                player1?.name ?? 'Player 1',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${match.player1Wins} - ${match.player2Wins}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: primaryColor,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                player2?.name ?? 'Player 2',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Best of 3 Games',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }
}
