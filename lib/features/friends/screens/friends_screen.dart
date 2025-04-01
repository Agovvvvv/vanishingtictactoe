import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/friend_service.dart';
import '../services/challenge_service.dart';
import '../services/notification_service.dart';
import 'package:vanishingtictactoe/shared/providers/user_provider.dart';
import 'package:vanishingtictactoe/shared/providers/hell_mode_provider.dart';
import 'package:vanishingtictactoe/features/friends/screens/friend_profile_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:vanishingtictactoe/core/utils/font_preloader.dart';
import 'package:vanishingtictactoe/features/profile/services/profile_customization_service.dart';
import 'package:vanishingtictactoe/shared/widgets/custom_icon.dart';
import 'package:vanishingtictactoe/core/utils/app_logger.dart';

class FriendsScreen extends StatefulWidget {
  const FriendsScreen({super.key});

  @override
  State<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FriendService _friendService = FriendService();
  final ChallengeService _challengeService = ChallengeService();
  final NotificationService _notificationService = NotificationService();
  final ProfileCustomizationService _customizationService = ProfileCustomizationService();
  List<Map<String, dynamic>> friends = [];
  List<Map<String, dynamic>> filteredFriends = [];
  List<Map<String, dynamic>> friendRequests = [];
  int _unreadNotifications = 0;
  StreamSubscription? _friendsSubscription;
  StreamSubscription? _requestsSubscription;
  StreamSubscription? _notificationsSubscription;
  Timer? _refreshTimer;
  ScaffoldMessengerState _scaffoldMessenger = ScaffoldMessengerState();
  
  // Cache for friend customizations
  final Map<String, ProfileCustomization> _friendCustomizations = {};

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    
    // Show loading state immediately
    setState(() {
      _isLoading = true;
    });
    
    // Load friend requests
    _requestsSubscription = _friendService.getFriendRequests().listen((requests) {
      if (mounted) {
        setState(() {
          friendRequests = requests;
        });
      }
    });

    // Load friends with optimized loading indicator
    _friendsSubscription = _friendService.getFriends().listen((friendsList) {
      if (mounted) {
        setState(() {
          friends = friendsList;
          _filterFriends(_searchController.text);
          _isLoading = false; // Hide loading indicator once friends are loaded
        });
        
        // Load customizations for each friend
        _loadFriendCustomizations(friendsList);
      }
    });
    
    // Listen for unread notifications
    _notificationsSubscription = _notificationService.getNotifications().listen((notifications) {
      if (mounted) {
        // Count unread game challenges that aren't expired
        final now = DateTime.now();
        final unreadCount = notifications.where((notification) {
          final isUnread = !(notification['read'] as bool? ?? true);
          final type = notification['type'] as String? ?? '';
          final isGameChallenge = type == 'gameChallenge';
          final isExpired = notification['expired'] as bool? ?? false;
          
          // Check expiration time
          bool expired = isExpired;
          if (!expired && isGameChallenge) {
            final expirationTime = notification['expirationTime'] as Timestamp?;
            if (expirationTime != null) {
              expired = now.isAfter(expirationTime.toDate());
            }
          }
          
          return isUnread && isGameChallenge && !expired;
        }).length;
        
        setState(() {
          _unreadNotifications = unreadCount;
        });
      }
    });
    
    // Start refresh timer with longer interval to reduce Firestore reads
    _refreshTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      _friendService.refreshFriendStatuses();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _scaffoldMessenger = ScaffoldMessenger.of(context);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _friendsSubscription?.cancel();
    _requestsSubscription?.cancel();
    _notificationsSubscription?.cancel();
    _refreshTimer?.cancel();
    super.dispose();
  }

  void _filterFriends(String query) {
    setState(() {
      if (query.isEmpty) {
        filteredFriends = List.from(friends);
      } else {
        filteredFriends = friends
            .where((friend) => friend['username']
                .toString()
                .toLowerCase()
                .contains(query.toLowerCase()))
            .toList();
      }
    });
  }
  
  // Load customizations for all friends
  Future<void> _loadFriendCustomizations(List<Map<String, dynamic>> friendsList) async {
    for (final friend in friendsList) {
      final friendId = friend['id'] as String?;
      if (friendId != null) {
        try {
          final customization = await _customizationService.getCustomization(friendId);
          if (mounted) {
            setState(() {
              _friendCustomizations[friendId] = customization;
            });
          }
        } catch (e) {
          AppLogger.warning('Could not load customization for friend $friendId: $e');
          // Use default values if customization can't be loaded
        }
      }
    }
  }
  
  // Build a friend avatar with custom icon if available
  Widget _buildFriendAvatar(Map<String, dynamic> friend) {
    final friendId = friend['id'] as String?;
    final username = friend['username'] as String? ?? 'U';
    
    // If we have customization for this friend, use it
    if (friendId != null && _friendCustomizations.containsKey(friendId)) {
      final customization = _friendCustomizations[friendId]!;
      
      return SizedBox(
        width: 48,
        height: 48,
        child: CustomProfileIcon(
          icon: customization.icon,
          borderStyle: customization.borderStyle,
          backgroundColor: customization.backgroundColor,
          iconColor: Colors.white,
          size: 48,
          showPremiumEffects: customization.isPremium,
          isPremium: customization.isPremium,
        ),
      );
    }
    
    // Otherwise use default avatar with first letter
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.blue.shade300,
            Colors.blue.shade500,
          ],
        ),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.blue.shade200.withOpacity(0.5),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Text(
          username[0].toUpperCase(),
          style: FontPreloader.getTextStyle(
            fontFamily: 'Poppins',
            fontSize: 20,
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
  
  // Build an avatar for friend requests
  Widget _buildRequestAvatar(Map<String, dynamic> request) {
    final username = request['username'] as String? ?? 'U';
    
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.blue.shade300,
            Colors.blue.shade500,
          ],
        ),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.blue.shade200.withOpacity(0.5),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Text(
          username[0].toUpperCase(),
          style: FontPreloader.getTextStyle(
            fontFamily: 'Poppins',
            fontSize: 16,
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  void _acceptFriendRequest(String userId) async {
    try {
      await _friendService.acceptFriendRequest(userId);
      _showSnackBar('Friend request accepted');
    } catch (e) {
      _showSnackBar('Error accepting friend request: ${e.toString()}', isError: true);
    }
  }

  void _rejectFriendRequest(String userId) async {
    try {
      await _friendService.rejectFriendRequest(userId);
      _showSnackBar('Friend request rejected');
    } catch (e) {
      _showSnackBar('Error rejecting friend request: ${e.toString()}', isError: true);
    }
  }

  // Challenge a friend to a game
  Future<void> _challengeFriend(String friendId, String friendUsername) async {
    try {
      await _challengeService.sendGameChallenge(friendId, friendUsername);
      _showSnackBar('Challenge sent to $friendUsername');
    } catch (e) {
      _showSnackBar('Error sending challenge: ${e.toString()}', isError: true);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    _scaffoldMessenger.showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        margin: const EdgeInsets.all(10),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final hellModeProvider = Provider.of<HellModeProvider>(context);
    final user = userProvider.user;
    final isHellMode = hellModeProvider.isHellModeActive;

    if (user == null) {
      // Define colors based on hell mode
      final primaryColor = isHellMode ? Colors.red : Colors.blue;
      final secondaryColor = isHellMode ? Colors.orange : Colors.blue.shade300;
      final backgroundColor = isHellMode ? Colors.grey.shade900 : Colors.white;
      final textColor = isHellMode ? Colors.white : Colors.grey.shade800;
      final subtextColor = isHellMode ? Colors.grey.shade400 : Colors.grey.shade600;
      
      return Scaffold(
        backgroundColor: backgroundColor,
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Text(
            'Friends', 
            style: FontPreloader.getTextStyle(
              fontFamily: 'Orbitron',
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: textColor,
              letterSpacing: 0.5,
            )
          ),
          iconTheme: IconThemeData(color: textColor),
        ),
        body: Stack(
          children: [
            // Background gradient
            if (isHellMode)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black,
                        Colors.red.shade900.withValues(alpha: 0.7),
                        Colors.black,
                      ],
                      stops: const [0.0, 0.5, 1.0],
                    ),
                  ),
                ),
              )
            else
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.white,
                        Colors.blue.shade50,
                        Colors.blue.shade100.withValues(alpha: 0.3),
                      ],
                      stops: const [0.0, 0.7, 1.0],
                    ),
                  ),
                ),
              ),
              
            // Main content with animations
            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24.0),
                  child: TweenAnimationBuilder<double>(
                    tween: Tween<double>(begin: 0.0, end: 1.0),
                    duration: const Duration(milliseconds: 1000),
                    curve: Curves.easeOutCubic,
                    builder: (context, value, child) {
                      return Opacity(
                        opacity: value,
                        child: Transform.translate(
                          offset: Offset(0, 30 * (1 - value)),
                          child: child,
                        ),
                      );
                    },
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Friends icon with animated effects
                        TweenAnimationBuilder<double>(
                          tween: Tween<double>(begin: 0.8, end: 1.0),
                          duration: const Duration(milliseconds: 1200),
                          curve: Curves.elasticOut,
                          builder: (context, value, child) {
                            return Transform.scale(
                              scale: value,
                              child: child,
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isHellMode ? Colors.black : Colors.white,
                              boxShadow: [
                                BoxShadow(
                                  color: primaryColor.withValues(alpha: 0.4),
                                  blurRadius: 15,
                                  spreadRadius: 2,
                                ),
                                BoxShadow(
                                  color: secondaryColor.withValues(alpha: 0.2),
                                  blurRadius: 20,
                                  spreadRadius: 5,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                              border: Border.all(
                                color: primaryColor.withValues(alpha: 0.7),
                                width: 2.5,
                              ),
                            ),
                            child: ShaderMask(
                              shaderCallback: (Rect bounds) {
                                return LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    primaryColor,
                                    primaryColor.withValues(alpha: 0.8),
                                  ],
                                ).createShader(bounds);
                              },
                              child: Icon(
                                isHellMode ? Icons.group : Icons.people_outline,
                                size: 70,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                        
                        const SizedBox(height: 40),
                        
                        // Main content card with glass effect
                        Container(
                          padding: const EdgeInsets.all(30),
                          decoration: BoxDecoration(
                            color: isHellMode 
                                ? Colors.black.withValues(alpha: 0.6) 
                                : Colors.white.withValues(alpha: 0.9),
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: primaryColor.withValues(alpha: 0.1),
                                blurRadius: 20,
                                spreadRadius: 5,
                                offset: const Offset(0, 10),
                              ),
                            ],
                            border: Border.all(
                              color: primaryColor.withValues(alpha: 0.2),
                              width: 1,
                            ),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(24),
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                              child: Column(
                                children: [
                                  Text(
                                    isHellMode ? 'Challenge Friends in Hell Mode' : 'Connect with Friends',
                                    style: FontPreloader.getTextStyle(
                                      fontFamily: 'Orbitron',
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                      color: textColor,
                                      letterSpacing: 0.5,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 20),
                                  Text(
                                    isHellMode
                                        ? 'Sign in to challenge your friends to Hell Mode battles'
                                        : 'Sign in to add friends and challenge them to games',
                                    style: FontPreloader.getTextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: 16,
                                      color: subtextColor,
                                      letterSpacing: 0.2,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 40),
                                  
                                  // Sign in button with animation
                                  TweenAnimationBuilder<double>(
                                    tween: Tween<double>(begin: 0.0, end: 1.0),
                                    duration: const Duration(milliseconds: 800),
                                    curve: Curves.easeOutCubic,
                                    builder: (context, value, child) {
                                      return Transform.scale(
                                        scale: 0.8 + (0.2 * value),
                                        child: Opacity(
                                          opacity: value,
                                          child: child,
                                        ),
                                      );
                                    },
                                    child: Container(
                                      width: double.infinity,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(16),
                                        boxShadow: [
                                          BoxShadow(
                                            color: primaryColor.withValues(alpha: 0.4),
                                            blurRadius: 15,
                                            offset: const Offset(0, 8),
                                            spreadRadius: 0,
                                          ),
                                        ],
                                        gradient: LinearGradient(
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                          colors: isHellMode
                                              ? [Colors.red.shade700, Colors.red.shade900]
                                              : [Colors.blue.shade400, Colors.blue.shade700],
                                        ),
                                      ),
                                      child: ElevatedButton(
                                        onPressed: () {
                                          Navigator.pushNamed(context, '/login');
                                        },
                                        style: ElevatedButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(vertical: 18),
                                          backgroundColor: Colors.transparent,
                                          foregroundColor: Colors.white,
                                          shadowColor: Colors.transparent,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(16),
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              isHellMode ? Icons.login : Icons.login_rounded,
                                              size: 20,
                                            ),
                                            const SizedBox(width: 12),
                                            Text(
                                              'SIGN IN',
                                              textAlign: TextAlign.center,
                                              style: FontPreloader.getTextStyle(
                                                fontFamily: 'Orbitron',
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white,
                                                letterSpacing: 1.0,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                  
                                  const SizedBox(height: 24),
                                  
                                  // Feature highlight
                                  TweenAnimationBuilder<double>(
                                    tween: Tween<double>(begin: 0.0, end: 1.0),
                                    duration: const Duration(milliseconds: 1000),
                                    curve: Curves.easeOutCubic,
                                    builder: (context, value, child) {
                                      return Opacity(
                                        opacity: value,
                                        child: Transform.translate(
                                          offset: Offset(0, 20 * (1 - value)),
                                          child: child,
                                        ),
                                      );
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: isHellMode 
                                            ? Colors.red.withValues(alpha: 0.1) 
                                            : Colors.blue.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: primaryColor.withValues(alpha: 0.2),
                                          width: 1,
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(10),
                                            decoration: BoxDecoration(
                                              color: primaryColor.withValues(alpha: 0.1),
                                              shape: BoxShape.circle,
                                            ),
                                            child: Icon(
                                              isHellMode ? Icons.local_fire_department : Icons.emoji_events_outlined,
                                              color: primaryColor,
                                              size: 24,
                                            ),
                                          ),
                                          const SizedBox(width: 16),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  isHellMode ? 'Hell Mode Challenges' : 'Friend Challenges',
                                                  style: FontPreloader.getTextStyle(
                                                    fontFamily: 'Poppins',
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.w600,
                                                    color: textColor,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  isHellMode 
                                                      ? 'Challenge friends to the ultimate test of skill' 
                                                      : 'Track your wins and compete with friends',
                                                  style: FontPreloader.getTextStyle(
                                                    fontFamily: 'Poppins',
                                                    fontSize: 14,
                                                    color: subtextColor,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    // We already have hellModeProvider and isHellMode from above
    
    return Scaffold(
      extendBody: true, // Important for the floating nav bar effect
      appBar: AppBar(
        title: Text(
          'Friends', 
          style: FontPreloader.getTextStyle(
            fontFamily: 'Orbitron',
            fontSize: 24,
            color: isHellMode ? Colors.red : Colors.black,
            fontWeight: FontWeight.bold,
          )
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: isHellMode ? Colors.red : Colors.black),
        actions: [
          // Notifications button with badge
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications, color: Colors.blue),
                onPressed: () {
                  Navigator.pushNamed(context, '/notifications');
                },
              ),
              if (_unreadNotifications > 0)
                Positioned(
                  right: 5,
                  top: 5,
                  child: Container(
                    padding: const EdgeInsets.all(1),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(6),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.red.withOpacity(0.3),
                          blurRadius: 3,
                          spreadRadius: 0,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 12,
                      minHeight: 12,
                    ),
                    child: Text(
                      _unreadNotifications.toString(),
                      style: FontPreloader.getTextStyle(
                        fontFamily: 'Orbitron',
                        fontSize: 8,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.person_add, color: Colors.blue),
            onPressed: () {
              Navigator.pushNamed(context, '/add-friend');
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          Container(
            height: MediaQuery.of(context).size.height - 90, // Make room for the floating nav bar
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: isHellMode 
                    ? [Colors.grey.shade900, Colors.black] 
                    : [Colors.white, Colors.blue.shade50],
              ),
            ),
            child: Column(
          children: [
            // Search bar with improved styling
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withValues(alpha: 0.1),
                      spreadRadius: 0,
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: (value) {
                    _filterFriends(value);
                  },
                  decoration: InputDecoration(
                    hintText: 'Search friends...',
                    prefixIcon: Icon(Icons.search, color: Colors.blue.shade400),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 15),
                  ),
                ),
              ),
            ),
            
            // Friend requests section with improved styling
            if (friendRequests.isNotEmpty)
              Container(
                margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.shade100.withValues(alpha: 0.3),
                      blurRadius: 10,
                      spreadRadius: 0,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              Icons.person_add_alt_1,
                              color: Colors.blue.shade700,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Friend Requests',
                            style: FontPreloader.getTextStyle(
                              fontFamily: 'Orbitron',
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey.shade800,
                            ),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade500,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${friendRequests.length}',
                              style: FontPreloader.getTextStyle(
                                fontFamily: 'Orbitron',
                                fontSize: 12,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1, thickness: 1, indent: 16, endIndent: 16),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: friendRequests.length,
                      itemBuilder: (context, index) {
                        final request = friendRequests[index];
                        return Container(
                          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ListTile(
                            leading: _buildRequestAvatar(request),
                            title: Text(
                              request['username'] ?? 'Unknown',
                              style: FontPreloader.getTextStyle(
                                fontFamily: 'Orbitron',
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Colors.black87,
                              ),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: Colors.green.shade50,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.check,
                                      color: Colors.green.shade600,
                                      size: 18,
                                    ),
                                  ),
                                  onPressed: () => _acceptFriendRequest(request['id']),
                                ),
                                IconButton(
                                  icon: Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: Colors.red.shade50,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.close,
                                      color: Colors.red.shade600,
                                      size: 18,
                                    ),
                                  ),
                                  onPressed: () => _rejectFriendRequest(request['id']),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            
            // Friends list with improved styling and loading indicator
            Expanded(
              child: _isLoading
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 50,
                            height: 50,
                            child: CircularProgressIndicator(
                              color: Colors.blue.shade400,
                              strokeWidth: 3,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Loading friends...',
                            style: FontPreloader.getTextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 16,
                              color: Colors.grey.shade700,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    )
                  : filteredFriends.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                _searchController.text.isNotEmpty
                                    ? Icons.search_off
                                    : Icons.people_outline,
                                size: 64,
                                color: Colors.grey.shade400,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                _searchController.text.isNotEmpty
                                    ? 'No matching friends found'
                                    : 'No friends yet',
                                style: FontPreloader.getTextStyle(
                                  fontFamily: 'Orbitron',
                                  fontSize: 18,
                                  color: Colors.grey.shade700,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              if (_searchController.text.isEmpty) 
                                Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: Text(
                                    'Add friends to challenge them to games',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        )
                      : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 80), // Added bottom padding to avoid navbar overlap
                      itemCount: filteredFriends.length,
                      itemBuilder: (context, index) {
                        final friend = filteredFriends[index];
                        final isOnline = friend['isOnline'] ?? false;
                        
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Colors.white,
                                Colors.blue.shade50,
                              ],
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.blue.shade100.withAlpha(77),
                                blurRadius: 10,
                                spreadRadius: 0,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            leading: Stack(
                              children: [
                                // Get the friend's customization if available
                                _buildFriendAvatar(friend),
                                if (isOnline)
                                  Positioned(
                                    right: 0,
                                    bottom: 0,
                                    child: Container(
                                      width: 14,
                                      height: 14,
                                      decoration: BoxDecoration(
                                        color: Colors.green,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: Colors.white,
                                          width: 2,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            title: Text(
                              friend['username'] ?? 'Unknown',
                              style: FontPreloader.getTextStyle(
                                fontFamily: 'Orbitron',
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                            subtitle: Text(
                              isOnline ? 'Online' : 'Offline',
                              style: FontPreloader.getTextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 13,
                                color: isOnline ? Colors.green.shade600 : Colors.grey.shade600,
                              ),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  decoration: BoxDecoration(
                                    color: Colors.blue.shade50,
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.blue.shade200.withValues(alpha: 0.3),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: IconButton(
                                    icon: Icon(
                                      Icons.sports_esports,
                                      color: Colors.blue.shade700,
                                      size: 20,
                                    ),
                                    onPressed: isOnline
                                        ? () {
                                            // Challenge friend to game
                                            _challengeFriend(friend['id'], friend['username'] ?? 'Unknown');
                                          }
                                        : null,
                                    tooltip: isOnline ? 'Challenge to a game' : 'Friend is offline',
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  decoration: BoxDecoration(
                                    color: Colors.purple.shade50,
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.purple.shade200.withValues( alpha: 0.3),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: IconButton(
                                    icon: Icon(
                                      Icons.person,
                                      color: Colors.purple.shade700,
                                      size: 20,
                                    ),
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => FriendProfileScreen(
                                            friendId: friend['id'],
                                            friendUsername: friend['username'] ?? 'Unknown',
                                          ),
                                        ),
                                      );
                                    },
                                    tooltip: 'View profile',
                                  ),
                                ),
                              ],
                            ),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => FriendProfileScreen(
                                    friendId: friend['id'],
                                    friendUsername: friend['username'] ?? 'Unknown',
                                  ),
                                ),
                              );
                            },
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      // Bottom navigation is now handled by MainNavigationController
    ],
    ),
    );
  }
}
