import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vanishingtictactoe/core/navigation/navigation_service.dart';
import 'package:vanishingtictactoe/features/tutorial/screens/tutorial_game_screen.dart';

class TutorialScreen extends StatefulWidget {
  const TutorialScreen({super.key});

  @override
  State<TutorialScreen> createState() => _TutorialScreenState();
}

class _TutorialScreenState extends State<TutorialScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  final int _totalPages = 2; // Reduced to 2 pages before the game

  final List<Map<String, dynamic>> _tutorialData = [
    {
      'title': 'Welcome to Vanishing Tic Tac Toe!',
      'description': 'A twist on the classic game where pieces vanish as the game progresses.',
      'icon': Icons.games,
    },
    {
      'title': 'Let\'s Learn By Playing',
      'description': 'The best way to learn is by playing! We\'ll guide you through your first game.',
      'icon': Icons.sports_esports,
    },
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _markTutorialComplete() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('tutorial_completed', true);
  }

  void _startTutorialGame() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const TutorialGameScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Replace theme colors with specific colors from mode_selection_screen
    final primaryColor = Colors.blue.shade700;
    final backgroundColor = Colors.white;
    
    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: () {
                      _markTutorialComplete();
                      NavigationService.instance.navigateToAndRemoveUntil('/main');

                    },
                    icon: const Icon(Icons.skip_next),
                    label: const Text('Skip'),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.blue.shade400,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (int page) {
                  setState(() {
                    _currentPage = page;
                  });
                },
                itemCount: _tutorialData.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            _tutorialData[index]['icon'],
                            size: 100,
                            color: primaryColor,
                          ),
                        ),
                        const SizedBox(height: 40),
                        Text(
                          _tutorialData[index]['title'],
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                            letterSpacing: 0.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _tutorialData[index]['description'],
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            Container(
              padding: const EdgeInsets.all(24.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.shade200.withValues( alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, -4),
                    spreadRadius: 1,
                  ),
                ],
                border: Border.all(
                  color: Colors.white.withValues( alpha: 0.5),
                  width: 1.5,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Page indicators
                  Row(
                    children: List.generate(
                      _tutorialData.length,
                      (index) => AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: _currentPage == index ? 20 : 10,
                        height: 10,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(5),
                          color: _currentPage == index
                              ? primaryColor
                              : Colors.grey[300],
                        ),
                      ),
                    ),
                  ),
                  // Next/Start Game button
                  ElevatedButton(
                    onPressed: () {
                      if (_currentPage < _totalPages - 1) {
                        _pageController.nextPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      } else {
                        _startTutorialGame();
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _currentPage < _totalPages - 1 ? 'Next' : 'Start Tutorial Game',
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          _currentPage < _totalPages - 1 ? Icons.arrow_forward : Icons.play_arrow,
                          size: 18,
                          color: Colors.white,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}