import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vanishingtictactoe/core/constants/app_colors.dart';
import 'package:vanishingtictactoe/shared/providers/hell_mode_provider.dart';

/// A customized loading indicator widget that maintains consistent styling across the app
/// with support for hell mode theming.
class LoadingIndicator extends StatelessWidget {
  final String? message;
  final double size;
  final double strokeWidth;
  final bool isOverlay;
  final Color? customColor;

  const LoadingIndicator({
    Key? key,
    this.message,
    this.size = 40.0,
    this.strokeWidth = 4.0,
    this.isOverlay = false,
    this.customColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final hellModeProvider = Provider.of<HellModeProvider>(context, listen: false);
    final isHellMode = hellModeProvider.isHellModeActive;
    
    final primaryColor = customColor ?? AppColors.getPrimaryColor(isHellMode);
    
    Widget loadingContent = Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: size,
          height: size,
          child: CircularProgressIndicator(
            strokeWidth: strokeWidth,
            valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
          ),
        ),
        if (message != null) ...[
          const SizedBox(height: 16),
          Text(
            message!,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: isHellMode ? Colors.red.shade900 : Colors.black87,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );

    if (isOverlay) {
      return Container(
        color: Colors.black.withValues(alpha: 0.5),
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: loadingContent,
          ),
        ),
      );
    }

    return Center(
      child: loadingContent,
    );
  }
}

/// A loading indicator that takes up the full screen with a semi-transparent background
class FullScreenLoadingIndicator extends StatelessWidget {
  final String? message;
  
  const FullScreenLoadingIndicator({
    Key? key,
    this.message,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return LoadingIndicator(
      message: message,
      isOverlay: true,
    );
  }
}

/// A loading indicator that can be used as a placeholder for content that is loading
class ContentLoadingIndicator extends StatelessWidget {
  final double height;
  final String? message;
  
  const ContentLoadingIndicator({
    Key? key,
    this.height = 200,
    this.message,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: LoadingIndicator(
        message: message,
        size: 32,
      ),
    );
  }
}
