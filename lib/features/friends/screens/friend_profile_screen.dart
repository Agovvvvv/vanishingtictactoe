import 'dart:async';
import 'package:flutter/material.dart';
import 'package:vanishingtictactoe/core/navigation/navigation_service.dart';
import 'package:vanishingtictactoe/core/utils/app_logger.dart';
import '../services/friend_service.dart';
import '../services/challenge_service.dart';
import 'package:vanishingtictactoe/features/profile/services/stats_service.dart';
import 'package:vanishingtictactoe/features/profile/services/profile_customization_service.dart';
import 'package:vanishingtictactoe/shared/models/user_account.dart';
import 'package:vanishingtictactoe/shared/models/user_level.dart';
import 'package:vanishingtictactoe/shared/widgets/stats_toggle.dart';
import 'package:vanishingtictactoe/shared/widgets/stats_section.dart';
import 'package:vanishingtictactoe/shared/widgets/custom_icon.dart';

class FriendProfileScreen extends StatefulWidget {
  final String friendId;
  final String friendUsername;

  const FriendProfileScreen({
    super.key,
    required this.friendId,
    required this.friendUsername,
  });

  @override
  State<FriendProfileScreen> createState() => _FriendProfileScreenState();
}

class _FriendProfileScreenState extends State<FriendProfileScreen> with AutomaticKeepAliveClientMixin {
  final FriendService _friendService = FriendService();
  final ChallengeService _challengeService = ChallengeService();
  final StatsService _statsService = StatsService();
  final ProfileCustomizationService _customizationService = ProfileCustomizationService();
  bool _isLoading = true;
  bool _isOnlineStatsSelected = false;
  bool _isInitialized = false;
  Map<String, dynamic>? _friendData;
  Map<String, GameStats>? _friendStats;
  ProfileCustomization? _friendCustomization;
  
  // Cache for profile data to avoid unnecessary rebuilds
  final Map<String, dynamic> _cachedProfileData = {};
  
  @override
  bool get wantKeepAlive => true; // Keep this screen alive when navigating

  @override
  void initState() {
    super.initState();
    _initializeScreen();
  }
  
  Future<void> _initializeScreen() async {
    if (_isInitialized) return;
    
    // Load friend data with progressive rendering
    _loadFriendData();
    
    // Mark as initialized to avoid duplicate initialization
    _isInitialized = true;
  }

  Future<void> _loadFriendData() async {
    // Start with a quick check of cached data
    final friendId = widget.friendId;
    
    if (_cachedProfileData.containsKey(friendId)) {
      // Use cached data first for immediate display
      AppLogger.info('Using cached profile data for quick display');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
    
    // Then refresh data in the background
    _refreshFriendData(showLoadingIndicator: _cachedProfileData.isEmpty);
  }
  
  Future<void> _refreshFriendData({bool showLoadingIndicator = true}) async {
    if (showLoadingIndicator && mounted) {
      setState(() => _isLoading = true);
    }
    
    try {
      // Load friend profile data
      final friendData = await _friendService.getFriendProfile(widget.friendId);
      
      // Load friend stats
      final stats = await _statsService.getUserStats(widget.friendId);
      
      // Load friend customization
      ProfileCustomization customization;
      try {
        customization = await _customizationService.getCustomization(widget.friendId);
        AppLogger.info('Successfully loaded friend customization');
      } catch (e) {
        AppLogger.warning('Could not load friend customization: $e');
        // Use default values if customization can't be loaded
        customization = ProfileCustomization(
          icon: ProfileIcons.person,
          borderStyle: ProfileBorderStyle.classic,
          backgroundColor: Colors.blue,
          isPremium: false
        );
      }
      
      if (mounted) {
        setState(() {
          _friendData = friendData;
          _friendStats = stats;
          _friendCustomization = customization;
          _isLoading = false;
          
          // Cache the refreshed data
          _cachedProfileData[widget.friendId] = {
            'lastUpdated': DateTime.now(),
            'onlineStats': stats['onlineStats'],
            'vsComputerStats': stats['vsComputerStats'],
            'friendData': friendData,
            'customization': customization,
          };
        });
        
        AppLogger.info('Refreshed and cached friend data in FriendProfileScreen');
      }
    } catch (e) {
      AppLogger.error('Error refreshing friend data: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        _showErrorSnackBar('Failed to load friend data: ${e.toString()}');
      }
    }
  }

  Future<void> _removeFriend() async {
    setState(() => _isLoading = true);
    
    try {
      await _friendService.deleteFriend(widget.friendId);
      if (mounted) {
        NavigationService.instance.goBack(context);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showErrorSnackBar('Failed to remove friend: ${e.toString()}');
      }
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        margin: const EdgeInsets.all(10),
      ),
    );
  }

  void _confirmRemoveFriend() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.person_remove, color: Colors.red.shade700),
            ),
            const SizedBox(width: 12),
            const Text('Remove Friend'),
          ],
        ),
        content: Text(
          'Are you sure you want to remove ${widget.friendUsername} from your friends list?',
          style: TextStyle(color: Colors.grey.shade700),
        ),
        actions: [
          TextButton(
            onPressed: () => NavigationService.instance.goBack(context),
            child: Text(
              'Cancel',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              NavigationService.instance.goBack(context);
              _removeFriend();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }

  // Fix the _challengeFriend method to use widget properties
  Future<void> _challengeFriend() async {
    try {
      await _challengeService.sendGameChallenge(widget.friendId, widget.friendUsername);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Challenge sent to ${widget.friendUsername}'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error sending challenge: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.friendUsername,
          style: const TextStyle(
            color: Colors.black,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.black),
            onPressed: () => _refreshFriendData(showLoadingIndicator: true),
          ),
        ],
      ),
      body: _buildBody(context),
    );
  }
  
  Widget _buildBody(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    
    // Create a UserLevel object from the map data
    final userLevelMap = _friendData?['userLevel'] as Map<String, dynamic>?;
    final userLevel = userLevelMap != null 
        ? UserLevel.fromJson(userLevelMap)
        : UserLevel(level: 1, currentXp: 0, xpToNextLevel: 100);
        
    final UserAccount friendAccount = UserAccount(
      id: widget.friendId,
      username: widget.friendUsername,
      email: _friendData?['email'] ?? '',
      onlineStats: _friendStats != null ? _friendStats!['onlineStats']! : GameStats(),
      vsComputerStats: _friendStats != null ? _friendStats!['vsComputerStats']! : GameStats(),
      userLevel: userLevel,
      isOnline: _friendData?['isOnline'] ?? false,
    );
    
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.white, Colors.blue.shade50],
        ),
      ),
      child: RefreshIndicator(
        onRefresh: () => _refreshFriendData(showLoadingIndicator: false),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Custom friend profile card
              _buildFriendProfileCard(friendAccount),
              const SizedBox(height: 24),
              
              // Stats toggle with optimized rebuilding
              RepaintBoundary(
                child: StatsToggle(
                  isOnlineStatsSelected: _isOnlineStatsSelected,
                  onToggle: (value) => setState(() => _isOnlineStatsSelected = value),
                ),
              ),
              const SizedBox(height: 18),
              
              // Stats section with optimized rebuilding
              RepaintBoundary(
                child: StatsSection(
                  title: _isOnlineStatsSelected ? 'Online Stats' : 'VS Computer Stats',
                  stats: _friendStats != null
                      ? (_isOnlineStatsSelected 
                          ? _friendStats!['onlineStats']!
                          : _friendStats!['vsComputerStats']!)
                      : GameStats(),
                  icon: _isOnlineStatsSelected ? Icons.public : Icons.computer,
                ),
              ),
              
              // Last played indicator
              if (_friendData != null && _friendData!['lastPlayed'] != null)
                Padding(
                  padding: const EdgeInsets.only(top: 24.0, bottom: 16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 16,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Last Played: ${_formatLastPlayed(_friendData!['lastPlayed'])}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              
              // Last updated indicator
              if (_cachedProfileData.containsKey(widget.friendId))
                Padding(
                  padding: const EdgeInsets.only(top: 8.0, bottom: 16.0),
                  child: Center(
                    child: Text(
                      'Last updated: ${_getFormattedLastUpdated(widget.friendId)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildFriendProfileCard(UserAccount account) {
    // Use customization data if available, otherwise use defaults
    IconData iconData = _friendCustomization?.icon ?? ProfileIcons.person;
    ProfileBorderStyle borderStyle = _friendCustomization?.borderStyle ?? ProfileBorderStyle.classic;
    Color backgroundColor = _friendCustomization?.backgroundColor ?? Colors.blue;
    bool isPremium = _friendCustomization?.isPremium ?? false;
    
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white,
              backgroundColor.withOpacity(0.05),
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: backgroundColor.withOpacity(0.1),
              blurRadius: 10,
              spreadRadius: 0,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              // Profile Avatar
              Stack(
                alignment: Alignment.bottomRight,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: backgroundColor.withOpacity(0.3),
                          blurRadius: 15,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: CustomProfileIcon(
                      icon: iconData,
                      borderStyle: borderStyle,
                      size: 120,
                      backgroundColor: backgroundColor,
                      iconColor: Colors.white,
                      isPremium: isPremium,
                      showPremiumEffects: isPremium,
                    ),
                  ),
                  // Online indicator
                  if (account.isOnline)
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 4,
                              spreadRadius: 0,
                            ),
                          ],
                        ),
                      ),
                    ),
                  // Premium badge if applicable
                  if (isPremium)
                    Positioned(
                      bottom: 0,
                      right: 30, // Offset to not overlap with online indicator
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.amber.shade600,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.amber.shade200.withOpacity(0.6),
                              blurRadius: 8,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.star,
                          color: Colors.white,
                          size: 14,
                        ),
                      ),
                    ),
                ],
              ),
              
              const SizedBox(height: 24),
              
              // Username with Level
              Column(
                children: [
                  Text(
                    account.username,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                      shadows: [
                        Shadow(
                          color: backgroundColor.withOpacity(0.3),
                          offset: const Offset(0, 1),
                          blurRadius: 2,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade100,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.amber.shade200.withOpacity(0.5),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      'Level ${account.userLevel.level}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.amber.shade800,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    account.isOnline ? 'Online' : 'Offline',
                    style: TextStyle(
                      fontSize: 16,
                      color: account.isOnline ? Colors.green.shade600 : Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 24),
              
              // Friend action buttons
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.sports_esports),
                      label: const Text('Challenge'),
                      onPressed: account.isOnline ? _challengeFriend : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade500,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.person_remove),
                      label: const Text('Remove'),
                      onPressed: _confirmRemoveFriend,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red.shade600,
                        side: BorderSide(color: Colors.red.shade300),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  String _getFormattedLastUpdated(String userId) {
    final lastUpdated = _cachedProfileData[userId]?['lastUpdated'] as DateTime?;
    if (lastUpdated == null) return 'Just now';
    
    final now = DateTime.now();
    final difference = now.difference(lastUpdated);
    
    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} ${difference.inMinutes == 1 ? 'minute' : 'minutes'} ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} ${difference.inHours == 1 ? 'hour' : 'hours'} ago';
    } else {
      return '${difference.inDays} ${difference.inDays == 1 ? 'day' : 'days'} ago';
    }
  }
  
  // Format the last played date
  String _formatLastPlayed(dynamic lastPlayed) {
    if (lastPlayed == null) return 'Never';
    
    DateTime lastPlayedDate;
    if (lastPlayed is String) {
      lastPlayedDate = DateTime.tryParse(lastPlayed) ?? DateTime.now();
    } else if (lastPlayed is Map) {
      // Handle Firestore Timestamp
      try {
        lastPlayedDate = DateTime.fromMillisecondsSinceEpoch(
          (lastPlayed['_seconds'] * 1000 + lastPlayed['_nanoseconds'] ~/ 1000000).toInt()
        );
      } catch (e) {
        return 'Unknown';
      }
    } else if (lastPlayed is DateTime) {
      lastPlayedDate = lastPlayed;
    } else {
      return 'Unknown';
    }
    
    // Format the date as dd/MM/yyyy
    return '${lastPlayedDate.day.toString().padLeft(2, '0')}/${lastPlayedDate.month.toString().padLeft(2, '0')}/${lastPlayedDate.year}';
  }
}