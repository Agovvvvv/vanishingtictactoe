import 'package:flutter/material.dart';
import 'package:vanishingtictactoe/core/utils/font_preloader.dart';
import 'package:vanishingtictactoe/features/tutorial/widgets/hell_tutorial/index.dart';

class HellTutorialScreen extends StatefulWidget {
  const HellTutorialScreen({super.key});

  @override
  State<HellTutorialScreen> createState() => _HellTutorialScreenState();
}

class _HellTutorialScreenState extends State<HellTutorialScreen> with SingleTickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  // First, let's fix the image path
  // Using static const for tutorial data to avoid rebuilding it on state changes
  static const List<Map<String, dynamic>> _tutorialData = [
    {
      'title': 'Welcome to Hell Mode!',
      'description': 'A challenging twist on Vanishing Tic Tac Toe that will test your skills to the limit.',
      'icon': Icons.local_fire_department,
      'image': null,
    },
    {
      'title': 'Nested Game Structure',
      'description': 'In Hell Mode, each cell contains its own mini Tic Tac Toe game! Win the mini-game to claim the cell on the main board.',
      'icon': Icons.grid_on,
      'image': null,
    },
    {
      'title': 'How It Works',
      'description': 'When you select a cell on the main board, you\'ll play a complete mini Tic Tac Toe game. The winner of that mini-game claims the cell on the main board.',
      'icon': Icons.sports_esports,
      'image': 'images/tutorial/hell_mini_game.png',
    },
    {
      'title': 'Win the Main Board',
      'description': 'Win mini-games strategically to claim cells that will help you get three in a row on the main board. The first player to get three in a row on the main board wins!',
      'icon': Icons.emoji_events,
      'image': null,
    },
  ];

  bool _imagesLoaded = false;

  @override
  void initState() {
    super.initState();
    // We'll precache images in didChangeDependencies instead
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    
    // Preload all images at once to avoid jank during page transitions
    // Only do this once to avoid unnecessary work
    if (!_imagesLoaded) {
      _imagesLoaded = true;
      for (final data in _tutorialData) {
        if (data['image'] != null) {
          precacheImage(AssetImage(data['image']), context);
        }
      }
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Colors.red.shade700;
    final backgroundColor = Colors.white;
    
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.red.shade700,
        elevation: 0,
        title: Text(
          'Hell Mode Tutorial',
          style: FontPreloader.getTextStyle(
            fontFamily: 'Orbitron',
            fontSize: 22,
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
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
                  return SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Show either icon or image with improved styling
                          HellTutorialVisualWidget(
                            index: index,
                            primaryColor: primaryColor,
                            tutorialData: _tutorialData,
                          ),
                          // Add tutorial content
                          HellTutorialContentWidget(
                            index: index,
                            primaryColor: primaryColor,
                            tutorialData: _tutorialData,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            // Bottom navigation controls with interactive dots
            HellNavigationControlsWidget(
              primaryColor: primaryColor,
              pageController: _pageController,
              currentPage: _currentPage,
              tutorialData: _tutorialData,
            ),
          ],
        ),
      ),
    );
  }
}