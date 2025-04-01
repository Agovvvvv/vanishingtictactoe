import 'package:flutter/material.dart';
import 'package:vanishingtictactoe/core/utils/font_preloader.dart';
import 'package:vanishingtictactoe/features/profile/widgets/levelup/item_icon_widget.dart';
import 'package:vanishingtictactoe/shared/models/unlockable_content.dart';

class UnlockableItemCard extends StatelessWidget {
  final UnlockableItem item;
  final int index;
  final bool isHighlighted;
  
  const UnlockableItemCard({
    super.key,
    required this.item,
    required this.index,
    this.isHighlighted = false,
  });
  
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 80,
      height: 100,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: item.isPremium 
              ? [
                  Colors.amber.shade800.withAlpha(isHighlighted ? 102 : 77), // 0.4/0.3 opacity
                  Colors.amber.shade900.withAlpha(isHighlighted ? 77 : 51), // 0.3/0.2 opacity
                ]
              : [
                  Colors.blue.shade700.withAlpha(isHighlighted ? 102 : 77), // 0.4/0.3 opacity
                  Colors.blue.shade900.withAlpha(isHighlighted ? 77 : 51), // 0.3/0.2 opacity
                ],
        ),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: item.isPremium 
              ? Colors.amber.shade300
              : Colors.white.withAlpha(128), // 0.5 opacity = 128 alpha
          width: isHighlighted ? 3 : 2,
        ),
        boxShadow: [
          BoxShadow(
            color: item.isPremium
                ? Colors.amber.withAlpha(isHighlighted ? 153 : 102) // 0.6/0.4 opacity
                : Colors.blue.withAlpha(isHighlighted ? 153 : 102), // 0.6/0.4 opacity
            blurRadius: isHighlighted ? 20 : 15,
            spreadRadius: isHighlighted ? 3 : 2,
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ItemIconWidget(
            item: item
          ),
          const SizedBox(height: 8),
          Text(
            item.name,
            textAlign: TextAlign.center,
            style: FontPreloader.getTextStyle(
              fontFamily: 'Poppins',
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: item.isPremium
                  ? Colors.amber.shade300
                  : Colors.white,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}