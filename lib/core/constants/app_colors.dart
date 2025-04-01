import 'package:flutter/material.dart';

/// App color constants for consistent theming across the application
class AppColors {
  // Primary colors
  static const Color primaryBlue = Color(0xFF2962FF);
  static const Color primaryBlueLight = Color(0xFFE3F2FD);
  
  // Player colors
  static final Color player1Light = Colors.blue.shade400;
  static final Color player1Dark = Colors.blue.shade700;
  static final Color player2Light = Colors.red.shade400;
  static final Color player2Dark = Colors.red.shade700;
  
  // Hell mode colors
  static const Color hellRed = Colors.redAccent;
  
  // Neutral colors
  static const Color background = Colors.white;
  static const Color surface = Colors.white;
  static const Color textPrimary = Colors.black87;
  static const Color textSecondary = Colors.black54;
  
  // Status colors
  static const Color success = Colors.green;
  static const Color error = Colors.red;
  static const Color warning = Colors.orange;
  static const Color info = Colors.blue;
  
  // Helper method to get primary color based on hell mode
  static Color getPrimaryColor(bool isHellMode) {
    return isHellMode ? hellRed : primaryBlue;
  }
  
  // Helper method to get light primary color based on hell mode
  static Color getLightPrimaryColor(bool isHellMode) {
    return isHellMode ? Colors.red.shade50 : primaryBlueLight;
  }
}
