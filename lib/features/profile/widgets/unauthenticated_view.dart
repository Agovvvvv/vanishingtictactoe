import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import 'package:vanishingtictactoe/core/utils/font_preloader.dart' show FontPreloader;
import 'package:provider/provider.dart';
import 'package:vanishingtictactoe/shared/providers/hell_mode_provider.dart';

class UnauthenticatedView extends StatefulWidget {
  const UnauthenticatedView({super.key});

  @override
  State<UnauthenticatedView> createState() => _UnauthenticatedViewState();
}

class _UnauthenticatedViewState extends State<UnauthenticatedView> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeInAnimation;
  late Animation<double> _slideAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _buttonAnimation;
  
  @override
  void initState() {
    super.initState();
    
    // Initialize animations
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    
    _fadeInAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    ));
    
    _slideAnimation = Tween<double>(
      begin: 50.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.2, 0.7, curve: Curves.easeOut),
    ));
    
    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.2, 0.8, curve: Curves.easeOut),
    ));
    
    _buttonAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.6, 1.0, curve: Curves.easeOut),
    ));
    
    // Start the animation
    _animationController.forward();
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hellModeProvider = Provider.of<HellModeProvider>(context);
    final isHellMode = hellModeProvider.isHellModeActive;
    
    // Define colors based on hell mode
    final primaryColor = isHellMode ? Colors.red : Colors.blue;
    final secondaryColor = isHellMode ? Colors.orange : Colors.blue.shade300;
    final backgroundColor = isHellMode ? Colors.grey.shade900 : Colors.white;
    final textColor = isHellMode ? Colors.white : Colors.grey.shade800;
    final subtextColor = isHellMode ? Colors.grey.shade400 : Colors.grey.shade600;
    
    return Scaffold(
      backgroundColor: backgroundColor,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: AnimatedBuilder(
          animation: _fadeInAnimation,
          builder: (context, child) {
            return Opacity(
              opacity: _fadeInAnimation.value,
              child: Text(
                'Account',
                style: FontPreloader.getTextStyle(
                  fontFamily: 'Orbitron',
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                  letterSpacing: 0.5,
                ),
              ),
            );
          },
        ),
      ),
      body: Stack(
        children: [
          // Background gradient or pattern
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
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                  child: Container(
                    color: Colors.black.withValues(alpha: 0.1),
                  ),
                ),
              ),
            ),
          
          // Main content
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: AnimatedBuilder(
                  animation: _animationController,
                  builder: (context, child) {
                    return Transform.translate(
                      offset: Offset(0, _slideAnimation.value),
                      child: Transform.scale(
                        scale: _scaleAnimation.value,
                        child: Opacity(
                          opacity: _fadeInAnimation.value,
                          child: child,
                        ),
                      ),
                    );
                  },
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Avatar container with sharper, clearer effects
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isHellMode ? Colors.black : Colors.white,
                          boxShadow: [
                            BoxShadow(
                              color: primaryColor.withValues(alpha: 0.4),
                              blurRadius: 15,  // Reduced blur for sharper edges
                              spreadRadius: 2,
                            ),
                            BoxShadow(
                              color: secondaryColor.withValues(alpha: 0.2),
                              blurRadius: 20,  // Reduced blur for better definition
                              spreadRadius: 5,
                              offset: const Offset(0, 8),
                            ),
                          ],
                          border: Border.all(
                            color: primaryColor.withValues(alpha: 0.7),  // Increased opacity for clearer border
                            width: 2.5,  // Slightly thicker border
                          ),
                        ),
                        child: ShaderMask(
                          shaderCallback: (Rect bounds) {
                            return LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                primaryColor,
                                primaryColor.withValues(alpha: 0.8),
                              ],
                            ).createShader(bounds);
                          },
                          child: Icon(
                            isHellMode ? Icons.person_outline : Icons.account_circle,
                            size: 110,  // Slightly larger icon
                            color: Colors.white,  // The ShaderMask will apply the actual color
                          ),
                        ),
                      ),
                      const SizedBox(height: 40),
                      
                      // Main content card with glass effect
                      Container(
                        padding: const EdgeInsets.all(30),
                        decoration: BoxDecoration(
                          color: isHellMode 
                              ? Colors.black.withValues(alpha: 0.6) 
                              : Colors.white.withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: primaryColor.withValues(alpha: 0.1),
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
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),  // Reduced blur for better clarity
                          child: Column(
                            children: [
                              Text(
                                isHellMode ? 'Sign in to Survive Hell Mode' : 'Sign in to Track Your Progress',
                                style: FontPreloader.getTextStyle(
                                  fontFamily: 'Orbitron',
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: textColor,
                                  letterSpacing: 0.5,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 20),
                              Text(
                                isHellMode
                                    ? 'Create an account to save your Hell Mode victories and compete with the bravest players'
                                    : 'Create an account to save your stats and compete with friends',
                                style: FontPreloader.getTextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 16,
                                  color: subtextColor,
                                  letterSpacing: 0.2,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 40),
                              
                              // Sign in button with animation
                              AnimatedBuilder(
                                animation: _buttonAnimation,
                                builder: (context, child) {
                                  return Transform.scale(
                                    scale: Curves.elasticOut.transform(_buttonAnimation.value),
                                    child: child,
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
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          isHellMode ? Icons.login : Icons.login_rounded,
                                          size: 20,
                                        ),
                                        const SizedBox(width: 12),
                                        Text(
                                          'SIGN IN',
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
                              const SizedBox(height: 24),
                              
                              // Create account button
                              AnimatedBuilder(
                                animation: _buttonAnimation,
                                builder: (context, child) {
                                  return Opacity(
                                    opacity: _buttonAnimation.value,
                                    child: child,
                                  );
                                },
                                child: TextButton(
                                  onPressed: () {
                                    HapticFeedback.lightImpact();
                                    Navigator.pushNamed(context, '/register');
                                  },
                                  style: TextButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                    backgroundColor: isHellMode 
                                        ? Colors.red.withValues(alpha: 0.1) 
                                        : Colors.blue.withValues(alpha: 0.1),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        'Create Account',
                                        style: FontPreloader.getTextStyle(
                                          fontFamily: 'Poppins',
                                          fontSize: 16,
                                          color: primaryColor,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Icon(
                                        Icons.arrow_forward_rounded,
                                        size: 18,
                                        color: primaryColor,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      
                      // Features section
                      const SizedBox(height: 40),
                      AnimatedBuilder(
                        animation: _buttonAnimation,
                        builder: (context, child) {
                          return Opacity(
                            opacity: _buttonAnimation.value,
                            child: Transform.translate(
                              offset: Offset(0, 20 * (1 - _buttonAnimation.value)),
                              child: child,
                            ),
                          );
                        },
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(24),
                          margin: const EdgeInsets.only(bottom: 50), 
                          decoration: BoxDecoration(
                            color: isHellMode 
                                ? Colors.black.withValues(alpha: 0.4) 
                                : Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: primaryColor.withValues(alpha: 0.15),
                              width: 1,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Account Benefits:',
                                style: FontPreloader.getTextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: textColor,
                                ),
                              ),
                              const SizedBox(height: 16),
                              _buildFeatureItem(
                                icon: Icons.history_rounded,
                                color: isHellMode ? Colors.red : Colors.blue,
                                text: 'Track your match history and stats',
                                isHellMode: isHellMode,
                              ),
                              const SizedBox(height: 12),
                              _buildFeatureItem(
                                icon: Icons.emoji_events_rounded,
                                color: isHellMode ? Colors.orange : Colors.amber,
                                text: 'Compete on global leaderboards',
                                isHellMode: isHellMode,
                              ),
                              const SizedBox(height: 12),
                              _buildFeatureItem(
                                icon: Icons.verified_user_rounded,
                                color: isHellMode ? Colors.green.shade700 : Colors.green,
                                text: 'Earn achievements and rewards',
                                isHellMode: isHellMode,
                              ),
                              const SizedBox(height: 12),
                              _buildFeatureItem(
                                icon: isHellMode ? Icons.local_fire_department_rounded : Icons.flash_on_rounded,
                                color: isHellMode ? Colors.deepOrange : Colors.purple,
                                text: isHellMode ? 'Unlock exclusive Hell Mode content' : 'Unlock special game modes',
                                isHellMode: isHellMode,
                              ),
                            ],
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
  
  Widget _buildFeatureItem({required IconData icon, required Color color, required String text, required bool isHellMode}) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            shape: BoxShape.circle,
            border: Border.all(
              color: color.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Icon(
            icon,
            color: color,
            size: 20,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            text,
            style: FontPreloader.getTextStyle(
              fontFamily: 'Poppins',
              fontSize: 15,
              color: isHellMode ? Colors.grey.shade300 : Colors.grey.shade700,
              letterSpacing: 0.2,
            ),
          ),
        ),
      ],
    );
  }
}