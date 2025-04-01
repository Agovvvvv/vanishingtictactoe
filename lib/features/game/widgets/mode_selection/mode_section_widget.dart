import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:vanishingtictactoe/core/utils/font_preloader.dart';
import 'package:vanishingtictactoe/features/game/screens/mode_selection_screen.dart';
import 'package:vanishingtictactoe/shared/providers/hell_mode_provider.dart';
import 'package:provider/provider.dart';

class ModeSectionWidget extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final GameMode mode;
  final Function handleModeSelection;
  
  const ModeSectionWidget({
    super.key,
    required this.title,
    required this.description,
    required this.icon,
    required this.handleModeSelection,
    required this.mode,
  });
  
  @override
  Widget build(BuildContext context) {
    final hellModeProvider = Provider.of<HellModeProvider>(context);
    // Apply fire styling if Hell Mode is active and this isn't the Hell Mode button itself
    final bool applyHellStyle = hellModeProvider.isHellModeActive && mode != GameMode.hellMode;
    
    // Define colors based on mode and hell mode status
    final Color primaryColor = applyHellStyle ? Colors.red : Colors.blue;
    final Color cardColor = applyHellStyle ? Colors.red.shade50 : Colors.white;
    final Color iconColor = applyHellStyle ? Colors.red.shade700 : Colors.blue.shade600;
    final Color titleColor = applyHellStyle ? Colors.red.shade900 : Colors.black87;
    final Color descriptionColor = applyHellStyle ? Colors.red.shade700 : Colors.grey[600]!;
    
    // Fixed height for all cards
    const double cardHeight = 130.0;
    
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => handleModeSelection(mode),
        borderRadius: BorderRadius.circular(20),
        splashColor: primaryColor.withValues( alpha: 0.1),
        highlightColor: primaryColor.withValues( alpha: 0.05),
        child: Container(
          height: cardHeight,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                cardColor,
                cardColor.withValues( alpha: 0.9),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: primaryColor.withValues( alpha: 0.15),
                blurRadius: 10,
                offset: const Offset(0, 6),
                spreadRadius: 0,
              ),
            ],
            border: Border.all(
              color: primaryColor.withValues( alpha: 0.1),
              width: 1.5,
            ),
          ),
          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Animated icon container
                TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 0.9, end: 1.0),
                  duration: const Duration(milliseconds: 1500),
                  curve: Curves.easeInOut,
                  builder: (context, value, child) {
                    return Transform.scale(
                      scale: value,
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: applyHellStyle 
                              ? Colors.red.shade100
                              : Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: primaryColor.withValues( alpha: 0.2),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                              spreadRadius: 0,
                            ),
                          ],
                        ),
                        child: Icon(
                          icon,
                          size: 30,
                          color: iconColor,
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: FontPreloader.getTextStyle(
                          fontFamily: 'Orbitron',
                          fontSize: 20,
                          color: titleColor,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                          shadows: [
                            Shadow(
                              color: primaryColor.withValues( alpha: 0.2),
                              offset: const Offset(0, 1),
                              blurRadius: 2,
                            ),
                          ],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        description,
                        style: FontPreloader.getTextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 15,
                          color: descriptionColor,
                          fontWeight: FontWeight.w400,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                // Animated arrow
                TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 0.0, end: 4.0),
                  duration: const Duration(milliseconds: 1500),
                  curve: Curves.easeInOut,
                  builder: (context, value, child) {
                    return Transform.translate(
                      offset: Offset(math.sin(value) * 3, 0),
                      child: Icon(
                        Icons.arrow_forward_rounded,
                        size: 22,
                        color: applyHellStyle ? Colors.red.shade400 : Colors.blue.shade400,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}