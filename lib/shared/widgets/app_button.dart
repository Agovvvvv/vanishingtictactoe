import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vanishingtictactoe/core/constants/app_colors.dart';
import 'package:vanishingtictactoe/shared/providers/hell_mode_provider.dart';

/// A customized button widget that maintains consistent styling across the app
/// with support for hell mode theming.
class AppButton extends StatelessWidget {
  final Function()? onPressed;
  final String text;
  final IconData? icon;
  final bool isOutlined;
  final bool isFullWidth;
  final bool isSmall;
  final bool isLoading;
  final Color? customColor;

  const AppButton({
    Key? key,
    required this.onPressed,
    required this.text,
    this.icon,
    this.isOutlined = false,
    this.isFullWidth = false,
    this.isSmall = false,
    this.isLoading = false,
    this.customColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final hellModeProvider = Provider.of<HellModeProvider>(context, listen: false);
    final isHellMode = hellModeProvider.isHellModeActive;
    
    final primaryColor = customColor ?? AppColors.getPrimaryColor(isHellMode);
    final textColor = isOutlined ? primaryColor : Colors.white;
    
    // Determine button size based on isSmall flag
    final double horizontalPadding = isSmall ? 16.0 : 24.0;
    final double verticalPadding = isSmall ? 8.0 : 12.0;
    final double fontSize = isSmall ? 14.0 : 16.0;
    final double iconSize = isSmall ? 18.0 : 20.0;
    
    // Create the button content with or without icon
    Widget buttonContent = Row(
      mainAxisSize: isFullWidth ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (isLoading)
          SizedBox(
            width: iconSize,
            height: iconSize,
            child: CircularProgressIndicator(
              strokeWidth: 2.0,
              valueColor: AlwaysStoppedAnimation<Color>(textColor),
            ),
          )
        else if (icon != null) 
          Icon(icon, size: iconSize, color: textColor),
        
        if ((icon != null || isLoading) && text.isNotEmpty)
          const SizedBox(width: 8.0),
        
        if (text.isNotEmpty)
          Text(
            text,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w600,
              color: textColor,
              letterSpacing: 0.5,
            ),
          ),
      ],
    );
    
    // Apply button styling based on isOutlined flag
    if (isOutlined) {
      return OutlinedButton(
        onPressed: isLoading ? null : onPressed,
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: primaryColor, width: 2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: EdgeInsets.symmetric(
            horizontal: horizontalPadding,
            vertical: verticalPadding,
          ),
          minimumSize: isFullWidth ? const Size.fromHeight(48) : null,
        ),
        child: buttonContent,
      );
    } else {
      return ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: 2,
          shadowColor: primaryColor.withValues(alpha: 0.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: EdgeInsets.symmetric(
            horizontal: horizontalPadding,
            vertical: verticalPadding,
          ),
          minimumSize: isFullWidth ? const Size.fromHeight(48) : null,
        ),
        child: buttonContent,
      );
    }
  }
}
