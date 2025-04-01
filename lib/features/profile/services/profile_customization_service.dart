import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vanishingtictactoe/core/utils/app_logger.dart';
import 'package:vanishingtictactoe/shared/models/unlockable_content.dart';
import 'package:vanishingtictactoe/shared/widgets/custom_icon.dart';
import 'package:vanishingtictactoe/features/profile/services/user_service.dart';

class ProfileCustomization {
  final IconData icon;
  final ProfileBorderStyle borderStyle;
  final Color backgroundColor;
  final bool isPremium;

  ProfileCustomization({
    required this.icon,
    required this.borderStyle,
    required this.backgroundColor,
    this.isPremium = false,
  });

  // Create a copy with updated fields
  ProfileCustomization copyWith({
    IconData? icon,
    ProfileBorderStyle? borderStyle,
    Color? backgroundColor,
    bool? isPremium,
  }) {
    return ProfileCustomization(
      icon: icon ?? this.icon,
      borderStyle: borderStyle ?? this.borderStyle,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      isPremium: isPremium ?? this.isPremium,
    );
  }
}

/// Centralized service for managing profile customization
/// Handles caching, loading, and saving profile customization data
class ProfileCustomizationService {
  // Singleton instance
  static final ProfileCustomizationService _instance = ProfileCustomizationService._internal();
  factory ProfileCustomizationService() => _instance;
  ProfileCustomizationService._internal();
  
  // Cache of profile customizations by user ID
  final Map<String, ProfileCustomization> _cache = {};
  // Track which users have pending changes to sync
  final Set<String> _pendingSync = {};
  // Track when each user's data was last loaded from server
  final Map<String, DateTime> _lastLoaded = {};
  // Track when each user's data was last modified
  final Map<String, DateTime> _lastModified = {};
  // Track debounce timers for each user
  final Map<String, Timer> _syncDebounceTimers = {};
  
  // Default values
  static final _defaultIcon = ProfileIcons.person;
  static final _defaultBorderStyle = ProfileBorderStyle.classic;
  static final _defaultBackgroundColor = Colors.blue;
  
  // Cache expiration time
  static const _cacheExpiration = Duration(hours: 2); // Extended from 30 minutes
  // Debounce time for server syncs
  static const _syncDebounceTime = Duration(seconds: 5);
  
  /// Get customization for a user, from cache if available and valid
  Future<ProfileCustomization> getCustomization(String userId) async {
    // Check if we have a valid cached version
    if (_hasValidCache(userId)) {
      AppLogger.debug('Using cached profile customization for user: $userId');
      return _cache[userId]!;
    }
    
    // If not in cache or expired, load from server
    return await _loadFromServer(userId);
  }
  
  /// Check if we have valid cache for a user
  bool _hasValidCache(String userId) {
    if (!_cache.containsKey(userId) || !_lastLoaded.containsKey(userId)) {
      return false;
    }
    
    final lastLoaded = _lastLoaded[userId]!;
    final timeSinceLoad = DateTime.now().difference(lastLoaded);
    
    // If we have pending changes, use a shorter expiration time
    if (_pendingSync.contains(userId)) {
      return timeSinceLoad < const Duration(minutes: 5);
    }
    
    // Otherwise use the standard expiration time
    return timeSinceLoad < _cacheExpiration;
  }
  
  /// Load customization from server and update cache
  Future<ProfileCustomization> _loadFromServer(String userId) async {
    AppLogger.debug('Loading profile customization from server for user: $userId');
    
    try {
      final userService = UserService();
      final customizationData = await userService.getProfileCustomization(userId);
      
      if (customizationData == null) {
        // If no server data, use defaults or local preferences
        return await _loadFromPreferences(userId);
      }
      
      // Parse server data
      IconData icon = _defaultIcon;
      ProfileBorderStyle borderStyle = _defaultBorderStyle;
      Color backgroundColor = _defaultBackgroundColor;
      bool isPremium = false;
      
      // Parse icon
      if (customizationData.containsKey('iconCodePoint')) {
        final codePoint = int.tryParse(customizationData['iconCodePoint']);
        if (codePoint != null) {
          // Try to reconstruct the icon using UserService helper
          final reconstructedIcon = userService.reconstructIconData(customizationData);
          if (reconstructedIcon != null) {
            icon = reconstructedIcon;
          }
          
          // Check if this is a premium icon
          isPremium = customizationData['isPremiumIcon'] as bool? ?? false;
        }
      }
      
      // Parse border style
      if (customizationData.containsKey('borderStyleColor')) {
        final colorHex = customizationData['borderStyleColor'] as String?;
        if (colorHex != null) {
          // Convert hex string to color
          final color = _hexToColor(colorHex);
          // Find matching border or create one with this color
          borderStyle = ProfileBorderStyle(
            shape: ProfileBorderShape.circle,
            borderColor: color,
            borderWidth: 2.0,
            borderRadius: 8.0,
          );
        }
      }
      
      // Parse background color
      if (customizationData.containsKey('backgroundColor')) {
        final colorHex = customizationData['backgroundColor'] as String?;
        if (colorHex != null) {
          backgroundColor = _hexToColor(colorHex);
        }
      }
      
      // Create customization object
      final customization = ProfileCustomization(
        icon: icon,
        borderStyle: borderStyle,
        backgroundColor: backgroundColor,
        isPremium: isPremium,
      );
      
      // Update cache
      _cache[userId] = customization;
      _lastLoaded[userId] = DateTime.now();
      
      // Also save to preferences for offline access
      _saveToPreferences(userId, customization);
      
      return customization;
    } catch (e) {
      AppLogger.error('Error loading profile customization from server: $e');
      // Fallback to preferences
      return await _loadFromPreferences(userId);
    }
  }
  
  // Helper method to convert hex string to Color
  Color _hexToColor(String hexString) {
    // Remove # if present
    final hex = hexString.startsWith('#') ? hexString.substring(1) : hexString;
    
    // Parse the hex value
    try {
      return Color(int.parse('0xFF$hex'));
    } catch (e) {
      AppLogger.error('Error parsing color hex value: $hexString');
      return _defaultBackgroundColor;
    }
  }
  
  /// Load customization from shared preferences
  Future<ProfileCustomization> _loadFromPreferences(String userId) async {
    AppLogger.debug('Loading profile customization from preferences for user: $userId');
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final keyPrefix = 'profile_${userId}_';
      
      // Default values
      IconData icon = _defaultIcon;
      ProfileBorderStyle borderStyle = _defaultBorderStyle;
      Color backgroundColor = _defaultBackgroundColor;
      bool isPremium = false;
      
      // Load icon
      final iconCodePoint = prefs.getString('${keyPrefix}icon');
      if (iconCodePoint != null) {
        final codePoint = int.tryParse(iconCodePoint);
        if (codePoint != null) {
          // Find matching icon
          final allIcons = UnlockableContent.getAllItems(type: UnlockableType.icon);
          final matchingIcon = allIcons.where((item) => 
              (item.content as IconData).codePoint == codePoint).firstOrNull;
          
          if (matchingIcon != null) {
            icon = matchingIcon.content as IconData;
            isPremium = matchingIcon.isPremium;
          }
        }
      }
      
      // Load border style
      final borderStyleColor = prefs.getString('${keyPrefix}border_style');
      if (borderStyleColor != null) {
        final colorValue = int.tryParse(borderStyleColor);
        if (colorValue != null) {
          final color = Color(colorValue);
          borderStyle = ProfileBorderStyle(
            shape: ProfileBorderShape.circle,
            borderColor: color,
            borderWidth: 2.0,
            borderRadius: 8.0,
          );
        }
      }
      
      // Load background color
      final backgroundColorValue = prefs.getInt('${keyPrefix}background_color');
      if (backgroundColorValue != null) {
        backgroundColor = Color(backgroundColorValue);
      }
      
      // Create customization object
      final customization = ProfileCustomization(
        icon: icon,
        borderStyle: borderStyle,
        backgroundColor: backgroundColor,
        isPremium: isPremium,
      );
      
      // Update cache
      _cache[userId] = customization;
      _lastLoaded[userId] = DateTime.now();
      
      return customization;
    } catch (e) {
      AppLogger.error('Error loading profile customization from preferences: $e');
      // Return defaults
      return ProfileCustomization(
        icon: _defaultIcon,
        borderStyle: _defaultBorderStyle,
        backgroundColor: _defaultBackgroundColor,
      );
    }
  }
  
  /// Save customization to preferences
  Future<void> _saveToPreferences(String userId, ProfileCustomization customization) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keyPrefix = 'profile_${userId}_';
      
      await prefs.setString('${keyPrefix}icon', customization.icon.codePoint.toString());
      await prefs.setString('${keyPrefix}border_style', customization.borderStyle.borderColor.value.toString());
      await prefs.setInt('${keyPrefix}background_color', customization.backgroundColor.value);
      await prefs.setBool('${keyPrefix}is_premium', customization.isPremium);
    } catch (e) {
      AppLogger.error('Error saving profile customization to preferences: $e');
    }
  }
  
  /// Update customization in cache and mark for sync with debounce
  Future<void> updateCustomization(
    String userId, {
    IconData? icon,
    ProfileBorderStyle? borderStyle,
    Color? backgroundColor,
    bool syncImmediately = false,
  }) async {
    // Get current customization or load if not in cache
    final current = _cache.containsKey(userId) 
        ? _cache[userId]!
        : await getCustomization(userId);
    
    // Check if any component is premium
    bool isPremium = current.isPremium;
    if (icon != null || borderStyle != null || backgroundColor != null) {
      final unlockables = UnlockableContent.getAllUnlockables();
      
      isPremium = unlockables.any((item) => 
        (item.type == UnlockableType.icon && item.content == (icon ?? current.icon) && item.isPremium) ||
        (item.type == UnlockableType.border && 
         (item.content as ProfileBorderStyle).borderColor == (borderStyle ?? current.borderStyle).borderColor && 
         item.isPremium) ||
        (item.type == UnlockableType.background && item.content == (backgroundColor ?? current.backgroundColor) && item.isPremium)
      );
    }
    
    // Create updated customization
    final updated = current.copyWith(
      icon: icon,
      borderStyle: borderStyle,
      backgroundColor: backgroundColor,
      isPremium: isPremium,
    );
    
    // Update cache
    _cache[userId] = updated;
    _lastLoaded[userId] = DateTime.now();
    _lastModified[userId] = DateTime.now();
    
    // Mark for sync
    _pendingSync.add(userId);
    
    // Save to preferences immediately
    await _saveToPreferences(userId, updated);
    
    // Handle server sync with debounce
    if (syncImmediately) {
      // Cancel any pending debounce timer
      _syncDebounceTimers[userId]?.cancel();
      _syncDebounceTimers.remove(userId);
      
      // Sync immediately
      await _syncUserToServer(userId);
    } else {
      // Debounce the sync to prevent too many server calls
      _debouncedSync(userId);
    }
    
    AppLogger.debug('Updated profile customization in cache for user: $userId');
  }
  
  /// Debounce sync to server for a specific user
  void _debouncedSync(String userId) {
    // Cancel existing timer if any
    _syncDebounceTimers[userId]?.cancel();
    
    // Create new timer
    _syncDebounceTimers[userId] = Timer(_syncDebounceTime, () async {
      await _syncUserToServer(userId);
      _syncDebounceTimers.remove(userId);
    });
  }
  
  /// Sync a specific user to server
  Future<void> _syncUserToServer(String userId) async {
    if (!_cache.containsKey(userId) || !_pendingSync.contains(userId)) return;
    
    try {
      final customization = _cache[userId]!;
      final userService = UserService();
      
      await userService.saveProfileCustomization(
        userId: userId,
        icon: customization.icon,
        borderStyle: customization.borderStyle,
        backgroundColor: customization.backgroundColor,
        isPremiumIcon: customization.isPremium,
      );
      
      // Remove from pending sync
      _pendingSync.remove(userId);
      
      AppLogger.debug('Synced profile customization to server for user: $userId');
    } catch (e) {
      AppLogger.error('Error syncing profile customization to server: $e');
    }
  }
  
  /// Sync all pending changes to server
  Future<void> syncToServer() async {
    // Cancel all debounce timers
    for (final timer in _syncDebounceTimers.values) {
      timer.cancel();
    }
    _syncDebounceTimers.clear();
    
    final userIds = Set<String>.from(_pendingSync);
    
    for (final userId in userIds) {
      await _syncUserToServer(userId);
    }
  }
  
  /// Force sync for a specific user
  Future<void> forceSyncForUser(String userId) async {
    // Cancel any pending debounce timer
    _syncDebounceTimers[userId]?.cancel();
    _syncDebounceTimers.remove(userId);
    
    // Add to pending sync if not already there
    if (_cache.containsKey(userId)) {
      _pendingSync.add(userId);
    }
    
    await _syncUserToServer(userId);
    
    AppLogger.debug('Force synced profile customization to server for user: $userId');
  }
  
  /// Clear cache for a user
  Future<void> clearCache(String userId) async {
    // Cancel any pending sync
    _syncDebounceTimers[userId]?.cancel();
    _syncDebounceTimers.remove(userId);
    
    // If there are pending changes, sync them first
    if (_pendingSync.contains(userId) && _cache.containsKey(userId)) {
      await _syncUserToServer(userId);
    }
    
    _cache.remove(userId);
    _lastLoaded.remove(userId);
    _lastModified.remove(userId);
    _pendingSync.remove(userId);
    
    AppLogger.debug('Cleared profile customization cache for user: $userId');
  }
  
  /// Clear all cache
  Future<void> clearAllCache() async {
    // Cancel all debounce timers
    for (final timer in _syncDebounceTimers.values) {
      timer.cancel();
    }
    _syncDebounceTimers.clear();
    
    // Sync any pending changes
    await syncToServer();
    
    _cache.clear();
    _lastLoaded.clear();
    _lastModified.clear();
    _pendingSync.clear();
    
    AppLogger.debug('Cleared all profile customization cache');
  }
  
  /// Dispose the service
  void dispose() {
    // Cancel all debounce timers
    for (final timer in _syncDebounceTimers.values) {
      timer.cancel();
    }
    _syncDebounceTimers.clear();
  }
}