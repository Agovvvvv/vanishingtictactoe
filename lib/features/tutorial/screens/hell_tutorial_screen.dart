import 'package:flutter/material.dart';
import 'package:vanishingtictactoe/core/utils/font_preloader.dart';

class HellTutorialScreen extends StatefulWidget {
  const HellTutorialScreen({super.key});

  @override
  State<HellTutorialScreen> createState() => _HellTutorialScreenState();
}

class _HellTutorialScreenState extends State<HellTutorialScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  // First, let's fix the image path
  final List<Map<String, dynamic>> _tutorialData = [
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
                          _tutorialData[index]['image'] != null
                              ? Container(
                                  height: 350,
                                  width: double.infinity,
                                  margin: const EdgeInsets.only(bottom: 20),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [Colors.red.shade200, Colors.red.shade50],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.circular(20),
                                    // Reduced shadow complexity for better performance
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.red.shade300.withValues( alpha: 0.4),
                                        blurRadius: 8,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                    border: Border.all(
                                      color: Colors.red.shade200,
                                      width: 2,
                                    ),
                                  ),
                                  child: Stack(
                                    children: [
                                      Positioned.fill(
                                        child: Padding(
                                          padding: const EdgeInsets.all(16.0),
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.circular(16),
                                            // Use precacheImage for better performance
                                            child: FutureBuilder(
                                              future: precacheImage(
                                                AssetImage(_tutorialData[index]['image']),
                                                context,
                                              ),
                                              builder: (context, snapshot) {
                                                if (snapshot.connectionState == ConnectionState.waiting) {
                                                  return const Center(
                                                    child: CircularProgressIndicator(),
                                                  );
                                                }
                                                return Image.asset(
                                                  _tutorialData[index]['image'],
                                                  fit: BoxFit.contain,
                                                  alignment: Alignment.center,
                                                  errorBuilder: (context, error, stackTrace) {
                                                    debugPrint('Error loading image: $error');
                                                    return Center(
                                                      child: Column(
                                                        mainAxisAlignment: MainAxisAlignment.center,
                                                        children: [
                                                          Icon(
                                                            _tutorialData[index]['icon'],
                                                            size: 80,
                                                            color: primaryColor,
                                                          ),
                                                          const SizedBox(height: 16),
                                                          Text(
                                                            'Visual example',
                                                            style: TextStyle(
                                                              color: Colors.grey[600],
                                                              fontStyle: FontStyle.italic,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    );
                                                  },
                                                );
                                              },
                                            ),
                                          ),
                                        ),
                                      ),
                                      Positioned(
                                        top: 10,
                                        right: 10,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                          decoration: BoxDecoration(
                                            color: primaryColor,
                                            borderRadius: BorderRadius.circular(20),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black.withValues( alpha: 0.2),
                                                blurRadius: 4,
                                                offset: const Offset(0, 2),
                                              ),
                                            ],
                                          ),
                                          child: Text(
                                            'Example',
                                            style: FontPreloader.getTextStyle(
                                              fontFamily: 'Orbitron',
                                              fontSize: 12,
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              : Container(
                                  padding: const EdgeInsets.all(32),
                                  margin: const EdgeInsets.symmetric(vertical: 20),
                                  decoration: BoxDecoration(
                                    gradient: RadialGradient(
                                      colors: [Colors.red.shade100, Colors.red.shade200],
                                      radius: 0.8,
                                    ),
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.red.shade300.withValues( alpha: 0.5),
                                        blurRadius: 15,
                                        offset: const Offset(0, 5),
                                        spreadRadius: 1,
                                      ),
                                    ],
                                    border: Border.all(
                                      color: Colors.red.shade200,
                                      width: 2,
                                    ),
                                  ),
                                  child: Icon(
                                    _tutorialData[index]['icon'],
                                    size: 120,
                                    color: primaryColor,
                                  ),
                                ),
                          const SizedBox(height: 30),
                          Container(
                            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [primaryColor.withValues( alpha: 0.1), primaryColor.withValues( alpha: 0.2)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(30),
                              boxShadow: [
                                BoxShadow(
                                  color: primaryColor.withValues( alpha: 0.1),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Text(
                              _tutorialData[index]['title'],
                              style: FontPreloader.getTextStyle(
                                fontFamily: 'Orbitron',
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: primaryColor,
                                letterSpacing: 0.5,
                                shadows: [
                                  Shadow(
                                    color: Colors.grey.withValues( alpha: 0.3),
                                    blurRadius: 2,
                                    offset: const Offset(1, 1),
                                  ),
                                ],
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          const SizedBox(height: 20),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Colors.red.shade50.withValues( alpha: 0.8), Colors.red.shade100.withValues( alpha: 0.6)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: Colors.red.shade200,
                                width: 1.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.red.shade100.withValues( alpha: 0.4),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.info_outline,
                                      color: primaryColor,
                                      size: 24,
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        "How It Works",
                                        style: FontPreloader.getTextStyle(
                                          fontFamily: 'Orbitron',
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: primaryColor,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  _tutorialData[index]['description'],
                                  style: TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 18,
                                    color: Colors.grey[800],
                                    height: 1.5,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            // Bottom navigation controls with interactive dots
            Container(
              padding: const EdgeInsets.all(24.0),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.white, Colors.red.shade50.withValues( alpha: 0.3)],
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.red.shade200.withValues( alpha: 0.3),
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
                  // Interactive page indicators
                  Row(
                    children: List.generate(
                      _tutorialData.length,
                      (index) => GestureDetector(
                        onTap: () {
                          _pageController.animateToPage(
                            index,
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: _currentPage == index ? 24 : 12,
                          height: 12,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(6),
                            color: _currentPage == index
                                ? primaryColor
                                : Colors.grey[300],
                            boxShadow: _currentPage == index
                                ? [
                                    BoxShadow(
                                      color: primaryColor.withValues( alpha: 0.4),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ]
                                : null,
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Next/Done button
                  ElevatedButton(
                    onPressed: () {
                      if (_currentPage < _tutorialData.length - 1) {
                        _pageController.nextPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      } else {
                        Navigator.pop(context);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      elevation: 3,
                      shadowColor: primaryColor.withValues( alpha: 0.6),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _currentPage < _tutorialData.length - 1 ? 'Next' : 'Got it!',
                          style: FontPreloader.getTextStyle(
                            fontFamily: 'Orbitron',
                            fontSize: 16,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          _currentPage < _tutorialData.length - 1 ? Icons.arrow_forward : Icons.check,
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