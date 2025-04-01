import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:vanishingtictactoe/features/friends/services/friend_service.dart';
import 'package:vanishingtictactoe/core/utils/app_logger.dart';
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

  final List<_BackgroundParticle> _particles = [];
  final math.Random _random = math.Random();

  @override
  void initState() {
    super.initState();
    _initializeData();
    _initializeAnimations();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_particles.isEmpty) {
      _generateBackgroundParticles();
    }
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

  void _generateBackgroundParticles() {
    for (int i = 0; i < 40; i++) {
      _particles.add(_BackgroundParticle(
        position: Offset(
          _random.nextDouble() * MediaQuery.of(context).size.width,
          _random.nextDouble() * MediaQuery.of(context).size.height,
        ),
        size: _random.nextDouble() * 8 + 2,
        speed: _random.nextDouble() * 0.3 + 0.1,
        angle: _random.nextDouble() * math.pi * 2,
      ));
    }
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

  // Navigation is now handled directly through the NavigationProvider

  @override
  Widget build(BuildContext context) {
    final Size screenSize = MediaQuery.of(context).size;

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
          AnimatedBuilder(
            animation: _backgroundAnimationController,
            builder: (context, child) {
              return CustomPaint(
                size: Size(screenSize.width, screenSize.height),
                painter: _BackgroundParticlePainter(
                  particles: _particles,
                  animationValue: _backgroundAnimationController.value,
                ),
              );
            },
          ),
          Positioned.fill(
            child: Opacity(
              opacity: 0.05,
              child: CustomPaint(painter: _GridPatternPainter()),
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
                          _buildInfoCard(
                            'vs Computer', 
                            '${user.vsComputerStats.gamesPlayed}', 
                            Icons.computer,
                            hellModeProvider.isHellModeActive,
                          ),
                          const SizedBox(width: 15),
                          _buildInfoCard(
                            'Wins', 
                            '${user.vsComputerStats.gamesWon}', 
                            Icons.emoji_events,
                            hellModeProvider.isHellModeActive,
                          ),
                          const SizedBox(width: 15),
                          _buildInfoCard(
                            hellModeProvider.isHellModeActive ? 'Hell Streak' : 'Streak', 
                            '${user.vsComputerStats.currentWinStreak}', 
                            Icons.local_fire_department,
                            hellModeProvider.isHellModeActive,
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

class _BackgroundParticle {
  Offset position;
  final double size;
  final double speed;
  final double angle;
  
  _BackgroundParticle({
    required this.position,
    required this.size,
    required this.speed,
    required this.angle,
  });
  
  void update(Size screenSize, double animationValue) {
    // Move particles in a circular pattern
    final time = animationValue * 2 * math.pi;
    final dx = math.cos(angle + time) * speed;
    final dy = math.sin(angle + time) * speed;
    
    position = Offset(
      (position.dx + dx) % screenSize.width,
      (position.dy + dy) % screenSize.height,
    );
  }
}

// Painter for background particles
class _BackgroundParticlePainter extends CustomPainter {
  final List<_BackgroundParticle> particles;
  final double animationValue;
  
  _BackgroundParticlePainter({
    required this.particles,
    required this.animationValue,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    // Update and draw particles
    for (final particle in particles) {
      particle.update(size, animationValue);
      
      // Calculate opacity based on position (fade out at edges)
      final distanceFromCenter = (particle.position - Offset(size.width / 2, size.height / 2)).distance;
      final maxDistance = size.width < size.height ? size.width / 2 : size.height / 2;
      final opacity = 0.7 - (distanceFromCenter / maxDistance).clamp(0.0, 0.6);
      
      final paint = Paint()
        ..color = Colors.blue.shade200.withValues( alpha: opacity * 0.3)
        ..style = PaintingStyle.fill
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
      
      canvas.drawCircle(particle.position, particle.size, paint);
    }
  }
  
  @override
  bool shouldRepaint(_BackgroundParticlePainter oldDelegate) => true;
}

// Painter for subtle grid pattern
class _GridPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withValues( alpha: 0.1)
      ..strokeWidth = 0.5
      ..style = PaintingStyle.stroke;
    
    // Draw horizontal lines
    for (double y = 0; y < size.height; y += 40) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
    
    // Draw vertical lines
    for (double x = 0; x < size.width; x += 40) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
  }
  
  @override
  bool shouldRepaint(_GridPatternPainter oldDelegate) => false;
}

// Helper method to build info cards
Widget _buildInfoCard(String title, String value, IconData icon, bool isHellMode) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    decoration: BoxDecoration(
      color: isHellMode 
          ? Colors.red.shade900.withValues(alpha: 0.3)
          : Colors.white.withValues(alpha: 0.2),
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: isHellMode
              ? Colors.red.shade900.withValues(alpha: 0.3)
              : Colors.blue.shade200.withValues(alpha: 0.2),
          blurRadius: 4,
          offset: const Offset(0, 2),
        ),
      ],
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          title,
          style: TextStyle(
            color: isHellMode ? Colors.orange.shade300 : Colors.blue.shade800,
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 2),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon, 
              size: 12, 
              color: isHellMode ? Colors.orange.shade500 : Colors.blue.shade600
            ),
            const SizedBox(width: 3),
            Text(
              value,
              style: TextStyle(
                color: isHellMode ? Colors.white : Colors.black87,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ],
    ),
  );
}


// Enhanced AppBarActions with improved styling and animations
class AppBarActions extends StatelessWidget {
  final Function(String) onNavigate;
  
  const AppBarActions({
    super.key,
    required this.onNavigate,
  });

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final user = userProvider.user;
    
    return Row(
      children: [
        // Only show level badge if user is logged in and has level data
        if (user != null)
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(30),
                onTap: () {
                  onNavigate(AppRoutes.levelRoadmap);
                },
                child: Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: LevelBadge.fromUserLevel(
                    userLevel: user.userLevel,
                    fontSize: 12,
                    iconSize: 16,
                  ),
                ),
              ),
            ),
          ),        
        const SizedBox(width: 8),
      ],
    );
  }
}