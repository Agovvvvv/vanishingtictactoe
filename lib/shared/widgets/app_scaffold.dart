import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vanishingtictactoe/core/constants/app_colors.dart';
import 'package:vanishingtictactoe/shared/providers/hell_mode_provider.dart';
import 'package:vanishingtictactoe/features/game/widgets/shared/hell_pattern_painter_widget.dart';

/// A custom scaffold that provides consistent styling across the app
/// with support for hell mode theming and common app layout patterns.
class AppScaffold extends StatelessWidget {
  final String? title;
  final Widget body;
  final List<Widget>? actions;
  final Widget? floatingActionButton;
  final Widget? bottomNavigationBar;
  final bool showBackButton;
  final VoidCallback? onBackPressed;
  final bool extendBodyBehindAppBar;
  final Color? backgroundColor;
  final bool resizeToAvoidBottomInset;
  final bool showAppBar;

  const AppScaffold({
    Key? key,
    this.title,
    required this.body,
    this.actions,
    this.floatingActionButton,
    this.bottomNavigationBar,
    this.showBackButton = true,
    this.onBackPressed,
    this.extendBodyBehindAppBar = false,
    this.backgroundColor,
    this.resizeToAvoidBottomInset = true,
    this.showAppBar = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final hellModeProvider = Provider.of<HellModeProvider>(context);
    final isHellMode = hellModeProvider.isHellModeActive;
    
    final appBarColor = isHellMode ? Colors.red.shade900 : AppColors.primaryBlue;
    final bgColor = backgroundColor ?? (isHellMode ? Colors.grey[50] : Colors.white);
    
    return Scaffold(
      appBar: showAppBar ? AppBar(
        title: title != null ? Text(
          title!,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: Colors.white,
          ),
        ) : null,
        backgroundColor: appBarColor,
        elevation: 0,
        leading: showBackButton ? IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: onBackPressed ?? () => Navigator.of(context).pop(),
        ) : null,
        actions: actions,
        centerTitle: true,
      ) : null,
      extendBodyBehindAppBar: extendBodyBehindAppBar,
      backgroundColor: bgColor,
      resizeToAvoidBottomInset: resizeToAvoidBottomInset,
      body: Stack(
        children: [
          // Background pattern for hell mode
          if (isHellMode)
            Positioned.fill(
              child: Opacity(
                opacity: 0.05,
                child: CustomPaint(
                  painter: HellPatternPainter(),
                ),
              ),
            ),
          
          // Main content
          SafeArea(
            child: body,
          ),
        ],
      ),
      floatingActionButton: floatingActionButton,
      bottomNavigationBar: bottomNavigationBar,
    );
  }
}
