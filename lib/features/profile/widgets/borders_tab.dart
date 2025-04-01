import 'package:flutter/material.dart';
import 'package:vanishingtictactoe/shared/models/unlockable_content.dart';
import 'package:vanishingtictactoe/shared/widgets/custom_icon.dart';
import 'package:vanishingtictactoe/features/profile/widgets/locked_content_section.dart';

class BordersTab extends StatefulWidget {
  final IconData selectedIcon;
  final ProfileBorderStyle selectedBorderStyle;
  final Color selectedBackgroundColor;
  final int userLevel;
  final List<UnlockableItem> unlockedBorders;
  final List<UnlockableItem> lockedBorders;
  final Function(ProfileBorderStyle) onBorderSelected;

  const BordersTab({
    super.key,
    required this.selectedIcon,
    required this.selectedBorderStyle,
    required this.selectedBackgroundColor,
    required this.userLevel,
    required this.unlockedBorders,
    required this.lockedBorders,
    required this.onBorderSelected,
  });

  @override
  State<BordersTab> createState() => _BordersTabState();
}

class _BordersTabState extends State<BordersTab> with SingleTickerProviderStateMixin {
  bool _showLockedBorders = false;
  late AnimationController _bordersDropdownController;
  late Animation<double> _bordersRotationAnimation;

  @override
  void initState() {
    super.initState();
    
    // Initialize dropdown animation controller
    _bordersDropdownController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    
    // Initialize rotation animation
    _bordersRotationAnimation = Tween<double>(
      begin: 0,
      end: -3.14159 / 2, // -90 degrees
    ).animate(CurvedAnimation(
      parent: _bordersDropdownController,
      curve: Curves.elasticOut,
    ));
  }

  @override
  void dispose() {
    _bordersDropdownController.dispose();
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
                  color: widget.selectedBorderStyle.borderColor.withValues( alpha: 0.25),
                  blurRadius: 24,
                  spreadRadius: 6,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: CustomProfileIcon(
              icon: widget.selectedIcon,
              // Force circle shape for the preview regardless of the original border style
              borderStyle: ProfileBorderStyle(
                shape: ProfileBorderShape.circle,
                borderColor: widget.selectedBorderStyle.borderColor,
                borderWidth: widget.selectedBorderStyle.borderWidth,
                useGradient: widget.selectedBorderStyle.useGradient,
              ),
              size: 130, // Increased size
              backgroundColor: widget.selectedBackgroundColor,
              iconColor: Colors.white,
              // Show premium effects if the selected border is premium
              isPremium: widget.unlockedBorders.any((item) => 
                item.content.borderColor == widget.selectedBorderStyle.borderColor && item.isPremium),
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
                    'Select Your Border',
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
          
          // Unlocked Borders Section with modern styling
          if (widget.unlockedBorders.isNotEmpty) ...[  
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
                  'Available Borders',
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
                    crossAxisCount: 2,
                    mainAxisSpacing: 20, // Increased spacing
                    crossAxisSpacing: 20, // Increased spacing
                    childAspectRatio: 1.0,
                  children: List.generate(widget.unlockedBorders.length, (index) {
                    final item = widget.unlockedBorders[index];
                    final style = item.content as ProfileBorderStyle;
                    final isPremium = item.isPremium;
                    final isSelected = widget.selectedBorderStyle.borderColor == style.borderColor &&
                                      widget.selectedBorderStyle.borderWidth == style.borderWidth &&
                                      widget.selectedBorderStyle.useGradient == style.useGradient;
                    
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      transform: isSelected 
                          ? (Matrix4.identity()..scale(1.06)) // Slightly increased scale
                          : Matrix4.identity(),
                      child: GestureDetector(
                        onTap: () => widget.onBorderSelected(ProfileBorderStyle(
                          // Always use circle shape for consistency regardless of original style
                          shape: ProfileBorderShape.circle,
                          borderColor: style.borderColor,
                          borderWidth: style.borderWidth,
                          useGradient: style.useGradient,
                        )),
                        child: Stack(
                          children: [
                            // Selection indicator with animation - Improved styling
                            Container(
                              padding: const EdgeInsets.all(10.0), // Increased padding
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16), // Increased radius
                                  border: Border.all(
                                    color: isSelected ? const Color(0xFF2962FF) : Colors.transparent, // Using primary blue
                                    width: 2.5, // Slightly increased width
                                  ),
                                  boxShadow: isSelected ? [
                                    BoxShadow(
                                      color: const Color(0xFF2962FF).withValues( alpha: 0.3), // Using primary blue
                                      blurRadius: 10,
                                      spreadRadius: 1,
                                    ),
                                  ] : [],
                                ),
                                child: Center(
                                  child: CustomProfileIcon(
                                    icon: widget.selectedIcon,
                                    borderStyle: ProfileBorderStyle(
                                      // Always force circle shape regardless of original style
                                      shape: ProfileBorderShape.circle,
                                      borderColor: style.borderColor,
                                      borderWidth: style.borderWidth,
                                      useGradient: style.useGradient,
                                    ),
                                    size: 85, // Increased size
                                    backgroundColor: widget.selectedBackgroundColor,
                                    isPremium: isPremium,
                                  ),
                                ),
                              ),
                            ),
                            // Premium indicator with improved styling
                            if (isPremium)
                              Positioned(
                                top: 14, // Adjusted position
                                right: 14, // Adjusted position
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
                                        color: Colors.amber.shade600.withValues( alpha: 0.5),
                                        blurRadius: 6,
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
          
          // Locked Borders Section with enhanced styling
          if (widget.lockedBorders.isNotEmpty) 
            Container(
              margin: const EdgeInsets.only(top: 16, bottom: 8), // Added margins
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20), // Increased radius
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues( alpha: 0.05),
                    blurRadius: 10,
                    spreadRadius: 1,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: LockedContentSection(
                title: 'Locked Borders',
                lockedItems: widget.lockedBorders,
                isExpanded: _showLockedBorders,
                rotationAnimation: _bordersRotationAnimation,
                onToggle: () {
                  setState(() {
                    _showLockedBorders = !_showLockedBorders;
                    if (_showLockedBorders) {
                      _bordersDropdownController.forward();
                    } else {
                      _bordersDropdownController.reverse();
                    }
                  });
                },
                itemBuilder: (context, index) {
                  final item = widget.lockedBorders[index];
                  final style = item.content as ProfileBorderStyle;
                  
                  return LockedItemCard(
                    item: item,
                    itemPreview: Container(
                      padding: const EdgeInsets.all(3), // Increased padding
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.grey.shade200,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues( alpha: 0.1),
                            blurRadius: 6, // Increased blur
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: CustomProfileIcon(
                        icon: widget.selectedIcon,
                        borderStyle: ProfileBorderStyle(
                          // Always force circle shape for locked borders too
                          shape: ProfileBorderShape.circle,
                          borderColor: style.borderColor.withValues( alpha: 0.5),
                          borderWidth: style.borderWidth,
                          useGradient: false,
                        ),
                        size: 65, // Increased size
                        backgroundColor: Colors.white,
                        iconColor: Colors.white.withValues( alpha: 0.7),
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
        ),
      ),
    );
  }
}