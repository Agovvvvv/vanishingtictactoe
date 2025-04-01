import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:vanishingtictactoe/shared/providers/hell_mode_provider.dart';
import 'package:vanishingtictactoe/core/utils/app_logger.dart';
import 'package:vanishingtictactoe/features/game/widgets/shared/play_game_button.dart';
import 'package:vanishingtictactoe/features/game/widgets/shared/hell_mode_button.dart';
import 'dart:ui';
import 'matchmaking_screen.dart';


class OnlineScreen extends StatefulWidget {
  final bool returnToModeSelection;
  
  const OnlineScreen({
    super.key,
    this.returnToModeSelection = false,
  });

  @override
  State<OnlineScreen> createState() => _OnlineScreenState();
}

class _OnlineScreenState extends State<OnlineScreen> with TickerProviderStateMixin {
  // Animation controllers for staggered animations
  late AnimationController _fadeController;
  late AnimationController _slideController;
  
  @override
  void initState() {
    super.initState();
    
    // Initialize animation controllers
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    
    // Start animations when screen loads
    _fadeController.forward();
    _slideController.forward();
  }
  
  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  void _startMatchmaking() {
    final hellModeProvider = Provider.of<HellModeProvider>(context, listen: false);
    final isHellMode = hellModeProvider.isHellModeActive;
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MatchmakingScreen(
          isHellMode: isHellMode,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Get hell mode status and adjust styling accordingly
    final hellModeActive = Provider.of<HellModeProvider>(context).isHellModeActive;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    // Set system UI overlay style
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: isDarkMode ? Brightness.light : Brightness.dark,
    ));
    
    return Scaffold(
      backgroundColor: hellModeActive ? Colors.grey[50] : Colors.white,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: FadeTransition(
          opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
            CurvedAnimation(
              parent: _fadeController,
              curve: const Interval(0.3, 0.8),
            ),
          ),
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, -0.2),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: _slideController,
              curve: Curves.easeOutQuart,
            )),
            child: Text(
              'Online Match',
              style: TextStyle(
                color: hellModeActive ? Colors.red.shade900 : Colors.blue.shade900,
                fontSize: 28,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
                shadows: [
                  Shadow(
                    color: (hellModeActive ? Colors.red : Colors.blue).withValues( alpha: 0.2),
                    offset: const Offset(0, 2),
                    blurRadius: 4,
                  ),
                ],
              ),
            ),
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: hellModeActive ? Colors.red.shade50 : Colors.blue.shade50,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues( alpha: 0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: IconButton(
            icon: Icon(
              Icons.arrow_back_ios_new_rounded, 
              color: hellModeActive ? Colors.red.shade800 : Colors.blue.shade800,
              size: 20,
            ),
            onPressed: () {
              AppLogger.info('Navigating back to mode selection screen');
              Navigator.pop(context);
            },
          ),
        ),
      ),
      body: Stack(
        children: [
          // Background gradient
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: hellModeActive
                  ? [
                      Colors.grey[50]!,
                      Colors.grey[50]!.withValues( alpha: 0.9),
                      Colors.red.shade50.withValues( alpha: 0.3),
                    ]
                  : [
                      Colors.white,
                      Colors.white.withValues( alpha: 0.9),
                      Colors.blue.shade50.withValues( alpha: 0.3),
                    ],
              ),
            ),
            child: SafeArea(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Animated match type description
                      SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0, 0.2),
                          end: Offset.zero,
                        ).animate(CurvedAnimation(
                          parent: _slideController,
                          curve: const Interval(0.1, 0.5, curve: Curves.easeOutQuart),
                        )),
                        child: FadeTransition(
                          opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
                            CurvedAnimation(
                              parent: _fadeController,
                              curve: const Interval(0.1, 0.5),
                            ),
                          ),
                          child: _buildMatchTypeDescription(hellModeActive),
                        ),
                      ),
                      
                      const SizedBox(height: 30),
                      
                      // Hell mode indicator if active
                      Consumer<HellModeProvider>(
                        builder: (context, hellModeProvider, child) {
                          if (hellModeProvider.isHellModeActive) {
                            return SlideTransition(
                              position: Tween<Offset>(
                                begin: const Offset(0, 0.3),
                                end: Offset.zero,
                              ).animate(CurvedAnimation(
                                parent: _slideController,
                                curve: const Interval(0.3, 0.7, curve: Curves.easeOutQuart),
                              )),
                              child: FadeTransition(
                                opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
                                  CurvedAnimation(
                                    parent: _fadeController,
                                    curve: const Interval(0.3, 0.7),
                                  ),
                                ),
                                child: _buildHellModeIndicator(),
                              ),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                      
                      const SizedBox(height: 60),
                      
                      // Bottom action buttons area with gradient background
                      SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0, 0.5),
                          end: Offset.zero,
                        ).animate(CurvedAnimation(
                          parent: _slideController,
                          curve: const Interval(0.6, 1.0, curve: Curves.easeOutQuart),
                        )),
                        child: FadeTransition(
                          opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
                            CurvedAnimation(
                              parent: _fadeController,
                              curve: const Interval(0.6, 1.0),
                            ),
                          ),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  (hellModeActive ? Colors.red : Colors.blue).withValues( alpha: 0.0),
                                  (hellModeActive ? Colors.red : Colors.blue).withValues( alpha: 0.05),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: Column(
                              children: [
                                // Hell mode button, aligned to the right
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: const HellModeButton(),
                                ),
                                const SizedBox(height: 12),
                                // Play game button
                                PlayGameButton(
                                  onPressed: _startMatchmaking,
                                  isHellMode: Provider.of<HellModeProvider>(context).isHellModeActive,
                                ),
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
          ),
        ],
      ),
    );
  }



  Widget _buildMatchTypeDescription(bool isHellMode) {
    const description = 'Play casual games with other players.';
    final primaryColor = isHellMode ? Colors.red : Colors.blue;
    final icon = isHellMode ? Icons.local_fire_department_rounded : Icons.sports_esports;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      color: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(
            colors: isHellMode
              ? [Colors.white.withValues( alpha: 0.9), Colors.red.shade50.withValues( alpha: 0.8)]
              : [Colors.white.withValues( alpha: 0.9), Colors.blue.shade50.withValues( alpha: 0.8)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          border: Border.all(
            color: primaryColor.withValues( alpha: 0.3),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: primaryColor.withValues( alpha: 0.15),
              blurRadius: 16,
              offset: const Offset(0, 8),
              spreadRadius: 0,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                children: [
                  // Animated icon
                  TweenAnimationBuilder<double>(
                    tween: Tween<double>(begin: 0.8, end: 1.0),
                    duration: const Duration(milliseconds: 600),
                    curve: Curves.elasticOut,
                    builder: (context, value, child) {
                      return Transform.scale(
                        scale: value,
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                primaryColor.withValues( alpha: 0.2),
                                primaryColor.withValues( alpha: 0.1),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: primaryColor.withValues( alpha: 0.3),
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: primaryColor.withValues( alpha: 0.2),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Icon(
                            icon,
                            size: 60,
                            color: primaryColor,
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                  // Description text
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 20,
                      height: 1.5,
                      fontWeight: FontWeight.w500,
                      color: isHellMode ? Colors.red.shade900 : Colors.blue.shade900,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  // Additional info text
                  Text(
                    isHellMode 
                      ? 'Challenge others in Hell Mode where each cell is its own game!'
                      : 'Find opponents of similar skill level for a fun match.',
                    style: TextStyle(
                      fontSize: 16,
                      height: 1.5,
                      color: isHellMode ? Colors.red.shade700 : Colors.blue.shade700,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildHellModeIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.red.shade800, Colors.deepOrange.shade700],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.red.withValues( alpha: 0.4),
            blurRadius: 12,
            offset: const Offset(0, 6),
            spreadRadius: 0,
          ),
        ],
        border: Border.all(
          color: Colors.red.shade300,
          width: 2,
        ),
      ),
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0.95, end: 1.05),
        duration: const Duration(milliseconds: 800),
        curve: Curves.easeInOut,
        builder: (context, value, child) {
          return Transform.scale(
            scale: value,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 0.8, end: 1.2),
                  duration: const Duration(milliseconds: 600),
                  curve: Curves.easeInOut,
                  builder: (context, iconScale, _) {
                    return Transform.scale(
                      scale: iconScale,
                      child: const Icon(
                        Icons.local_fire_department_rounded, 
                        color: Colors.yellow,
                        size: 28,
                      ),
                    );
                  },
                ),
                const SizedBox(width: 12),
                const Text(
                  'HELL MODE ACTIVE',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                    shadows: [
                      Shadow(
                        color: Colors.black26,
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

}
