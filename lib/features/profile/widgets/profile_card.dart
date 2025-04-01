import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vanishingtictactoe/core/utils/app_logger.dart';
import 'package:vanishingtictactoe/shared/models/user_account.dart';
import 'package:vanishingtictactoe/shared/models/unlockable_content.dart';
import 'package:vanishingtictactoe/shared/widgets/level_progress_bar.dart';
import 'package:vanishingtictactoe/features/profile/screens/edit_credentials_screen.dart';
import 'package:vanishingtictactoe/features/profile/screens/icon_selection_screen.dart';
import 'package:vanishingtictactoe/shared/widgets/custom_icon.dart';
import 'package:vanishingtictactoe/features/profile/services/profile_customization_service.dart';
import 'package:vanishingtictactoe/features/tutorial/screens/tutorial_screen.dart';

class ProfileCard extends StatefulWidget {
  final UserAccount account;

  const ProfileCard({super.key, required this.account});

  @override
  State<ProfileCard> createState() => _ProfileCardState();
}

class _ProfileCardState extends State<ProfileCard> with AutomaticKeepAliveClientMixin, TickerProviderStateMixin {
  IconData _selectedIcon = ProfileIcons.person;
  ProfileBorderStyle _selectedBorderStyle = ProfileBorderStyle.classic;
  Color _selectedBackgroundColor = Colors.blue;
  bool _isLoading = true;
  bool _isPremium = false;
  
  // Reference to the profile customization service
  final _customizationService = ProfileCustomizationService();
  
  // Animation controllers
  late AnimationController _pulseController;
  late AnimationController _slideController;
  late AnimationController _fadeController;
  
  @override
  bool get wantKeepAlive => true;
  
  @override
  void initState() {
    super.initState();
    
    // Initialize animation controllers
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
    
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    
    // Start animations
    _slideController.forward();
    _fadeController.forward();
    
    _loadSavedProfileSettings();
  }
  
  @override
  void didUpdateWidget(ProfileCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Only reload if the account ID changed
    if (oldWidget.account.id != widget.account.id) {
      _loadSavedProfileSettings();
    }
  }
  
  @override
  void dispose() {
    _pulseController.dispose();
    _slideController.dispose();
    _fadeController.dispose();
    super.dispose();
  }
  
  Future<void> _loadSavedProfileSettings() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Get customization from the service
      final customization = await _customizationService.getCustomization(widget.account.id);
      
      if (mounted) {
        setState(() {
          _selectedIcon = customization.icon;
          _selectedBorderStyle = customization.borderStyle;
          _selectedBackgroundColor = customization.backgroundColor;
          _isPremium = customization.isPremium;
          _isLoading = false;
        });
      }
    } catch (e) {
      AppLogger.error('Error loading profile settings: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  
  // Add this method to reset the tutorial flag and start the tutorial
  Future<void> _resetTutorial() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('tutorial_completed', false);
    
    if (mounted) {
      // Show a brief message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Starting tutorial...'),
          duration: Duration(seconds: 1),
          behavior: SnackBarBehavior.floating,
        ),
      );
      
      // Navigate to the tutorial screen
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => const TutorialScreen(),
          ),
        );
      }
    }
  }

  // Add method to calculate premium status
  bool _calculatePremiumStatus(IconData icon, ProfileBorderStyle borderStyle, Color backgroundColor) {
    // Check if any of the customization items are premium
    final isPremiumIcon = UnlockableContent.isPremiumIcon(icon);
    final isPremiumBorder = UnlockableContent.isPremiumBorderStyle(borderStyle);
    final isPremiumBackground = UnlockableContent.isPremiumBackgroundColor(backgroundColor);
    
    return isPremiumIcon || isPremiumBorder || isPremiumBackground;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    
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
              _selectedBackgroundColor.withValues( alpha: 0.05),
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: _selectedBackgroundColor.withValues( alpha: 0.1),
              blurRadius: 10,
              spreadRadius: 0,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: _isLoading 
              ? const Center(child: CircularProgressIndicator())
              : Center(
                  child: Column(
                    children: [
                    // Profile Avatar with animation - Wrapped in RepaintBoundary for performance
                    RepaintBoundary(
                      child: Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          // Animated pulse effect for the avatar
                          AnimatedBuilder(
                            animation: _pulseController,
                            builder: (context, child) {
                              return Transform.scale(
                                scale: 1.0 + (_pulseController.value * 0.05),
                                child: child,
                              );
                            },
                            child: GestureDetector(
                              onTap: () async {
                              final result = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => IconSelectionScreen(
                                    initialIcon: _selectedIcon,
                                    initialBorderStyle: _selectedBorderStyle,
                                    initialBackgroundColor: _selectedBackgroundColor,
                                  ),
                                ),
                              );
                              
                              if (result != null && mounted) {
                                // Explicitly cast each value to ensure correct types
                                final newIcon = result['icon'] as IconData;
                                final newBorderStyle = result['borderStyle'] as ProfileBorderStyle;
                                final newBackgroundColor = result['backgroundColor'] as Color? ?? _selectedBackgroundColor;
                                
                                // Calculate premium status for new customization
                                final isPremium = _calculatePremiumStatus(
                                  newIcon, 
                                  newBorderStyle, 
                                  newBackgroundColor
                                );
                                
                                // Update state with new values
                                setState(() {
                                  _selectedIcon = newIcon;
                                  _selectedBorderStyle = newBorderStyle;
                                  _selectedBackgroundColor = newBackgroundColor;
                                  _isPremium = isPremium;
                                });
                                
                                // Save to SharedPreferences for persistence across app restarts
                                final prefs = await SharedPreferences.getInstance();
                                await prefs.setString('profile_icon_${widget.account.id}', 
                                    newIcon.codePoint.toString());
                                await prefs.setString('profile_border_style_${widget.account.id}', 
                                    newBorderStyle.borderColor.toString());
                                await prefs.setInt('profile_background_color_${widget.account.id}', 
                                    newBackgroundColor.value);
                                
                                // Save the updated customization using the service
                                await _customizationService.updateCustomization(
                                  widget.account.id,
                                  icon: _selectedIcon,
                                  borderStyle: _selectedBorderStyle,
                                  backgroundColor: _selectedBackgroundColor,
                                );
                                
                                // Force rebuild to ensure icon is updated
                                if (mounted) {
                                  setState(() {});
                                }
                              }
                            },
                              child: Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: _selectedBackgroundColor.withValues( alpha: 0.3),
                                      blurRadius: 15,
                                      spreadRadius: 2,
                                    ),
                                  ],
                                ),
                                child: CustomProfileIcon(
                                  icon: _selectedIcon,
                                  borderStyle: _selectedBorderStyle,
                                  size: 120,
                                  backgroundColor: _selectedBackgroundColor,
                                  iconColor: Colors.white,
                                  isPremium: _isPremium,
                                  showPremiumEffects: _isPremium, // Only show premium effects if the icon is premium
                                ),
                              ),
                            ),
                          ),
                          // Premium badge if applicable
                          if (_isPremium)
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.amber.shade600,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.amber.shade200.withValues( alpha: 0.6),
                                      blurRadius: 8,
                                      spreadRadius: 1,
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.star,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Username with Level - Wrapped in RepaintBoundary with animations
                    RepaintBoundary(
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0, 0.2),
                          end: Offset.zero,
                        ).animate(CurvedAnimation(
                          parent: _slideController,
                          curve: const Interval(0.1, 0.6, curve: Curves.easeOutQuart),
                        )),
                        child: FadeTransition(
                          opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
                            CurvedAnimation(
                              parent: _fadeController,
                              curve: const Interval(0.1, 0.6),
                            ),
                          ),
                          child: Column(
                            children: [
                              Text(
                                widget.account.username,
                                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.5,
                                  shadows: [
                                    Shadow(
                                      color: _selectedBackgroundColor.withValues( alpha: 0.3),
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
                                      color: Colors.amber.shade200.withValues( alpha: 0.5),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Text(
                                  'Level ${widget.account.userLevel.level}',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.amber.shade800,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                widget.account.email,
                                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                  color: Colors.grey.shade600,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Level Progress Bar with more details - Wrapped in RepaintBoundary with animations
                    RepaintBoundary(
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0, 0.3),
                          end: Offset.zero,
                        ).animate(CurvedAnimation(
                          parent: _slideController,
                          curve: const Interval(0.3, 0.8, curve: Curves.easeOutQuart),
                        )),
                        child: FadeTransition(
                          opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
                            CurvedAnimation(
                              parent: _fadeController,
                              curve: const Interval(0.3, 0.8),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(left: 4, bottom: 8),
                                child: Text(
                                  'Experience Progress',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey.shade700,
                                  ),
                                ),
                              ),
                              Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.amber.shade200.withValues( alpha: 0.3),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: LevelProgressBar(
                                  userLevel: widget.account.userLevel,
                                  progressColor: Colors.amber.shade500,
                                  backgroundColor: Colors.amber.shade100,
                                  height: 18,
                                  showPercentage: false,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Edit Credentials button with animation
                    SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0, 0.4),
                        end: Offset.zero,
                      ).animate(CurvedAnimation(
                        parent: _slideController,
                        curve: const Interval(0.5, 1.0, curve: Curves.easeOutQuart),
                      )),
                      child: FadeTransition(
                        opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
                          CurvedAnimation(
                            parent: _fadeController,
                            curve: const Interval(0.5, 1.0),
                          ),
                        ),
                        child: Container(
                          width: double.infinity,
                          margin: const EdgeInsets.symmetric(horizontal: 8),
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const EditCredentialsScreen(),
                                ),
                              );
                            },
                            icon: const Icon(Icons.edit, color: Colors.white),
                            label: const Text(
                              'Edit Credentials',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                                letterSpacing: 0.5,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                              backgroundColor: _selectedBackgroundColor,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 4,
                              shadowColor: _selectedBackgroundColor.withValues( alpha: 0.5),
                            ),
                          ),
                        ),
                      ),
                    ),
                    
                    // Add a small reset tutorial button with animation
                    const SizedBox(height: 16),
                    SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0, 0.5),
                        end: Offset.zero,
                      ).animate(CurvedAnimation(
                        parent: _slideController,
                        curve: const Interval(0.7, 1.0, curve: Curves.easeOutQuart),
                      )),
                      child: FadeTransition(
                        opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
                          CurvedAnimation(
                            parent: _fadeController,
                            curve: const Interval(0.7, 1.0),
                          ),
                        ),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.shade300.withValues( alpha: 0.5),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: TextButton.icon(
                            onPressed: _resetTutorial,
                            icon: Icon(Icons.refresh, size: 16, color: Colors.grey.shade700),
                            label: Text(
                              'Reset Tutorial',
                              style: TextStyle(fontSize: 13, color: Colors.grey.shade700, fontWeight: FontWeight.w500),
                            ),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              minimumSize: const Size(0, 36),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    ),
    );
  }
}


