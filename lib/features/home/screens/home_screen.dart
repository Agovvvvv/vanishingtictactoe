import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:vanishingtictactoe/features/friends/services/friend_service.dart';
import 'package:vanishingtictactoe/core/utils/app_logger.dart';
import 'package:vanishingtictactoe/features/home/widgets/grid_pattern_painter_widget.dart';
import 'package:vanishingtictactoe/features/home/widgets/info_card_widget.dart';
import 'package:vanishingtictactoe/shared/providers/user_provider.dart';
import 'package:vanishingtictactoe/shared/providers/mission_provider.dart';
import 'package:vanishingtictactoe/shared/providers/navigation_provider.dart';
import 'package:vanishingtictactoe/shared/providers/hell_mode_provider.dart';
import 'package:vanishingtictactoe/shared/widgets/level_badge.dart';
import 'package:vanishingtictactoe/features/home/widgets/animated_title.dart';
import 'package:vanishingtictactoe/core/routes/app_routes.dart';
import 'package:vanishingtictactoe/core/utils/font_preloader.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  final FriendService _friendService = FriendService();
  StreamSubscription? _requestsSubscription;
  bool _isInitialized = false;

  late AnimationController _backgroundAnimationController;
  late AnimationController _buttonAnimationController;
  late Animation<double> _buttonScaleAnimation;

  @override
  void initState() {
    super.initState();
    _initializeData();
    _initializeAnimations();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
  }

  void _initializeAnimations() {
    _backgroundAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();

    _buttonAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _buttonScaleAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _buttonAnimationController, curve: Curves.easeInOut),
    );
  }

  Future<void> _initializeData() async {
    // We no longer need to track friend requests since we removed that UI element
    _requestsSubscription = _friendService.getFriendRequests().listen((_) {
      // No need to update state
    }, onError: (error) {
      AppLogger.error('Error fetching friend requests: $error');
    });

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        final userProvider = Provider.of<UserProvider>(context, listen: false);
        final missionProvider = Provider.of<MissionProvider>(context, listen: false);

        if (userProvider.isLoggedIn) {
          await missionProvider.initialize(userProvider.user?.id);
        }

        if (mounted) {
          setState(() {
            _isInitialized = true;
          });
        }
      } catch (e) {
        AppLogger.error('Error during HomeScreen initialization: $e');
        if (mounted) {
          setState(() {
            _isInitialized = true;
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _requestsSubscription?.cancel();
    _backgroundAnimationController.dispose();
    _buttonAnimationController.dispose();
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {

    final hellModeProvider = Provider.of<HellModeProvider>(context);
    
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: hellModeProvider.isHellModeActive
              ? [
                  Colors.red.shade900,
                  Colors.red.shade800,
                  Colors.black,
                ]
              : [
                  Colors.blue.shade50,
                  Colors.blue.shade100,
                  Colors.blue.shade200.withValues(alpha: 0.5),
                ],
          stops: const [0.0, 0.6, 1.0],
        ),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: Opacity(
              opacity: 0.05,
              child: GridPatternPainterWidget(),
            ),
          ),
          Column(
            children: [
              AppBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                systemOverlayStyle: SystemUiOverlayStyle.dark,
                automaticallyImplyLeading: false,
                title: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Game stats or achievements could go here
                    const SizedBox(width: 40),
                    
                    // Level badge on the right
                    Consumer<UserProvider>(
                      builder: (context, userProvider, _) {
                        final user = userProvider.user;
                        if (user != null) {
                          return GestureDetector(
                            onTap: () {
                              Navigator.pushNamed(context, AppRoutes.levelRoadmap);
                            },
                            child: Row(
                              children: [
                                Consumer<HellModeProvider>(
                                  builder: (context, hellModeProvider, _) {
                                    return Row(
                                      children: [
                                        Icon(
                                          Icons.info_outline,
                                          size: 16,
                                          color: hellModeProvider.isHellModeActive
                                              ? Colors.orange.shade300
                                              : Colors.blue.shade200,
                                        ),
                                        const SizedBox(width: 4),
                                        hellModeProvider.isHellModeActive
                                            ? LevelBadge.hellModeFromUserLevel(
                                                userLevel: user.userLevel,
                                                fontSize: 14,
                                                iconSize: 18,
                                                showShadow: true,
                                              )
                                            : LevelBadge.fromUserLevel(
                                                userLevel: user.userLevel,
                                                fontSize: 14,
                                                iconSize: 18,
                                                showShadow: true,
                                                backgroundColor: Colors.blue.shade700,
                                              ),
                                      ],
                                    );
                                  },
                                ),
                              ],
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ],
                ),
              ),
              Expanded(
                child: AnimatedOpacity(
                  opacity: _isInitialized ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.easeOut,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Removed large icon to save space
                        const SizedBox(height: 10),
                        // Game title
                        const AnimatedTitle(),
                        const SizedBox(height: 20),
                        // Game tagline
                        Consumer<HellModeProvider>(
                          builder: (context, hellModeProvider, _) {
                            return Text(
                              hellModeProvider.isHellModeActive
                                  ? 'Challenge yourself in HELL MODE'
                                  : 'A new twist on a classic game',
                              style: TextStyle(
                                color: hellModeProvider.isHellModeActive
                                    ? Colors.orange.shade300
                                    : Colors.blue.shade800,
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                              textAlign: TextAlign.center,
                            );
                          },
                        ),
                        const SizedBox(height: 40),
                        // Play button
                        AnimatedBuilder(
                          animation: _buttonAnimationController,
                          builder: (context, child) {
                            return Transform.scale(
                              scale: _buttonScaleAnimation.value,
                              child: ElevatedButton(
                                onPressed: () {
                                  // First update the navigation provider
                                  Provider.of<NavigationProvider>(context, listen: false).setCurrentIndex(2);
                                  
                                  // Add a small delay to ensure the state is updated
                                  Future.delayed(const Duration(milliseconds: 50), () {
                                    HapticFeedback.mediumImpact();
                                  });
                                },
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 60, vertical: 20),
                                  backgroundColor: hellModeProvider.isHellModeActive
                                      ? Colors.red.shade700
                                      : Colors.blue.shade600,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                  elevation: 8,
                                  shadowColor: hellModeProvider.isHellModeActive
                                      ? Colors.red.shade900
                                      : Colors.blue.shade300,
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      hellModeProvider.isHellModeActive
                                          ? Icons.local_fire_department
                                          : Icons.play_arrow_rounded,
                                      size: 32,
                                      color: Colors.white,
                                    ),
                                    const SizedBox(width: 12),
                                    ShaderMask(
                                      shaderCallback: (bounds) => LinearGradient(
                                        colors: [Colors.white, Colors.white.withValues(alpha: 0.9)],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ).createShader(bounds),
                                      child: Text(
                                        hellModeProvider.isHellModeActive ? 'PLAY HELL MODE' : 'PLAY',
                                        style: FontPreloader.getTextStyle(
                                          fontFamily: 'Poppins',
                                          fontSize: hellModeProvider.isHellModeActive ? 22 : 26,
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: 1.2,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              // Quick stats or game info
              Consumer2<HellModeProvider, UserProvider>(
                builder: (context, hellModeProvider, userProvider, _) {
                  final user = userProvider.user;
                  
                  if (user != null) {
                    // User is logged in, show their stats
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          InfoCardWidget(
                            title: 'vs Computer', 
                            value: '${user.vsComputerStats.gamesPlayed}', 
                            icon: Icons.computer,
                            isHellMode: hellModeProvider.isHellModeActive,
                          ),
                          const SizedBox(width: 15),
                          InfoCardWidget(
                            title: 'Wins', 
                            value: '${user.vsComputerStats.gamesWon}', 
                            icon: Icons.emoji_events,
                            isHellMode: hellModeProvider.isHellModeActive,
                          ),
                          const SizedBox(width: 15),
                          InfoCardWidget(
                            title: hellModeProvider.isHellModeActive ? 'Hell Streak' : 'Streak', 
                            value: '${user.vsComputerStats.currentWinStreak}', 
                            icon: Icons.local_fire_department,
                            isHellMode: hellModeProvider.isHellModeActive,
                          ),
                        ],
                      ),
                    );
                  } else {
                    // User is not logged in, show login prompt
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        decoration: BoxDecoration(
                          color: hellModeProvider.isHellModeActive
                              ? Colors.red.shade900.withValues(alpha: 0.3)
                              : Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: hellModeProvider.isHellModeActive
                                  ? Colors.red.shade900.withValues(alpha: 0.3)
                                  : Colors.blue.shade200.withValues(alpha: 0.2),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: GestureDetector(
                          onTap: () {
                            Navigator.of(context).pushNamed('/login');
                          },
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.login_rounded,
                                size: 18,
                                color: hellModeProvider.isHellModeActive
                                    ? Colors.orange.shade300
                                    : Colors.blue.shade700,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Sign in to track your stats',
                                style: TextStyle(
                                  color: hellModeProvider.isHellModeActive
                                      ? Colors.orange.shade300
                                      : Colors.blue.shade800,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }
                },
              ),
              const SizedBox(height: 150), // Space for the bottom nav bar
            ],
          ),
          if (!_isInitialized)
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 40,
                    height: 40,
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.blue.shade400),
                      strokeWidth: 3,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Loading...',
                    style: FontPreloader.getTextStyle(
                      fontFamily: 'Poppins',
                      color: Colors.blue.shade700,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}


