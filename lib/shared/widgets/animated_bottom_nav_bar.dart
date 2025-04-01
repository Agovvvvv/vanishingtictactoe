import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import 'package:provider/provider.dart';
import 'package:vanishingtictactoe/core/utils/font_preloader.dart';
import 'package:vanishingtictactoe/shared/providers/hell_mode_provider.dart';

class AnimatedBottomNavBar extends StatefulWidget {
  final int currentIndex;
  final Function(int) onTap;
  final bool showLabels;
  final bool isHellMode;

  const AnimatedBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.showLabels = true,
    this.isHellMode = false,
  });

  @override
  State<AnimatedBottomNavBar> createState() => _AnimatedBottomNavBarState();
}

class _AnimatedBottomNavBarState extends State<AnimatedBottomNavBar> with TickerProviderStateMixin {
  // Initial appearance animation controller
  late AnimationController _animationController;
  final List<Animation<double>> _animations = [];
  
  // Tab switching animation controller
  late AnimationController _tabController;
  
  // Ripple effect animation
  late AnimationController _rippleController;
  late Animation<double> _rippleAnimation;
  
  // Track previous index for animations
  int _previousIndex = 0;
  
  @override
  void initState() {
    super.initState();
    _previousIndex = widget.currentIndex;
    
    // Initial appearance animation
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    
    // Create animations for each tab
    for (int i = 0; i < 5; i++) {
      final curvedAnimation = CurvedAnimation(
        parent: _animationController,
        curve: Interval(
          0.1 * i, 
          0.1 * i + 0.5, 
          curve: Curves.easeOut,
        ),
      );
      
      _animations.add(Tween<double>(begin: 0.0, end: 1.0).animate(curvedAnimation));
    }
    
    // Tab switching animation - using simpler animations to avoid assertion errors
    _tabController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    
    // We'll calculate animation values directly in the build method
    
    // Ripple effect animation
    _rippleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    
    _rippleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(
      parent: _rippleController,
      curve: Curves.easeOut,
    ));
    
    // Start the initial animation
    _animationController.forward();
  }
  
  @override
  void didUpdateWidget(AnimatedBottomNavBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Trigger animations when the selected tab changes
    if (widget.currentIndex != oldWidget.currentIndex) {
      _previousIndex = oldWidget.currentIndex;
      
      // Ensure animations are properly reset and completed
      if (_tabController.isAnimating) {
        _tabController.stop();
      }
      _tabController.reset();
      _tabController.forward();
      
      if (_rippleController.isAnimating) {
        _rippleController.stop();
      }
      _rippleController.reset();
      _rippleController.forward();
    }
  }
  
  @override
  void dispose() {
    // Make sure to stop animations before disposing
    if (_animationController.isAnimating) {
      _animationController.stop();
    }
    if (_tabController.isAnimating) {
      _tabController.stop();
    }
    if (_rippleController.isAnimating) {
      _rippleController.stop();
    }
    
    _animationController.dispose();
    _tabController.dispose();
    _rippleController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    // Check if Hell Mode is active from the provider
    final hellModeProvider = Provider.of<HellModeProvider>(context, listen: true);
    final isHellMode = widget.isHellMode || hellModeProvider.isHellModeActive;
    
    return Stack(
      alignment: Alignment.center,
      children: [
        // Ripple effect for tab changes
        if (widget.currentIndex != _previousIndex && _rippleAnimation.value >= 0.0 && _rippleAnimation.value <= 1.0)
          AnimatedBuilder(
            animation: _rippleAnimation,
            builder: (context, child) {
              // Calculate the position of the ripple based on the selected tab
              final double tabPosition = _getTabPosition(widget.currentIndex);
              
              return Positioned(
                bottom: 8,
                left: tabPosition,
                child: Transform.scale(
                  scale: _rippleAnimation.value * 2.0,
                  child: Opacity(
                    opacity: (1 - _rippleAnimation.value) * 0.4,
                    child: Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isHellMode ? Colors.red.withValues(alpha: 0.5) : Colors.blue.withValues(alpha: 0.3),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        
        // Main nav bar container
        Container(
          height: 75,
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isHellMode ? Colors.black.withValues(alpha: 0.85) : Colors.white.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: isHellMode 
                    ? Colors.red.withValues(alpha: 0.25) 
                    : Colors.black.withValues(alpha: 0.08),
                blurRadius: 12,
                spreadRadius: 1,
                offset: const Offset(0, 2),
              ),
            ],
            border: Border.all(
              color: isHellMode 
                  ? Colors.red.withValues(alpha: 0.2) 
                  : Colors.grey.withValues(alpha: 0.15),
              width: 1.0,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: BackdropFilter(
              filter: isHellMode
                  ? ImageFilter.blur(sigmaX: 10, sigmaY: 10)
                  : ImageFilter.blur(sigmaX: 5, sigmaY: 5),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildNavItem(0, Icons.home_rounded, 'Home'),
                  _buildNavItem(1, Icons.flag_rounded, 'Missions'),
                  _buildPlayButton(2),
                  _buildNavItem(3, Icons.people_alt_rounded, 'Friends'),
                  _buildNavItem(4, Icons.person_rounded, 'Profile'),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
  
  // Helper method to get the position of a tab for the ripple effect
  double _getTabPosition(int index) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double tabWidth = (screenWidth - 32) / 5; // Account for horizontal margin
    
    // Adjust position for the center play button which is wider
    if (index < 2) {
      return 16 + (index * tabWidth);
    } else if (index == 2) {
      return 16 + (index * tabWidth) - 10; // Center play button adjustment
    } else {
      return 16 + (index * tabWidth) - 20; // Tabs after the play button
    }
  }
  
  Widget _buildNavItem(int index, IconData icon, String label) {
    final isSelected = widget.currentIndex == index;
    final hellModeProvider = Provider.of<HellModeProvider>(context);
    final isHellMode = widget.isHellMode || hellModeProvider.isHellModeActive;
    
    return AnimatedBuilder(
      animation: _animations[index],
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, (1 - _animations[index].value) * 15),
          child: Opacity(
            opacity: _animations[index].value,
            child: InkWell(
              onTap: () {
                HapticFeedback.lightImpact();
                widget.onTap(index);
              },
              customBorder: const CircleBorder(),
              child: SizedBox(
                width: 60,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Apply scale and rotation animations when this tab is selected
                    AnimatedBuilder(
                      animation: _tabController,
                      builder: (context, child) {
                        // Use a try-catch to handle any potential animation errors
                        double scaleValue = 1.0;
                        double rotateValue = 0.0;
                        
                        try {
                          if (isSelected) {
                            // Apply a simple bounce effect
                            scaleValue = _tabController.status == AnimationStatus.forward ?
                                1.0 + (_tabController.value * 0.2) :
                                1.0;
                                
                            // Apply a simple wobble effect
                            rotateValue = _tabController.value < 0.5 ?
                                _tabController.value * 0.05 :
                                0.05 - ((_tabController.value - 0.5) * 0.1);
                          }
                        } catch (e) {
                          // Fallback to default values if any error occurs
                          scaleValue = 1.0;
                          rotateValue = 0.0;
                        }
                        
                        return Transform.scale(
                          scale: scaleValue,
                          child: Transform.rotate(
                            angle: rotateValue,
                            child: child!,
                          ),
                        );
                      },
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Background glow effect for selected item
                          if (isSelected)
                            Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: RadialGradient(
                                  colors: [
                                    isHellMode 
                                        ? Colors.red.withValues(alpha: 0.3) 
                                        : Colors.blue.withValues(alpha: 0.2),
                                    Colors.transparent,
                                  ],
                                  stops: const [0.5, 1.0],
                                ),
                              ),
                            ),
                          
                          // Icon container with animated properties
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: isSelected 
                                  ? (isHellMode ? Colors.red.withValues(alpha: 0.15) : Colors.blue.withValues(alpha: 0.12)) 
                                  : Colors.transparent,
                              shape: BoxShape.circle,
                              boxShadow: isSelected ? [
                                BoxShadow(
                                  color: isHellMode 
                                      ? Colors.red.withValues(alpha: 0.2) 
                                      : Colors.blue.withValues(alpha: 0.15),
                                  blurRadius: 8,
                                  spreadRadius: 1,
                                ),
                              ] : null,
                            ),
                            child: Icon(
                              icon,
                              color: isSelected 
                                  ? (isHellMode ? Colors.red : Colors.blue) 
                                  : (isHellMode ? Colors.grey.shade400 : Colors.grey.shade500),
                              size: 22,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (widget.showLabels) ...[
                      const SizedBox(height: 4),
                      AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 200),
                        style: FontPreloader.getTextStyle(
                          fontFamily: 'Poppins',
                          fontSize: isSelected ? 11 : 10,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                          color: isSelected 
                              ? (isHellMode ? Colors.red : Colors.blue) 
                              : (isHellMode ? Colors.grey.shade400 : Colors.grey.shade500),
                          letterSpacing: 0.2,
                        ),
                        child: Text(label),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildPlayButton(int index) {
    final hellModeProvider = Provider.of<HellModeProvider>(context);
    final isHellMode = widget.isHellMode || hellModeProvider.isHellModeActive;
    final isSelected = widget.currentIndex == index;
    
    return AnimatedBuilder(
      animation: _animations[index],
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, (1 - _animations[index].value) * 20),
          child: Opacity(
            opacity: _animations[index].value,
            child: InkWell(
              onTap: () {
                HapticFeedback.mediumImpact();
                widget.onTap(index);
              },
              customBorder: const CircleBorder(),
              child: AnimatedBuilder(
                animation: _tabController,
                builder: (context, child) {
                  // Use a try-catch to handle any potential animation errors
                  double scaleValue = 1.0;
                  
                  try {
                    if (isSelected) {
                      // Apply a simple bounce effect
                      scaleValue = _tabController.status == AnimationStatus.forward ?
                          1.0 + (_tabController.value * 0.2) :
                          1.0;
                    }
                  } catch (e) {
                    // Fallback to default value if any error occurs
                    scaleValue = 1.0;
                  }
                  
                  return Transform.scale(
                    scale: scaleValue,
                    child: child!,
                  );
                },
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isHellMode 
                          ? [Colors.red.shade600, Colors.deepOrange.shade800]
                          : [Colors.blue.shade400, Colors.blue.shade600],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: isHellMode 
                            ? Colors.red.withValues(alpha: 0.3)
                            : Colors.blue.withValues(alpha: 0.25),
                        blurRadius: 12,
                        spreadRadius: 2,
                        offset: const Offset(0, 4),
                      ),
                      if (isSelected)
                        BoxShadow(
                          color: isHellMode 
                              ? Colors.red.withValues(alpha: 0.4)
                              : Colors.blue.withValues(alpha: 0.3),
                          blurRadius: 20,
                          spreadRadius: 4,
                          offset: const Offset(0, 4),
                        ),
                    ],
                    border: Border.all(
                      color: isHellMode 
                          ? Colors.red.shade300.withValues(alpha: 0.5) 
                          : Colors.blue.shade300.withValues(alpha: 0.5),
                      width: 1.5,
                    ),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Animated pulse effect when selected
                      if (isSelected && _rippleAnimation.value >= 0.0 && _rippleAnimation.value <= 1.0)
                        AnimatedBuilder(
                          animation: _rippleAnimation,
                          builder: (context, child) {
                            final safeValue = _rippleAnimation.value.clamp(0.0, 1.0);
                            return Opacity(
                              opacity: (1 - safeValue) * 0.3,
                              child: Container(
                                width: 70 * safeValue,
                                height: 70 * safeValue,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isHellMode ? Colors.red : Colors.blue,
                                ),
                              ),
                            );
                          },
                        ),
                      
                      // Main icon
                      Icon(
                        isHellMode ? Icons.local_fire_department_rounded : Icons.play_arrow_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}