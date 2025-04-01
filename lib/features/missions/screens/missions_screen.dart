import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:vanishingtictactoe/features/missions/models/mission.dart';
import 'package:vanishingtictactoe/shared/providers/mission_provider.dart';
import 'package:vanishingtictactoe/shared/providers/user_provider.dart';
import 'package:vanishingtictactoe/shared/providers/hell_mode_provider.dart';
import 'package:vanishingtictactoe/features/missions/widgets/mission_card.dart';
import 'package:vanishingtictactoe/features/missions/widgets/mission_complete_animation.dart';
import 'package:vanishingtictactoe/core/utils/app_logger.dart';
import 'package:vanishingtictactoe/core/utils/font_preloader.dart';


class MissionsScreen extends StatefulWidget {
  const MissionsScreen({super.key});

  @override
  State<MissionsScreen> createState() => _MissionsScreenState();
}

class _MissionsScreenState extends State<MissionsScreen> with SingleTickerProviderStateMixin {
  // Controller and state variables
  late TabController _tabController;
  Mission? _completedMission;
  bool _showAnimation = false;
  bool _showHellMissions = false;
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_handleTabChange);
    
    _initializeMissions();
  }
  
  // Extract initialization to a separate method for clarity
  void _initializeMissions() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final missionProvider = Provider.of<MissionProvider>(context, listen: false);
      
      if (userProvider.isLoggedIn) {
        missionProvider.initialize(userProvider.user?.id);
      }
    });
  }

  void _handleTabChange() {
    if (_tabController.indexIsChanging) {
      // Add haptic feedback when changing tabs
      HapticFeedback.lightImpact();
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();
    super.dispose();
  }

  void _showMissionCompleteAnimation(Mission mission) {
    setState(() {
      _completedMission = mission;
      _showAnimation = true;
    });
  }

  void _hideAnimation() {
    setState(() {
      _showAnimation = false;
      _completedMission = null;
    });
  }

  Future<void> _refreshMissions() async {
    setState(() {
      _isRefreshing = true;
    });
    
    final missionProvider = Provider.of<MissionProvider>(context, listen: false);
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    
    if (userProvider.isLoggedIn) {
      await missionProvider.initialize(userProvider.user?.id, forceRefresh: true);
    }
    
    setState(() {
      _isRefreshing = false;
    });
  }

  Future<void> _claimMissionReward(Mission mission) async {
    final missionProvider = Provider.of<MissionProvider>(context, listen: false);
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    
    if (!userProvider.isLoggedIn) return;
    
    try {
      // Show animation first
      _showMissionCompleteAnimation(mission);
      
      // Claim the reward
      final xpReward = await missionProvider.completeMission(mission.id);
      
      // Add XP to user
      if (xpReward > 0) {
        await userProvider.addXp(xpReward);
        AppLogger.info('Mission completed: ${mission.title}, XP awarded: $xpReward');
      }
    } catch (e) {
      AppLogger.error('Error claiming mission reward: $e');
      // Hide animation if there was an error
      _hideAnimation();
      
      // Show error snackbar
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to claim reward: ${e.toString()}'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final missionProvider = Provider.of<MissionProvider>(context);
    final hellModeProvider = Provider.of<HellModeProvider>(context);
    final isHellMode = hellModeProvider.isHellModeActive;
    final showHellMissions = _showHellMissions;
  
    if (!userProvider.isLoggedIn) {
      return _buildLoginPrompt();
    }
  
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: _buildAppBar(showHellMissions),
      body: Stack(
        children: [
          Container(
            margin: const EdgeInsets.only(bottom: 70), // Add margin here
            child: TabBarView(
              controller: _tabController,
              children: [
                // Daily missions tab
                _buildMissionsTab(
                  missions: missionProvider.dailyMissions,
                  isLoading: missionProvider.isLoading,
                  emptyMessage: 'No daily missions available',
                  isHellMode: isHellMode,
                  showHellMissions: showHellMissions,
                ),
  
                // Weekly missions tab
                _buildMissionsTab(
                  missions: missionProvider.weeklyMissions,
                  isLoading: missionProvider.isLoading,
                  emptyMessage: 'No weekly missions available',
                  isHellMode: isHellMode,
                  showHellMissions: showHellMissions,
                ),
              ],
            ),
          ),
  
          // Mission complete animation overlay
          if (_showAnimation && _completedMission != null)
            MissionCompleteAnimation(
              missionTitle: _completedMission!.title,
              xpReward: _completedMission!.xpReward,
              isHellMode: isHellMode,
              onAnimationComplete: _hideAnimation,
            ),
  
          // Refreshing indicator
          if (_isRefreshing)
            _buildRefreshingIndicator(),
        ],
      ),
    );
  }

  // Extract AppBar to a separate method
  PreferredSizeWidget _buildAppBar(bool showHellMissions) {
    final primaryColor = showHellMissions 
        ? Colors.red.shade800 
        : Color(0xFF2962FF); // Deeper blue for more modern look
        
    return AppBar(
      elevation: 0,
      backgroundColor: primaryColor,
      automaticallyImplyLeading: false,
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: showHellMissions 
                ? [Colors.red.shade700, Colors.red.shade900]
                : [Color(0xFF2979FF), Color(0xFF1565C0)],
          ),
        ),
      ),
      title: Row(
        children: [
          Icon(
            showHellMissions ? Icons.local_fire_department_rounded : Icons.emoji_events_rounded,
            color: Colors.white,
            size: 28,
          ),
          const SizedBox(width: 12),
          Text(
            'Missions',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 22,
              letterSpacing: 0.5,
              shadows: [
                Shadow(
                  color: Colors.black26,
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        _buildModeToggle(showHellMissions),
      ],
      bottom: PreferredSize(
        preferredSize: Size.fromHeight(48),
        child: Container(
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: Colors.white.withValues( alpha: 0.2),
                width: 1,
              ),
            ),
          ),
          child: TabBar(
            controller: _tabController,
            indicatorColor: Colors.white,
            indicatorWeight: 3,
            indicatorSize: TabBarIndicatorSize.label,
            tabs: [
              Tab(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.today_rounded, size: 18),
                    SizedBox(width: 8),
                    Text('DAILY'),
                  ],
                ),
              ),
              Tab(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.date_range_rounded, size: 18),
                    SizedBox(width: 8),
                    Text('WEEKLY'),
                  ],
                ),
              ),
            ],
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white.withValues( alpha: 0.7),
            labelStyle: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              letterSpacing: 1.0,
            ),
            unselectedLabelStyle: TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }

  // Extract mode toggle to a separate method
  Widget _buildModeToggle(bool showHellMissions) {
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: Container(
        height: 40,
        width: 100,
        decoration: BoxDecoration(
          color: Colors.black.withValues( alpha: 0.2),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: Colors.white.withValues( alpha: 0.3),
            width: 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues( alpha: 0.2),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Animated slider
            AnimatedPositioned(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutBack,
              left: showHellMissions ? 50 : 0,
              top: 0,
              bottom: 0,
              width: 50,
              child: Container(
                margin: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: showHellMissions 
                        ? [Colors.orange.shade600, Colors.red.shade700]
                        : [Colors.blue.shade400, Colors.blue.shade700],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: (showHellMissions ? Colors.red : Colors.blue).withValues( alpha: 0.4),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
              ),
            ),
            // Button row
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Normal mode (star) button
                Expanded(
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: const BorderRadius.horizontal(left: Radius.circular(24)),
                      onTap: _showHellMissions ? () {
                        setState(() => _showHellMissions = false);
                        HapticFeedback.mediumImpact();
                      } : null,
                      child: Center(
                        child: Icon(
                          Icons.star_rounded,
                          color: Colors.white,
                          size: 24,
                          shadows: !showHellMissions ? [
                            Shadow(color: Colors.white.withValues( alpha: 0.8), blurRadius: 10)
                          ] : null,
                        ),
                      ),
                    ),
                  ),
                ),
                // Hell mode (fire) button
                Expanded(
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: const BorderRadius.horizontal(right: Radius.circular(24)),
                      onTap: !_showHellMissions ? () {
                        setState(() => _showHellMissions = true);
                        HapticFeedback.mediumImpact();
                      } : null,
                      child: Center(
                        child: Icon(
                          Icons.local_fire_department_rounded,
                          color: Colors.white,
                          size: 24,
                          shadows: showHellMissions ? [
                            Shadow(color: Colors.white.withValues( alpha: 0.8), blurRadius: 10)
                          ] : null,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Extract refreshing indicator to a separate method
  Widget _buildRefreshingIndicator() {
    return Positioned(
      top: 20,
      left: 0,
      right: 0,
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.black.withValues( alpha: 0.8),
                Colors.black.withValues( alpha: 0.9),
              ],
            ),
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues( alpha: 0.3),
                blurRadius: 10,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              const SizedBox(width: 16),
              Text(
                'Refreshing missions...',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                  fontSize: 15,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMissionsTab({
    required List<Mission> missions,
    required bool isLoading,
    required String emptyMessage,
    required bool isHellMode,
    required bool showHellMissions,
  }) {
    final primaryColor = showHellMissions ? Colors.red.shade700 : Color(0xFF2962FF);
    
    if (isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 50,
              height: 50,
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                strokeWidth: 3,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Loading missions...',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade700,
                letterSpacing: 0.3,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Please wait while we fetch your missions',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      );
    }
    
    // Filter missions by category based on hell mode
    final filteredMissions = showHellMissions
        ? missions.where((m) => m.category == MissionCategory.hell).toList()
        : missions.where((m) => m.category == MissionCategory.normal).toList();
    
    if (filteredMissions.isEmpty) {
      return _buildEmptyState(
        icon: showHellMissions ? Icons.local_fire_department_rounded : Icons.assignment_rounded,
        color: showHellMissions ? Colors.red.shade400 : primaryColor.withValues( alpha: 0.7),
        message: showHellMissions
            ? 'No Hell Mode missions available'
            : 'No missions available yet',
        subMessage: 'Pull down to refresh',
      );
    }
    
    return RefreshIndicator(
      onRefresh: _refreshMissions,
      color: primaryColor,
      backgroundColor: Colors.white,
      strokeWidth: 3,
      displacement: 40,
      child: ListView.builder(
        padding: const EdgeInsets.all(20),
        physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
        itemCount: filteredMissions.length + 1, // +1 for the header
        itemBuilder: (context, index) {
          if (index == 0) {
            // Header with mission count
            return Padding(
              padding: const EdgeInsets.only(bottom: 20, left: 4),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: primaryColor.withValues( alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: primaryColor.withValues( alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _tabController.index == 0 
                              ? Icons.today_rounded 
                              : Icons.date_range_rounded,
                          color: primaryColor,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${filteredMissions.length} ${_tabController.index == 0 ? 'Daily' : 'Weekly'} Missions',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: primaryColor,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }
          
          final mission = filteredMissions[index - 1];
          return TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: Duration(milliseconds: 400 + (index * 100)),
            curve: Curves.easeOutCubic,
            builder: (context, value, child) {
              return Transform.translate(
                offset: Offset(0, 30 * (1 - value)),
                child: Opacity(
                  opacity: value,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 20),
                    child: MissionCard(
                      mission: mission,
                      onClaim: () => _claimMissionReward(mission),
                      showAnimation: false,
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required Color? color,
    required String message,
    String? subMessage,
  }) {
    final primaryColor = _showHellMissions ? Colors.red.shade700 : Color(0xFF2962FF);
    
    return RefreshIndicator(
      onRefresh: _refreshMissions,
      color: primaryColor,
      backgroundColor: Colors.white,
      strokeWidth: 3,
      displacement: 40,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.7,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: (color ?? primaryColor).withValues( alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Icon(
                        icon,
                        size: 64,
                        color: color ?? primaryColor,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.shade200,
                          blurRadius: 10,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Text(
                          message,
                          style: TextStyle(
                            fontSize: 20,
                            color: color ?? Colors.grey.shade800,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.3,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        if (subMessage != null) ...[                    
                          const SizedBox(height: 12),
                          Text(
                            subMessage,
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w400,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: primaryColor.withValues( alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.arrow_downward_rounded,
                      color: primaryColor,
                      size: 32,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Pull to refresh',
                    style: TextStyle(
                      fontSize: 14,
                      color: primaryColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoginPrompt() {
    // Get Hell Mode status from provider
    final hellModeProvider = Provider.of<HellModeProvider>(context);
    final isHellMode = hellModeProvider.isHellModeActive;
    
    // Define colors based on hell mode
    final primaryColor = isHellMode ? Colors.red.shade700 : Color(0xFF2962FF);
    final backgroundColor = isHellMode ? Colors.grey.shade900 : Colors.grey.shade50;
    final textColor = isHellMode ? Colors.white : Colors.grey.shade800;
    final subtextColor = isHellMode ? Colors.grey.shade400 : Colors.grey.shade600;
    final cardColor = isHellMode ? Colors.black.withValues(alpha: 0.7) : Colors.white;
    
    return Scaffold(
      backgroundColor: backgroundColor,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        automaticallyImplyLeading: false, // Add this line to remove the back arrow
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isHellMode 
                ? [Colors.red.shade900, Colors.black] 
                : [Color(0xFF2979FF), Color(0xFF1565C0)],
            ),
          ),
        ),
        title: Row(
          children: [
            ShaderMask(
              shaderCallback: (Rect bounds) {
                return LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isHellMode
                    ? [Colors.orange, Colors.yellow]
                    : [Colors.amber.shade300, Colors.amber.shade500],
                ).createShader(bounds);
              },
              child: Icon(
                isHellMode ? Icons.local_fire_department : Icons.emoji_events_rounded,
                color: Colors.white,
                size: 28,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              isHellMode ? 'Hell Missions' : 'Missions',
              style: FontPreloader.getTextStyle(
                fontFamily: 'Orbitron',
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 0.5,
                shadows: [
                  Shadow(
                    color: Colors.black26,
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Stack(
        children: [
          // Background gradient
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
              ),
            )
          else
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.blue.shade700.withValues(alpha: 0.8),
                      Colors.blue.shade50,
                      Colors.white,
                    ],
                    stops: const [0.0, 0.3, 1.0],
                  ),
                ),
              ),
            ),
            
          // Main content with animations
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 0.0, end: 1.0),
                  duration: const Duration(milliseconds: 1000),
                  curve: Curves.easeOutCubic,
                  builder: (context, value, child) {
                    return Opacity(
                      opacity: value,
                      child: Transform.translate(
                        offset: Offset(0, 30 * (1 - value)),
                        child: child,
                      ),
                    );
                  },
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Animated lock icon
                      TweenAnimationBuilder<double>(
                        tween: Tween<double>(begin: 0.8, end: 1.0),
                        duration: const Duration(milliseconds: 1200),
                        curve: Curves.elasticOut,
                        builder: (context, value, child) {
                          return Transform.scale(
                            scale: value,
                            child: child,
                          );
                        },
                        child: Container(
                          width: 180,
                          height: 180,
                          decoration: BoxDecoration(
                            color: isHellMode ? Colors.red.withValues(alpha: 0.1) : primaryColor.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: primaryColor.withValues(alpha: 0.2),
                                blurRadius: 15,
                                spreadRadius: 2,
                              ),
                            ],
                            border: Border.all(
                              color: primaryColor.withValues(alpha: 0.3),
                              width: 2,
                            ),
                          ),
                          child: Center(
                            child: ShaderMask(
                              shaderCallback: (Rect bounds) {
                                return LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: isHellMode
                                    ? [Colors.red, Colors.orange]
                                    : [primaryColor, primaryColor.withValues(alpha: 0.8)],
                                ).createShader(bounds);
                              },
                              child: Icon(
                                isHellMode ? Icons.lock : Icons.lock_outline_rounded,
                                size: 80,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 40),
                      
                      // Content card with glass effect
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(30),
                        decoration: BoxDecoration(
                          color: cardColor,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: primaryColor.withValues(alpha: 0.15),
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
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(24),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                            child: Column(
                              children: [
                                Text(
                                  isHellMode ? 'Login to Access Hell Missions' : 'Login to Access Missions',
                                  style: FontPreloader.getTextStyle(
                                    fontFamily: 'Orbitron',
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: textColor,
                                    letterSpacing: 0.5,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 20),
                                Text(
                                  isHellMode
                                    ? 'Complete challenging missions to earn XP, level up, and unlock hellish rewards!'
                                    : 'Complete daily and weekly missions to earn XP, level up, and unlock special rewards!',
                                  style: TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 16,
                                    color: subtextColor,
                                    height: 1.5,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 40),
                                
                                // Login button with animation
                                TweenAnimationBuilder<double>(
                                  tween: Tween<double>(begin: 0.0, end: 1.0),
                                  duration: const Duration(milliseconds: 800),
                                  curve: Curves.easeOutCubic,
                                  builder: (context, value, child) {
                                    return Transform.scale(
                                      scale: 0.8 + (0.2 * value),
                                      child: Opacity(
                                        opacity: value,
                                        child: child,
                                      ),
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
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            isHellMode ? Icons.login : Icons.login_rounded,
                                            color: isHellMode? Colors.black : Colors.white,
                                            size: 20,
                                          ),
                                          const SizedBox(width: 12),
                                          Text(
                                            'LOGIN NOW',
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
                              ],
                            ),
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 35),
                      
                      // Benefits section with animation
                      TweenAnimationBuilder<double>(
                        tween: Tween<double>(begin: 0.0, end: 1.0),
                        duration: const Duration(milliseconds: 1000),
                        curve: Curves.easeOutCubic,
                        builder: (context, value, child) {
                          return Opacity(
                            opacity: value,
                            child: Transform.translate(
                              offset: Offset(0, 20 * (1 - value)),
                              child: child,
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          margin: const EdgeInsets.only(bottom: 60),
                          decoration: BoxDecoration(
                            color: isHellMode ? Colors.black.withValues(alpha: 0.5) : Colors.white.withValues(alpha: 0.8),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: primaryColor.withValues(alpha: 0.2),
                              width: 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: primaryColor.withValues(alpha: 0.1),
                                blurRadius: 10,
                                spreadRadius: 0,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Benefits:',
                                    style: FontPreloader.getTextStyle(
                                      fontFamily: 'Orbitron',
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                      color: textColor,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  _buildBenefitItem(
                                    icon: Icons.emoji_events_rounded,
                                    color: isHellMode ? Colors.orange : Colors.amber,
                                    text: isHellMode
                                      ? 'Earn Hell XP and dominate the leaderboard'
                                      : 'Earn XP and climb the leaderboard',
                                  ),
                                  const SizedBox(height: 12),
                                  _buildBenefitItem(
                                    icon: isHellMode ? Icons.whatshot : Icons.calendar_today_rounded,
                                    color: isHellMode ? Colors.red : Colors.green,
                                    text: isHellMode
                                      ? 'Complete infernal challenges'
                                      : 'Complete daily and weekly challenges',
                                  ),
                                  const SizedBox(height: 12),
                                  _buildBenefitItem(
                                    icon: Icons.card_giftcard_rounded,
                                    color: isHellMode ? Colors.deepPurple : Colors.purple,
                                    text: isHellMode
                                      ? 'Unlock hellish rewards and achievements'
                                      : 'Unlock exclusive rewards and achievements',
                                  ),
                                ],
                              ),
                            ),
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
  
  // Helper method for login prompt benefits
  Widget _buildBenefitItem({required IconData icon, required Color color, required String text}) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues( alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade700,
            ),
          ),
        ),
      ],
    );
  }
}