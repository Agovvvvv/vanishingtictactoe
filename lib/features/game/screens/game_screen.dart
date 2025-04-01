import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vanishingtictactoe/features/game/models/game_logic_2players.dart';
import 'package:vanishingtictactoe/features/game/models/game_logic_online.dart';
import 'package:vanishingtictactoe/features/game/models/game_logic_vscomputer.dart';
import 'package:vanishingtictactoe/shared/models/player.dart';
import 'package:vanishingtictactoe/shared/providers/game_provider.dart';
import 'package:vanishingtictactoe/features/game/screens/2Players/two_players_screen.dart';
import 'package:vanishingtictactoe/features/game/services/game_end_service.dart';
import 'package:vanishingtictactoe/features/game/widgets/match/game_board_widget.dart';
import 'package:vanishingtictactoe/features/game/widgets/match/turn_indicator_widget.dart';
import 'package:vanishingtictactoe/features/game/widgets/match/animated_title_widget.dart';
import 'package:vanishingtictactoe/core/constants/app_colors.dart';
import 'package:vanishingtictactoe/core/utils/app_logger.dart';

class GameScreen extends StatefulWidget {
  final Player player1;
  final Player player2;
  final GameLogic logic;
  final bool isOnlineGame;
  final bool vanishingEffectEnabled;

  const GameScreen({
    super.key,
    required this.player1,
    required this.player2,
    required this.logic,
    this.isOnlineGame = false,
    this.vanishingEffectEnabled = true,
  });

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  late AnimationController _backgroundController;
  late Animation<double> _backgroundAnimation;
  late AnimationController _boardScaleController;
  late Animation<double> _boardScaleAnimation;

  @override
  void initState() {
    super.initState();

    // Setup fade-in animation
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOutCubic,
    );

    // Setup background animation
    _backgroundController = AnimationController(
      duration: const Duration(milliseconds: 20000),
      vsync: this,
    )..repeat(reverse: true);

    _backgroundAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _backgroundController, curve: Curves.easeInOut),
    );

    // Setup board scale animation
    _boardScaleController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _boardScaleAnimation = CurvedAnimation(
      parent: _boardScaleController,
      curve: Curves.elasticOut,
    );

    // Start the animations with sequence
    Future.delayed(const Duration(milliseconds: 100), () {
      _fadeController.forward();
      Future.delayed(const Duration(milliseconds: 300), () {
        _boardScaleController.forward();
      });
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _backgroundController.dispose();
    _boardScaleController.dispose();
    super.dispose();
  }

  void _onPlayAgain(BuildContext context) {
    AppLogger.debug('Play again selected');
    if (widget.isOnlineGame) {
      Navigator.of(
        context,
        rootNavigator: true,
      ).popUntil((route) => route.isFirst);
    } else {
      final provider = Provider.of<GameProvider>(context, listen: false);

      // Disable game end handlers during reset
      provider.gameLogic.onGameEnd = (_) {};
      provider.gameController.onGameEnd = (_) {};

      // Reset the game
      provider.resetGame();

      // Set up the game end handler again after reset is complete
      Future.delayed(const Duration(milliseconds: 100), () {
        if (context.mounted) {
          gameEndHandler(String winner) {
            GameEndService(
              context: context,
              gameProvider: provider,
            ).handleGameEnd(
              forcedWinner: winner,
              onPlayAgain: provider.onPlayAgain,
              onBackToMenu: () => _onBackToMenu(context),
            );
          }

          provider.gameLogic.onGameEnd = gameEndHandler;
          provider.gameController.onGameEnd = gameEndHandler;
        }
      });
    }
  }

  void _onBackToMenu(BuildContext context) {
    final navigator = Navigator.of(context, rootNavigator: true);
    AppLogger.debug('Back to menu selected');

    bool foundTargetRoute = false;
    navigator.popUntil((route) {
      final routeName = route.settings.name;
      if (routeName == '/two-players-history' ||
          routeName == '/difficulty-selection') {
        foundTargetRoute = true;
        return true;
      }
      return route.isFirst;
    });

    if (!foundTargetRoute) {
      AppLogger.warning('Target route not found, falling back to home screen');
      navigator.pushReplacement(
        MaterialPageRoute(
          builder: (context) => const TwoPlayersHistoryScreen(),
          settings: const RouteSettings(name: '/two-players-history'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Set the vanishing effect on the logic before creating the provider
    widget.logic.vanishingEffectEnabled = widget.vanishingEffectEnabled;
    final colorScheme = Theme.of(context).colorScheme;

    return ChangeNotifierProvider(
      create:
          (context) => GameProvider(
            gameLogic: widget.logic,
            onGameEnd: (winner) {},
            onPlayAgain: () {}, // Empty placeholder
            paramPlayer1: widget.player1,
            paramPlayer2: widget.player2,
            paramIsOnlineGame: widget.isOnlineGame,
            paramVanishingEffectEnabled: widget.vanishingEffectEnabled,
          ),
      child: Builder(
        builder: (BuildContext gameContext) {
          final gameProvider = Provider.of<GameProvider>(
            gameContext,
            listen: false,
          );

          // Set the actual onPlayAgain callback here with the correct context
          gameProvider.onPlayAgain = () {
            AppLogger.debug('Play again selected - resetting game');
            _onPlayAgain(gameContext);
          };

          // Define a single game end handler to avoid duplicates
          gameEndHandler(String winner) => GameEndService(
            context: gameContext,
            gameProvider: gameProvider,
          ).handleGameEnd(
            forcedWinner: winner,
            onPlayAgain: gameProvider.onPlayAgain,
            onBackToMenu: () => _onBackToMenu(gameContext),
          );

          // Set the handler only once
          gameProvider.gameController.onGameEnd = gameEndHandler;
          gameProvider.gameLogic.onGameEnd = gameEndHandler;

          return PopScope(
            canPop: true,
            onPopInvokedWithResult: (didPop, result) async {
              AppLogger.info('PopScope: didPop=$didPop');
              if (didPop) {
                final provider = Provider.of<GameProvider>(
                  gameContext,
                  listen: false,
                );
                if (provider.gameLogic is GameLogicOnline) {
                  (provider.gameLogic as GameLogicOnline).dispose();
                }
                provider.resetGame();
                AppLogger.info('GameScreen cleaned up');
              }
            },
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Scaffold(
                extendBodyBehindAppBar: true,
                appBar: AppBar(
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  automaticallyImplyLeading: false,
                  toolbarHeight: 0,
                ),
                body: AnimatedBuilder(
                  animation: _backgroundAnimation,
                  builder: (context, child) {
                    // Determine colors based on current player
                    final isXPlayer = gameProvider.gameLogic.currentPlayer == 'X';
                    final primaryColor = isXPlayer ? AppColors.player1Dark : AppColors.player2Dark;
                    final secondaryColor = isXPlayer ? AppColors.player1Light : AppColors.player2Light;

                    return Stack(
                      children: [
                        // Modern gradient background with subtle animation
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              stops: [
                                0.0,
                                _backgroundAnimation.value * 0.3 + 0.3,
                                _backgroundAnimation.value * 0.2 + 0.6,
                                1.0,
                              ],
                              colors: [
                                Color.lerp(
                                  colorScheme.surface.withOpacity(0.95),
                                  primaryColor.withValues(alpha: 0.08),
                                  _backgroundAnimation.value,
                                ) ?? colorScheme.surface.withOpacity(0.95),
                                Color.lerp(
                                  colorScheme.surfaceContainerHigh.withOpacity(0.9),
                                  primaryColor.withValues(alpha: 0.15),
                                  _backgroundAnimation.value,
                                ) ?? colorScheme.surfaceContainerHigh.withOpacity(0.9),
                                Color.lerp(
                                  colorScheme.surfaceContainerHighest.withOpacity(0.85),
                                  secondaryColor.withValues(alpha: 0.15),
                                  _backgroundAnimation.value,
                                ) ?? colorScheme.surfaceContainerHighest.withOpacity(0.85),
                                Color.lerp(
                                  colorScheme.surfaceContainerHighest.withValues(alpha: 0.8),
                                  secondaryColor.withValues(alpha: 0.08),
                                  _backgroundAnimation.value,
                                ) ?? colorScheme.surfaceContainerHighest.withValues(alpha: 0.8),
                              ],
                            ),
                          ),
                        ),
                        // Main content
                        child!,
                      ],
                    );
                  },
                  child: Stack(
                    children: [
                      SafeArea(
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16.0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                // Game title with animated appearance
                                SlideTransition(
                                  position: Tween<Offset>(
                                    begin: const Offset(0, -1.0),
                                    end: Offset.zero,
                                  ).animate(
                                    CurvedAnimation(
                                      parent: _fadeController,
                                      curve: const Interval(
                                        0.0,
                                        0.6,
                                        curve: Curves.easeOutCubic,
                                      ),
                                    ),
                                  ),
                                  child: FadeTransition(
                                    opacity: CurvedAnimation(
                                      parent: _fadeController,
                                      curve: const Interval(
                                        0.1,
                                        0.7,
                                        curve: Curves.easeOut,
                                      ),
                                    ),
                                    child: Consumer<GameProvider>(
                                      builder: (context, gameProvider, child) {
                                        String gameTitle = "Tic Tac Toe";
                                        bool isHellMode = false;

                                        // Determine game type
                                        if (gameProvider.gameLogic is GameLogicOnline) {
                                          gameTitle = "Online Game";
                                        } else if (gameProvider.gameLogic is GameLogicVsComputer) {
                                          gameTitle = "Computer Game";
                                        } else if (widget.isOnlineGame) {
                                          gameTitle = "Friendly Game";
                                        }

                                        return AnimatedTitleWidget(
                                          text: gameTitle,
                                          isHellMode: isHellMode,
                                        );
                                      },
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 25),
                                // Turn indicator with animated appearance
                                SlideTransition(
                                  position: Tween<Offset>(
                                    begin: const Offset(0, -0.5),
                                    end: Offset.zero,
                                  ).animate(
                                    CurvedAnimation(
                                      parent: _fadeController,
                                      curve: const Interval(
                                        0.2,
                                        0.8,
                                        curve: Curves.easeOutCubic,
                                      ),
                                    ),
                                  ),
                                  child: FadeTransition(
                                    opacity: CurvedAnimation(
                                      parent: _fadeController,
                                      curve: const Interval(
                                        0.3,
                                        0.9,
                                        curve: Curves.easeOut,
                                      ),
                                    ),
                                    child: Consumer<GameProvider>(
                                      builder: (context, gameProvider, child) => TurnIndicatorWidget(
                                        gameProvider: gameProvider,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 30),
                                // Game board with scale animation
                                ScaleTransition(
                                  scale: _boardScaleAnimation,
                                  child: Consumer<GameProvider>(
                                    builder: (context, gameProvider, child) => GameBoardWidget(
                                      isInteractionDisabled: gameProvider.isInteractionDisabled(),
                                      onCellTapped: gameProvider.makeMove,
                                      gameLogic: gameProvider.gameLogic,
                                      onWinAnimationComplete: () {
                                        // Handle win animation completion
                                      },
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 30),
                              ],
                            ),
                          ),
                        ),
                      ),

                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
