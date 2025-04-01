import 'dart:ui' show VoidCallback;
import 'package:vanishingtictactoe/core/utils/app_logger.dart';
import '../models/game_logic_2players.dart';
import '../models/game_logic_vscomputer.dart';
import '../models/game_logic_online.dart';
import '../models/friendly_game_logic_online.dart';
import 'package:vanishingtictactoe/shared/models/player.dart';
import 'package:vanishingtictactoe/features/history/services/local_match_history_service.dart';

class GameController {
  final GameLogic gameLogic;
  Function(String) onGameEnd;
  final VoidCallback? onPlayerChanged;
  final LocalMatchHistoryService matchHistoryService = LocalMatchHistoryService();

  GameController({
    required this.gameLogic,
    required this.onGameEnd,
    this.onPlayerChanged,
  });

  void makeMove(int index) {
    gameLogic.makeMove(index);
  }

  void resetGame() {
    gameLogic.resetGame();
  }

  String getCurrentPlayerName(Player? player1, Player? player2) {
    AppLogger.debug('Current game state - Player1(${player1?.name}): ${gameLogic.player1Symbol}, '
        'Player2(${player2?.name}): ${gameLogic.player2Symbol}, Current: ${gameLogic.currentPlayer}');
    if (gameLogic is GameLogicVsComputer) {
      final vsComputer = gameLogic as GameLogicVsComputer;
      final isHumanTurn = !vsComputer.isComputerTurn;
      return isHumanTurn ? 'You' : 'Computer';
    }
    // Match currentPlayer to the correct player's symbol
    if (gameLogic.currentPlayer == gameLogic.player1Symbol) {
      return player1?.name ?? 'Player 1';
    } else {
      return player2?.name ?? 'Player 2';
    }
  }

  String getOnlinePlayerTurnText(dynamic onlineLogic, bool isConnecting) {
    // Handle both GameLogicOnline and FriendlyGameLogicOnline
    if (isConnecting || !(onlineLogic.isConnected ?? false)) {
      return "Connecting...";
    }
    
    try {
      final opponentName = onlineLogic.opponentName?.isNotEmpty == true
          ? onlineLogic.opponentName
          : 'Opponent';
      
      return onlineLogic.isLocalPlayerTurn
          ? "Your turn"
          : "$opponentName's turn";
    } catch (e) {
      AppLogger.error('Error getting turn text: $e');
      return "Game in progress";
    }
  }

  bool isInteractionDisabled(bool isConnecting) {
    if (gameLogic is GameLogicVsComputer) {
      return (gameLogic as GameLogicVsComputer).isComputerTurn;
    } else if (gameLogic is GameLogicOnline) {
      return !(gameLogic as GameLogicOnline).isLocalPlayerTurn || isConnecting;
    } else if (gameLogic is FriendlyGameLogicOnline) {
      return !(gameLogic as FriendlyGameLogicOnline).isLocalPlayerTurn || isConnecting;
    }
    return false;
  }

  String? determineSurrenderWinner() {
    if (gameLogic is GameLogicVsComputer) {
      String winner = (gameLogic as GameLogicVsComputer).computerPlayer.symbol;
      AppLogger.debug('Surrender: Computer wins, symbol=$winner');
      return winner;
    } else if (gameLogic is! GameLogicOnline && gameLogic is! FriendlyGameLogicOnline) {
      String current = gameLogic.currentPlayer;
      String winner = current == 'X' ? 'O' : 'X';
      AppLogger.debug('Surrender: Current player=$current, Winner=$winner');
      return winner;
    }
    AppLogger.debug('Surrender: Online game, returning null');
    return null;
  }
}