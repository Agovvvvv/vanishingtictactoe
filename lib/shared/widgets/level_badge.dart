import 'package:flutter/material.dart';
import '../models/user_level.dart';

/// A widget that displays a user's level in a visually appealing badge.
/// Can be configured to show just the level number or include an icon and label.
class LevelBadge extends StatelessWidget {
  /// The user level to display
  final int level;
  
  /// Whether to show the stars icon
  final bool showIcon;
  
  /// Whether to show the "LVL" label
  final bool showLabel;
  
  /// Background color of the badge
  final Color? backgroundColor;
  
  /// Text color for the badge
  final Color? textColor;
  
  /// Icon color for the badge
  final Color? iconColor;
  
  /// Size of the text
  final double fontSize;
  
  /// Size of the icon
  final double iconSize;
  
  /// Custom padding for the badge
  final EdgeInsetsGeometry? padding;
  
  /// Whether to show a shadow under the badge
  final bool showShadow;
  
  /// Whether to use Hell Mode styling
  final bool isHellMode;

  const LevelBadge({
    super.key,
    required this.level,
    this.showIcon = true,
    this.showLabel = true,
    this.backgroundColor,
    this.textColor,
    this.iconColor,
    this.fontSize = 12.0,
    this.iconSize = 16.0,
    this.padding,
    this.showShadow = true,
    this.isHellMode = false,
  });

  /// Create a level badge from a UserLevel object
  factory LevelBadge.fromUserLevel({
    required UserLevel userLevel,
    bool showIcon = true,
    bool showLabel = true,
    Color? backgroundColor,
    Color? textColor,
    Color? iconColor,
    double fontSize = 12.0,
    double iconSize = 16.0,
    EdgeInsetsGeometry? padding,
    bool showShadow = true,
    bool isHellMode = false,
  }) {
    return LevelBadge(
      level: userLevel.level,
      showIcon: showIcon,
      showLabel: showLabel,
      backgroundColor: backgroundColor,
      textColor: textColor,
      iconColor: iconColor,
      fontSize: fontSize,
      iconSize: iconSize,
      padding: padding,
      showShadow: showShadow,
      isHellMode: isHellMode,
    );
  }
  
  /// Create a level badge with Hell Mode styling
  factory LevelBadge.hellMode({
    required int level,
    bool showIcon = true,
    bool showLabel = true,
    double fontSize = 12.0,
    double iconSize = 16.0,
    EdgeInsetsGeometry? padding,
    bool showShadow = true,
  }) {
    return LevelBadge(
      level: level,
      showIcon: showIcon,
      showLabel: showLabel,
      backgroundColor: Colors.red.shade700,
      textColor: Colors.white,
      iconColor: Colors.orange.shade300,
      fontSize: fontSize,
      iconSize: iconSize,
      padding: padding,
      showShadow: showShadow,
      isHellMode: true,
    );
  }
  
  /// Create a level badge with Hell Mode styling from a UserLevel object
  factory LevelBadge.hellModeFromUserLevel({
    required UserLevel userLevel,
    bool showIcon = true,
    bool showLabel = true,
    double fontSize = 12.0,
    double iconSize = 16.0,
    EdgeInsetsGeometry? padding,
    bool showShadow = true,
  }) {
    return LevelBadge.hellMode(
      level: userLevel.level,
      showIcon: showIcon,
      showLabel: showLabel,
      fontSize: fontSize,
      iconSize: iconSize,
      padding: padding,
      showShadow: showShadow,
    );
  }

  @override
  Widget build(BuildContext context) {
    final defaultBackgroundColor = backgroundColor ?? (isHellMode ? Colors.red.shade700 : Colors.amber.shade300);
    final defaultTextColor = textColor ?? (isHellMode ? Colors.white : Colors.white);
    final defaultIconColor = iconColor ?? (isHellMode ? Colors.orange.shade300 : Colors.amber.shade800);
    final defaultPadding = padding ?? const EdgeInsets.symmetric(horizontal: 8, vertical: 4);
    
    return Container(
      padding: defaultPadding,
      decoration: BoxDecoration(
        color: defaultBackgroundColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: showShadow ? [
          BoxShadow(
            color: defaultBackgroundColor.withValues(alpha: 0.4),
            blurRadius: 4,
            offset: const Offset(0, 2),
            spreadRadius: 0,
          ),
        ] : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showIcon) ...[
            Icon(
              isHellMode ? Icons.local_fire_department : Icons.military_tech_rounded,
              color: defaultIconColor,
              size: iconSize,
            ),
            const SizedBox(width: 4),
          ],
          Text(
            showLabel ? 'LVL $level' : '$level',
            style: TextStyle(
              color: defaultTextColor,
              fontWeight: FontWeight.bold,
              fontSize: fontSize,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}
