import 'dart:async' show Timer;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:vanishingtictactoe/core/utils/font_preloader.dart';
import 'package:vanishingtictactoe/features/profile/widgets/levelup/item_card_widget.dart';
import 'package:vanishingtictactoe/features/profile/widgets/levelup/level_circle_widget.dart';
import 'package:vanishingtictactoe/features/profile/widgets/levelup/level_text_widget.dart';
import 'package:vanishingtictactoe/shared/models/unlockable_content.dart';

/// A fullscreen modal overlay that displays when a player levels up.
/// 
/// This screen shows the new level with animations and displays any newly unlocked
/// items that the player can interact with. It includes:
/// - Animated level number display
/// - Interactive carousel of unlocked items
/// - Continue button to dismiss the screen
class LevelUpScreen extends StatefulWidget {
  /// The new level that the player has reached
  final int newLevel;
  
  /// List of items that were unlocked at this level
  final List<UnlockableItem> newUnlockables;
  
  /// Callback function triggered when the player dismisses the screen
  final VoidCallback onContinue;

  const LevelUpScreen({
    super.key,
    required this.newLevel,
    required this.newUnlockables,
    required this.onContinue,
  });
  
  /// Shows the level up screen as a modal overlay with a higher z-index than regular dialogs.
  /// 
  /// This method ensures the level up screen appears above all other UI elements
  /// and provides a smooth fade-in transition.
  /// 
  /// Parameters:
  /// - [context]: The BuildContext to show the dialog in
  /// - [newLevel]: The new level that the player has reached
  /// - [newUnlockables]: List of items that were unlocked at this level
  /// - [onContinue]: Callback function triggered when the player dismisses the screen
  static Future<void> show({
    required BuildContext context,
    required int newLevel,
    required List<UnlockableItem> newUnlockables,
    required VoidCallback onContinue,
  }) {
    // Add haptic feedback for a more immersive experience
    HapticFeedback.mediumImpact();
    
    // Close any existing dialogs first to ensure this appears on top
    Navigator.of(context, rootNavigator: true).popUntil((route) {
      return route.isFirst || route.settings.name == '/game-screen';
    });
    
    // Use a custom route with the highest possible z-index
    return Navigator.of(context, rootNavigator: true).push(
      PageRouteBuilder(
        // Set opaque to false to allow transparency
        opaque: false,
        // Set a very high z-index value
        settings: const RouteSettings(name: '/level-up-screen'),
        // Prevent dismissal by tapping outside
        barrierDismissible: false,
        barrierColor: Colors.transparent,
        pageBuilder: (context, animation, secondaryAnimation) {
          return LevelUpScreen(
            newLevel: newLevel,
            newUnlockables: newUnlockables,
            onContinue: onContinue,
          );
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          // Use a curved animation for a more polished feel
          final curvedAnimation = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          );
          
          return FadeTransition(
            opacity: curvedAnimation,
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }

  @override
  State<LevelUpScreen> createState() => _LevelUpScreenState();
}

class _LevelUpScreenState extends State<LevelUpScreen> with TickerProviderStateMixin {
  // Animation controllers
  late final AnimationController _levelController;
  late final AnimationController _unlockablesController;
  late final AnimationController _backgroundController;
  
  // Animation objects
  late final Animation<double> _levelAnimation;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _pulseAnimation;
  
  // UI state
  bool _showUnlockables = false;
  Timer? _unlockableTimer;
  
  // For interactive sliding
  final PageController _pageController = PageController();
  double _currentPage = 0;
  late List<GlobalKey> _itemKeys;

  @override
  void initState() {
    super.initState();
    
    // Initialize animation controllers and animations
    _initializeAnimationControllers();
    _setupAnimations();
    
    // Initialize item keys for each unlockable
    _itemKeys = List.generate(widget.newUnlockables.length, (_) => GlobalKey());
    
    // Listen to page controller changes for smooth animations
    _pageController.addListener(_handlePageChange);
    
    // Start the level animation sequence
    _startLevelAnimation();
    
    // Add haptic feedback for a more immersive experience
    HapticFeedback.lightImpact();
  }
  
  /// Handles page changes in the PageView
  void _handlePageChange() {
    if (!mounted) return;
    
    setState(() {
      _currentPage = _pageController.page ?? 0;
    });
  }
  
  /// Initializes all animation controllers with appropriate durations and vsync
  void _initializeAnimationControllers() {
    // Main level animation controller - controls the level number appearance
    _levelController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    
    // Controls the appearance of unlockable items
    _unlockablesController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    // Background animation controller for continuous effects
    _backgroundController = AnimationController(
      duration: const Duration(seconds: 8),
      vsync: this,
    );
    
    // Start the background animation with repeat
    // Using forward/reverse instead of repeat() for smoother animations
    _backgroundController.forward();
    _backgroundController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _backgroundController.reverse();
      } else if (status == AnimationStatus.dismissed) {
        _backgroundController.forward();
      }
    });
  }
  
  /// Sets up all animations with appropriate curves and intervals
  void _setupAnimations() {
    // Level number animation - smooth entrance with slight bounce
    _levelAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _levelController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOutBack),
      ),
    );
    
    // Scale animation with spring effect for dramatic entrance
    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _levelController,
        // Using elasticOut for a bouncy effect that draws attention
        curve: const Interval(0.1, 0.6, curve: Curves.elasticOut),
      ),
    );
    
    // Pulse animation for continuous subtle movement
    // Using a more subtle range (1.0 to 1.05) for better performance
    _pulseAnimation = Tween<double>(
      begin: 1.0, 
      end: 1.05,
    ).animate(
      CurvedAnimation(
        parent: _backgroundController,
        curve: Curves.easeInOut,
      ),
    );
  }
  
  /// Starts the level animation sequence and sets up completion listeners
  void _startLevelAnimation() {
    // Start the main level animation
    _levelController.forward();
    
    // Listen for animation completion to trigger next steps
    _levelController.addStatusListener((status) {
      // Only proceed if the animation completed and widget is still mounted
      if (status == AnimationStatus.completed && mounted) {
        setState(() {
          _showUnlockables = true;
        });
        
        // Start the unlockables animation
        _unlockablesController.forward();
        
        // If there are unlockable items, start their reveal animation
        if (widget.newUnlockables.isNotEmpty) {
          _startUnlockableReveal();
        }
      }
    });
  }
  
  /// Prepares and starts the animation for revealing unlockable items
  void _startUnlockableReveal() {
    // Cancel any existing timer to prevent memory leaks
    _unlockableTimer?.cancel();
    _unlockableTimer = null;
    
    setState(() {
      // Reset page controller to first page with proper animation
      if (_pageController.hasClients) {
        _pageController.jumpToPage(0);
      }
      _currentPage = 0;
    });
    
    // Add haptic feedback for item reveal
    if (widget.newUnlockables.isNotEmpty) {
      HapticFeedback.lightImpact();
    }
  }
  
  // No longer needed as we show all items at once
  
  /// Builds the interactive carousel of unlockable items with page indicators
  Widget _buildInteractiveUnlockables(BoxConstraints constraints) {
    // If no unlockables, return an empty container
    if (widget.newUnlockables.isEmpty) {
      return const SizedBox.shrink();
    }
    
    // Calculate the optimal item width based on the number of items
    final double screenWidth = MediaQuery.of(context).size.width;
    
    return Stack(
      alignment: Alignment.center,
      children: [
        // Navigation arrows for better discoverability
        if (widget.newUnlockables.length > 1) ...[  
          // Left arrow
          Positioned(
            left: 0,
            child: IconButton(
              icon: Icon(Icons.arrow_back_ios, 
                color: _currentPage > 0 ? Colors.white : Colors.white.withOpacity(0.3),
              ),
              onPressed: () {
                if (_currentPage > 0 && _pageController.hasClients) {
                  _pageController.previousPage(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOut,
                  );
                  HapticFeedback.selectionClick();
                }
              },
            ),
          ),
          
          // Right arrow
          Positioned(
            right: 0,
            child: IconButton(
              icon: Icon(Icons.arrow_forward_ios,
                color: _currentPage < widget.newUnlockables.length - 1 ? 
                  Colors.white : Colors.white.withOpacity(0.3),
              ),
              onPressed: () {
                if (_currentPage < widget.newUnlockables.length - 1 && _pageController.hasClients) {
                  _pageController.nextPage(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOut,
                  );
                  HapticFeedback.selectionClick();
                }
              },
            ),
          ),
        ],
        
        // Page indicators (dots)
        Positioned(
          bottom: 0,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              widget.newUnlockables.length,
              (index) => GestureDetector(
                onTap: () {
                  if (_pageController.hasClients) {
                    _pageController.animateToPage(
                      index,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOut,
                    );
                    HapticFeedback.selectionClick();
                  }
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: index == _currentPage.round() ? 16 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: index == _currentPage.round() ? BoxShape.rectangle : BoxShape.circle,
                    borderRadius: index == _currentPage.round() ? BorderRadius.circular(4) : null,
                    color: index == _currentPage.round()
                        ? Colors.blue.shade600
                        : Colors.grey.shade400,
                    boxShadow: index == _currentPage.round() ? [
                      BoxShadow(
                        color: Colors.blue.shade200.withOpacity(0.5),
                        blurRadius: 4,
                        spreadRadius: 1,
                      )
                    ] : null,
                  ),
                ),
              ),
            ),
          ),
        ),
        
        // Slidable items with PageView for smooth swiping
        SizedBox(
          width: screenWidth,
          child: PageView.builder(
            controller: _pageController,
            // Set viewportFraction to show part of adjacent items
            pageSnapping: true,
            // Add visual cues that there are more items
            padEnds: false,
            // Show a bit of the next/previous item to indicate scrolling
            itemCount: widget.newUnlockables.length,
            onPageChanged: (index) {
              if (!mounted) return;
              
              // Add haptic feedback for page changes
              HapticFeedback.selectionClick();
              
              setState(() {
                _currentPage = index.toDouble();
              });
            },
            itemBuilder: (context, index) {
              final item = widget.newUnlockables[index];
              final bool isCurrentItem = index == _currentPage.round();
              
              // Use RepaintBoundary for better performance
              return RepaintBoundary(
                child: Center(
                  child: TweenAnimationBuilder<double>(
                    key: _itemKeys[index],
                    tween: Tween<double>(begin: 0.0, end: 1.0),
                    duration: const Duration(milliseconds: 500),
                    curve: isCurrentItem ? Curves.easeOutBack : Curves.easeOutCubic,
                    builder: (context, scale, child) {
                      return Transform.scale(
                        scale: isCurrentItem ? scale : 0.85,
                        child: Opacity(
                          opacity: isCurrentItem ? 1.0 : 0.6,
                          child: UnlockableItemCard(
                            item: item,
                            index: index,
                            isHighlighted: isCurrentItem,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    // Stop all animations before disposing to prevent Ticker errors
    _levelController.stop();
    _unlockablesController.stop();
    _backgroundController.stop();
    
    // Remove listeners to prevent memory leaks
    _pageController.removeListener(_handlePageChange);
    
    // Cancel any active timers
    _unlockableTimer?.cancel();
    _unlockableTimer = null;
    
    // Dispose all controllers
    _levelController.dispose();
    _unlockablesController.dispose();
    _backgroundController.dispose();
    _pageController.dispose();
    
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: Container(
        color: Colors.black.withAlpha(217),
        child: SafeArea(
          child: Stack(
            children: [
              // Main content
              Center(
                child: SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Level up text
                    LevelUpTextWidget(
                      levelAnimation:  _levelAnimation,
                    ),
                    
                    const SizedBox(height: 40),
                    
                    // Level circle with number
                    LevelCircleWidget(
                      newLevel: widget.newLevel,
                      showUnlockables: _showUnlockables,
                      scaleAnimation: _scaleAnimation,
                      pulseAnimation: _pulseAnimation,
                    ),
                    
                    const SizedBox(height: 40),
                    
                    // Unlockables section
                    if (_showUnlockables) ...[
                      AnimatedBuilder(
                        animation: _unlockablesController,
                        builder: (context, child) {
                          return Opacity(
                            opacity: _unlockablesController.value,
                            child: Transform.translate(
                              offset: Offset(0, 20 * (1 - _unlockablesController.value)),
                              child: Column(
                                children: [
                                  Text(
                                    widget.newUnlockables.isNotEmpty
                                        ? "NEW ITEMS UNLOCKED!"
                                        : "KEEP PLAYING TO UNLOCK MORE!",
                                    style: FontPreloader.getTextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.amber.shade300,
                                      letterSpacing: 1.0,
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  if (widget.newUnlockables.isNotEmpty)
                                    SizedBox(
                                      height: 150,
                                      child: LayoutBuilder(
                                        builder: (context, constraints) {
                                          return RepaintBoundary(
                                            child: _buildInteractiveUnlockables(constraints)
                                          );
                                        },
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                      
                      const SizedBox(height: 40),
                      
                      // Continue button
                      TweenAnimationBuilder<double>(
                        tween: Tween<double>(begin: 0.0, end: 1.0),
                        duration: const Duration(milliseconds: 500),
                        curve: Curves.elasticOut,
                        builder: (context, value, child) {
                          return Transform.scale(
                            scale: value,
                            child: ElevatedButton(
                              onPressed: widget.onContinue,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue.shade600,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                                elevation: 5,
                                shadowColor: Colors.blue.shade700,
                              ),
                              child: Text(
                                "CONTINUE",
                                style: FontPreloader.getTextStyle(
                                  fontFamily: 'Orbitron',
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.0,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ],
                ),
              ),
          ),
          ],
          ),
        ),
      ),
    );
  }
}


  
  