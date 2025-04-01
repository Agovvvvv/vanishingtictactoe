import 'package:flutter/material.dart';
import 'package:vanishingtictactoe/shared/models/unlockable_content.dart';
import 'package:vanishingtictactoe/shared/widgets/custom_icon.dart';

class ItemIconWidget extends StatelessWidget {
  final UnlockableItem item;
  
  const ItemIconWidget({
    super.key,
    required this.item,
  });
  
  @override
  Widget build(BuildContext context) {
    switch (item.type) {
      case UnlockableType.icon:
        return Icon(
          item.content as IconData,
          size: 30,
          color: item.isPremium ? Colors.amber.shade300 : Colors.white,
        );
      case UnlockableType.border:
        return Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: (item.content as ProfileBorderStyle).borderColor,
              width: 3,
            ),
          ),
        );
      case UnlockableType.background:
        return Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: item.content as Color,
            shape: BoxShape.circle,
          ),
        );
      default:
        return const Icon(Icons.star, size: 30, color: Colors.white);
    }
  }
}