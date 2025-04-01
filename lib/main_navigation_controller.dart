import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vanishingtictactoe/features/game/screens/mode_selection_screen.dart';
import 'package:vanishingtictactoe/features/home/screens/home_screen.dart';
import 'package:vanishingtictactoe/features/missions/screens/missions_screen.dart';
import 'package:vanishingtictactoe/features/friends/screens/friends_screen.dart';
import 'package:vanishingtictactoe/features/profile/screens/account_screen.dart';
import 'package:vanishingtictactoe/shared/providers/hell_mode_provider.dart';
import 'package:vanishingtictactoe/shared/providers/navigation_provider.dart';
import 'package:vanishingtictactoe/shared/widgets/animated_bottom_nav_bar.dart';

class MainNavigationController extends StatefulWidget {
  const MainNavigationController({super.key});

  @override
  State<MainNavigationController> createState() => _MainNavigationControllerState();
}

class _MainNavigationControllerState extends State<MainNavigationController> with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  late PageController _pageController;
  late AnimationController _pageTransitionController;
  late NavigationProvider _navigationProvider;
  bool _isPageViewReady = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
    _pageTransitionController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _navigationProvider = Provider.of<NavigationProvider>(context, listen: false);

    // Listen for navigation changes
    _navigationProvider.addListener(_handleNavigationChange);

    // Initialize NavigationProvider after the first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _navigationProvider.initialize(_pageController);
      setState(() {
        _isPageViewReady = true; // Mark as ready after PageView is built
      });
    });
  }

  void _handleNavigationChange() {
    // Only proceed if the page controller is ready and attached
    if (_isPageViewReady && _pageController.hasClients) {
      final index = _navigationProvider.currentIndex;
      if (_currentIndex != index) {
        setState(() {
          _currentIndex = index;
        });
        _animateToPage(index);
      }
    }
  }

  @override
  void dispose() {
    _navigationProvider.removeListener(_handleNavigationChange);
    _pageController.dispose();
    _pageTransitionController.dispose();
    super.dispose();
  }

  void _animateToPage(int index) {
    if (_isPageViewReady && _pageController.hasClients) {
      _pageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
      );
    } else {
      _pageController.jumpToPage(index); // Fallback if animation isn't possible
    }
  }

  void _onTabTapped(int index) {
    if (!_isPageViewReady) {
      // Delay navigation until PageView is ready
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _navigateToIndex(index);
      });
    } else {
      _navigateToIndex(index);
    }
  }

  void _navigateToIndex(int index) {
    setState(() {
      _currentIndex = index;
    });
    _animateToPage(index);
    _navigationProvider.setCurrentIndex(index);
  }

  @override
  Widget build(BuildContext context) {
    final hellModeProvider = Provider.of<HellModeProvider>(context);
    final isHellMode = hellModeProvider.isHellModeActive;

    return Scaffold(
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(), // Prevent swipe navigation
        onPageChanged: (index) {
          setState(() {
            _currentIndex = index;
          });
          _navigationProvider.setCurrentIndex(index);
        },
        children: const [
          HomeScreen(),
          MissionsScreen(),
          ModeSelectionScreen(),
          FriendsScreen(),
          AccountScreen(),
        ],
      ),
      extendBody: true, // Ensure the body extends behind the bottom nav bar
      bottomNavigationBar: SafeArea(
        minimum: EdgeInsets.only(bottom: 10),
        child: AnimatedBottomNavBar(
          currentIndex: _currentIndex,
          onTap: _onTabTapped,
          isHellMode: isHellMode,
          showLabels: true,
        ),
      ),
    );
  }
}