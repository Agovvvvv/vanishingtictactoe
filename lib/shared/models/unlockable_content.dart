import 'package:flutter/material.dart';
import 'package:vanishingtictactoe/shared/widgets/custom_icon.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

/// Defines the type of unlockable content
enum UnlockableType {
  icon,
  border,
  background,
  effect
}

/// Represents an unlockable item that can be earned through level progression
class UnlockableItem {
  final String id;
  final String name;
  final String description;
  final int requiredLevel;
  final UnlockableType type;
  final dynamic content; // The actual content (IconData, ProfileBorderStyle, Color, etc.)
  final bool isPremium; // Whether this is a premium/exclusive item
  
  const UnlockableItem({
    required this.id,
    required this.name,
    required this.description,
    required this.requiredLevel,
    required this.type,
    required this.content,
    this.isPremium = false,
  });
  
  // Check if this item is unlocked based on user level
  bool isUnlocked(int userLevel) {
    return userLevel >= requiredLevel;
  }
}

/// Manages all unlockable content in the app
class UnlockableContent {
  // Premium Icons (unlocked at higher levels)
  static const IconData diamondIcon = Icons.diamond;
  static const IconData crownIcon = FontAwesomeIcons.crown;
  static const IconData rocketIcon = Icons.rocket;
  static const IconData trophyIcon = Icons.emoji_events;
  static const IconData ninjaIcon = Icons.sports_martial_arts;
  
  // Premium Border Styles
  static const ProfileBorderStyle platinumBorder = ProfileBorderStyle(
    shape: ProfileBorderShape.circle,
    borderColor: Color(0xFFE5E4E2), // Platinum color
    borderWidth: 3.5,
    useGradient: true,
  );
  
  static const ProfileBorderStyle rainbowBorder = ProfileBorderStyle(
    shape: ProfileBorderShape.circle,
    borderColor: Colors.purple, // Base color for rainbow
    borderWidth: 3.0,
    useGradient: true,
  );
  
  static const ProfileBorderStyle crystalBorder = ProfileBorderStyle(
    shape: ProfileBorderShape.roundedSquare,
    borderColor: Colors.cyan,
    borderWidth: 3.0,
    borderRadius: 15.0,
    useGradient: true,
  );
  
  static const ProfileBorderStyle obsidianBorder = ProfileBorderStyle(
    shape: ProfileBorderShape.roundedSquare,
    borderColor: Colors.black,
    borderWidth: 3.5,
    borderRadius: 10.0,
    useGradient: true,
  );
  
  // Premium Background Colors
  static final Color galaxyPurple = Colors.deepPurple.shade800;
  static final Color royalGold = Color(0xFFFFD700);
  static final Color deepOcean = Colors.indigo.shade900;
  static final Color volcanicRed = Colors.red.shade900;
  
  // List of all unlockable icons
  static List<UnlockableItem> getUnlockableIcons() {
    return [
      // Standard icons are available from the start
      UnlockableItem(
        id: 'icon_person',
        name: 'Person',
        description: 'Standard profile icon',
        requiredLevel: 1,
        type: UnlockableType.icon,
        content: ProfileIcons.person,
      ),
      UnlockableItem(
        id: 'icon_face',
        name: 'Face',
        description: 'Friendly face icon',
        requiredLevel: 1,
        type: UnlockableType.icon,
        content: ProfileIcons.face,
      ),
      UnlockableItem(
        id: 'icon_star',
        name: 'Star',
        description: 'Star icon for achievers',
        requiredLevel: 3,
        type: UnlockableType.icon,
        content: ProfileIcons.star,
      ),
      UnlockableItem(
        id: 'icon_sports',
        name: 'Gamer',
        description: 'Icon for gaming enthusiasts',
        requiredLevel: 5,
        type: UnlockableType.icon,
        content: ProfileIcons.sports,
      ),
      UnlockableItem(
        id: 'icon_school',
        name: 'Scholar',
        description: 'Icon for strategic thinkers',
        requiredLevel: 7,
        type: UnlockableType.icon,
        content: ProfileIcons.school,
      ),
      // Premium icons unlocked at higher levels
      UnlockableItem(
        id: 'icon_diamond',
        name: 'Diamond',
        description: 'Exclusive diamond icon for high-level players',
        requiredLevel: 10,
        type: UnlockableType.icon,
        content: diamondIcon,
        isPremium: true,
      ),
      UnlockableItem(
        id: 'icon_crown',
        name: 'Crown',
        description: 'Royal crown for the elite players',
        requiredLevel: 15,
        type: UnlockableType.icon,
        content: crownIcon,
        isPremium: true,
      ),
      UnlockableItem(
        id: 'icon_rocket',
        name: 'Rocket',
        description: 'Soar above the competition',
        requiredLevel: 20,
        type: UnlockableType.icon,
        content: rocketIcon,
        isPremium: true,
      ),
      UnlockableItem(
        id: 'icon_trophy',
        name: 'Trophy',
        description: 'Champion of the game',
        requiredLevel: 25,
        type: UnlockableType.icon,
        content: trophyIcon,
        isPremium: true,
      ),
      UnlockableItem(
        id: 'icon_ninja',
        name: 'Ninja',
        description: 'Master of stealth and strategy',
        requiredLevel: 30,
        type: UnlockableType.icon,
        content: ninjaIcon,
        isPremium: true,
      ),
    ];
  }
  
  // List of all unlockable border styles
  static List<UnlockableItem> getUnlockableBorders() {
    return [
      // Standard borders available from the start or at low levels
      UnlockableItem(
        id: 'border_classic',
        name: 'Classic',
        description: 'Simple blue border',
        requiredLevel: 1,
        type: UnlockableType.border,
        content: ProfileBorderStyle.classic,
      ),
      UnlockableItem(
        id: 'border_gold',
        name: 'Gold',
        description: 'Golden border for winners',
        requiredLevel: 5,
        type: UnlockableType.border,
        content: ProfileBorderStyle.gold,
      ),
      UnlockableItem(
        id: 'border_emerald',
        name: 'Emerald',
        description: 'Emerald green border',
        requiredLevel: 8,
        type: UnlockableType.border,
        content: ProfileBorderStyle.emerald,
      ),
      UnlockableItem(
        id: 'border_ruby',
        name: 'Ruby',
        description: 'Ruby red border',
        requiredLevel: 12,
        type: UnlockableType.border,
        content: ProfileBorderStyle.ruby,
      ),
      UnlockableItem(
        id: 'border_diamond',
        name: 'Diamond',
        description: 'Diamond blue border',
        requiredLevel: 15,
        type: UnlockableType.border,
        content: ProfileBorderStyle.diamond,
      ),
      // Premium borders unlocked at higher levels
      UnlockableItem(
        id: 'border_platinum',
        name: 'Platinum',
        description: 'Exclusive platinum border for high-level players',
        requiredLevel: 20,
        type: UnlockableType.border,
        content: platinumBorder,
        isPremium: true,
      ),
      UnlockableItem(
        id: 'border_rainbow',
        name: 'Rainbow',
        description: 'Colorful rainbow border for the elite',
        requiredLevel: 25,
        type: UnlockableType.border,
        content: rainbowBorder,
        isPremium: true,
      ),
      UnlockableItem(
        id: 'border_crystal',
        name: 'Crystal',
        description: 'Shimmering crystal border',
        requiredLevel: 30,
        type: UnlockableType.border,
        content: crystalBorder,
        isPremium: true,
      ),
      UnlockableItem(
        id: 'border_obsidian',
        name: 'Obsidian',
        description: 'Dark and mysterious obsidian border',
        requiredLevel: 35,
        type: UnlockableType.border,
        content: obsidianBorder,
        isPremium: true,
      ),
    ];
  }
  
  // List of all unlockable background colors
  static List<UnlockableItem> getUnlockableBackgrounds() {
    return [
      // Standard backgrounds available from the start or at low levels
      UnlockableItem(
        id: 'bg_blue',
        name: 'Blue',
        description: 'Standard blue background',
        requiredLevel: 1,
        type: UnlockableType.background,
        content: Colors.blue,
      ),
      UnlockableItem(
        id: 'bg_red',
        name: 'Red',
        description: 'Vibrant red background',
        requiredLevel: 2,
        type: UnlockableType.background,
        content: Colors.red,
      ),
      UnlockableItem(
        id: 'bg_green',
        name: 'Green',
        description: 'Fresh green background',
        requiredLevel: 3,
        type: UnlockableType.background,
        content: Colors.green,
      ),
      UnlockableItem(
        id: 'bg_purple',
        name: 'Purple',
        description: 'Royal purple background',
        requiredLevel: 4,
        type: UnlockableType.background,
        content: Colors.purple,
      ),
      UnlockableItem(
        id: 'bg_orange',
        name: 'Orange',
        description: 'Energetic orange background',
        requiredLevel: 5,
        type: UnlockableType.background,
        content: Colors.orange,
      ),
      // Premium backgrounds unlocked at higher levels
      UnlockableItem(
        id: 'bg_galaxy',
        name: 'Galaxy Purple',
        description: 'Deep space purple background',
        requiredLevel: 10,
        type: UnlockableType.background,
        content: galaxyPurple,
        isPremium: true,
      ),
      UnlockableItem(
        id: 'bg_gold',
        name: 'Royal Gold',
        description: 'Luxurious gold background',
        requiredLevel: 15,
        type: UnlockableType.background,
        content: royalGold,
        isPremium: true,
      ),
      UnlockableItem(
        id: 'bg_ocean',
        name: 'Deep Ocean',
        description: 'Mysterious deep ocean background',
        requiredLevel: 20,
        type: UnlockableType.background,
        content: deepOcean,
        isPremium: true,
      ),
      UnlockableItem(
        id: 'bg_volcanic',
        name: 'Volcanic Red',
        description: 'Intense volcanic red background',
        requiredLevel: 25,
        type: UnlockableType.background,
        content: volcanicRed,
        isPremium: true,
      ),
    ];
  }
  
  // Get all unlockable items
  static List<UnlockableItem> getAllUnlockables() {
    return [
      ...getUnlockableIcons(),
      ...getUnlockableBorders(),
      ...getUnlockableBackgrounds(),
    ];
  }
  
  // Get all items of a specific type
  static List<UnlockableItem> getAllItems({UnlockableType? type}) {
    if (type == null) {
      return getAllUnlockables();
    }
    
    switch (type) {
      case UnlockableType.icon:
        return getUnlockableIcons();
      case UnlockableType.border:
        return getUnlockableBorders();
      case UnlockableType.background:
        return getUnlockableBackgrounds();
      case UnlockableType.effect:
        return []; // No effects implemented yet
    }
  }
  
  // Get unlocked items based on user level
  static List<UnlockableItem> getUnlockedItems(int userLevel, {UnlockableType? type}) {
    final allItems = getAllUnlockables();
    
    return allItems.where((item) {
      final typeMatch = type == null || item.type == type;
      return item.isUnlocked(userLevel) && typeMatch;
    }).toList();
  }
  
  // Get locked items based on user level
  static List<UnlockableItem> getLockedItems(int userLevel, {UnlockableType? type}) {
    final allItems = getAllUnlockables();
    
    return allItems.where((item) {
      final typeMatch = type == null || item.type == type;
      return !item.isUnlocked(userLevel) && typeMatch;
    }).toList();
  }
  
  // Get next unlockable items (items that will be unlocked at the next few levels)
  static List<UnlockableItem> getNextUnlockables(int userLevel, {int count = 3, UnlockableType? type}) {
    final lockedItems = getLockedItems(userLevel, type: type);
    
    // Sort by required level (ascending)
    lockedItems.sort((a, b) => a.requiredLevel.compareTo(b.requiredLevel));
    
    // Return the next 'count' items
    return lockedItems.take(count).toList();
  }
  
  // Add this method if it doesn't exist
  static List<UnlockableItem> getUnlockablesForLevel(int level) {
    final allUnlockables = getAllUnlockables();
    return allUnlockables.where((item) => item.requiredLevel == level).toList();
  }
  
  // Check if an icon is premium
  static bool isPremiumIcon(IconData icon) {
    final allIcons = getUnlockableIcons();
    final matchingIcon = allIcons.where((item) => 
      (item.content as IconData).codePoint == icon.codePoint &&
      (item.content as IconData).fontFamily == icon.fontFamily
    ).toList();
    
    return matchingIcon.isNotEmpty && matchingIcon.first.isPremium;
  }
  
  // Check if a border style is premium
  static bool isPremiumBorderStyle(ProfileBorderStyle borderStyle) {
    final allBorders = getUnlockableBorders();
    final matchingBorder = allBorders.where((item) {
      final itemBorder = item.content as ProfileBorderStyle;
      return itemBorder.borderColor == borderStyle.borderColor &&
             itemBorder.shape == borderStyle.shape;
    }).toList();
    
    return matchingBorder.isNotEmpty && matchingBorder.first.isPremium;
  }
  
  // Check if a background color is premium
  static bool isPremiumBackgroundColor(Color backgroundColor) {
    final allBackgrounds = getUnlockableBackgrounds();
    final matchingBackground = allBackgrounds.where((item) => 
      (item.content as Color).value == backgroundColor.value
    ).toList();
    
    return matchingBackground.isNotEmpty && matchingBackground.first.isPremium;
  }
}