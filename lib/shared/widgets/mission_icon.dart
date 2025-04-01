import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/mission_provider.dart';
import '../providers/hell_mode_provider.dart';
import 'package:vanishingtictactoe/features/missions/models/mission.dart';

class MissionIcon extends StatefulWidget {
  const MissionIcon({super.key});

  @override
  State<MissionIcon> createState() => _MissionIconState();
}

class _MissionIconState extends State<MissionIcon> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;
  late Animation<double> _pulseAnimation;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
    
    // Keep the same animations
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );
    
    _rotationAnimation = Tween<double>(begin: -0.05, end: 0.05).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );
    
    _pulseAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween<double>(begin: 1.0, end: 1.2), weight: 1),
      TweenSequenceItem(tween: Tween<double>(begin: 1.2, end: 1.0), weight: 1),
    ]).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.5, curve: Curves.easeInOut),
    ));
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final missionProvider = Provider.of<MissionProvider>(context);
    final hellModeProvider = Provider.of<HellModeProvider>(context);
    final isHellMode = hellModeProvider.isHellModeActive;
    
    // Count completed missions that haven't been claimed
    final completedMissions = missionProvider.getCompletedUnclaimedMissions();
    
    // Filter by hell mode if active
    final filteredMissions = isHellMode
        ? completedMissions.where((m) => m.category == MissionCategory.hell).toList()
        : completedMissions.where((m) => m.category == MissionCategory.normal).toList();
    
    final hasCompletedMissions = filteredMissions.isNotEmpty;
    
    // Use a SizedBox with fixed dimensions to ensure proper sizing and centering
    return SizedBox(
      width: 48,
      height: 48,
      child: Stack(
        alignment: Alignment.center, // Ensure stack contents are centered
        children: [
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Transform.rotate(
                angle: hasCompletedMissions ? _rotationAnimation.value * 3.14 : 0,
                child: Transform.scale(
                  scale: hasCompletedMissions ? _scaleAnimation.value : 1.0,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isHellMode 
                          ? Colors.red.shade800 
                          : Colors.blue.shade700,
                      shape: BoxShape.circle,
                      boxShadow: hasCompletedMissions ? [
                        BoxShadow(
                          color: (isHellMode ? Colors.red.shade800 : Colors.blue.shade700).withAlpha(128),
                          blurRadius: 8,
                          spreadRadius: 1,
                        )
                      ] : null,
                    ),
                    child: const Icon(
                      Icons.assignment_outlined,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),
              );
            },
          ),
        if (hasCompletedMissions)
          Positioned(
            right: 0, // Adjusted position to account for the new padding
            top: 0,   // Adjusted position to account for the new padding
            child: AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _pulseAnimation.value,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.green.shade600,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.green.shade600.withAlpha(128),
                          blurRadius: 4,
                          spreadRadius: 0,
                        )
                      ],
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 20,
                      minHeight: 20,
                    ),
                    child: Center(
                      child: Text(
                        filteredMissions.length > 9 ? '9+' : '${filteredMissions.length}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
