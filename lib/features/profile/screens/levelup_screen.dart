import 'dart:async' show Timer;
import 'package:flutter/material.dart';
import 'package:vanishingtictactoe/features/profile/widgets/levelup/item_card_widget.dart';
import 'package:vanishingtictactoe/features/profile/widgets/levelup/level_circle_widget.dart';
import 'package:vanishingtictactoe/features/profile/widgets/levelup/level_text_widget.dart';
import 'package:vanishingtictactoe/shared/models/unlockable_content.dart';
import 'package:vanishingtictactoe/core/utils/font_preloader.dart';

class LevelUpScreen extends StatefulWidget {
  final int newLevel;
  final List<UnlockableItem> newUnlockables;
  final VoidCallback onContinue;

  const LevelUpScreen({
    super.key,
    required this.newLevel,
    required this.newUnlockables,
    required this.onContinue,
  });
  
  /// Shows the level up screen as a modal overlay with a higher z-index than regular dialogs
  static Future<void> show({
    required BuildContext context,
    required int newLevel,
    required List<UnlockableItem> newUnlockables,
    required VoidCallback onContinue,
  }) {
    return showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierLabel: 'Level Up Screen',
      // Use a high value for routeSettings to ensure it appears above other dialogs
      routeSettings: const RouteSettings(name: '/level-up-screen'),
      // Use a custom PageRouteBuilder to control the transition and z-order
      pageBuilder: (context, animation, secondaryAnimation) {
        return Stack(
          children: [
            // This ensures our dialog appears above others
            Positioned.fill(
              child: LevelUpScreen(
                newLevel: newLevel,
                newUnlockables: newUnlockables,
                onContinue: onContinue,
              ),
            ),
          ],
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: animation,
          child: child,
        );
      },
      transitionDuration: const Duration(milliseconds: 300),
    );
  }

  @override
  State<LevelUpScreen> createState() => _LevelUpScreenState();
}

class _LevelUpScreenState extends State<LevelUpScreen> with TickerProviderStateMixin {
  late AnimationController _levelController;
  late AnimationController _unlockablesController;
  late AnimationController _backgroundController;
  late Animation<double> _levelAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _pulseAnimation;
  bool _showUnlockables = false;
  int _currentUnlockableIndex = -1;
  Timer? _unlockableTimer;
  
  // For interactive sliding
  final PageController _pageController = PageController();
  double _currentPage = 0;
  List<GlobalKey> _itemKeys = [];

  @override
  void initState() {
    super.initState();
    
    _initializeAnimationControllers();
    _setupAnimations();
    _startLevelAnimation();
    
    // Initialize item keys for each unlockable
    _itemKeys = List.generate(widget.newUnlockables.length, (_) => GlobalKey());
    
    // Listen to page controller changes
    _pageController.addListener(() {
      setState(() {
        _currentPage = _pageController.page ?? 0;
      });
    });
  }
  
  void _initializeAnimationControllers() {
    _levelController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    
    _unlockablesController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _backgroundController = AnimationController(
      duration: const Duration(seconds: 8),
      vsync: this,
    )..repeat();
  }
  
  void _setupAnimations() {
    // Level number animation
    _levelAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _levelController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOutBack),
      ),
    );
    
    // Scale animation with spring effect
    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _levelController,
        curve: const Interval(0.1, 0.6, curve: Curves.elasticOut),
      ),
    );
    
    // Pulse animation for continuous effect
    _pulseAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween<double>(begin: 1.0, end: 1.08), weight: 1),
      TweenSequenceItem(tween: Tween<double>(begin: 1.08, end: 1.0), weight: 1),
    ]).animate(
      CurvedAnimation(
        parent: _backgroundController,
        curve: Curves.easeInOut,
      ),
    );
  }
  
  void _startLevelAnimation() {
    _levelController.forward();
    
    _levelController.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) {
        setState(() {
          _showUnlockables = true;
        });
        _unlockablesController.forward();
        
        if (widget.newUnlockables.isNotEmpty) {
          _startUnlockableReveal();
        }
      }
    });
  }
  
  void _startUnlockableReveal() {
    // Reset index to ensure all items are shown
    setState(() {
      _currentUnlockableIndex = widget.newUnlockables.length - 1;
      // Reset page controller to first page
      _pageController.jumpToPage(0);
      _currentPage = 0;
    });
    
    // Cancel any existing timer
    _unlockableTimer?.cancel();
    _unlockableTimer = null;
    
    // Log the number of unlockable items for debugging
    print('Showing ${widget.newUnlockables.length} unlockable items');
    for (int i = 0; i < widget.newUnlockables.length; i++) {
      print('Item $i: ${widget.newUnlockables[i].name}');
    }
  }
  
  // No longer needed as we show all items at once
  
  Widget _buildInteractiveUnlockables(BoxConstraints constraints) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Background indicators
        Positioned(
          bottom: 0,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              widget.newUnlockables.length,
              (index) => Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _currentUnlockableIndex >= 0
                      ? Colors.blue.shade600
                      : Colors.grey.shade300,
                ),
              ),
            ),
          ),
        ),
        
        // Slidable items
        PageView.builder(
          controller: _pageController,
          // Show all unlockable items
          itemCount: widget.newUnlockables.length,
          onPageChanged: (index) {
            // This allows manual navigation between revealed items
            setState(() {
              // Just update the current page for visual effects
              _currentPage = index.toDouble();
            });
          },
          itemBuilder: (context, index) {
            final item = widget.newUnlockables[index];
            final bool isCurrentItem = index == _currentPage.round();
            
            return Center(
              child: TweenAnimationBuilder<double>(
                key: _itemKeys[index],
                tween: Tween<double>(begin: 0.0, end: 1.0),
                duration: const Duration(milliseconds: 500),
                curve: isCurrentItem ? Curves.elasticOut : Curves.easeOutCubic,
                builder: (context, scale, child) {
                  return Transform.scale(
                    scale: isCurrentItem ? scale : 1.0,
                    child: Opacity(
                      opacity: index == _currentPage ? 1.0 : 0.7,
                      child: UnlockableItemCard(
                        item: item,
                        index: index,
                        isHighlighted: index == _currentPage.round(),
                      ),
                    ),
                  );
                },
              ),
            );
          },
        ),
      ],
    );
  }

  @override
  void dispose() {
    _levelController.dispose();
    _unlockablesController.dispose();
    _backgroundController.dispose();
    _unlockableTimer?.cancel();
    _unlockableTimer = null;
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


  
  