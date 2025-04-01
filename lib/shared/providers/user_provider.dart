import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:vanishingtictactoe/shared/models/user_account.dart';
import 'package:vanishingtictactoe/shared/models/user_level.dart';
import 'package:vanishingtictactoe/features/game/models/computer_player.dart';
import 'package:vanishingtictactoe/features/auth/services/auth_service.dart';
import 'package:vanishingtictactoe/features/profile/services/user_service.dart';
import 'package:vanishingtictactoe/core/utils/app_logger.dart';
import 'package:vanishingtictactoe/features/missions/services/mission_service.dart'; // Add this import

class UserProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final UserService _userService = UserService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final MissionService _missionService = MissionService(); // Add this line
  UserAccount? _user;
  bool _isInitialized = false;
  bool _isOnline = false;

  UserAccount? get user => _user;
  bool get isLoggedIn => _user != null;
  bool get isOnline => _isOnline;

  // Initialize the provider
  Future<void> initialize() async {
    if (_isInitialized || _user != null) return;

    try {
      // Initialize user service and get cached user data
      _user = await _userService.initialize() ?? _authService.currentUser;

      if (_user != null) {
        // Operations that can run concurrently
        await Future.wait([
          refreshUserData(forceServerRefresh: true),
          _setUserOnlineStatus(true),
        ]);

        AppLogger.info('User initialized successfully. Level: ${_user!.userLevel.level}, XP: ${_user!.totalXp}');
        notifyListeners();
      }
    } catch (e) {
      AppLogger.error('Error initializing user provider: $e');
    }

    _isInitialized = true;
  }

  // Sign in
  Future<void> signIn(String email, String password) async {
    try {
      _user = await _authService.signInWithEmailAndPassword(email, password);
      if (_user == null) throw Exception('Sign in failed');

      final userFuture = _userService.loadUser(_user!.id);
      final refreshFuture = refreshUserData(forceServerRefresh: true);
      // Remove this line - UserService will handle mission generation
      // final missionsFuture = _missionService.generateMissions(_user!.id);

      final userData = await userFuture;
      if (userData != null) {
        _user = userData;
      }

      // Update this line to remove missionsFuture
      await Future.wait([refreshFuture, _setUserOnlineStatus(true)]);

      notifyListeners();
      AppLogger.info('User signed in successfully. Level: ${_user!.userLevel.level}, XP: ${_user!.totalXp}');
    } catch (e) {
      AppLogger.error('Sign in error: $e');
      rethrow;
    }
  }

  // Register
  Future<void> register(String email, String password, String username) async {
    try {
      final userFuture = _authService.registerWithEmailAndPassword(email, password, username);
      final saveUserFuture = userFuture.then((user) {
        return _userService.saveUser(user);
      });

      _user = await userFuture;
      await saveUserFuture;
      notifyListeners();
    } catch (e) {
      AppLogger.error('Registration error: $e');
      rethrow;
    }
  }

  // Sign out
  Future<void> signOut() async {
    if (_user == null) return;
    await _setUserOnlineStatus(false);
    await Future.wait([_authService.signOut(), _userService.clearCache()]);
    _user = null;
    notifyListeners();
  }

  bool _isUpdatingStats = false;

  Future<void> updateGameStats({
    bool? isWin,
    bool? isDraw,
    int? movesToWin,
    required bool isOnline,
    bool isFriendlyMatch = false,
    bool isHellMode = false,
    GameDifficulty difficulty = GameDifficulty.easy,
  }) async {
    if (_isUpdatingStats) {
      AppLogger.debug('updateGameStats already in progress, ignoring duplicate call');
      return;
    }
    _isUpdatingStats = true;
    try {
      if (_user == null) return;

      // Update local state for game statistics
      _user!.updateStats(
        isWin: isWin,
        isDraw: isDraw,
        movesToWin: movesToWin,
        isOnline: isOnline,
      );

      // Only award XP for online games or computer games (not 2-player local games)
      // Never award XP for friendly matches
      if ((isOnline || !isFriendlyMatch) && !isFriendlyMatch) {
        // Calculate XP to award based on game outcome
        final xpToAward = UserLevel.calculateGameXp(
          isWin: isWin ?? false,
          isDraw: isDraw ?? false,
          movesToWin: movesToWin,
          level: _user!.userLevel.level,
          isHellMode: isHellMode,
          difficulty: difficulty,
        );

        // Add XP to user
        _user = _user!.addXp(xpToAward);
        final difficultyName = difficulty.toString().split('.').last;
        final hellModeText = isHellMode ? ' (2x Hell Mode bonus)' : '';
        AppLogger.info('User gained $xpToAward XP - $difficultyName difficulty$hellModeText. New total: ${_user!.totalXp}, Level: ${_user!.userLevel.level}');
      } else {
        AppLogger.info('No XP awarded for friendly/2-player match');
      }

      notifyListeners();

      // Update Firestore
      await _userService.updateGameStatsAndXp(
        userId: _user!.id,
        isWin: isWin,
        isDraw: isDraw,
        movesToWin: movesToWin,
        isOnline: isOnline,
        xpToAdd: isOnline || !isFriendlyMatch ? _calculateXpToAward(isWin, isDraw, movesToWin, isHellMode: isHellMode, difficulty: difficulty) : 0,
        totalXp: _user!.totalXp,
        userLevel: _user!.userLevel,
      );
    } finally {
      _isUpdatingStats = false;
    }
  }

  // Add this block to update missions whenever a game is played
  Future<void> trackGamePlayed(
    bool? isWin,
    bool? isDraw,
    int? movesToWin,
    bool isHellMode,
    GameDifficulty difficulty,
  ) async {
    if (_user != null) {
      try {
        await _missionService.trackGamePlayed(
          userId: _user!.id,
          isHellMode: isHellMode,
          isWin: isWin ?? false,
          difficulty: difficulty,
        );
        AppLogger.info('Mission progress updated for game played');
      } catch (e) {
        AppLogger.error('Error updating mission progress: $e');
      }
    }
  }
  
  // Helper method to calculate XP
  int _calculateXpToAward(bool? isWin, bool? isDraw, int? movesToWin, {bool isHellMode = false, GameDifficulty difficulty = GameDifficulty.easy}) {
    return UserLevel.calculateGameXp(
      isWin: isWin ?? false,
      isDraw: isDraw ?? false,
      movesToWin: movesToWin,
      level: _user!.userLevel.level,
      isHellMode: isHellMode,
      difficulty: difficulty,
    );
  }

  // Update username
  Future<void> updateUsername(String newUsername) async {
    if (_user == null) return;
    
    await Future.wait([
      _authService.updateUsername(newUsername),
    ]);
    
    _user = _user!.copyWith(username: newUsername);
    notifyListeners();
  }
  
  // Set user online status
  Future<void> _setUserOnlineStatus(bool status) async {
    if (_user == null) return;
    
    try {
      _isOnline = status;
      final userDocRef = _firestore.collection('users').doc(_user!.id);
      await userDocRef.update({
        'isOnline': status,
        'lastOnline': FieldValue.serverTimestamp(),
      });
      
      _user = _user!.copyWith(isOnline: status);
      notifyListeners();
    } catch (e) {
      AppLogger.error('Error updating online status: $e');
    }
  }

  // Update email
  Future<void> updateEmail(String newEmail) async {
    if (_user == null) return;
    
    final user = _authService.currentUser;
    if (user == null) throw Exception('Not signed in');

    if (newEmail != user.email) {
      await _authService.updateEmail(newEmail);
      _user = _user!.copyWith(email: newEmail);
      await _userService.saveUser(_user!);
      notifyListeners();
    }
  }

  // Update password
  Future<void> updatePassword(String newPassword) async {
    if (_user == null) return;
    
    final user = _authService.currentUser;
    if (user == null) throw Exception('Not signed in');

    if (newPassword.isNotEmpty) {
      await _authService.updatePassword(newPassword);
      notifyListeners();
    }
  }

  // Update email and password
  Future<void> updateEmailAndPassword(String newEmail, String? newPassword) async {
    if (_user == null) return;
    
    await updateEmail(newEmail);
    
    if (newPassword != null && newPassword.isNotEmpty) {
      await updatePassword(newPassword);
    }
  }

  Future<void> refreshUserData({bool forceServerRefresh = false}) async {
  if (_user == null) {
    AppLogger.warning('Cannot refresh user data: User is null');
    return;
  }

  try {
    AppLogger.info('Refreshing user data for ${_user!.id} (forceServerRefresh: $forceServerRefresh)');

    // Attempt to sync user data from UserService
    await _userService.syncUserData(_user!.id);
    _user = _userService.currentUser;

    if (_user == null) {
      AppLogger.warning('Failed to refresh user data: UserService returned null. Falling back to Firestore.');

      // Direct Firestore fetch as fallback
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(_user!.id)
          .get(GetOptions(source: forceServerRefresh ? Source.server : Source.serverAndCache));

      if (userDoc.exists) {
        _user = UserAccount.fromJson({...userDoc.data()!, 'id': userDoc.id});
        await _userService.saveUser(_user!, checkUsernameUniqueness: false);
      }
    }

    if (_user != null) {
      AppLogger.info('User data refreshed successfully. Level: ${_user!.userLevel.level}, XP: ${_user!.totalXp}');
      notifyListeners();
    }
  } catch (e, stackTrace) {
    AppLogger.error('Error refreshing user data: $e');
    AppLogger.error('Stack trace: $stackTrace');
  }
}
  // Add XP to user and update in Firestore
  Future<void> addXp(int xpAmount) async {
    if (_user == null) return;

    // Add XP locally
    _user = _user!.addXp(xpAmount);
    notifyListeners();

    // Update Firestore
    await _userService.updateGameStatsAndXp(
      userId: _user!.id,
      xpToAdd: xpAmount,
      totalXp: _user!.totalXp,
      userLevel: _user!.userLevel,
      isOnline: _isOnline,
    );

    AppLogger.info('Added $xpAmount XP. New total: ${_user!.totalXp}, Level: ${_user!.userLevel.level}');
  }
}
