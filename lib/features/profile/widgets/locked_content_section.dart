import 'package:flutter/material.dart';
import 'package:vanishingtictactoe/shared/models/unlockable_content.dart';
import 'dart:ui' as ui;

/// A reusable widget for displaying locked content sections in the profile customization screens
class LockedContentSection extends StatefulWidget {
  final String title;
  final List<UnlockableItem> lockedItems;
  final bool isExpanded;
  final Animation<double> rotationAnimation;
  final Function() onToggle;
  final Widget Function(BuildContext, int) itemBuilder;

  const LockedContentSection({
    super.key,
    required this.title,
    required this.lockedItems,
    required this.isExpanded,
    required this.rotationAnimation,
    required this.onToggle,
    required this.itemBuilder,
  });

  @override
  State<LockedContentSection> createState() => _LockedContentSectionState();
}

class _LockedContentSectionState extends State<LockedContentSection> {
  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Expanded content that appears above the toggle button when expanded
        if (widget.isExpanded)
          Positioned(
            bottom: 50, // Position above the toggle button
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
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
                      widget.title,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                  ),
                  // Grid layout for the locked items with scrolling support
                  Container(
                    constraints: BoxConstraints(
                      maxHeight: MediaQuery.of(context).size.height * 0.4, // Limit height to 40% of screen
                    ),
                    child: GridView.builder(
                      shrinkWrap: true,
                      physics: const BouncingScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        mainAxisSpacing: 16,
                        crossAxisSpacing: 16,
                        childAspectRatio: 0.75, // Adjusted for better fit
                      ),
                      itemCount: widget.lockedItems.length,
                      itemBuilder: widget.itemBuilder,
                    ),
                  ),
                ],
              ),
            ),
          ),
        // Toggle button
        GestureDetector(
          onTap: widget.onToggle,
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
                      widget.title,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                  ],
                ),
                AnimatedBuilder(
                  animation: widget.rotationAnimation,
                  builder: (context, child) {
                    return Transform.rotate(
                      angle: widget.rotationAnimation.value,
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
    );
  }
}

/// A reusable widget for displaying a locked item in the profile customization screens
class LockedItemCard extends StatelessWidget {
  final UnlockableItem item;
  final Widget itemPreview;

  const LockedItemCard({
    super.key,
    required this.item,
    required this.itemPreview,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      // Fixed size container to prevent overflow
      width: 80,
      height: 100,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Preview with lock overlay - takes most of the space
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(bottom: 4),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  // The actual preview widget
                  Positioned.fill(child: itemPreview),
                  // Lock overlay
                  Positioned.fill(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(item.isPremium ? 12 : 0),
                      child: BackdropFilter(
                        filter: ui.ImageFilter.blur(sigmaX: 1.5, sigmaY: 1.5),
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              colors: [
                                Colors.black.withValues(alpha: 0.3),
                                Colors.black.withValues(alpha: 0.6),
                              ],
                              stops: const [0.6, 1.0],
                            ),
                          ),
                          child: Center(
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.black.withValues(alpha: 0.4),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.2),
                                    blurRadius: 4,
                                    spreadRadius: 1,
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.lock_outline_rounded,
                                color: Colors.white,
                                size: 16, // Slightly smaller icon
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Level requirement - compact design
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.amber.shade100,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              'LVL ${item.requiredLevel}',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: Colors.amber.shade800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}