import 'package:flutter/material.dart';
import 'package:vanishingtictactoe/shared/models/unlockable_content.dart';
import 'package:vanishingtictactoe/shared/widgets/custom_icon.dart';
import 'package:vanishingtictactoe/features/profile/widgets/locked_content_section.dart';

class IconsTab extends StatefulWidget {
  final IconData selectedIcon;
  final ProfileBorderStyle selectedBorderStyle;
  final Color selectedBackgroundColor;
  final int userLevel;
  final List<UnlockableItem> unlockedIcons;
  final List<UnlockableItem> lockedIcons;
  final Function(IconData) onIconSelected;

  const IconsTab({
    super.key,
    required this.selectedIcon,
    required this.selectedBorderStyle,
    required this.selectedBackgroundColor,
    required this.userLevel,
    required this.unlockedIcons,
    required this.lockedIcons,
    required this.onIconSelected,
  });

  @override
  State<IconsTab> createState() => _IconsTabState();
}

class _IconsTabState extends State<IconsTab> with SingleTickerProviderStateMixin {
  bool _showLockedIcons = false;
  late AnimationController _iconsDropdownController;
  late Animation<double> _iconsRotationAnimation;

  @override
  void initState() {
    super.initState();
    
    // Initialize dropdown animation controller
    _iconsDropdownController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    
    // Initialize rotation animation - for upward expansion
    _iconsRotationAnimation = Tween<double>(
      begin: 0,
      end: -3.14159 / 2, // -90 degrees (pointing upwards)
    ).animate(CurvedAnimation(
      parent: _iconsDropdownController,
      curve: Curves.elasticOut,
    ));
  }

  @override
  void dispose() {
    _iconsDropdownController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24.0), // Increased padding
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Preview with enhanced styling
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            margin: const EdgeInsets.only(bottom: 36.0), // Increased margin
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: widget.selectedBackgroundColor.withValues( alpha: 0.25),
                  blurRadius: 24,
                  spreadRadius: 6,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: CustomProfileIcon(
              icon: widget.selectedIcon,
              borderStyle: widget.selectedBorderStyle,
              size: 130, // Increased size
              backgroundColor: widget.selectedBackgroundColor,
              iconColor: Colors.white,
              // Show premium effects if the selected icon is premium
              isPremium: widget.unlockedIcons.any((item) => 
                item.content == widget.selectedIcon && item.isPremium),
            ),
          ),
          // Modern title with level indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10), // Increased padding
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF2962FF).withValues( alpha: 0.1), // Using primary blue
                  const Color(0xFF2962FF).withValues( alpha: 0.05),
                ],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues( alpha: 0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                  child: const Text(
                    'Select Your Icon',
                    style: TextStyle(
                      fontSize: 16, 
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 12), // Increased spacing
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5), // Increased padding
                  decoration: BoxDecoration(
                    color: Colors.amber.shade700,
                    borderRadius: BorderRadius.circular(14), // Increased radius
                    boxShadow: [
                      BoxShadow(
                        color: Colors.amber.shade700.withValues( alpha: 0.3),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    'LVL ${widget.userLevel}',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32), // Increased spacing
          
          // Unlocked Icons Section with modern styling
          if (widget.unlockedIcons.isNotEmpty) ...[  
            Align(
              alignment: Alignment.centerLeft,
              child: Container(
                margin: const EdgeInsets.only(left: 12.0, bottom: 16.0), // Increased margins
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), // Increased padding
                decoration: BoxDecoration(
                  color: const Color(0xFF2962FF).withValues( alpha: 0.08), // Using primary blue
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(4),
                    topRight: Radius.circular(16), // Increased radius
                    bottomRight: Radius.circular(16), // Increased radius
                  ),
                  border: Border(left: BorderSide(color: const Color(0xFF2962FF), width: 3)), // Using primary blue
                ),
                child: const Text(
                  'Available Icons',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16, // Increased font size
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0), // Added padding
              child: GridView.count(
                shrinkWrap: true, // This makes the grid take only the space it needs
                physics: const NeverScrollableScrollPhysics(), // Disable scrolling
                crossAxisCount: 3,
                mainAxisSpacing: 20, // Increased spacing
                crossAxisSpacing: 20, // Increased spacing
                childAspectRatio: 0.9,
                  children: List.generate(widget.unlockedIcons.length, (index) {
                    final item = widget.unlockedIcons[index];
                    final icon = item.content as IconData;
                    final isSelected = widget.selectedIcon == icon;
                    final isPremium = item.isPremium;
                    
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      transform: isSelected 
                          ? (Matrix4.identity()..scale(1.06)) // Slightly increased scale
                          : Matrix4.identity(),
                      child: GestureDetector(
                        onTap: () => widget.onIconSelected(icon),
                        child: Stack(
                          children: [
                            // Selection indicator with animation
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isSelected ? const Color(0xFF2962FF) : Colors.transparent, // Using primary blue
                                  width: 3,
                                ),
                                boxShadow: isSelected ? [
                                  BoxShadow(
                                    color: const Color(0xFF2962FF).withValues(alpha: 0.4), // Using primary blue
                                    blurRadius: 14,
                                    spreadRadius: 2,
                                  ),
                                ] : [],
                              ),
                              child: CustomProfileIcon(
                                icon: icon,
                                borderStyle: widget.selectedBorderStyle,
                                size: 85, // Slightly increased size
                                backgroundColor: isSelected ? const Color(0xFF2962FF) : const Color(0xFF5C8AFF), // Using primary blue shades
                                isPremium: isPremium,
                              ),
                            ),
                            // Premium indicator with improved styling
                            if (isPremium)
                              Positioned(
                                top: 0,
                                right: 0,
                                child: Container(
                                  padding: const EdgeInsets.all(5), // Increased padding
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Colors.amber.shade600,
                                        Colors.amber.shade400,
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.amber.shade600.withValues(alpha: 0.5),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.star,
                                    color: Colors.white,
                                    size: 14, // Increased size
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          
            // Locked Icons Section with enhanced styling - opens upwards
          if (widget.lockedIcons.isNotEmpty) 
            Container(
              margin: const EdgeInsets.only(top: 16, bottom: 8), // Added bottom margin
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20), // Increased radius
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    spreadRadius: 1,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  // Expanded content that appears above the toggle button
                  if (_showLockedIcons)
                    Positioned(
                      bottom: 50, // Position above the toggle button
                      left: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 10,
                              spreadRadius: 1,
                              offset: const Offset(0, -3), // Shadow appears above
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: Text(
                                'Locked Icons',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Theme.of(context).primaryColor,
                                ),
                              ),
                            ),
                            GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 3,
                                mainAxisSpacing: 20,
                                crossAxisSpacing: 20,
                                childAspectRatio: 0.9,
                              ),
                              itemCount: widget.lockedIcons.length,
                              itemBuilder: (context, index) {
                                final item = widget.lockedIcons[index];
                                final icon = item.content as IconData;
                                
                                return LockedItemCard(
                                  item: item,
                                  itemPreview: Container(
                                    padding: const EdgeInsets.all(3), // Increased padding
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: LinearGradient(
                                        colors: [
                                          Colors.grey.shade300,
                                          Colors.grey.shade400,
                                        ],
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha: 0.1),
                                          blurRadius: 4,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: CustomProfileIcon(
                                      icon: icon,
                                      borderStyle: ProfileBorderStyle.classic,
                                      size: 65, // Increased size
                                      backgroundColor: Colors.grey.shade400,
                                      iconColor: Colors.white.withValues(alpha: 0.7),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  // Toggle button
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _showLockedIcons = !_showLockedIcons;
                        if (_showLockedIcons) {
                          _iconsDropdownController.forward();
                        } else {
                          _iconsDropdownController.reverse();
                        }
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 5,
                            spreadRadius: 1,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.lock,
                                color: Theme.of(context).primaryColor.withValues(alpha: 0.7),
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Locked Icons',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).primaryColor,
                                ),
                              ),
                            ],
                          ),
                          AnimatedBuilder(
                            animation: _iconsRotationAnimation,
                            builder: (context, child) {
                              return Transform.rotate(
                                angle: _iconsRotationAnimation.value,
                                child: Icon(
                                  Icons.arrow_forward_ios,
                                  size: 16,
                                  color: Theme.of(context).primaryColor,
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}