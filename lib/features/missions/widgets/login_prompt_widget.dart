import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:vanishingtictactoe/core/utils/font_preloader.dart';
import 'package:vanishingtictactoe/features/missions/widgets/benefit_item_widget.dart';
import 'package:vanishingtictactoe/shared/providers/hell_mode_provider.dart';

class LoginPromptWidget extends StatelessWidget {
  const LoginPromptWidget({super.key});
  
  @override
  Widget build(BuildContext context) {
    // Get Hell Mode status from provider
    final hellModeProvider = Provider.of<HellModeProvider>(context);
    final isHellMode = hellModeProvider.isHellModeActive;
    
    // Define colors based on hell mode
    final primaryColor = isHellMode ? Colors.red.shade700 : Color(0xFF2962FF);
    final backgroundColor = isHellMode ? Colors.grey.shade900 : Colors.grey.shade50;
    final textColor = isHellMode ? Colors.white : Colors.grey.shade800;
    final subtextColor = isHellMode ? Colors.grey.shade400 : Colors.grey.shade600;
    final cardColor = isHellMode ? Colors.black.withValues(alpha: 0.7) : Colors.white;
    
    return Scaffold(
      backgroundColor: backgroundColor,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        automaticallyImplyLeading: false, // Add this line to remove the back arrow
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isHellMode 
                ? [Colors.red.shade900, Colors.black] 
                : [Color(0xFF2979FF), Color(0xFF1565C0)],
            ),
          ),
        ),
        title: Row(
          children: [
            ShaderMask(
              shaderCallback: (Rect bounds) {
                return LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isHellMode
                    ? [Colors.orange, Colors.yellow]
                    : [Colors.amber.shade300, Colors.amber.shade500],
                ).createShader(bounds);
              },
              child: Icon(
                isHellMode ? Icons.local_fire_department : Icons.emoji_events_rounded,
                color: Colors.white,
                size: 28,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              isHellMode ? 'Hell Missions' : 'Missions',
              style: FontPreloader.getTextStyle(
                fontFamily: 'Orbitron',
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 0.5,
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
      ),
      body: Stack(
        children: [
          // Background gradient
          if (isHellMode)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black,
                      Colors.red.shade900.withValues(alpha: 0.7),
                      Colors.black,
                    ],
                    stops: const [0.0, 0.5, 1.0],
                  ),
                ),
              ),
            )
          else
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.blue.shade700.withValues(alpha: 0.8),
                      Colors.blue.shade50,
                      Colors.white,
                    ],
                    stops: const [0.0, 0.3, 1.0],
                  ),
                ),
              ),
            ),
            
          // Main content with animations
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 0.0, end: 1.0),
                  duration: const Duration(milliseconds: 1000),
                  curve: Curves.easeOutCubic,
                  builder: (context, value, child) {
                    return Opacity(
                      opacity: value,
                      child: Transform.translate(
                        offset: Offset(0, 30 * (1 - value)),
                        child: child,
                      ),
                    );
                  },
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Animated lock icon
                      TweenAnimationBuilder<double>(
                        tween: Tween<double>(begin: 0.8, end: 1.0),
                        duration: const Duration(milliseconds: 1200),
                        curve: Curves.elasticOut,
                        builder: (context, value, child) {
                          return Transform.scale(
                            scale: value,
                            child: child,
                          );
                        },
                        child: Container(
                          width: 180,
                          height: 180,
                          decoration: BoxDecoration(
                            color: isHellMode ? Colors.red.withValues(alpha: 0.1) : primaryColor.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: primaryColor.withValues(alpha: 0.2),
                                blurRadius: 15,
                                spreadRadius: 2,
                              ),
                            ],
                            border: Border.all(
                              color: primaryColor.withValues(alpha: 0.3),
                              width: 2,
                            ),
                          ),
                          child: Center(
                            child: ShaderMask(
                              shaderCallback: (Rect bounds) {
                                return LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: isHellMode
                                    ? [Colors.red, Colors.orange]
                                    : [primaryColor, primaryColor.withValues(alpha: 0.8)],
                                ).createShader(bounds);
                              },
                              child: Icon(
                                isHellMode ? Icons.lock : Icons.lock_outline_rounded,
                                size: 80,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 40),
                      
                      // Content card with glass effect
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(30),
                        decoration: BoxDecoration(
                          color: cardColor,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: primaryColor.withValues(alpha: 0.15),
                              blurRadius: 20,
                              spreadRadius: 5,
                              offset: const Offset(0, 10),
                            ),
                          ],
                          border: Border.all(
                            color: primaryColor.withValues(alpha: 0.2),
                            width: 1,
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(24),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                            child: Column(
                              children: [
                                Text(
                                  isHellMode ? 'Login to Access Hell Missions' : 'Login to Access Missions',
                                  style: FontPreloader.getTextStyle(
                                    fontFamily: 'Orbitron',
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: textColor,
                                    letterSpacing: 0.5,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 20),
                                Text(
                                  isHellMode
                                    ? 'Complete challenging missions to earn XP, level up, and unlock hellish rewards!'
                                    : 'Complete daily and weekly missions to earn XP, level up, and unlock special rewards!',
                                  style: TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 16,
                                    color: subtextColor,
                                    height: 1.5,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 40),
                                
                                // Login button with animation
                                TweenAnimationBuilder<double>(
                                  tween: Tween<double>(begin: 0.0, end: 1.0),
                                  duration: const Duration(milliseconds: 800),
                                  curve: Curves.easeOutCubic,
                                  builder: (context, value, child) {
                                    return Transform.scale(
                                      scale: 0.8 + (0.2 * value),
                                      child: Opacity(
                                        opacity: value,
                                        child: child,
                                      ),
                                    );
                                  },
                                  child: Container(
                                    width: double.infinity,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(16),
                                      boxShadow: [
                                        BoxShadow(
                                          color: primaryColor.withValues(alpha: 0.4),
                                          blurRadius: 15,
                                          offset: const Offset(0, 8),
                                          spreadRadius: 0,
                                        ),
                                      ],
                                      gradient: LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: isHellMode
                                          ? [Colors.red.shade700, Colors.red.shade900]
                                          : [Colors.blue.shade400, Colors.blue.shade700],
                                      ),
                                    ),
                                    child: ElevatedButton(
                                      onPressed: () {
                                        HapticFeedback.mediumImpact();
                                        Navigator.pushNamed(context, '/login');
                                      },
                                      style: ElevatedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(vertical: 18),
                                        backgroundColor: Colors.transparent,
                                        foregroundColor: Colors.white,
                                        shadowColor: Colors.transparent,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(16),
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            isHellMode ? Icons.login : Icons.login_rounded,
                                            color: isHellMode? Colors.black : Colors.white,
                                            size: 20,
                                          ),
                                          const SizedBox(width: 12),
                                          Text(
                                            'LOGIN NOW',
                                            textAlign: TextAlign.center,
                                            style: FontPreloader.getTextStyle(
                                              fontFamily: 'Orbitron',
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                              letterSpacing: 1.0,
                                            ),
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
                      
                      const SizedBox(height: 35),
                      
                      // Benefits section with animation
                      TweenAnimationBuilder<double>(
                        tween: Tween<double>(begin: 0.0, end: 1.0),
                        duration: const Duration(milliseconds: 1000),
                        curve: Curves.easeOutCubic,
                        builder: (context, value, child) {
                          return Opacity(
                            opacity: value,
                            child: Transform.translate(
                              offset: Offset(0, 20 * (1 - value)),
                              child: child,
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          margin: const EdgeInsets.only(bottom: 60),
                          decoration: BoxDecoration(
                            color: isHellMode ? Colors.black.withValues(alpha: 0.5) : Colors.white.withValues(alpha: 0.8),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: primaryColor.withValues(alpha: 0.2),
                              width: 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: primaryColor.withValues(alpha: 0.1),
                                blurRadius: 10,
                                spreadRadius: 0,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Benefits:',
                                    style: FontPreloader.getTextStyle(
                                      fontFamily: 'Orbitron',
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                      color: textColor,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  BenefitItemWidget(
                                    icon: Icons.emoji_events_rounded,
                                    color: isHellMode ? Colors.orange : Colors.amber,
                                    text: isHellMode
                                      ? 'Earn Hell XP and dominate the leaderboard'
                                      : 'Earn XP and climb the leaderboard',
                                  ),
                                  const SizedBox(height: 12),
                                  BenefitItemWidget(
                                    icon: isHellMode ? Icons.whatshot : Icons.calendar_today_rounded,
                                    color: isHellMode ? Colors.red : Colors.green,
                                    text: isHellMode
                                      ? 'Complete infernal challenges'
                                      : 'Complete daily and weekly challenges',
                                  ),
                                  const SizedBox(height: 12),
                                  BenefitItemWidget(
                                    icon: Icons.card_giftcard_rounded,
                                    color: isHellMode ? Colors.deepPurple : Colors.purple,
                                    text: isHellMode
                                      ? 'Unlock hellish rewards and achievements'
                                      : 'Unlock exclusive rewards and achievements',
                                  ),
                                ],
                              ),
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
}