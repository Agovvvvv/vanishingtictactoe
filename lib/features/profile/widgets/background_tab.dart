import 'package:flutter/material.dart';
import 'package:vanishingtictactoe/shared/models/unlockable_content.dart';
import 'package:vanishingtictactoe/shared/widgets/custom_icon.dart';
import 'package:vanishingtictactoe/features/profile/widgets/locked_content_section.dart';

class BackgroundTab extends StatefulWidget {
  final IconData selectedIcon;
  final ProfileBorderStyle selectedBorderStyle;
  final Color selectedBackgroundColor;
  final int userLevel;
  final List<UnlockableItem> unlockedBackgrounds;
  final List<UnlockableItem> lockedBackgrounds;
  final Function(Color) onBackgroundSelected;

  const BackgroundTab({
    super.key,
    required this.selectedIcon,
    required this.selectedBorderStyle,
    required this.selectedBackgroundColor,
    required this.userLevel,
    required this.unlockedBackgrounds,
    required this.lockedBackgrounds,
    required this.onBackgroundSelected,
  });

  @override
  State<BackgroundTab> createState() => _BackgroundTabState();
}

class _BackgroundTabState extends State<BackgroundTab> with SingleTickerProviderStateMixin {
  bool _showLockedBackgrounds = false;
  late AnimationController _backgroundsDropdownController;
  late Animation<double> _backgroundsRotationAnimation;

  @override
  void initState() {
    super.initState();
    
    // Initialize dropdown animation controller
    _backgroundsDropdownController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    
    // Initialize rotation animation
    _backgroundsRotationAnimation = Tween<double>(
      begin: 0,
      end: -3.14159 / 2, // -90 degrees
    ).animate(CurvedAnimation(
      parent: _backgroundsDropdownController,
      curve: Curves.elasticOut,
    ));
  }

  @override
  void dispose() {
    _backgroundsDropdownController.dispose();
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
                  color: widget.selectedBackgroundColor.withValues( alpha: 0.25), // Increased opacity
                  blurRadius: 24, // Increased blur
                  spreadRadius: 6, // Increased spread
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
              // Show premium effects if the selected background is premium
              isPremium: widget.unlockedBackgrounds.any((item) => 
                item.content == widget.selectedBackgroundColor && item.isPremium),
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
                    'Select Your Background Color',
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
                        blurRadius: 6, // Increased blur
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
          
          // Unlocked Backgrounds Section with modern styling
          if (widget.unlockedBackgrounds.isNotEmpty) ...[  
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
                  'Available Colors',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16, // Increased font size
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
            // Fixed height instead of Expanded
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0), // Added padding
                child: GridView.count(
                  shrinkWrap: true, // This makes the grid take only the space it needs
                    physics: const NeverScrollableScrollPhysics(), // Disable scrolling
                    crossAxisCount: 4,
                    mainAxisSpacing: 20, // Increased spacing
                    crossAxisSpacing: 20, // Increased spacing
                    childAspectRatio: 1.0,
                  children: List.generate(widget.unlockedBackgrounds.length, (index) {
                    final item = widget.unlockedBackgrounds[index];
                    final color = item.content as Color;
                    final isPremium = item.isPremium;
                    final isSelected = widget.selectedBackgroundColor == color;
                    
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      transform: isSelected 
                          ? (Matrix4.identity()..scale(1.06)) // Slightly increased scale
                          : Matrix4.identity(),
                      child: GestureDetector(
                        onTap: () => widget.onBackgroundSelected(color),
                        child: Stack(
                          children: [
                            // Color circle with animation
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              margin: const EdgeInsets.all(4.0), // Added margin
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: color,
                                border: Border.all(
                                  color: isSelected ? const Color(0xFF2962FF) : Colors.transparent, // Using primary blue
                                  width: 3.5, // Increased width
                                ),
                                boxShadow: isSelected ? [
                                  BoxShadow(
                                    color: color.withValues( alpha: 0.6), // Increased opacity
                                    blurRadius: 14, // Increased blur
                                    spreadRadius: 2,
                                  ),
                                ] : [
                                  BoxShadow(
                                    color: Colors.black26,
                                    blurRadius: 5, // Increased blur
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                                gradient: isPremium ? RadialGradient(
                                  colors: [
                                    color,
                                    color.withValues( alpha: 0.7),
                                  ],
                                  center: Alignment.center,
                                  focal: Alignment.center,
                                  radius: 0.8,
                                ) : null,
                              ),
                            ),
                            // Premium indicator with improved styling
                            if (isPremium)
                              Positioned(
                                top: 2, // Adjusted position
                                right: 2, // Adjusted position
                                child: Container(
                                  padding: const EdgeInsets.all(4.5), // Increased padding
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
                                    size: 13, // Increased size
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
          
          // Locked Backgrounds Section with enhanced styling
          if (widget.lockedBackgrounds.isNotEmpty) 
            Container(
              margin: const EdgeInsets.only(top: 16, bottom: 8), // Increased margin
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20), // Increased radius
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues( alpha: 0.05), // Changed color
                    blurRadius: 10, // Increased blur
                    spreadRadius: 1,
                    offset: const Offset(0, 3), // Adjusted offset
                  ),
                ],
              ),
              child: LockedContentSection(
                title: 'Locked Colors',
                lockedItems: widget.lockedBackgrounds,
                isExpanded: _showLockedBackgrounds,
                rotationAnimation: _backgroundsRotationAnimation,
                onToggle: () {
                  setState(() {
                    _showLockedBackgrounds = !_showLockedBackgrounds;
                    if (_showLockedBackgrounds) {
                      _backgroundsDropdownController.forward();
                    } else {
                      _backgroundsDropdownController.reverse();
                    }
                  });
                },
                itemBuilder: (context, index) {
                  final item = widget.lockedBackgrounds[index];
                  final color = item.content as Color;
                  
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
                            color: Colors.black.withValues( alpha: 0.1),
                            blurRadius: 6, // Increased blur
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: Container(
                        height: 65, // Increased size
                        width: 65, // Increased size
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: color.withValues( alpha: 0.3),
                          border: Border.all(
                            color: Colors.grey.shade200,
                            width: 1.5, // Added border
                          ),
                        ),
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