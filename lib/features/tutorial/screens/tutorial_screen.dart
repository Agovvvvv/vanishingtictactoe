import 'package:flutter/material.dart';
import 'package:vanishingtictactoe/features/tutorial/screens/tutorial_game_screen.dart';
import 'package:vanishingtictactoe/features/tutorial/widgets/normal_tutorial/navigation_controls_widget.dart';
import 'package:vanishingtictactoe/features/tutorial/widgets/normal_tutorial/page_widget.dart';
import 'package:vanishingtictactoe/features/tutorial/widgets/normal_tutorial/skip_button_widget.dart';

class TutorialScreen extends StatefulWidget {
  const TutorialScreen({super.key});

  @override
  State<TutorialScreen> createState() => _TutorialScreenState();
}

class _TutorialScreenState extends State<TutorialScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

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
            TutorialSkipButtonWidget(),
            _buildTutorialContent(primaryColor),
            TutorialNavigationControlsWidget(
              primaryColor: primaryColor,
              pageController: _pageController,
              currentPage: _currentPage,
              tutorialData: _tutorialData,
              startTutorialGame: _startTutorialGame,
            ),
          ],
        ),
      ),
    );
  }
  
  // Build the main tutorial content with PageView
  Widget _buildTutorialContent(Color primaryColor) {
    return Expanded(
      child: PageView.builder(
        controller: _pageController,
        onPageChanged: (int page) {
          setState(() {
            _currentPage = page;
          });
        },
        itemCount: _tutorialData.length,
        itemBuilder: (context, index) {
          return TutorialPageWidget(
            index: index, 
            primaryColor: primaryColor, 
            tutorialData: _tutorialData
          );
        },
      ),
    );
  }
  
  
  
  
  
  
  
  
  
  
}