import 'package:flutter/material.dart';

/// A widget that provides customizable profile icons and borders
/// for user profiles in the application.
class CustomProfileIcon extends StatefulWidget {
  /// The icon to display
  final IconData icon;
  
  /// The border style to use
  final ProfileBorderStyle borderStyle;
  
  /// Background color of the avatar
  final Color backgroundColor;
  
  /// Icon color
  final Color iconColor;
  
  /// Size of the avatar (diameter)
  final double size;
  
  /// Whether to show a shadow under the avatar
  final bool showShadow;
  
  /// Whether to show premium effects (animations, gradients, etc.)
  final bool showPremiumEffects;
  
  /// Whether this is a premium item that should display special effects
  final bool isPremium;

  const CustomProfileIcon({
    super.key,
    required this.icon,
    required this.borderStyle,
    this.backgroundColor = Colors.blue,
    this.iconColor = Colors.white,
    this.size = 100.0,
    this.showShadow = true,
    this.showPremiumEffects = true,
    this.isPremium = false,
  });

  @override
  State<CustomProfileIcon> createState() => _CustomProfileIconState();
}

class _CustomProfileIconState extends State<CustomProfileIcon> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _rotationAnimation;
  late Animation<double> _glowAnimation;
  
  @override
  void initState() {
    super.initState();
    
    // Initialize animation controller
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
    
    // Pulse animation for premium icons
    _pulseAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.05), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 1.05, end: 1.0), weight: 1),
    ]).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    // Subtle rotation animation for premium icons
    _rotationAnimation = Tween<double>(
      begin: -0.02,
      end: 0.02,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    // Glow animation for premium borders
    _glowAnimation = Tween<double>(
      begin: 0.7,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    // Start animation if premium effects are enabled
    if (widget.isPremium && widget.showPremiumEffects) {
      _animationController.repeat(reverse: true);
    }
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
  
  @override
  void didUpdateWidget(CustomProfileIcon oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Update animation state if premium status changes
    if (widget.isPremium != oldWidget.isPremium || 
        widget.showPremiumEffects != oldWidget.showPremiumEffects) {
      if (widget.isPremium && widget.showPremiumEffects) {
        _animationController.repeat(reverse: true);
      } else {
        _animationController.stop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.scale(
          scale: widget.isPremium && widget.showPremiumEffects ? _pulseAnimation.value : 1.0,
          child: Transform.rotate(
            angle: widget.isPremium && widget.showPremiumEffects ? _rotationAnimation.value : 0.0,
            child: Container(
              width: widget.size,
              height: widget.size,
              decoration: BoxDecoration(
                shape: widget.borderStyle.shape == ProfileBorderShape.circle 
                    ? BoxShape.circle 
                    : BoxShape.rectangle,
                borderRadius: widget.borderStyle.shape == ProfileBorderShape.circle 
                    ? null 
                    : BorderRadius.circular(widget.borderStyle.borderRadius),
                boxShadow: widget.showShadow ? [
                  BoxShadow(
                    color: widget.isPremium && widget.showPremiumEffects
                        ? widget.borderStyle.borderColor.withValues( alpha: 0.3 * _glowAnimation.value)
                        : Colors.black26,
                    blurRadius: widget.isPremium && widget.showPremiumEffects ? 15 : 10,
                    spreadRadius: widget.isPremium && widget.showPremiumEffects ? 2 : 0,
                    offset: const Offset(0, 4),
                  ),
                ] : null,
              ),
              // Use a Stack to separate the border from the background
              child: Stack(
                children: [
                  // Border container (positioned at the bottom of the stack)
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        shape: widget.borderStyle.shape == ProfileBorderShape.circle 
                            ? BoxShape.circle 
                            : BoxShape.rectangle,
                        borderRadius: widget.borderStyle.shape == ProfileBorderShape.circle 
                            ? null 
                            : BorderRadius.circular(widget.borderStyle.borderRadius),
                        border: Border.all(
                          color: widget.borderStyle.useGradient ? Colors.transparent : widget.borderStyle.borderColor,
                          width: widget.borderStyle.borderWidth,
                        ),
                        gradient: widget.borderStyle.useGradient ? LinearGradient(
                          colors: widget.isPremium && widget.showPremiumEffects
                              ? [
                                  widget.borderStyle.borderColor,
                                  widget.borderStyle.borderColor.withValues( alpha: 0.7 * _glowAnimation.value),
                                  widget.borderStyle.borderColor,
                                ]
                              : [
                                  widget.borderStyle.borderColor,
                                  widget.borderStyle.borderColor.withValues( alpha: 0.7),
                                ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ) : null,
                      ),
                    ),
                  ),
                  // Background container (positioned on top to show through the border)
                  Center(
                    child: Container(
                      width: widget.size - (widget.borderStyle.borderWidth * 2),
                      height: widget.size - (widget.borderStyle.borderWidth * 2),
                      decoration: BoxDecoration(
                        color: widget.backgroundColor,
                        shape: widget.borderStyle.shape == ProfileBorderShape.circle 
                            ? BoxShape.circle 
                            : BoxShape.rectangle,
                        borderRadius: widget.borderStyle.shape == ProfileBorderShape.circle 
                            ? null 
                            : BorderRadius.circular(widget.borderStyle.borderRadius - widget.borderStyle.borderWidth),
                        gradient: widget.isPremium && widget.showPremiumEffects
                            ? RadialGradient(
                                colors: [
                                  widget.backgroundColor,
                                  widget.backgroundColor.withValues( alpha: 0.8),
                                ],
                                center: Alignment.center,
                                focal: Alignment.center,
                                radius: 0.8,
                              )
                            : null,
                      ),
                      // Center the icon in the background container
                      child: Icon(
                        widget.icon,
                        color: widget.iconColor,
                        size: widget.size * 0.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Enum defining the shape of the profile border
enum ProfileBorderShape {
  circle,
  roundedSquare,
  diamond,
  hexagon,
  octagon,
}

/// Class defining the style of the profile border
class ProfileBorderStyle {
  final ProfileBorderShape shape;
  final Color borderColor;
  final double borderWidth;
  final double borderRadius;
  final bool useGradient;

  const ProfileBorderStyle({
    required this.shape,
    required this.borderColor,
    this.borderWidth = 2.0,
    this.borderRadius = 16.0,
    this.useGradient = false,
  });

  /// Predefined border styles
  static const ProfileBorderStyle classic = ProfileBorderStyle(
    shape: ProfileBorderShape.circle,
    borderColor: Colors.blue,
    borderWidth: 2.0,
  );

  static const ProfileBorderStyle gold = ProfileBorderStyle(
    shape: ProfileBorderShape.circle,
    borderColor: Colors.amber,
    borderWidth: 3.0,
    useGradient: true,
  );

  static const ProfileBorderStyle emerald = ProfileBorderStyle(
    shape: ProfileBorderShape.circle,
    borderColor: Colors.green,
    borderWidth: 2.5,
    borderRadius: 20.0,
  );

  static const ProfileBorderStyle ruby = ProfileBorderStyle(
    shape: ProfileBorderShape.circle,
    borderColor: Colors.red,
    borderWidth: 2.5,
    borderRadius: 12.0,
    useGradient: true,
  );

  static const ProfileBorderStyle diamond = ProfileBorderStyle(
    shape: ProfileBorderShape.circle,
    borderColor: Colors.lightBlue,
    borderWidth: 2.0,
    borderRadius: 8.0,
    useGradient: true,
  );
}

/// Class providing predefined profile icons
class ProfileIcons {
  /// Standard person icon
  static const IconData person = Icons.person;
  
  /// Smiling face icon
  static const IconData face = Icons.face;
  
  /// Star icon for special users
  static const IconData star = Icons.star;
  
  /// Sports icon for athletic users
  static const IconData sports = Icons.sports_esports;
  
  /// School icon for academic users
  static const IconData school = Icons.school;

  /// Get all available profile icons
  static List<IconData> getAllIcons() {
    return [person, face, star, sports, school];
  }
}

/// Widget for selecting a custom profile icon
class ProfileIconSelector extends StatelessWidget {
  final IconData selectedIcon;
  final ProfileBorderStyle selectedBorderStyle;
  final Function(IconData) onIconSelected;
  final Function(ProfileBorderStyle) onBorderStyleSelected;

  const ProfileIconSelector({
    super.key,
    required this.selectedIcon,
    required this.selectedBorderStyle,
    required this.onIconSelected,
    required this.onBorderStyleSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Choose Your Icon',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 16),
        // Icon selection
        SizedBox(
          height: 80,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: ProfileIcons.getAllIcons().map((icon) {
              final isSelected = selectedIcon == icon;
              return GestureDetector(
                onTap: () => onIconSelected(icon),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected ? Colors.blue : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  child: CustomProfileIcon(
                    icon: icon,
                    borderStyle: selectedBorderStyle,
                    size: 60,
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Choose Your Border',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 16),
        // Border style selection
        SizedBox(
          height: 80,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              ProfileBorderStyle.classic,
              ProfileBorderStyle.gold,
              ProfileBorderStyle.emerald,
              ProfileBorderStyle.ruby,
              ProfileBorderStyle.diamond,
            ].map((style) {
              final isSelected = selectedBorderStyle.shape == style.shape && 
                                selectedBorderStyle.borderColor == style.borderColor;
              return GestureDetector(
                onTap: () => onBorderStyleSelected(style),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected ? Colors.blue : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  child: CustomProfileIcon(
                    icon: selectedIcon,
                    borderStyle: style,
                    size: 60,
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}