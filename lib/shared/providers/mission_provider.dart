import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:vanishingtictactoe/features/missions/models/mission.dart';
import 'package:vanishingtictactoe/core/utils/app_logger.dart';
import 'package:vanishingtictactoe/features/missions/services/mission_service.dart';
import 'package:vanishingtictactoe/features/game/models/computer_player.dart';

class MissionProvider extends ChangeNotifier {
  final MissionService _missionService = MissionService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  List<Mission> _missions = [];
  List<Mission> _dailyMissions = [];
  List<Mission> _weeklyMissions = [];
  List<Mission> _normalMissions = [];
  List<Mission> _hellMissions = [];
  
  bool _isLoading = false;
  bool _hasError = false;
  bool _isTrackingGame = false;
  String? _errorMessage;
  String? _userId;
  StreamSubscription? _missionsSubscription;
  DateTime? _lastRefresh;
  
  // Getters
  List<Mission> get missions => _missions;
  List<Mission> get dailyMissions => _dailyMissions;
  List<Mission> get weeklyMissions => _weeklyMissions;
  List<Mission> get normalMissions => _normalMissions;
  List<Mission> get hellMissions => _hellMissions;
  bool get isLoading => _isLoading;
  bool get hasError => _hasError;
  String? get errorMessage => _errorMessage;
  DateTime? get lastRefresh => _lastRefresh;
  
  // Initialize the provider with user ID
  Future<void> initialize(String? userId, {bool forceRefresh = false}) async {
    if (userId == null || userId.isEmpty) {
      _resetState();
      notifyListeners();
      return;
    }
    
    // Skip initialization if already initialized for this user and not forcing refresh
    if (_userId == userId && !forceRefresh) return;
    
    _userId = userId;
    _isLoading = true;
    _hasError = false;
    _errorMessage = null;
    notifyListeners();
    
    try {
      // Remove the generateMissions call here - UserService will handle this
      // await _missionService.generateMissions(userId);
      
      // First load missions immediately to ensure we have the latest data
      await loadMissions();
      
      // Then subscribe to missions updates
      _cancelSubscriptions();
      
      // Set up the stream listener for real-time updates
      _missionsSubscription = _missionService.getUserMissions(userId).listen((missions) {
        _missions = missions;
        _filterMissions();
        _isLoading = false;
        _hasError = false;
        _errorMessage = null;
        _lastRefresh = DateTime.now();
        
        // Only log significant changes to reduce noise
        AppLogger.info('Mission stream updated: ${missions.length} missions');
        notifyListeners();
      }, onError: (error) {
        AppLogger.error('Error loading missions: $error');
        _isLoading = false;
        _hasError = true;
        _errorMessage = 'Failed to load missions: ${error.toString()}';
        notifyListeners();
      });
    } catch (e) {
      AppLogger.error('Error initializing mission provider: $e');
      _isLoading = false;
      _hasError = true;
      _errorMessage = 'Failed to initialize missions: ${e.toString()}';
      notifyListeners();
    }
  }
  
  // Get completed missions that haven't been claimed
  List<Mission> getCompletedUnclaimedMissions() {
    // Don't trigger a load here - rely on the stream subscription
    return _missions.where((mission) => 
      mission.completed && !mission.rewardClaimed).toList();
  }
  
  // Manually load missions - only use when absolutely necessary
  Future<void> loadMissions() async {
    if (_userId == null) return;
    if (_isLoading) return; // Prevent multiple simultaneous loads
    
    AppLogger.debug('Manual mission load requested');
    
    _isLoading = true;
    _hasError = false;
    _errorMessage = null;
    notifyListeners();
    
    try {
      // Remove the generateMissions call here - UserService will handle this
      // await _missionService.generateMissions(_userId!);
      
      // Get current missions
      final missions = await _firestore
          .collection('users')
          .doc(_userId!)
          .collection('missions')
          .where('expiresAt', isGreaterThan: Timestamp.fromDate(DateTime.now()))
          .get();
      
      _missions = missions.docs
          .map((doc) => Mission.fromJson(doc.data(), doc.id))
          .toList();
      
      _filterMissions();
      _lastRefresh = DateTime.now();
      
      // Only log once at the end of loading
      AppLogger.info('Manually loaded ${_missions.length} missions');
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      AppLogger.error('Error loading missions: $e');
      _isLoading = false;
      _hasError = true;
      _errorMessage = 'Failed to load missions: ${e.toString()}';
      notifyListeners();
    }
  }
  
  // Update the trackGamePlayed method to avoid unnecessary mission loading
  Future<void> trackGamePlayed({
    required bool isHellMode,
    required bool isWin,
    GameDifficulty? difficulty,
  }) async {
    if (_userId == null) return;
    if (_isTrackingGame) {
      AppLogger.debug('trackGamePlayed already in progress, ignoring duplicate call');
      return;
    }

    _isTrackingGame = true;
    try {
      await _missionService.trackGamePlayed(
        userId: _userId!,
        isHellMode: isHellMode,
        isWin: isWin,
        difficulty: difficulty,
      );
      
      // Don't manually load missions here - the stream will update automatically
      AppLogger.info('Game played tracked: isHellMode=$isHellMode, isWin=$isWin');
    } catch (e) {
      AppLogger.error('Error tracking game played: $e');
      _hasError = true;
      _errorMessage = 'Failed to track game: ${e.toString()}';
      notifyListeners();
    } finally {
      _isTrackingGame = false;
    }
  }
  // Complete a mission and claim reward
  Future<int> completeMission(String missionId) async {
    if (_userId == null) return 0;
    
    try {
      final xpReward = await _missionService.completeMission(_userId!, missionId);
      
      // Update local mission data
      final index = _missions.indexWhere((m) => m.id == missionId);
      if (index >= 0) {
        // Using the correct parameter name that exists in the Mission class
        final updatedMission = _missions[index].copyWith(
          completed: true,
          // The Mission class likely has a different parameter for tracking claimed rewards
          // such as 'claimed' or 'isRewardClaimed' instead of 'rewardClaimed'
          // such as 'claimed' or 'isRewardClaimed' instead of 'rewardClaimed'
          rewardClaimed: true,
        );
        _missions[index] = updatedMission;
        _filterMissions();
        notifyListeners();
      }
      
      return xpReward;
    } catch (e) {
      AppLogger.error('Error completing mission: $e');
      _hasError = true;
      _errorMessage = 'Failed to complete mission: ${e.toString()}';
      notifyListeners();
      return 0;
    }
  }
  // Reset state when user logs out
  void _resetState() {
    _missions = [];
    _dailyMissions = [];
    _weeklyMissions = [];
    _normalMissions = [];
    _hellMissions = [];
    _cancelSubscriptions();
    _isLoading = false;
    _hasError = false;
    _errorMessage = null;
    _userId = null;
    _lastRefresh = null;
  }
  
  // Filter missions into categories
  void _filterMissions() {
    _dailyMissions = _missions.where((m) => m.type == MissionType.daily).toList()
      ..sort((a, b) => a.completed ? 1 : (b.completed ? -1 : 0));
    
    _weeklyMissions = _missions.where((m) => m.type == MissionType.weekly).toList()
      ..sort((a, b) => a.completed ? 1 : (b.completed ? -1 : 0));
    
    _normalMissions = _missions.where((m) => m.category == MissionCategory.normal).toList()
      ..sort((a, b) => a.completed ? 1 : (b.completed ? -1 : 0));
    
    _hellMissions = _missions.where((m) => m.category == MissionCategory.hell).toList()
      ..sort((a, b) => a.completed ? 1 : (b.completed ? -1 : 0));
  }
  
  // Get missions that are about to expire (within 24 hours)
  List<Mission> getExpiringMissions() {
    final now = DateTime.now();
    return _missions.where((mission) {
      if (mission.completed) return false;
      final difference = mission.expiresAt.difference(now);
      return difference.inHours <= 24 && difference.inSeconds > 0;
    }).toList();
  }
  
  // Get mission by ID
  Mission? getMissionById(String missionId) {
    try {
      return _missions.firstWhere((m) => m.id == missionId);
    } catch (e) {
      return null;
    }
  }
  
  // Cancel subscriptions when not needed
  void _cancelSubscriptions() {
    _missionsSubscription?.cancel();
    _missionsSubscription = null;
  }

  @override
  void dispose() {
    _cancelSubscriptions();
    super.dispose();
  }
}
