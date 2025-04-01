import 'package:flutter/material.dart';
import 'package:vanishingtictactoe/shared/models/unlockable_content.dart';
import 'package:vanishingtictactoe/shared/providers/user_provider.dart';
import 'package:provider/provider.dart';
import 'package:vanishingtictactoe/shared/widgets/custom_icon.dart';
import 'package:vanishingtictactoe/core/utils/font_preloader.dart';

import 'dart:ui';

class LevelRoadmapScreen extends StatefulWidget {
  const LevelRoadmapScreen({super.key});

  @override
  State<LevelRoadmapScreen> createState() => _LevelRoadmapScreenState();
}

class _LevelRoadmapScreenState extends State<LevelRoadmapScreen> with SingleTickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  late AnimationController _pageEnterAnimationController;
  late Animation<double> _fadeInAnimation;
  
  @override
  void initState() {
    super.initState();
    
    // Setup page enter animation
    _pageEnterAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _fadeInAnimation = CurvedAnimation(
      parent: _pageEnterAnimationController,
      curve: Curves.easeOut,
    );
    
    _pageEnterAnimationController.forward();
    
    // Scroll to user's level after the widget is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToUserLevel();
    });
  }
  
  void _scrollToUserLevel() {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final currentLevel = userProvider.user?.userLevel.level ?? 1;
    
    // Calculate approximate position based on level
    // Subtract 2 to position the current level a bit below the top for better visibility
    final targetIndex = (currentLevel > 2) ? currentLevel - 2 : 0;
    
    // Use a more accurate item height estimation based on the actual layout
    // Each level with unlockables is around 250px, without is around 120px
    // For simplicity and to ensure we get close enough, use an average
    final estimatedItemHeight = 210.0;
    
    _scrollController.animateTo(
      targetIndex * estimatedItemHeight,
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _pageEnterAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final currentLevel = userProvider.user?.userLevel.level ?? 1;
    final allUnlockables = UnlockableContent.getAllUnlockables();
    
    // Group unlockables by level
    Map<int, List<UnlockableItem>> unlockablesByLevel = {};
    for (var item in allUnlockables) {
      if (!unlockablesByLevel.containsKey(item.requiredLevel)) {
        unlockablesByLevel[item.requiredLevel] = [];
      }
      unlockablesByLevel[item.requiredLevel]!.add(item);
    }
    
    return Theme(
      data: Theme.of(context).copyWith(
        colorScheme: Theme.of(context).colorScheme.copyWith(
          primary: Colors.blue.shade700,
          secondary: Colors.amber.shade600,
          surface: Colors.white,
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.grey.shade50,
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          title: FadeTransition(
            opacity: _fadeInAnimation,
            child: Text(
              'Level Roadmap',
              style: FontPreloader.getTextStyle(
                fontFamily: 'Orbitron',
                fontSize: 22,
                color: Colors.black,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ),
          backgroundColor: Colors.white.withValues( alpha: 0.85),
          elevation: 0,
          foregroundColor: Colors.black,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
          flexibleSpace: ClipRRect(
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(color: Colors.transparent),
            ),
          ),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(
              bottom: Radius.circular(16),
            ),
          ),
        ),
        body: SafeArea(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                FadeTransition(
                  opacity: _fadeInAnimation,
                  child: GestureDetector(
                    onTap: _scrollToUserLevel,
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 16),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.blue.shade600,
                            Colors.blue.shade800,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.blue.shade200.withValues( alpha: 0.5),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.emoji_events,
                            color: Colors.white,
                            size: 24,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Level $currentLevel',
                            style: FontPreloader.getTextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            Icons.keyboard_double_arrow_down,
                            color: Colors.white.withValues( alpha: 0.8),
                            size: 18,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: FadeTransition(
                    opacity: _fadeInAnimation,
                    child: ListView.builder(
                      controller: _scrollController,
                      physics: const BouncingScrollPhysics(),
                      itemCount: 50, // Levels 1-50
                      itemBuilder: (context, index) {
                        final level = index + 1; // Start from level 1
                        final levelUnlockables = unlockablesByLevel[level] ?? [];
                        final isCurrentLevel = level == currentLevel;
                        final isPastLevel = level < currentLevel;
                        
                        return AnimatedRoadmapLevelItem(
                          level: level,
                          unlockables: levelUnlockables,
                          isCurrentLevel: isCurrentLevel,
                          isPastLevel: isPastLevel,
                          delayFactor: index * 0.1,
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class AnimatedRoadmapLevelItem extends StatefulWidget {
  final int level;
  final List<UnlockableItem> unlockables;
  final bool isCurrentLevel;
  final bool isPastLevel;
  final double delayFactor;

  const AnimatedRoadmapLevelItem({
    super.key,
    required this.level,
    required this.unlockables,
    required this.isCurrentLevel,
    required this.isPastLevel,
    this.delayFactor = 0.0,
  });

  @override
  State<AnimatedRoadmapLevelItem> createState() => _AnimatedRoadmapLevelItemState();
}

class _AnimatedRoadmapLevelItemState extends State<AnimatedRoadmapLevelItem> 
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    // Staggered animations with delay based on item position
    Future.delayed(Duration(milliseconds: (widget.delayFactor * 200).toInt()), () {
      if (mounted) {
        _controller.forward();
      }
    });
    
    // Different animation curves for more dynamic feel
    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );
    
    _slideAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );
    
    _scaleAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final slideDirection = widget.level % 2 == 0 ? -0.2 : 0.2;
    
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: Offset(slideDirection, 0.1),
          end: Offset.zero,
        ).animate(_slideAnimation),
        child: ScaleTransition(
          scale: Tween<double>(
            begin: 0.95,
            end: 1.0,
          ).animate(_scaleAnimation),
          child: RoadmapLevelItem(
            level: widget.level,
            unlockables: widget.unlockables,
            isCurrentLevel: widget.isCurrentLevel,
            isPastLevel: widget.isPastLevel,
          ),
        ),
      ),
    );
  }
}

class RoadmapLevelItem extends StatefulWidget {
  final int level;
  final List<UnlockableItem> unlockables;
  final bool isCurrentLevel;
  final bool isPastLevel;

  const RoadmapLevelItem({
    super.key,
    required this.level,
    required this.unlockables,
    required this.isCurrentLevel,
    required this.isPastLevel,
  });

  @override
  State<RoadmapLevelItem> createState() => _RoadmapLevelItemState();
}

class _RoadmapLevelItemState extends State<RoadmapLevelItem> {
  @override
  Widget build(BuildContext context) {
    final hasUnlockables = widget.unlockables.isNotEmpty;
    final isEvenLevel = widget.level % 2 == 0;
    final contentWidth = MediaQuery.of(context).size.width * 0.40; // Slightly smaller to avoid overflow
    
    return SizedBox(
      height: hasUnlockables ? 250 : 120, // Increased height to accommodate wrapped content
      child: Column(
        children: [
          Expanded(
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // Vertical line that connects levels
                Positioned.fill(
                  child: Align(
                    alignment: Alignment.center,
                    child: Container(
                      width: 3,
                      height: double.infinity,
                      decoration: BoxDecoration(
                        gradient: widget.isPastLevel
                          ? LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.blue.shade400,
                                Colors.blue.shade300,
                              ],
                            )
                          : null,
                        color: widget.isPastLevel ? null : Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(1.5),
                      ),
                    ),
                  ),
                ),
                
                // Level circle with pulse animation for current level
                Positioned.fill(
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: _buildLevelCircle(),
                  ),
                ),
                
                // Content box - positioned to the left for even levels, right for odd levels
                if (hasUnlockables)
                  Positioned(
                    top: 0, // Align with the level circle
                    left: isEvenLevel ? 0 : null,
                    right: isEvenLevel ? null : 0,
                    child: Container(
                      width: contentWidth,
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(top: 0, bottom: 30),
                      decoration: BoxDecoration(
                        color: widget.isCurrentLevel 
                            ? Colors.amber.shade50
                            : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: widget.isCurrentLevel 
                              ? Colors.amber.shade200
                              : Colors.grey.shade300,
                          width: widget.isCurrentLevel ? 1.5 : 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: (widget.isCurrentLevel 
                                ? Colors.amber.shade100
                                : Colors.grey.shade200).withValues( alpha: 0.5),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: isEvenLevel 
                            ? CrossAxisAlignment.start 
                            : CrossAxisAlignment.end,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Header for the unlockable content box
                          if (widget.unlockables.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.stars_rounded,
                                    size: 16,
                                    color: widget.isCurrentLevel
                                        ? Colors.amber.shade700
                                        : Colors.blue.shade700,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Unlocks',
                                    style: FontPreloader.getTextStyle(
                                      fontFamily: 'Orbitron',
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: widget.isCurrentLevel
                                          ? Colors.amber.shade700
                                          : Colors.blue.shade700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ...widget.unlockables.map((item) => 
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: UnlockableItemWidget(item: item),
                            )
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildLevelCircle() {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        if (widget.isCurrentLevel)
          // Pulse effect for current level
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(seconds: 2),
            curve: Curves.easeInOut,
            builder: (context, value, child) {
              return Opacity(
                opacity: (1 - value).clamp(0.0, 0.7),
                child: Transform.scale(
                  scale: 0.8 + (value * 0.5),
                  child: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.amber.withValues( alpha: 0.3),
                    ),
                  ),
                ),
              );
            },
            // Restart animation when complete
            onEnd: () {
              if (mounted) {
                setState(() {}); // Properly trigger rebuild
              }
            },
          ),
          
        // Main level circle
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: widget.isCurrentLevel
                  ? [Colors.amber.shade400, Colors.amber.shade600]
                  : widget.isPastLevel
                      ? [Colors.blue.shade400, Colors.blue.shade600]
                      : [Colors.grey.shade300, Colors.grey.shade400],
            ),
            border: Border.all(
              color: widget.isCurrentLevel
                  ? Colors.amber.shade700
                  : widget.isPastLevel
                      ? Colors.blue.shade700
                      : Colors.grey.shade400,
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: (widget.isCurrentLevel
                    ? Colors.amber.shade200
                    : widget.isPastLevel
                        ? Colors.blue.shade200
                        : Colors.grey.shade300).withValues( alpha: 0.5),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Center(
            child: Text(
              '${widget.level}',
              style: FontPreloader.getTextStyle(
                fontFamily: 'Orbitron',
                fontSize: 18,
                color: Colors.white,
                fontWeight: FontWeight.bold,
                shadows: [
                  Shadow(
                    color: Colors.black26,
                    blurRadius: 2,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
            ),
          ),
        ),
        
        // Icon indicator for current or completed level
        if (widget.isCurrentLevel || widget.isPastLevel)
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: widget.isCurrentLevel ? Colors.amber.shade700 : Colors.blue.shade700,
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues( alpha: 0.2),
                    blurRadius: 2,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Center(
                child: Icon(
                  widget.isCurrentLevel ? Icons.star : Icons.check,
                  size: 10,
                  color: Colors.white,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class UnlockableItemWidget extends StatelessWidget {
  final UnlockableItem item;

  const UnlockableItemWidget({
    super.key,
    required this.item,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        gradient: item.isPremium
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.amber.shade50,
                  Colors.amber.shade100.withValues( alpha: 0.5),
                ],
              )
            : null,
        color: item.isPremium ? null : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: item.isPremium
              ? Colors.amber.shade300
              : Colors.grey.shade300,
          width: item.isPremium ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: (item.isPremium
                ? Colors.amber.shade200
                : Colors.grey.shade200).withValues( alpha: 0.4),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildItemIconContainer(),
              const SizedBox(width: 8),
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: constraints.maxWidth - 44, // Icon width + padding
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      item.name,
                      style: FontPreloader.getTextStyle(
                        fontFamily: 'Orbitron',
                        fontSize: 13,
                        fontWeight: item.isPremium
                            ? FontWeight.bold
                            : FontWeight.w500,
                        color: item.isPremium
                            ? Colors.amber.shade800
                            : Colors.black87,
                        letterSpacing: 0.3,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                    const SizedBox(height: 2),
                    Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: item.isPremium
                                ? Colors.amber.shade700
                                : Colors.blue.shade700,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            _getTypeText(),
                            style: FontPreloader.getTextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 9,
                              fontWeight: FontWeight.w500,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        if (item.isPremium)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.deepPurple.shade700,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.diamond,
                                  size: 8,
                                  color: Colors.white,
                                ),
                                const SizedBox(width: 2),
                                Text(
                                  'PRO',
                                  style: FontPreloader.getTextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 8,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          );
        },
    ),
    );
  }

  Widget _buildItemIconContainer() {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: item.isPremium
            ? Colors.amber.shade100
            : Colors.blue.shade50,
        border: Border.all(
          color: item.isPremium
              ? Colors.amber.shade300
              : Colors.blue.shade200,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues( alpha: 0.05),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Center(
        child: _buildItemIcon(),
      ),
    );
  }

  Widget _buildItemIcon() {
    switch (item.type) {
      case UnlockableType.icon:
        return Icon(
          item.content as IconData,
          size: 20,
          color: item.isPremium ? Colors.amber.shade700 : Colors.blue.shade700,
        );
      case UnlockableType.border:
        return Container(
          width: 18,
          height: 18,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: (item.content as ProfileBorderStyle).borderColor,
              width: 2,
            ),
          ),
        );
      case UnlockableType.background:
        return Container(
          width: 18,
          height: 18,
          decoration: BoxDecoration(
            color: item.content as Color,
            shape: BoxShape.circle,
          ),
        );
      default:
        return const Icon(Icons.star, size: 18);
    }
  }

  String _getTypeText() {
    switch (item.type) {
      case UnlockableType.icon:
        return 'ICON';
      case UnlockableType.border:
        return 'BORDER';
      case UnlockableType.background:
        return 'BG';
      case UnlockableType.effect:
        return 'EFFECT';
    }
  }
}