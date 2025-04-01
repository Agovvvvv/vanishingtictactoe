import 'package:flutter/material.dart';
import 'package:vanishingtictactoe/features/missions/models/mission.dart';
import 'package:vanishingtictactoe/features/missions/widgets/mission_card.dart';
import 'package:vanishingtictactoe/features/missions/widgets/empty_state_widget.dart';

class MissionsTabWidget extends StatelessWidget {
  final List<Mission> missions;
  final bool isLoading;
  final String emptyMessage;
  final bool isHellMode;
  final bool showHellMissions;
  final Future<void> Function() refreshMissions;
  final Function(Mission) onClaimMission;
  final TabController tabController;
  
  const MissionsTabWidget({
    super.key,
    required this.missions,
    required this.isLoading,
    required this.emptyMessage,
    required this.isHellMode,
    required this.showHellMissions,
    required this.refreshMissions,
    required this.onClaimMission,
    required this.tabController,
  });
  
  @override
  Widget build(BuildContext context) {
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
      return EmptyStateWidget(
        showHellMissions: showHellMissions,
        refreshMissions: refreshMissions,
        context: context,
        icon: showHellMissions ? Icons.local_fire_department_rounded : Icons.assignment_rounded,
        color: showHellMissions ? Colors.red.shade400 : primaryColor.withValues(alpha: 0.7),
        message: showHellMissions
            ? 'No Hell Mode missions available'
            : 'No missions available yet',
        subMessage: 'Pull down to refresh',
      );
    }
    
    return RefreshIndicator(
      onRefresh: refreshMissions,
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
                          tabController.index == 0 
                              ? Icons.today_rounded 
                              : Icons.date_range_rounded,
                          color: primaryColor,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${filteredMissions.length} ${tabController.index == 0 ? 'Daily' : 'Weekly'} Missions',
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
                      onClaim: () => onClaimMission(mission),
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
}