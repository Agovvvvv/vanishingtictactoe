import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:vanishingtictactoe/features/game/models/computer_player.dart';
import 'package:vanishingtictactoe/shared/providers/hell_mode_provider.dart';

class DifficultySelector extends StatefulWidget {
  const DifficultySelector({
    super.key, 
    required this.selectedDifficulty,
    required this.onDifficultyChanged,
  });

  final GameDifficulty selectedDifficulty;
  final ValueChanged<GameDifficulty> onDifficultyChanged;

  @override
  State<DifficultySelector> createState() => _DifficultySelectorState();
}

class _DifficultySelectorState extends State<DifficultySelector> {
  final List<GameDifficulty> _difficulties = [
    GameDifficulty.easy,
    GameDifficulty.medium,
    GameDifficulty.hard,
  ];
  
  GameDifficulty _selectedDifficulty = GameDifficulty.easy;
  
  @override
  void initState() {
    super.initState();
    _selectedDifficulty = widget.selectedDifficulty;
  }

  String _getDifficultyName(GameDifficulty difficulty) {
    return switch (difficulty) {
      GameDifficulty.easy => 'Easy',
      GameDifficulty.medium => 'Medium',
      GameDifficulty.hard => 'Hard',
    };
  }
  
  @override
  Widget build(BuildContext context) {
    final hellModeActive = Provider.of<HellModeProvider>(context).isHellModeActive;
    final primaryColor = hellModeActive ? Colors.red : Colors.blue;
    
    return Card(
      margin: const EdgeInsets.fromLTRB(24, 8, 24, 4),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      color: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(
            colors: hellModeActive
              ? [Colors.white.withValues( alpha: 0.9), Colors.red.shade50.withValues( alpha: 0.8)]
              : [Colors.white.withValues( alpha: 0.9), Colors.blue.shade50.withValues( alpha: 0.8)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          border: Border.all(
            color: primaryColor.withValues( alpha: 0.3),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: primaryColor.withValues( alpha: 0.15),
              blurRadius: 16,
              offset: const Offset(0, 8),
              spreadRadius: 0,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Animated title with icon
                  TweenAnimationBuilder<double>(
                    tween: Tween<double>(begin: 0.8, end: 1.0),
                    duration: const Duration(milliseconds: 600),
                    curve: Curves.elasticOut,
                    builder: (context, value, child) {
                      return Transform.scale(
                        scale: value,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              hellModeActive ? Icons.local_fire_department_rounded : Icons.emoji_events_rounded,
                              color: hellModeActive ? Colors.red.shade700 : Colors.blue.shade700,
                              size: 24,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'Choose your challenge level',
                              style: TextStyle(
                                fontSize: 18,
                                color: hellModeActive ? Colors.red.shade900 : Colors.blue.shade900,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.5,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                  
                  // Difficulty options with improved styling
                  Row(
                    children: _difficulties.map((difficulty) {
                      final isSelected = _selectedDifficulty == difficulty;
                      final index = _difficulties.indexOf(difficulty);
                      
                      return Expanded(
                        child: TweenAnimationBuilder<double>(
                          tween: Tween<double>(begin: 0.0, end: 1.0),
                          duration: Duration(milliseconds: 400 + (index * 100)),
                          curve: Curves.easeOutBack,
                          builder: (context, value, child) {
                            return Transform.scale(
                              scale: value,
                              child: Padding(
                                padding: EdgeInsets.only(
                                  right: difficulty != _difficulties.last ? 12 : 0,
                                ),
                                child: GestureDetector(
                                  onTap: () {
                                    HapticFeedback.lightImpact();
                                    setState(() => _selectedDifficulty = difficulty);
                                    widget.onDifficultyChanged(difficulty);
                                  },
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 300),
                                    padding: const EdgeInsets.symmetric(vertical: 18),
                                    decoration: BoxDecoration(
                                      gradient: isSelected 
                                        ? LinearGradient(
                                            colors: hellModeActive
                                              ? [Colors.red.shade600, Colors.deepOrange.shade600]
                                              : [Colors.blue.shade600, Colors.blue.shade400],
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                          )
                                        : null,
                                      color: isSelected ? null : (hellModeActive ? Colors.red.shade50 : Colors.blue.shade50).withValues( alpha: 0.5),
                                      borderRadius: BorderRadius.circular(16),
                                      boxShadow: isSelected 
                                        ? [
                                            BoxShadow(
                                              color: (hellModeActive ? Colors.red : Colors.blue).withValues( alpha: 0.4),
                                              blurRadius: 12,
                                              offset: const Offset(0, 4),
                                              spreadRadius: 0,
                                            ),
                                          ] 
                                        : null,
                                      border: Border.all(
                                        color: isSelected 
                                          ? (hellModeActive ? Colors.red.shade300 : Colors.blue.shade300)
                                          : (hellModeActive ? Colors.red.shade200 : Colors.blue.shade200).withValues( alpha: 0.5),
                                        width: 2,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        if (isSelected)
                                          Icon(
                                            Icons.check_circle_rounded,
                                            color: Colors.white,
                                            size: 18,
                                          ),
                                        if (isSelected)
                                          const SizedBox(width: 8),
                                        Text(
                                          _getDifficultyName(difficulty),
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w700,
                                            color: isSelected 
                                              ? Colors.white 
                                              : hellModeActive ? Colors.red.shade900 : Colors.blue.shade900,
                                            letterSpacing: 0.2,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}