import 'package:flutter/material.dart';
import 'package:vanishingtictactoe/core/utils/font_preloader.dart';
import 'dart:math' as math;

class ModeToggleTabs extends StatefulWidget {
  final bool showHellMatches;
  final Function(bool) onToggle;

  const ModeToggleTabs({
    super.key,
    required this.showHellMatches,
    required this.onToggle,
  });
  
  @override
  State<ModeToggleTabs> createState() => _ModeToggleTabsState();
}

class _ModeToggleTabsState extends State<ModeToggleTabs> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    
    if (widget.showHellMatches) {
      _animationController.repeat();
    }
  }
  
  @override
  void didUpdateWidget(ModeToggleTabs oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (widget.showHellMatches && !_animationController.isAnimating) {
      _animationController.repeat();
    } else if (!widget.showHellMatches && _animationController.isAnimating) {
      _animationController.stop();
    }
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final regularColor = const Color(0xFF2E86DE);
    final hellColor = const Color(0xFFE74C3C);
    final inactiveColor = const Color(0xFF7F8C8D);
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues( alpha: 0.08),
              blurRadius: 12,
              spreadRadius: 2,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Row(
            children: [
              // Regular matches tab
              Expanded(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => widget.onToggle(false),
                    child: Ink(
                      decoration: BoxDecoration(
                        color: !widget.showHellMatches ? regularColor : Colors.white,
                        boxShadow: !widget.showHellMatches ? [
                          BoxShadow(
                            color: regularColor.withValues( alpha: 0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ] : null,
                      ),
                      child: Center(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.grid_3x3,
                                size: 16,
                                color: !widget.showHellMatches ? Colors.white : inactiveColor,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'REGULAR',
                                style: FontPreloader.getTextStyle(
                                  fontFamily: 'Orbitron',
                                  fontSize: 12,
                                  color: !widget.showHellMatches ? Colors.white : inactiveColor,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              // Hell matches tab
              Expanded(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => widget.onToggle(true),
                    child: Ink(
                      decoration: BoxDecoration(
                        color: widget.showHellMatches ? hellColor : Colors.white,
                        gradient: widget.showHellMatches ? const LinearGradient(
                          colors: [Color(0xFFE74C3C), Color(0xFFC0392B)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ) : null,
                      ),
                      child: Center(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (widget.showHellMatches)
                                AnimatedBuilder(
                                  animation: _animationController,
                                  builder: (context, child) {
                                    return Transform.rotate(
                                      angle: widget.showHellMatches ? 0.05 * math.sin(_animationController.value * math.pi * 4) : 0,
                                      child: Icon(
                                        Icons.whatshot,
                                        size: 16,
                                        color: Colors.yellow.withValues( alpha: 0.7 + 0.3 * math.sin(_animationController.value * math.pi * 3)),
                                      ),
                                    );
                                  },
                                )
                              else
                                Icon(
                                  Icons.whatshot,
                                  size: 16,
                                  color: inactiveColor,
                                ),
                              const SizedBox(width: 6),
                              Text(
                                'HELL',
                                style: FontPreloader.getTextStyle(
                                  fontFamily: 'Orbitron',
                                  fontSize: 12,
                                  color: widget.showHellMatches ? Colors.white : inactiveColor,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}