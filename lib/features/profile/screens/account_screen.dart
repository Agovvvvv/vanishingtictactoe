// Update imports to use shared widgets
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vanishingtictactoe/core/navigation/navigation_service.dart';
import 'package:vanishingtictactoe/shared/providers/user_provider.dart';
import 'package:vanishingtictactoe/features/profile/widgets/profile_card.dart';
import 'package:vanishingtictactoe/shared/widgets/stats_section.dart';
import 'package:vanishingtictactoe/shared/widgets/stats_toggle.dart';
import 'package:vanishingtictactoe/features/profile/widgets/unauthenticated_view.dart';
import 'package:vanishingtictactoe/core/utils/app_logger.dart';
import 'package:vanishingtictactoe/features/profile/services/profile_customization_service.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> with AutomaticKeepAliveClientMixin {
  bool _isOnlineStatsSelected = false;
  bool _isLoading = true;
  bool _isInitialized = false;
  
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
    
    // Load user data with progressive rendering
    _loadUserData();
    
    // Mark as initialized to avoid duplicate initialization
    _isInitialized = true;
  }

  Future<void> _loadUserData() async {
    // Start with a quick check of cached data
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final userId = userProvider.user?.id;
    
    if (userId != null && _cachedProfileData.containsKey(userId)) {
      // Use cached data first for immediate display
      AppLogger.info('Using cached profile data for quick display');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
    
    // Then refresh data in the background
    _refreshUserData(showLoadingIndicator: _cachedProfileData.isEmpty);
  }

  Future<void> _refreshUserData({bool showLoadingIndicator = true}) async {
    if (showLoadingIndicator && mounted) {
      setState(() => _isLoading = true);
    }
    
    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final userId = userProvider.user?.id;
      
      if (userId != null) {
        // Refresh user data
        await userProvider.refreshUserData();
        
        // Clear profile customization cache to force reload
        final customizationService = ProfileCustomizationService();
        customizationService.clearCache(userId);
        
        // Cache the refreshed data
        if (userProvider.user != null) {
          _cachedProfileData[userId] = {
            'lastUpdated': DateTime.now(),
            'onlineStats': userProvider.user!.onlineStats,
            'vsComputerStats': userProvider.user!.vsComputerStats,
            // Add other frequently accessed data here
          };
        }
        
        AppLogger.info('Refreshed and cached user data in AccountScreen');
      }
    } catch (e) {
      AppLogger.error('Error refreshing user data: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    
    return Consumer<UserProvider>(
      builder: (context, userProvider, _) {
        final account = userProvider.user;

        if (account == null) {
          return const UnauthenticatedView();
        }

        return Scaffold(
          extendBody: true, // Important for the floating nav bar effect
          appBar: AppBar(
            title: const Text(
              'Account',
              style: TextStyle(
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
                onPressed: () => _refreshUserData(showLoadingIndicator: true),
              ),
              IconButton(
                icon: const Icon(Icons.logout, color: Colors.black),
                onPressed: () => _confirmLogout(context, userProvider),
              ),
            ],
          ),
          body: Padding(
            padding: const EdgeInsets.only(bottom: 60), // Add padding for the navbar
            child: _buildBody(context, account),
          ),
          );
        },
      );
  }
  
  Widget _buildBody(BuildContext context, dynamic account) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.white, Colors.blue.shade50],
        ),
      ),
      child: RefreshIndicator(
        onRefresh: () => _refreshUserData(showLoadingIndicator: false),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Profile card with optimized rebuilding
              RepaintBoundary(
                child: ProfileCard(account: account),
              ),
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
                  stats: _isOnlineStatsSelected ? account.onlineStats : account.vsComputerStats,
                  icon: _isOnlineStatsSelected ? Icons.public : Icons.computer,
                ),
              ),
              
              // Last updated indicator
              if (_cachedProfileData.containsKey(account.id))
                Padding(
                  padding: const EdgeInsets.only(top: 16.0, bottom: 40),
                  child: Center(
                    child: Text(
                            'Last updated: ${_getFormattedLastUpdated(account.id)}',
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

  void _confirmLogout(BuildContext context, UserProvider userProvider) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        elevation: 8,
        child: Container(
          padding: const EdgeInsets.all(24.0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.white, Colors.grey.shade100],
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.red.shade100,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.logout_rounded,
                      color: Colors.red.shade700,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Text(
                    'Confirm Logout',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                'Are you sure you want to log out?',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[700],
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.grey[700],
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: () async {
                      Navigator.pop(context); // Close dialog
                      await userProvider.signOut();
                      if (context.mounted) {       
                        NavigationService.instance.navigateToAndRemoveUntil('/main');
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade700,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      'Logout',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
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
}