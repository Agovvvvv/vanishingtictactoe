import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:vanishingtictactoe/features/game/widgets/computer/login_prompt_widget.dart';
import 'package:vanishingtictactoe/features/missions/models/mission.dart';
import 'package:vanishingtictactoe/features/missions/widgets/app_bar_widget.dart';
import 'package:vanishingtictactoe/features/missions/widgets/missions_tab_widget.dart';
import 'package:vanishingtictactoe/features/missions/widgets/refresh_indicator_widget.dart';
import 'package:vanishingtictactoe/shared/providers/mission_provider.dart';
import 'package:vanishingtictactoe/shared/providers/user_provider.dart';
import 'package:vanishingtictactoe/shared/providers/hell_mode_provider.dart';
import 'package:vanishingtictactoe/features/missions/widgets/mission_complete_animation.dart';
import 'package:vanishingtictactoe/core/utils/app_logger.dart';


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
      return LoginPromptWidget(
        message: 'Please log in to view missions',
      );
    }
  
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBarWidget(
        showHellMissions: showHellMissions,
        onModeChanged: (value) {
          setState(() {
            _showHellMissions = value;
          });
          HapticFeedback.mediumImpact();
        },
        tabController: _tabController,
      ),
      body: Stack(
        children: [
          Container(
            margin: const EdgeInsets.only(bottom: 70), // Add margin here
            child: TabBarView(
              controller: _tabController,
              children: [
                // Daily missions tab
                MissionsTabWidget(
                  missions: missionProvider.dailyMissions,
                  isLoading: missionProvider.isLoading,
                  emptyMessage: 'No daily missions available',
                  isHellMode: isHellMode,
                  showHellMissions: showHellMissions,
                  refreshMissions: _refreshMissions,
                  onClaimMission: _claimMissionReward,
                  tabController: _tabController,
                ),
  
                // Weekly missions tab
                MissionsTabWidget(
                  missions: missionProvider.weeklyMissions,
                  isLoading: missionProvider.isLoading,
                  emptyMessage: 'No weekly missions available',
                  isHellMode: isHellMode,
                  showHellMissions: showHellMissions,
                  refreshMissions: _refreshMissions,
                  onClaimMission: _claimMissionReward,
                  tabController: _tabController,
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
            const RefreshingIndicatorWidget(),
        ],
      ),
    );
  }
}