import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ModeToggleWidget extends StatelessWidget {
  final bool showHellMissions;
  final ValueChanged<bool> onModeChanged;

  const ModeToggleWidget({
    super.key, 
    required this.showHellMissions,
    required this.onModeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: Container(
        height: 40,
        width: 100,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.3),
            width: 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
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
                      color: (showHellMissions ? Colors.red : Colors.blue).withValues(alpha: 0.4),
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
                      onTap: showHellMissions ? () {
                        onModeChanged(false);
                        HapticFeedback.mediumImpact();
                      } : null,
                      child: Center(
                        child: Icon(
                          Icons.star_rounded,
                          color: Colors.white,
                          size: 24,
                          shadows: !showHellMissions ? [
                            Shadow(color: Colors.white.withValues(alpha: 0.8), blurRadius: 10)
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
                      onTap: !showHellMissions ? () {
                        onModeChanged(true);
                        HapticFeedback.mediumImpact();
                      } : null,
                      child: Center(
                        child: Icon(
                          Icons.local_fire_department_rounded,
                          color: Colors.white,
                          size: 24,
                          shadows: showHellMissions ? [
                            Shadow(color: Colors.white.withValues(alpha: 0.8), blurRadius: 10)
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
}
