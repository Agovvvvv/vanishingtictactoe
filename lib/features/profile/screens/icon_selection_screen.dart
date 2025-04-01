import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:math' as math;
import 'package:vanishingtictactoe/shared/widgets/custom_icon.dart';
import 'package:vanishingtictactoe/shared/models/unlockable_content.dart';
import 'package:vanishingtictactoe/shared/providers/user_provider.dart';
import 'package:vanishingtictactoe/core/utils/app_logger.dart';
import 'package:vanishingtictactoe/features/profile/widgets/icons_tab.dart';
import 'package:vanishingtictactoe/features/profile/widgets/borders_tab.dart';
import 'package:vanishingtictactoe/features/profile/widgets/background_tab.dart';
import 'package:vanishingtictactoe/features/profile/services/profile_customization_service.dart';

// Custom painter for subtle grid pattern
class _GridPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.blue.shade200.withValues( alpha: 0.1)
      ..strokeWidth = 0.5
      ..style = PaintingStyle.stroke;
    
    // Draw horizontal lines
    for (int i = 0; i < size.height; i += 20) {
      canvas.drawLine(Offset(0, i.toDouble()), Offset(size.width, i.toDouble()), paint);
    }
    
    // Draw vertical lines
    for (int i = 0; i < size.width; i += 20) {
      canvas.drawLine(Offset(i.toDouble(), 0), Offset(i.toDouble(), size.height), paint);
    }
    
    // Draw some decorative circles
    final circlePaint = Paint()
      ..color = Colors.blue.shade200.withValues( alpha: 0.1)
      ..style = PaintingStyle.fill;
      
    final random = math.Random(42); // Fixed seed for consistent pattern
    
    for (int i = 0; i < 20; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;
      final radius = random.nextDouble() * 10 + 5;
      
      canvas.drawCircle(Offset(x, y), radius, circlePaint);
    }
  }

  @override
  bool shouldRepaint(_GridPatternPainter oldDelegate) => false;
}

class IconSelectionScreen extends StatefulWidget {
  final IconData initialIcon;
  final ProfileBorderStyle initialBorderStyle;
  final Color initialBackgroundColor;

  const IconSelectionScreen({
    super.key,
    required this.initialIcon,
    required this.initialBorderStyle,
    this.initialBackgroundColor = Colors.blue,
  });

  @override
  State<IconSelectionScreen> createState() => _IconSelectionScreenState();
}

class _IconSelectionScreenState extends State<IconSelectionScreen> with TickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  late TabController _tabController;
  late IconData _selectedIcon;
  late ProfileBorderStyle _selectedBorderStyle;
  Color _selectedBackgroundColor = Colors.blue;
  bool _hasChanges = false;
  bool _isLoading = true;
  
  // Lists for unlockable content
  List<UnlockableItem> _unlockedIcons = [];
  List<UnlockableItem> _lockedIcons = [];
  List<UnlockableItem> _unlockedBorders = [];
  List<UnlockableItem> _lockedBorders = [];
  List<UnlockableItem> _unlockedBackgrounds = [];
  List<UnlockableItem> _lockedBackgrounds = [];
  int _userLevel = 1; // Default level if not logged in
  String? _currentUserId;
  
  // Reference to the profile customization service
  final _customizationService = ProfileCustomizationService();
  
  // Animation controllers
  late AnimationController _fadeController;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _fadeAnimation;

  @override
  bool get wantKeepAlive => true; // Keep state when navigating away

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _selectedIcon = widget.initialIcon;
    _selectedBorderStyle = widget.initialBorderStyle;
    _selectedBackgroundColor = widget.initialBackgroundColor;
    
    // Initialize animations
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
    
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
    
    // Load data with optimized approach
    _initializeData();
    
    // Start fade in animation
    _fadeController.forward();
  }
  
  Future<void> _initializeData() async {
    setState(() {
      _isLoading = true;
    });
    
    // Load user level and unlockables
    await _loadUserLevelAndUnlockables();
    
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  Future<void> _loadUserLevelAndUnlockables() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final userId = userProvider.user?.id;
    
    // Skip reload if user hasn't changed
    if (_currentUserId == userId && !_isLoading) {
      AppLogger.debug('Skipping reload for same user: $_currentUserId');
      return;
    }
    
    _currentUserId = userId;
    
    if (userId != null) {
      setState(() {
        _userLevel = userProvider.user!.userLevel.level;
      });
      
      AppLogger.debug('Loading unlockables for user level: $_userLevel');
      
      // Load unlockable content based on user level
      await _loadUnlockableContent(_userLevel);
    } else {
      // If not logged in, only show basic items
      setState(() {
        _userLevel = 1;
      });
      
      await _loadUnlockableContent(_userLevel);
    }
  }
  
  Future<void> _savePreferences() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final userId = userProvider.user?.id;
    
    if (userId != null) {
      // Update customization in the service
      await _customizationService.updateCustomization(
        userId,
        icon: _selectedIcon,
        borderStyle: _selectedBorderStyle,
        backgroundColor: _selectedBackgroundColor,
      );
    }
    
    if (mounted) {
      // Show a modern success message with animation
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_outline, color: Colors.white),
              const SizedBox(width: 12),
              const Text(
                'Profile customization saved',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
            ],
          ),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          duration: const Duration(seconds: 2),
          backgroundColor: const Color(0xFF2962FF), // Using kPrimaryBlue
          elevation: 8,
          action: SnackBarAction(
            label: 'DISMISS',
            textColor: Colors.white,
            onPressed: () {
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
            },
          ),
        ),
      );
      
      Navigator.pop(context, {
        'icon': _selectedIcon,
        'borderStyle': _selectedBorderStyle,
        'backgroundColor': _selectedBackgroundColor,
      });
    }
  }
  
  // Separate method to load unlockable content to improve code organization
  Future<void> _loadUnlockableContent(int userLevel) async {
    // Use compute for heavy operations if needed
    final allUnlockables = await Future.microtask(() {
      return {
        'unlockedIcons': UnlockableContent.getUnlockedItems(userLevel, type: UnlockableType.icon),
        'lockedIcons': UnlockableContent.getLockedItems(userLevel, type: UnlockableType.icon),
        'unlockedBorders': UnlockableContent.getUnlockedItems(userLevel, type: UnlockableType.border),
        'lockedBorders': UnlockableContent.getLockedItems(userLevel, type: UnlockableType.border),
        'unlockedBackgrounds': UnlockableContent.getUnlockedItems(userLevel, type: UnlockableType.background),
        'lockedBackgrounds': UnlockableContent.getLockedItems(userLevel, type: UnlockableType.background),
      };
    });
    
    if (mounted) {
      setState(() {
        _unlockedIcons = allUnlockables['unlockedIcons']!;
        _lockedIcons = allUnlockables['lockedIcons']!;
        _unlockedBorders = allUnlockables['unlockedBorders']!;
        _lockedBorders = allUnlockables['lockedBorders']!;
        _unlockedBackgrounds = allUnlockables['unlockedBackgrounds']!;
        _lockedBackgrounds = allUnlockables['lockedBackgrounds']!;
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _fadeController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    
    return PopScope(
      canPop: !_hasChanges,
      onPopInvokedWithResult: (didPop, result) async {
        if (!didPop) {
          final shouldSave = await _showSaveConfirmationDialog();
          if (shouldSave) {
            await _savePreferences();
          } else {
            // Allow pop if user chooses not to save
            if (context.mounted) {
              Navigator.of(context).pop();
            }
          }
        }
      },
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          elevation: 0,
          backgroundColor: Colors.transparent,
          title: const Text(
            'Customize Profile',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 22,
              letterSpacing: 0.5,
            ),
          ),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(110), // Further increased height for more space
            child: Padding(
              padding: const EdgeInsets.only(bottom: 20, left: 12, right: 12, top: 8), // Added padding on all sides
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16), // Adjusted horizontal margin
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28), // Increased border radius
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues( alpha: 0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: TabBar(
                  controller: _tabController,
                  // Changed to underline indicator
                  indicator: UnderlineTabIndicator(
                    borderSide: BorderSide(
                      width: 3.0,
                      color: const Color(0xFF2962FF),
                    ),
                    insets: const EdgeInsets.symmetric(horizontal: 8.0),
                  ),
                  dividerColor: Colors.transparent, // Remove the divider line
                  labelColor: const Color(0xFF2962FF),
                  unselectedLabelColor: Colors.grey[600],
                  labelStyle: const TextStyle(fontWeight: FontWeight.bold),
                  padding: const EdgeInsets.symmetric(vertical: 8), // Added padding
                  isScrollable: false, // Ensure tabs don't scroll
                  labelPadding: const EdgeInsets.symmetric(horizontal: 8.0), // Reduced padding
                  tabs: const [
                    Tab(icon: Icon(Icons.face, size: 20), text: 'Icons'),
                    Tab(icon: Icon(Icons.border_all, size: 20), text: 'Borders'),
                    Tab(icon: Icon(Icons.color_lens, size: 20), text: 'Background'),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            Container(
              margin: const EdgeInsets.only(right: 20), // Increased margin
              child: AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _hasChanges ? _pulseAnimation.value : 1.0,
                    child: ElevatedButton.icon(
                      onPressed: _hasChanges ? _savePreferences : null,
                      icon: Icon(Icons.save_rounded, size: 18, color: _hasChanges ? Colors.white : Colors.grey[600]),
                      label: Text(
                        'Save',
                        style: TextStyle(
                          color: _hasChanges ? Colors.white : Colors.grey[600],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _hasChanges ? const Color(0xFF2962FF) : Colors.grey[300],
                        elevation: _hasChanges ? 4 : 0,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10), // Increased padding
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
        body: Stack(
          children: [
            // Background pattern
            Positioned.fill(
              child: CustomPaint(
                painter: _GridPatternPainter(),
              ),
            ),
            
            // Main content
            SafeArea(
              bottom: false, // Don't add padding at the bottom
              child: _isLoading 
                ? const Center(
                    child: CircularProgressIndicator(),
                  )
                : FadeTransition(
                    opacity: _fadeAnimation,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20), // Increased border radius
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues( alpha: 0.05),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      margin: const EdgeInsets.fromLTRB(20, 24, 20, 24), // Increased margins
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: TabBarView(
                          controller: _tabController,
                          children: [
                            // Icons Tab - Wrap each tab in RepaintBoundary
                            RepaintBoundary(
                              child: Padding(
                                padding: const EdgeInsets.all(8.0), // Added padding
                                child: IconsTab(
                                  selectedIcon: _selectedIcon,
                                  selectedBorderStyle: _selectedBorderStyle,
                                  selectedBackgroundColor: _selectedBackgroundColor,
                                  userLevel: _userLevel,
                                  unlockedIcons: _unlockedIcons,
                                  lockedIcons: _lockedIcons,
                                  onIconSelected: (IconData icon) {
                                    setState(() {
                                      _selectedIcon = icon;
                                      _hasChanges = true;
                                    });
                                  },
                                ),
                              ),
                            ),
                            // Borders Tab
                            RepaintBoundary(
                              child: Padding(
                                padding: const EdgeInsets.all(8.0), // Added padding
                                child: BordersTab(
                                  selectedIcon: _selectedIcon,
                                  selectedBorderStyle: _selectedBorderStyle,
                                  selectedBackgroundColor: _selectedBackgroundColor,
                                  userLevel: _userLevel,
                                  unlockedBorders: _unlockedBorders,
                                  lockedBorders: _lockedBorders,
                                  onBorderSelected: (ProfileBorderStyle style) {
                                    setState(() {
                                      _selectedBorderStyle = style;
                                      _hasChanges = true;
                                    });
                                  },
                                ),
                              ),
                            ),
                            // Background Tab
                            RepaintBoundary(
                              child: Padding(
                                padding: const EdgeInsets.all(8.0), // Added padding
                                child: BackgroundTab(
                                  selectedIcon: _selectedIcon,
                                  selectedBorderStyle: _selectedBorderStyle,
                                  selectedBackgroundColor: _selectedBackgroundColor,
                                  userLevel: _userLevel,
                                  unlockedBackgrounds: _unlockedBackgrounds,
                                  lockedBackgrounds: _lockedBackgrounds,
                                  onBackgroundSelected: (Color color) {
                                    setState(() {
                                      _selectedBackgroundColor = color;
                                      _hasChanges = true;
                                    });
                                  },
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
      ),
    );
  }

  Future<bool> _showSaveConfirmationDialog() async {
    return await showDialog<bool>(
      context: context,
      barrierColor: Colors.black54,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text(
          'Save Changes?',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
        ),
        content: const Text(
          'You have unsaved changes. Would you like to save them before leaving?',
          style: TextStyle(fontSize: 16, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            style: TextButton.styleFrom(
              foregroundColor: Colors.grey[700],
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            child: const Text(
              'Discard',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2962FF),
              foregroundColor: Colors.white,
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text(
              'Save',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
        actionsPadding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
        contentPadding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
        elevation: 24,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
      ),
    ) ?? false; // Default to false if dialog is dismissed
  }
}