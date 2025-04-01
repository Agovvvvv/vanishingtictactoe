import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:vanishingtictactoe/shared/models/player.dart';
import 'package:vanishingtictactoe/core/utils/font_preloader.dart';
import 'package:vanishingtictactoe/shared/providers/hell_mode_provider.dart';
import 'dart:math' as math;

class PlayerSetupModal extends StatefulWidget {
  const PlayerSetupModal({super.key});

  @override
  State<PlayerSetupModal> createState() => _PlayerSetupModalState();
}

class _PlayerSetupModalState extends State<PlayerSetupModal> with SingleTickerProviderStateMixin {
  final _player1Controller = TextEditingController();
  final _player2Controller = TextEditingController();
  bool _vanishingEffectEnabled = true; // Default to true for the vanishing effect
  late AnimationController _animationController;
  
  // Constants for styling
  static const double _defaultPadding = 20.0;
  static const double _spacingHeight = 16.0;
  
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }
  
  @override
  void dispose() {
    _player1Controller.dispose();
    _player2Controller.dispose();
    _animationController.dispose();
    super.dispose();
  }

  // Method to build a text field for player name input
  Widget _buildPlayerTextField(TextEditingController controller, String labelText, IconData icon, bool isHellMode) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        final Color baseColor = isHellMode ? Colors.red : Colors.blue;
        final borderColor = _vanishingEffectEnabled && !isHellMode
            ? HSLColor.fromColor(baseColor)
                .withLightness(0.5 + 0.1 * math.sin(_animationController.value * math.pi))
                .toColor()
            : baseColor;
            
        return TextField(
          controller: controller,
          style: FontPreloader.getTextStyle(
            fontFamily: 'Orbitron',
            fontSize: 16,
            color: Colors.black87,
          ),
          onChanged: (_) => HapticFeedback.selectionClick(),
          decoration: InputDecoration(
            labelText: labelText,
            labelStyle: FontPreloader.getTextStyle(
              fontFamily: 'Orbitron',
              fontSize: 14,
              color: Colors.grey[700],
              fontWeight: FontWeight.w500,
            ),
            prefixIcon: Icon(icon, color: Colors.grey[600]),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: borderColor, width: 2),
            ),
            filled: true,
            fillColor: Colors.grey[50],
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final hellModeProvider = Provider.of<HellModeProvider>(context);
    final isHellMode = hellModeProvider.isHellModeActive;
    
    // In Hell Mode, vanishing effect is always disabled
    if (isHellMode) {
      _vanishingEffectEnabled = false;
    }
    
    // No need to define unused colors here
    
    return Dialog(
      backgroundColor: Colors.white,
      elevation: 12,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: LinearGradient(
                colors: [
                  Colors.white,
                  isHellMode
                    ? Colors.red.withValues(alpha: 0.05)
                    : (_vanishingEffectEnabled 
                      ? Colors.blue.withValues(alpha: 0.05 + 0.03 * math.sin(_animationController.value * math.pi))
                      : Colors.grey.withValues(alpha: 0.05))
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              boxShadow: [
                BoxShadow(
                  color: isHellMode
                    ? Colors.red.withValues(alpha: 0.15)
                    : (_vanishingEffectEnabled
                      ? Colors.blue.withValues(alpha: 0.1 + 0.05 * math.sin(_animationController.value * math.pi))
                      : Colors.black.withValues(alpha: 0.1)),
                  blurRadius: 20,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(_defaultPadding),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title with icon
                  Row(
                    children: [
                      Icon(
                        isHellMode ? Icons.local_fire_department : Icons.sports_esports,
                        size: 32,
                        color: isHellMode
                          ? Colors.red.withValues(alpha: 0.8)
                          : (_vanishingEffectEnabled
                            ? Colors.blue.withValues(alpha: 0.7 + 0.3 * math.sin(_animationController.value * math.pi * 2))
                            : Colors.blue),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        isHellMode ? 'Hell Mode Setup' : 'Player Setup',
                        style: FontPreloader.getTextStyle(
                          fontFamily: 'Orbitron',
                          fontSize: 28,
                          color: isHellMode ? Colors.red.shade900 : Colors.black87,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: _defaultPadding),
                  _buildPlayerTextField(_player1Controller, 'Player 1 Name', Icons.person, isHellMode),
                  const SizedBox(height: _spacingHeight),
                  _buildPlayerTextField(_player2Controller, 'Player 2 Name', Icons.person_2, isHellMode),
                  const SizedBox(height: _spacingHeight * 1.5),
                  
                  // Vanishing effect toggle with animated container - only show if not in Hell Mode
                  if (!isHellMode)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        color: _vanishingEffectEnabled 
                          ? Colors.blue.withValues(alpha: 0.1 + 0.05 * math.sin(_animationController.value * math.pi))
                          : Colors.grey.withValues(alpha: 0.1),
                        border: Border.all(
                          color: _vanishingEffectEnabled 
                            ? Colors.blue.withValues(alpha: 0.3 + 0.1 * math.sin(_animationController.value * math.pi))
                            : Colors.grey.withValues(alpha: 0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.auto_awesome,
                                size: 20,
                                color: _vanishingEffectEnabled 
                                  ? Colors.blue.withValues(alpha: 0.7 + 0.3 * math.sin(_animationController.value * math.pi * 2))
                                  : Colors.grey[600],
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Vanishing Effect',
                                style: FontPreloader.getTextStyle(
                                  fontFamily: 'Orbitron',
                                  fontSize: 16,
                                  color: _vanishingEffectEnabled ? Colors.blue[700] : Colors.grey[700],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          Switch(
                            value: _vanishingEffectEnabled,
                            onChanged: (value) {
                              HapticFeedback.mediumImpact();
                              setState(() {
                                _vanishingEffectEnabled = value;
                              });
                            },
                            activeColor: Colors.blue,
                            activeTrackColor: Colors.blue.withValues(alpha: 0.3),
                          ),
                        ],
                      ),
                    ),
                  
                  // In Hell Mode, show an info message instead of the toggle
                  if (isHellMode)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        color: Colors.red.withValues(alpha: 0.1),
                        border: Border.all(
                          color: Colors.red.withValues(alpha: 0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            size: 20,
                            color: Colors.red.shade800,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Vanishing Effect is enabled in Hell Mode',
                              style: FontPreloader.getTextStyle(
                                fontFamily: 'Orbitron',
                                fontSize: 14,
                                color: Colors.red.shade800,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  
                  const SizedBox(height: _defaultPadding),
                  // Action buttons row with better overflow handling
                  Wrap(
                    alignment: WrapAlignment.end,
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      // Cancel button
                      TextButton(
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          Navigator.pop(context);
                        },
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'Cancel',
                          style: FontPreloader.getTextStyle(
                            fontFamily: 'Orbitron',
                            fontSize: 14,
                            color: isHellMode ? Colors.red.shade800 : Colors.grey[800],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      
                      // Start Game button
                      ElevatedButton(
                        onPressed: () {
                          HapticFeedback.mediumImpact();
                          if (_player1Controller.text.isEmpty || _player2Controller.text.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Please enter names for both players',
                                  style: FontPreloader.getTextStyle(
                                    fontFamily: 'Orbitron',
                                    fontSize: 14,
                                    color: Colors.white,
                                  ),
                                ),
                                backgroundColor: isHellMode ? Colors.red.shade900 : Colors.black87,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            );
                            return;
                          }
                          Navigator.pop(
                            context,
                            {
                              'players': [
                                Player(name: _player1Controller.text, symbol: 'X'),
                                Player(name: _player2Controller.text, symbol: 'O'),
                              ],
                              'vanishingEffectEnabled': _vanishingEffectEnabled,
                            },
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isHellMode
                            ? Colors.red.shade700
                            : (_vanishingEffectEnabled 
                              ? Colors.blue.withValues(alpha: 0.8 + 0.2 * math.sin(_animationController.value * math.pi))
                              : Colors.blue),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          elevation: 4,
                          shadowColor: isHellMode
                            ? Colors.red.withValues(alpha: 0.4)
                            : (_vanishingEffectEnabled 
                              ? Colors.blue.withValues(alpha: 0.3 + 0.1 * math.sin(_animationController.value * math.pi))
                              : Colors.blue.withValues(alpha: 0.3)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              isHellMode ? 'Start Hell Game' : 'Start Game',
                              style: FontPreloader.getTextStyle(
                                fontFamily: 'Orbitron',
                                fontSize: 14,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(
                              isHellMode ? Icons.local_fire_department : Icons.play_arrow_rounded,
                              size: 20,
                              color: Colors.white.withValues(alpha: 0.8 + 0.2 * math.sin(_animationController.value * math.pi * 2)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
  );
  }
} 
