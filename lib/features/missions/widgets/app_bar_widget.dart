import 'package:flutter/material.dart';
import 'package:vanishingtictactoe/features/missions/widgets/mode_toggle_widget.dart';

class AppBarWidget extends StatelessWidget implements PreferredSizeWidget {
  final bool showHellMissions;
  final ValueChanged<bool> onModeChanged;
  final TabController tabController;
  
  const AppBarWidget({
    super.key, 
    required this.showHellMissions,
    required this.onModeChanged,
    required this.tabController,
  });
  
  @override
  Size get preferredSize => Size.fromHeight(kToolbarHeight + 48);
  
  @override
  Widget build(BuildContext context) {
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
        ModeToggleWidget(
          showHellMissions: showHellMissions,
          onModeChanged: onModeChanged,
        ),
      ],
      bottom: PreferredSize(
        preferredSize: Size.fromHeight(48),
        child: Container(
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: Colors.white.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
          ),
          child: TabBar(
            controller: tabController,
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
            unselectedLabelColor: Colors.white.withValues(alpha: 0.7),
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
}
