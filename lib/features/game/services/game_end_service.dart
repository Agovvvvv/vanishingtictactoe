import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vanishingtictactoe/features/game/models/computer_player.dart';
import 'package:vanishingtictactoe/core/utils/app_logger.dart';
import 'package:vanishingtictactoe/core/utils/win_checker.dart';
import 'package:vanishingtictactoe/features/game/models/game_logic_vscomputer.dart';
import 'package:vanishingtictactoe/features/game/models/game_logic_online.dart';
import 'package:vanishingtictactoe/features/game/models/friendly_game_logic_online.dart';
import 'package:vanishingtictactoe/shared/models/match.dart';
import 'package:vanishingtictactoe/features/history/services/local_match_history_service.dart';
import 'package:vanishingtictactoe/features/history/services/match_history_updates.dart';
import 'package:vanishingtictactoe/shared/providers/user_provider.dart';
import 'package:vanishingtictactoe/shared/providers/mission_provider.dart';
import 'package:vanishingtictactoe/shared/providers/hell_mode_provider.dart';
import 'package:vanishingtictactoe/features/game/widgets/match/game_end_dialog.dart';
import 'package:vanishingtictactoe/shared/providers/game_provider.dart';
import 'package:vanishingtictactoe/features/history/services/match_history_service.dart';
import 'package:vanishingtictactoe/features/friends/services/notification_service.dart';

class GameEndService {
  static final GameEndService _instance = GameEndService._internal();
  
  factory GameEndService({
    required BuildContext context,
    required GameProvider gameProvider,
  }) {
    _instance._context = context;
    _instance._gameProvider = gameProvider;
    return _instance;
  }

  GameEndService._internal();

  BuildContext? _context;
  GameProvider? _gameProvider;
  final LocalMatchHistoryService _matchHistoryService = LocalMatchHistoryService();
  bool _isHandlingGameEnd = false;
  bool _isShowingWinAnimation = false;

  Future<void> handleGameEnd({
    String? forcedWinner,
    bool isSurrendered = false,
    VoidCallback? onBackToMenu,
    required VoidCallback onPlayAgain,
    bool vanishingEffectEnabled = true,
  }) async {
    if (_isHandlingGameEnd) return;
    _isHandlingGameEnd = true;
    _isShowingWinAnimation = false;

    final context = _context;
    final gameProvider = _gameProvider;
    if (context == null || gameProvider == null) {
      AppLogger.error('GameEndService not properly initialized with context or gameProvider');
      return;
    }

    try {
      final gameLogic = gameProvider.gameLogic;
      final player1 = gameProvider.player1;
      final player2 = gameProvider.player2;
      
      final isFriendlyMatch = gameLogic is FriendlyGameLogicOnline;
      final isOnlineGame = gameProvider.isOnlineGame && !isFriendlyMatch;
      
      AppLogger.debug('Game types: isOnlineGame=$isOnlineGame, isFriendlyMatch=$isFriendlyMatch, gameLogic=${gameLogic.runtimeType}');

      // Reduce log verbosity - only log important parameters
      AppLogger.debug('Game ending: forcedWinner=$forcedWinner, surrendered=$isSurrendered');

      String winner = forcedWinner ?? '';
      
      // Handle surrender case specifically
      if (isSurrendered) {
        winner = gameProvider.determineSurrenderWinner() ?? '';
        AppLogger.debug('Surrender detected, winner symbol: $winner');
        
        // For online games, update the match status on the server
      } else if (winner.isEmpty) {
        winner = gameLogic.checkWinner();
      }

      bool isDraw = winner == 'draw' || (winner.isEmpty && !gameLogic.board.contains(''));

      // Consolidate computer game logic checks
      if (gameLogic is GameLogicVsComputer) {
        if (winner.isEmpty && !isSurrendered) {
          winner = gameLogic.checkWinner();
        }
        if (forcedWinner != null && forcedWinner.isNotEmpty) {
          winner = forcedWinner;
          isDraw = false;
        }
      }

      // Consolidate online game logic checks
      if (gameLogic is GameLogicOnline) {
        final onlineLogic = gameLogic;
        final match = onlineLogic.currentMatch;
        if (!isSurrendered && match != null && match.status == 'completed') {
          if (match.winner.isNotEmpty && match.winner != 'draw') {
            winner = match.winner;
            isDraw = false;
          } else if (match.winner == 'draw' || !match.board.contains('')) {
            isDraw = true;
          }
        }
      }

      // Single log for final game state
      AppLogger.info('Game ended: winner=$winner, isDraw=$isDraw, isSurrendered=$isSurrendered');

      if (winner.isNotEmpty || isDraw) {
        String winnerName;
        bool isHumanWinner = false;
        List<int>? winningPattern;
        
        // Get the winning pattern if there's a winner and it's not a draw
        if (winner.isNotEmpty && winner != 'draw' && !isDraw && !isSurrendered) {
          winningPattern = WinChecker.getWinningPattern(gameLogic.board, winner);
          AppLogger.debug('Found winning pattern: $winningPattern');
        }

        if (gameLogic is GameLogicVsComputer) {
          final vsComputer = gameLogic;
          isHumanWinner = winner == vsComputer.player1Symbol;
          final player1Name = player1.name;
          winnerName = isHumanWinner ? player1Name : 'Computer';
        } else if (gameLogic is GameLogicOnline || gameLogic is FriendlyGameLogicOnline) {
          GameMatch? match;
          if (gameLogic is GameLogicOnline) {
            final onlineLogic = gameLogic;
            match = onlineLogic.currentMatch;
          } else if (gameLogic is FriendlyGameLogicOnline) {
            final friendlyLogic = gameLogic;
            match = friendlyLogic.currentMatch;
          }
          
          if (isDraw || winner == 'draw') {
            winnerName = 'Nobody';
          } else if (isSurrendered) {
            // For surrendered games, determine winner based on symbols
            if (winner == gameLogic.player1Symbol) {
              winnerName = player1.name;
            } else if (winner == gameLogic.player2Symbol) {
              winnerName = player2.name;
            } else {
              // Fallback
              winnerName = (gameLogic as dynamic).isLocalPlayerTurn ? player2.name : player1.name;
            }
            AppLogger.debug('Surrender winner determined: $winnerName (symbol: $winner)');
          } else if (match != null && match.winner.isNotEmpty) {
            if (match.winner == match.player1.id) {
              winnerName = match.player1.name;
            } else {
              winnerName = match.player2.name;
            }
          } else {
            winnerName = 'Unknown';
          }
        } else {
          // Two-player game: Use dynamic symbol mapping
          winnerName = winner == player1.symbol ? player1.name : player2.name;
          AppLogger.debug('Two-player winner: symbol=$winner, name=$winnerName');
        }

        String message;
        if (isSurrendered) {
          message = winnerName == 'Computer' ? 'You surrendered!' : '$winnerName wins by surrender!';
        } else if (isDraw) {
          message = 'It\'s a draw!';
        } else if (gameLogic is GameLogicOnline || gameLogic is FriendlyGameLogicOnline) {
          GameMatch? match;
          String localPlayerId = '';
          
          if (gameLogic is GameLogicOnline) {
            final online = gameLogic;
            match = online.currentMatch;
            localPlayerId = online.localPlayerId;
          } else if (gameLogic is FriendlyGameLogicOnline) {
            final friendlyLogic = gameLogic;
            match = friendlyLogic.currentMatch;
            localPlayerId = friendlyLogic.localPlayerId;
          }
          
          if (match != null) {
            // Check if local player is winner, handling both player ID and symbol formats
            bool isLocalPlayerWinner = false;
            
            if (gameLogic is GameLogicOnline) {
              final onlineLogic = gameLogic;
              // For challenge games, winner might be stored as a symbol
              isLocalPlayerWinner = match.winner == localPlayerId || 
                                   (match.winner == onlineLogic.localPlayerSymbol);
            } else if (gameLogic is FriendlyGameLogicOnline) {
              final friendlyLogic = gameLogic;
              isLocalPlayerWinner = match.winner == localPlayerId || 
                                   (match.winner == friendlyLogic.localPlayerSymbol);
            }
            
            message = isLocalPlayerWinner ? 'You win!' : '$winnerName wins!';
          } else {
            message = '$winnerName wins!';
          }
        } else {
          message = isHumanWinner ? 'You win!' : '$winnerName wins!';
        }

        int? winnerMoves;
        if (!isDraw || !isSurrendered) {
          winnerMoves = winner == 'X' ? gameLogic.xMoveCount : gameLogic.oMoveCount;
        }

        if (gameLogic is! FriendlyGameLogicOnline) {
          _updateGameStatsAndHistory(
            gameLogic: gameLogic,
            winner: winner,
            winnerName: winnerName,
            isDraw: isDraw,
            isSurrendered: isSurrendered,
            winnerMoves: winnerMoves,
            player1Name: player1.name,
            player2Name: player2.name,
            vanishingEffectEnabled: vanishingEffectEnabled,
          );
        }
        
        if (context.mounted) {
          // Show winning line animation before dialog if there's a winning pattern
          if (winningPattern != null && !_isShowingWinAnimation) {
            _isShowingWinAnimation = true;
            AppLogger.debug('Showing winning line animation before dialog');
            
            // Update the game provider with the winning pattern to display the animation
            gameProvider.setWinningPattern(winningPattern);
            
            // Set a delay to show the dialog after the animation plays
            // Increased delay to 2500ms to allow cell animations to complete
            Future.delayed(const Duration(milliseconds: 2500), () {
              if (context.mounted) {
                AppLogger.debug('Animation complete, showing game end dialog');
                _showGameEndDialog(
                  gameLogic: gameLogic,
                  context: context,
                  isSurrendered: isSurrendered,
                  message: message,
                  isOnlineGame: isOnlineGame,
                  isVsComputer: gameLogic is GameLogicVsComputer,
                  isFriendlyMatch: isFriendlyMatch,
                  player1: player1,
                  player2: player2,
                  winnerMoves: winnerMoves,
                  onPlayAgain: onPlayAgain,
                  onBackToMenu: onBackToMenu,
                  gameProvider: gameProvider,
                );
              }
            });
          } else {
            // If there's no winning pattern, just show the dialog
            AppLogger.debug('No winning pattern, showing game end dialog directly');
            _showGameEndDialog(
              gameLogic: gameLogic,
              context: context,
              isSurrendered: isSurrendered,
              message: message,
              isOnlineGame: isOnlineGame,
              isVsComputer: gameLogic is GameLogicVsComputer,
              isFriendlyMatch: isFriendlyMatch,
              player1: player1,
              player2: player2,
              winnerMoves: winnerMoves,
              onPlayAgain: onPlayAgain,
              onBackToMenu: onBackToMenu,
              gameProvider: gameProvider,
            );
          }
        }

      }
    } finally {
      _isHandlingGameEnd = false;
    }
  }

  Future<void> _updateGameStatsAndHistory({
    required dynamic gameLogic,
    required String winner,
    required String winnerName,
    required bool isDraw,
    required bool isSurrendered,
    required int? winnerMoves,
    required String player1Name,
    required String player2Name,
    required bool vanishingEffectEnabled,
  }) async {
    try {
      // Only save local match history for 2-player games (not friendly matches)
      if (gameLogic is! GameLogicVsComputer && gameLogic is! GameLogicOnline && gameLogic is! FriendlyGameLogicOnline) {
        final player1WentFirst = gameLogic.player1Symbol == 'X';
        await _matchHistoryService.saveMatch(
          player1: player1Name,
          player2: player2Name,
          winner: winnerName,
          player1WentFirst: player1WentFirst,
          player1Symbol: _gameProvider!.player1.symbol,
          player2Symbol: _gameProvider!.player2.symbol,
          vanishingEffectEnabled: vanishingEffectEnabled,
        );
        MatchHistoryUpdates.notifyUpdate();
      }

      final userProvider = Provider.of<UserProvider>(_context!, listen: false);
      final missionProvider = Provider.of<MissionProvider>(_context!, listen: false);
      final hellModeProvider = Provider.of<HellModeProvider>(_context!, listen: false);
      final isHellMode = hellModeProvider.isHellModeActive;
      final MatchHistoryService matchHistoryService = MatchHistoryService();
      
      // Create game result notifications for online multiplayer games
      if ((gameLogic is GameLogicOnline || gameLogic is FriendlyGameLogicOnline) && 
          !isSurrendered && userProvider.user != null) {
        _createGameResultNotifications(
          gameLogic: gameLogic,
          winner: winner,
          isDraw: isDraw,
          player1Name: player1Name,
          player2Name: player2Name,
          winnerMoves: winnerMoves,
          gameMode: vanishingEffectEnabled ? 'Vanishing' : 'Standard',
          isHellMode: isHellMode,
        );
      }

      if (userProvider.user != null) {
        if (gameLogic is GameLogicVsComputer) {
          final isHumanWinner = winner == gameLogic.player1Symbol;
          GameDifficulty? difficulty;
          if (_gameProvider!.player2 is ComputerPlayer) {
            difficulty = (_gameProvider!.player2 as ComputerPlayer).difficulty;
          }

          await userProvider.updateGameStats(
            isWin: isDraw ? false : isHumanWinner,
            isDraw: isDraw,
            movesToWin: isDraw ? null : (isHumanWinner ? winnerMoves : null),
            isOnline: false,
            isFriendlyMatch: false,
            isHellMode: isHellMode,
            difficulty: difficulty ?? GameDifficulty.easy,
          );

          // Use the debounced version in MatchHistoryService to prevent duplicates
          await matchHistoryService.saveMatchResult(
            userId: userProvider.user!.id, 
            difficulty: difficulty, 
            result: isHumanWinner? 'win' : isDraw? 'draw' : 'loss',
          );

          await missionProvider.trackGamePlayed(
            isHellMode: isHellMode,
            isWin: isHumanWinner,
            difficulty: difficulty,
          );
        } else if (gameLogic is GameLogicOnline) {
          final online = gameLogic;
          final isWin = online.localPlayerId == online.currentMatch?.winner;

          await userProvider.updateGameStats(
            isWin: isDraw ? false : isWin,
            isDraw: isDraw,
            movesToWin: isDraw ? null : (isWin ? winnerMoves : null),
            isOnline: true,
            isFriendlyMatch: isSurrendered,
          );

          if (!isSurrendered) {
            await missionProvider.trackGamePlayed(
              isHellMode: isHellMode,
              isWin: isWin,
              difficulty: null,
            );
          }
        }
      }
    } catch (e) {
      AppLogger.error('Error updating game stats and history: $e');
    }
  }

  /// Creates game result notifications for both players in an online game
  /// 
  /// This method sends notifications to both players about the outcome of their match,
  /// including who won, the game mode, and optional rank changes.
  Future<void> _createGameResultNotifications({
    required dynamic gameLogic,
    required String winner,
    required bool isDraw,
    required String player1Name,
    required String player2Name,
    required int? winnerMoves,
    required String gameMode,
    required bool isHellMode,
  }) async {
    try {
      final notificationService = NotificationService();
      String? player1Id;
      String? player2Id;
      String? matchId;
      
      // Extract player IDs based on game logic type
      if (gameLogic is GameLogicOnline) {
        player1Id = gameLogic.localPlayerId;
        // Get opponent ID from the match data
        final match = gameLogic.currentMatch;
        if (match != null) {
          player2Id = match.player1.id == player1Id ? match.player2.id : match.player1.id;
          matchId = match.id;
        }
      } else if (gameLogic is FriendlyGameLogicOnline) {
        // For friendly games, extract IDs from the match data
        player1Id = gameLogic.localPlayerId;
        final match = gameLogic.currentMatch;
        if (match != null) {
          player2Id = match.player1.id == player1Id ? match.player2.id : match.player1.id;
          matchId = match.id;
        }
      }
      
      // Only proceed if we have valid player IDs
      if (player1Id == null || player2Id == null) {
        AppLogger.error('Cannot create game result notifications: Missing player IDs');
        return;
      }
      
      // Calculate rank changes (if this is a ranked game)
      // This is a placeholder - implement your actual rank calculation logic
      int? rankChange;
      if (!isDraw && !isHellMode) {
        // Simple example: winner gets +15, loser gets -15
        rankChange = 15;
      }
      
      // Determine which player won (if not a draw)
      String? winnerPlayerId;
      String? loserPlayerId;
      
      if (!isDraw) {
        // Determine winner and loser IDs based on the winner symbol
        if (winner == gameLogic.player1Symbol) {
          winnerPlayerId = gameLogic.currentMatch?.player1.id;
          loserPlayerId = gameLogic.currentMatch?.player2.id;
        } else if (winner == gameLogic.player2Symbol) {
          winnerPlayerId = gameLogic.currentMatch?.player2.id;
          loserPlayerId = gameLogic.currentMatch?.player1.id;
        }
        
        // Send win notification to winner
        if (winnerPlayerId != null && loserPlayerId != null) {
          final winnerName = winnerPlayerId == gameLogic.currentMatch?.player1.id ? 
              player1Name : player2Name;
          final loserName = loserPlayerId == gameLogic.currentMatch?.player1.id ? 
              player1Name : player2Name;
          
          // Send win notification to winner
          await notificationService.createGameResultNotification(
            recipientId: winnerPlayerId,
            opponentUsername: loserName,
            userWon: true,  // Winner always gets a win notification
            isDraw: false,
            gameMode: isHellMode ? 'Hell Mode' : gameMode,
            matchId: matchId,
            rankChange: rankChange,
          );
          
          // Send loss notification to loser
          await notificationService.createGameResultNotification(
            recipientId: loserPlayerId,
            opponentUsername: winnerName,
            userWon: false,  // Loser always gets a loss notification
            isDraw: false,
            gameMode: isHellMode ? 'Hell Mode' : gameMode,
            matchId: matchId,
            rankChange: rankChange != null ? -rankChange : null,
          );
        }
      } else {
        // For draws, both players get the same draw notification
        await notificationService.createGameResultNotification(
          recipientId: player1Id,
          opponentUsername: player2Name,
          userWon: false,
          isDraw: true,
          gameMode: isHellMode ? 'Hell Mode' : gameMode,
          matchId: matchId,
          rankChange: null,  // No rank change for draws
        );
        
        await notificationService.createGameResultNotification(
          recipientId: player2Id,
          opponentUsername: player1Name,
          userWon: false,
          isDraw: true,
          gameMode: isHellMode ? 'Hell Mode' : gameMode,
          matchId: matchId,
          rankChange: null,  // No rank change for draws
        );
      }
      
      AppLogger.debug('Created game result notifications for both players');
    } catch (e) {
      AppLogger.error('Error creating game result notifications: $e');
    }
  }

  void _showGameEndDialog({
    required BuildContext context,
    required String message,
    required bool isOnlineGame,
    required bool isVsComputer,
    required bool isFriendlyMatch,
    required bool isSurrendered,
    required dynamic gameLogic,
    required dynamic player1,
    required dynamic player2,
    required int? winnerMoves,
    required VoidCallback onPlayAgain,
    VoidCallback? onBackToMenu,
    required GameProvider gameProvider,
  }) {
    AppLogger.debug('Showing game end dialog');
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => GameEndDialog(
        isSurrendered: isSurrendered,
        message: message,
        isOnlineGame: isOnlineGame,
        isVsComputer: isVsComputer,
        isFriendlyMatch: isFriendlyMatch,
        player1: player1,
        player2: player2,
        winnerMoves: winnerMoves,
        onPlayAgain: onPlayAgain,
        onBackToMenu: onBackToMenu,
        gameProvider: gameProvider,
      ),
    );
  }
}