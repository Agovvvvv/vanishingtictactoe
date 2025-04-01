import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vanishingtictactoe/shared/models/user_account.dart';
import 'package:vanishingtictactoe/shared/models/user_level.dart';
import 'package:vanishingtictactoe/core/utils/app_logger.dart';
import 'package:vanishingtictactoe/shared/models/unlockable_content.dart';
import 'package:vanishingtictactoe/features/profile/screens/levelup_screen.dart';
import 'package:vanishingtictactoe/core/navigation/navigation_service.dart';
import 'package:vanishingtictactoe/features/missions/services/mission_service.dart';
import 'package:vanishingtictactoe/shared/widgets/custom_icon.dart';
import 'package:vanishingtictactoe/features/profile/services/profile_customization_service.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late SharedPreferences _prefs;
  UserAccount? _currentUser;
  final MissionService _missionService = MissionService();
  bool _missionsGeneratedThisSession = false;

  Future<UserAccount?> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    _loadCachedUser();

    // Start syncing user data without waiting for it to complete
    if (_currentUser != null) {
      syncUserData(_currentUser!.id).catchError((e) {
        AppLogger.error('Error during initial sync: $e');
      });
    }

    return _currentUser;
  }

  void _loadCachedUser() {
    final userData = _prefs.getString('user_data');
    if (userData == null) return;

    try {
      final userMap = json.decode(userData) as Map<String, dynamic>;
      if (userMap.containsKey('id') && userMap.containsKey('username') && userMap.containsKey('email')) {
        _currentUser = UserAccount.fromJson(userMap);
      } else {
        AppLogger.error('Error loading cached user: missing required fields');
        _prefs.remove('user_data');
      }
    } catch (e) {
      AppLogger.error('Error loading cached user: $e');
      _prefs.remove('user_data');
    }
  }

  UserAccount? get currentUser => _currentUser;

  Future<bool> isUsernameAvailable(String username) async {
    try {
      final querySnapshot = await _firestore
          .collection('users')
          .where('username', isEqualTo: username)
          .get();
      return querySnapshot.docs.isEmpty;
    } catch (e) {
      AppLogger.error('Error checking username availability: $e', e);
      rethrow;
    }
  }

  Future<void> saveUser(UserAccount user, {bool checkUsernameUniqueness = true}) async {
    final userData = user.toJson();
    try {
      if (userData['id'] == null || userData['username'] == null || userData['email'] == null) {
        throw FormatException('Missing required fields');
      }

      final existingDoc = await _firestore.collection('users').doc(user.id).get();
      final isNewUser = !existingDoc.exists;

      if (isNewUser || existingDoc.data()!['username'] != userData['username']) {
        if (checkUsernameUniqueness && !await isUsernameAvailable(userData['username'])) {
          throw Exception('Username is already taken');
        }
      }

      await _firestore.collection('users').doc(user.id).set(userData);
      final userJson = json.encode(userData);
      await _prefs.setString('user_data', userJson);
      _currentUser = user;
    } catch (e) {
      AppLogger.error('Error saving user: $e');
      rethrow;
    }
  }

  Future<UserAccount?> loadUser(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (!doc.exists) return null;

      final user = UserAccount.fromJson(doc.data()!);
      _currentUser = user;
      await _prefs.setString('user_data', json.encode(user.toJson()));

      AppLogger.info('Loaded user from Firestore. Level: ${user.userLevel.level}, XP: ${user.totalXp}');
      return user;
    } catch (e) {
      AppLogger.error('Error loading user: $e');
      return null;
    }
  }

  // After the loadUser method
  
    Future<void> syncUserData(String userId) async {
      try {
        final doc = await _firestore.collection('users').doc(userId).get(const GetOptions(source: Source.server));
        if (!doc.exists) {
          AppLogger.warning('User not found in Firestore during sync: $userId');
          return;
        }

        final remoteUser = UserAccount.fromJson(doc.data()!);

        if (_currentUser?.id == userId) {
          // Only update the level and XP fields to avoid overwriting other local data
          _currentUser = _currentUser!.copyWith(
            userLevel: remoteUser.userLevel,
            totalXp: remoteUser.totalXp,
          );
        } else {
          _currentUser = remoteUser;
        }

        await _prefs.setString('user_data', json.encode(_currentUser!.toJson()));
      
        // Generate missions only once per app session
        if (!_missionsGeneratedThisSession) {
          await _missionService.generateMissions(userId);
          _missionsGeneratedThisSession = true;
        }
      } catch (e) {
        AppLogger.error('Error syncing user data: $e');
      }
    }

  Future<void> updateGameStatsAndXp({
    required String userId,
    bool? isWin,
    bool? isDraw,
    int? movesToWin,
    required bool isOnline,
    required int xpToAdd,
    required int totalXp,
    required UserLevel userLevel,
  }) async {
    try {
      final userDoc = _firestore.collection('users').doc(userId);
      final userDocFuture = userDoc.get();
      final userDocData = (await userDocFuture).data();
      if (userDocData == null) {
        throw Exception('User not found');
      }

      final user = UserAccount.fromJson(userDocData);

      user.updateStats(
        isWin: isWin,
        isDraw: isDraw,
        movesToWin: movesToWin,
        isOnline: isOnline,
      );

      final updatedUser = user.addXp(xpToAdd);

      await userDoc.update({
        'vsComputerStats': updatedUser.vsComputerStats.toJson(),
        'onlineStats': updatedUser.onlineStats.toJson(),
        'totalXp': updatedUser.totalXp,
        'userLevel': updatedUser.userLevel.toJson(),
      });

      if (_currentUser?.id == userId) {
        _currentUser = updatedUser;
        await _prefs.setString('user_data', json.encode(updatedUser.toJson()));
      }

      AppLogger.info('Updated user XP in Firestore. Added $xpToAdd XP. New total: $totalXp, Level: ${userLevel.level}');
      
      // Check if the user leveled up by comparing previous XP + added XP with the level threshold
      final previousXp = totalXp - xpToAdd;
      final previousLevel = UserLevel.fromTotalXp(previousXp);
      
      // If the level has increased, show the level up screen
      if (userLevel.level > previousLevel.level) {
        AppLogger.info('User leveled up from ${previousLevel.level} to ${userLevel.level}!');
        
        // Get newly unlocked items for this level
        final newUnlockables = UnlockableContent.getUnlockablesForLevel(userLevel.level);
        
        // Show the level up screen using the navigator key
        if (navigatorKey.currentContext != null) {
          Navigator.of(navigatorKey.currentContext!).push(
            PageRouteBuilder(
              opaque: false,
              barrierDismissible: false,
              pageBuilder: (context, animation, secondaryAnimation) => LevelUpScreen(
                newLevel: userLevel.level,
                newUnlockables: newUnlockables,
                onContinue: () {
                  Navigator.of(context).pop();
                },
              ),
              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                return FadeTransition(
                  opacity: animation,
                  child: child,
                );
              },
            ),
          );
        } else {
          AppLogger.error('Cannot show level up screen: Navigator context is null');
        }
      }
    } catch (e) {
      AppLogger.error('Error updating game stats and XP: $e');
      rethrow;
    }
  }

  Future<void> updateGameStats({
    required String userId,
    bool? isWin,
    bool? isDraw,
    int? movesToWin,
    required bool isOnline,
  }) async {
    final userDoc = _firestore.collection('users').doc(userId);
    final userDocData = (await userDoc.get()).data();
    if (userDocData == null) {
      throw Exception('User not found');
    }

    final user = UserAccount.fromJson(userDocData);
    final xpToAdd = UserLevel.calculateGameXp(
      isWin: isWin ?? false,
      isDraw: isDraw ?? false,
      movesToWin: movesToWin,
      level: user.userLevel.level,
    );

    await userDoc.update({
      'vsComputerStats': user.vsComputerStats.toJson(),
      'onlineStats': user.onlineStats.toJson(),
      'totalXp': user.totalXp + xpToAdd,
      'userLevel': UserLevel.fromTotalXp(user.totalXp + xpToAdd).toJson(),
    });
  }

  Future<Map<String, dynamic>> getUserStats(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get(const GetOptions(source: Source.server));
      if (!doc.exists) return {};

      final onlineStats = GameStats.fromJson(doc.data()?['onlineStats'] ?? {});
      return onlineStats.toJson();
    } catch (e) {
      AppLogger.error('Error fetching user stats: $e');
      return {};
    }
  }

  Future<void> clearCache() async {
    _currentUser = null;
    await _prefs.remove('user_data');
  }

  Future<UserAccount?> getLatestUserData(String userId) async {
    final userDoc = await _firestore.collection('users').doc(userId).get(const GetOptions(source: Source.server));
    if (!userDoc.exists) return null;

    final remoteUser = UserAccount.fromJson(userDoc.data()!);
    _currentUser = remoteUser;
    await _prefs.setString('user_data', json.encode(remoteUser.toJson()));

    return _currentUser;
  }
  
  // Optimized method to retrieve profile customization from Firestore
  Future<Map<String, dynamic>?> getProfileCustomization(String userId) async {
    try {
      final docSnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('profile')
          .doc('customization')
          .get();
      
      if (docSnapshot.exists) {
        final customization = docSnapshot.data();
        
        // Log successful retrieval
        if (customization != null) {
          AppLogger.debug('Retrieved profile customization from Firestore for user: $userId');
          
          // Log the actual icon code point for debugging
          if (customization.containsKey('iconCodePoint')) {
            AppLogger.debug('Icon code point from Firestore: ${customization['iconCodePoint']}');
          }
        }
        
        return customization;
      }
      return null;
    } catch (e) {
      AppLogger.error('Error retrieving profile customization: $e');
      return null;
    }
  }
  
  // Updated method to save profile customization to Firestore
  Future<void> saveProfileCustomization({
    required String userId,
    required IconData icon,
    required ProfileBorderStyle borderStyle,
    required Color backgroundColor,
    required bool isPremiumIcon,
  }) async {
    try {
      final customizationData = {
        'iconCodePoint': icon.codePoint.toString(),
        'iconFontFamily': icon.fontFamily,
        'iconFontPackage': icon.fontPackage,
        'iconMatchTextDirection': icon.matchTextDirection,
        'isPremiumIcon': isPremiumIcon,
        'borderStyleColor': borderStyle.borderColor.toHex(), // Fixed deprecated value usage
        'backgroundColor': backgroundColor.toHex(), // Fixed deprecated value usage
        'lastUpdated': FieldValue.serverTimestamp(),
      };
      
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('profile')
          .doc('customization')
          .set(customizationData, SetOptions(merge: true));
      
      AppLogger.debug('Profile customization saved to Firestore for user: $userId');
      return;
    } catch (e) {
      AppLogger.error('Error saving profile customization: $e');
      rethrow;
    }
  }

  // Removed duplicate getProfileCustomization method

  // Add a method to sync all pending profile customizations
  Future<void> syncPendingProfileCustomizations() async {
    try {
      // Use the ProfileCustomizationService to sync all pending changes
      final customizationService = ProfileCustomizationService();
      await customizationService.syncToServer();
      AppLogger.debug('Synced all pending profile customizations');
    } catch (e) {
      AppLogger.error('Error syncing pending profile customizations: $e');
    }
  }
  
  // Add a method to reset the missions generated flag (can be called on logout)
  void resetMissionsGeneratedFlag() {
    _missionsGeneratedThisSession = false;
  }
  
  // Helper method to reconstruct IconData from stored data
  IconData? reconstructIconData(Map<String, dynamic> customization) {
    try {
      if (!customization.containsKey('iconCodePoint')) {
        return null;
      }
      
      final codePointStr = customization['iconCodePoint'];
      final codePoint = int.tryParse(codePointStr);
      
      if (codePoint == null) {
        AppLogger.error('Failed to parse icon code point: $codePointStr');
        return null;
      }
      
      // Only use predefined icons from ProfileIcons
      final allIcons = ProfileIcons.getAllIcons();
      for (var icon in allIcons) {
        if (icon.codePoint == codePoint) {
          AppLogger.debug('Found matching icon in ProfileIcons: ${icon.codePoint}');
          return icon;
        }
      }
      
      // If not found in ProfileIcons, use a default icon instead of creating a new IconData
      AppLogger.warning('Icon with code point $codePoint not found in ProfileIcons, using default icon');
      return ProfileIcons.person; // Default to person icon
    } catch (e) {
      AppLogger.error('Error reconstructing IconData: $e');
      return ProfileIcons.person; // Default to person icon on error
    }
  }
  
  // Debug method to log profile customization details
  Future<void> debugProfileCustomization(String userId) async {
    try {
      final customization = await getProfileCustomization(userId);
      
      if (customization == null) {
        AppLogger.debug('No profile customization found for user: $userId');
        return;
      }
      
      AppLogger.debug('Profile customization details for user: $userId');
      customization.forEach((key, value) {
        AppLogger.debug('  $key: $value');
      });
      
      // Try to reconstruct the icon
      final iconData = reconstructIconData(customization);
      if (iconData != null) {
        AppLogger.debug('Reconstructed icon: codePoint=${iconData.codePoint}, fontFamily=${iconData.fontFamily}');
      } else {
        AppLogger.debug('Failed to reconstruct icon, will use default icon');
      }
      
      // Check if the icon exists in ProfileIcons
      final allIcons = ProfileIcons.getAllIcons();
      final codePointStr = customization['iconCodePoint'];
      final codePoint = int.tryParse(codePointStr ?? '');
      
      if (codePoint != null) {
        final matchingIcons = allIcons.where((icon) => icon.codePoint == codePoint).toList();
        AppLogger.debug('Found ${matchingIcons.length} matching icons in ProfileIcons');
        if (matchingIcons.isEmpty) {
          AppLogger.debug('No matching icon found in ProfileIcons, will use default icon');
        }
      }
    } catch (e) {
      AppLogger.error('Error debugging profile customization: $e');
    }
  }
}

// Extension to handle color conversion properly
extension ColorExtension on Color? {
  String toHex() {
    if (this == null) {
      throw ArgumentError('Color cannot be null');
    }

    final value = this!.value;
    return '#${(value & 0xFFFFFF).toRadixString(16).padLeft(6, '0')}';
  }
}