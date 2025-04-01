import 'dart:async' show Timer;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:vanishingtictactoe/shared/providers/user_provider.dart';
import 'package:vanishingtictactoe/features/online/services/matchmaking_service.dart';
import 'package:vanishingtictactoe/core/utils/app_logger.dart';
import 'match_found_screen.dart';

class MatchmakingScreen extends StatefulWidget {
  final bool isHellMode;

  const MatchmakingScreen({
    super.key,
    this.isHellMode = false,
  });

  @override
  State<MatchmakingScreen> createState() => _MatchmakingScreenState();
}

class _MatchmakingScreenState extends State<MatchmakingScreen> with TickerProviderStateMixin {
  bool _isSearching = true;
  String? _matchId;
  String? _errorMessage;
  String _statusMessage = 'Initializing matchmaking...';
  final MatchmakingService _matchmakingService = MatchmakingService();
  bool _isCancelling = false;
  int _searchTimeSeconds = 0;
  Timer? _searchTimer;
  
  // Animation controllers
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _pulseController;
  late AnimationController _rotateController;

  @override
  void initState() {
    super.initState();
    
    // Initialize animation controllers
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    
    _rotateController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat();
    
    // Start animations
    _fadeController.forward();
    _slideController.forward();
    
    // Use Future.microtask to ensure the context is available
    Future.microtask(() => _startMatchmaking());
  }

  @override
  void dispose() {
    // If we found a match but are leaving the screen, clean up
    // Use a synchronous flag to prevent setState calls after dispose
    _isCancelling = true;
    _cancelMatchmaking();
    _searchTimer?.cancel();
    
    // Dispose animation controllers
    _fadeController.dispose();
    _slideController.dispose();
    _pulseController.dispose();
    _rotateController.dispose();
    
    super.dispose();
  }

  Future<void> _cancelMatchmaking() async {
    if (_isCancelling) return;
    
    // Only call setState if the widget is still mounted
    if (mounted) {
      setState(() {
        _isCancelling = true;
      });
    } else {
      // Just set the flag without setState if we're already disposed
      _isCancelling = true;
    }
    
    try {
      // First cancel any active matchmaking
      await _matchmakingService.cancelMatchmaking();
      
      // Then leave the match if we have one
      if (_matchId != null) {
        await _matchmakingService.leaveMatch(_matchId!);
      }
    } catch (e) {
      AppLogger.error('Error cancelling matchmaking: $e');
    }
  }

  Future<void> _startMatchmaking() async {
    // Get the user provider safely
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    
    if (userProvider.user == null) {
      if (mounted) {
        setState(() {
          _isSearching = false;
          _errorMessage = 'You must be logged in to play online';
        });
      }
      return;
    }

    try {
      if (mounted) {
        setState(() {
          _isSearching = true;
          _errorMessage = null;
          _statusMessage = 'Initializing matchmaking...';
          _searchTimeSeconds = 0;
        });
      }
      
      // Start a timer to show search time
      _searchTimer?.cancel();
      _searchTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (mounted && _isSearching && !_isCancelling) {
          setState(() {
            _searchTimeSeconds++;
            
            // Update status message based on search time
            if (_searchTimeSeconds < 10) {
              _statusMessage = 'Looking for opponents...';
            } else if (_searchTimeSeconds < 30) {
              _statusMessage = 'Searching for a suitable match...';
            } else if (_searchTimeSeconds < 60) {
              _statusMessage = 'This is taking longer than usual...';
            } else if (_searchTimeSeconds < 120) {
              _statusMessage = 'Still searching. Please be patient...';
            } else {
              _statusMessage = 'Extended search in progress...';
            }
          });
        }
      });

      // Pass hell mode parameters to the matchmaking service
      final matchId = await _matchmakingService.findMatch(
        isHellMode: widget.isHellMode,
      );
      
      _searchTimer?.cancel();
      
      if (mounted && !_isCancelling) {
        setState(() {
          _isSearching = false;
          _matchId = matchId;
          _statusMessage = 'Match found!';
        });
        
        // Navigate to match found screen with coin flip
        if (mounted && !_isCancelling) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => MatchFoundScreen(
                matchId: matchId,
                isHellMode: widget.isHellMode,
              ),
            ),
          );
        }
      }
    } catch (e) {
      _searchTimer?.cancel();
      
      if (mounted && !_isCancelling) {
        setState(() {
          _isSearching = false;
          _errorMessage = e.toString();
        });
      }
    }
  }

  @override 
  Widget build(BuildContext context) {
    final bool isHellMode = widget.isHellMode;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    // Set system UI overlay style
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: isDarkMode ? Brightness.light : Brightness.dark,
    ));
    
    return PopScope(
      onPopInvokedWithResult: (didPop, result) async {
        await _cancelMatchmaking();
      },
      child: Scaffold(
        backgroundColor: isHellMode ? Colors.grey[50] : Colors.white,
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          title: FadeTransition(
            opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
              CurvedAnimation(
                parent: _fadeController,
                curve: const Interval(0.3, 0.8),
              ),
            ),
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, -0.2),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: _slideController,
                curve: Curves.easeOutQuart,
              )),
              child: Text(
                isHellMode ? 'Hell Mode Match' : 'Finding Opponent',
                style: TextStyle(
                  color: isHellMode ? Colors.red.shade900 : Colors.blue.shade900,
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                  shadows: [
                    Shadow(
                      color: (isHellMode ? Colors.red : Colors.blue).withValues( alpha: 0.2),
                      offset: const Offset(0, 2),
                      blurRadius: 4,
                    ),
                  ],
                ),
              ),
            ),
          ),
          leading: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isHellMode ? Colors.red.shade50 : Colors.blue.shade50,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues( alpha: 0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: IconButton(
              icon: Icon(
                Icons.arrow_back_ios_new_rounded, 
                color: isHellMode ? Colors.red.shade800 : Colors.blue.shade800,
                size: 20,
              ),
              onPressed: () async {
                await _cancelMatchmaking();
                if (mounted && context.mounted) {
                  Navigator.pop(context, true);
                }
              },
            ),
          ),
        ),
        body: Stack(
          children: [
            // Background gradient
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: isHellMode
                    ? [
                        Colors.grey[50]!,
                        Colors.grey[50]!.withValues( alpha: 0.9),
                        Colors.red.shade50.withValues( alpha: 0.3),
                      ]
                    : [
                        Colors.white,
                        Colors.white.withValues( alpha: 0.9),
                        Colors.blue.shade50.withValues( alpha: 0.3),
                      ],
                ),
              ),
            ),
            
            // Main content
            SafeArea(
              child: Center(
                child: _isSearching
                  ? _buildSearchingWidget()
                  : _errorMessage != null
                      ? _buildErrorWidget()
                      : const CircularProgressIndicator(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchingWidget() {
    final bool isHellMode = widget.isHellMode;
    final Color primaryColor = isHellMode ? Colors.red.shade700 : Colors.blue.shade700;
    
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0, 0.1),
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
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Custom animated waiting indicator
              AnimatedBuilder(
                animation: _rotateController,
                builder: (context, child) {
                  return Transform.rotate(
                    angle: _rotateController.value * 2 * 3.14159,
                    child: child,
                  );
                },
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: SweepGradient(
                      colors: isHellMode 
                        ? [Colors.red.shade300, Colors.red.shade700, Colors.deepOrange.shade900, Colors.red.shade300]
                        : [Colors.blue.shade300, Colors.blue.shade700, Colors.indigo.shade900, Colors.blue.shade300],
                      stops: const [0.0, 0.3, 0.6, 1.0],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: primaryColor.withValues( alpha: 0.3),
                        blurRadius: 15,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: primaryColor.withValues( alpha: 0.2),
                            blurRadius: 10,
                            spreadRadius: -5,
                          ),
                        ],
                      ),
                      child: Center(
                        child: AnimatedBuilder(
                          animation: _pulseController,
                          builder: (context, child) {
                            return Transform.scale(
                              scale: 0.8 + (_pulseController.value * 0.2),
                              child: Icon(
                                isHellMode ? Icons.local_fire_department_rounded : Icons.search_rounded,
                                size: 50,
                                color: primaryColor,
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 30),
              
              // Status message with glass effect
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues( alpha: 0.8),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: primaryColor.withValues( alpha: 0.3),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: primaryColor.withValues( alpha: 0.1),
                          blurRadius: 15,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // Animated status message
                        TweenAnimationBuilder<double>(
                          tween: Tween<double>(begin: 0.9, end: 1.0),
                          duration: const Duration(milliseconds: 600),
                          curve: Curves.elasticOut,
                          builder: (context, value, child) {
                            return Transform.scale(
                              scale: value,
                              child: Text(
                                _statusMessage,
                                style: TextStyle(
                                  fontSize: 18,
                                  color: primaryColor,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.5,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 12),
                        
                        // Animated time elapsed
                        AnimatedBuilder(
                          animation: _pulseController,
                          builder: (context, child) {
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    primaryColor.withValues( alpha: 0.1 + (_pulseController.value * 0.05)),
                                    primaryColor.withValues( alpha: 0.2 + (_pulseController.value * 0.05)),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: primaryColor.withValues( alpha: 0.1),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Text(
                                'Time elapsed: ${_formatSearchTime(_searchTimeSeconds)}',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: primaryColor,
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 40),
              
              // Hell mode indicator if active
              if (isHellMode) ...[  
                SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.3),
                    end: Offset.zero,
                  ).animate(CurvedAnimation(
                    parent: _slideController,
                    curve: const Interval(0.3, 0.8, curve: Curves.easeOutQuart),
                  )),
                  child: AnimatedBuilder(
                    animation: _pulseController,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: 0.95 + (_pulseController.value * 0.05),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Colors.red.shade800, Colors.deepOrange.shade700],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.red.withValues( alpha: 0.4),
                                blurRadius: 12,
                                offset: const Offset(0, 6),
                                spreadRadius: 0,
                              ),
                            ],
                            border: Border.all(
                              color: Colors.red.shade300,
                              width: 2,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              TweenAnimationBuilder<double>(
                                tween: Tween<double>(begin: 0.8, end: 1.2),
                                duration: const Duration(milliseconds: 600),
                                curve: Curves.easeInOut,
                                builder: (context, iconScale, _) {
                                  return Transform.scale(
                                    scale: iconScale,
                                    child: const Icon(
                                      Icons.local_fire_department_rounded, 
                                      color: Colors.yellow,
                                      size: 28,
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(width: 12),
                              const Text(
                                'HELL MODE ACTIVE',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.5,
                                  shadows: [
                                    Shadow(
                                      color: Colors.black26,
                                      blurRadius: 4,
                                      offset: Offset(0, 2),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 40),
              ],
              
              // Cancel button with animated effects
              SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.5),
                  end: Offset.zero,
                ).animate(CurvedAnimation(
                  parent: _slideController,
                  curve: const Interval(0.4, 1.0, curve: Curves.easeOutQuart),
                )),
                child: Container(
                  width: 220,
                  height: 56,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: (isHellMode ? Colors.red : Colors.red.shade400).withValues( alpha: 0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                        spreadRadius: 0,
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: () async {
                      await _cancelMatchmaking();
                      if (mounted && context.mounted) {
                        Navigator.pop(context);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isHellMode ? Colors.red.shade800 : Colors.red.shade400,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.cancel_rounded, size: 24, color: Colors.white,),
                        const SizedBox(width: 12),
                        const Text(
                          'CANCEL SEARCH',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
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
    );
  }

  Widget _buildErrorWidget() {
    final bool isHellMode = widget.isHellMode;
    final Color primaryColor = isHellMode ? Colors.red.shade700 : Colors.blue.shade700;
    final Color secondaryColor = isHellMode ? Colors.deepOrange.shade700 : Colors.blue.shade900;
    
    // Format error message for better readability
    String formattedError = _errorMessage?.replaceAll('Exception: ', '') ?? 'Unknown error';
    String errorTitle = 'Error Finding Match';
    String errorSuggestion = '';
    IconData errorIcon = Icons.error_outline_rounded;
    
    // Provide more specific error messages and suggestions
    if (formattedError.contains('Matchmaking timeout')) {
      errorTitle = 'No Opponents Found';
      formattedError = 'We couldn\'t find an opponent for you at this time.';
      errorSuggestion = 'Try again later when more players are online.';
      errorIcon = Icons.people_outline_rounded;
    } else if (formattedError.contains('permission-denied')) {
      errorTitle = 'Connection Issue';
      formattedError = 'There was a problem connecting to the game server.';
      errorSuggestion = 'Please check your internet connection and try again.';
      errorIcon = Icons.wifi_off_rounded;
    }
    
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0, 0.1),
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
        child: Container(
          margin: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: primaryColor.withValues( alpha: 0.15),
                blurRadius: 20,
                spreadRadius: 0,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: Colors.white.withValues( alpha: 0.9),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: primaryColor.withValues( alpha: 0.3),
                    width: 2,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Animated error icon
                    TweenAnimationBuilder<double>(
                      tween: Tween<double>(begin: 0.8, end: 1.0),
                      duration: const Duration(milliseconds: 800),
                      curve: Curves.elasticOut,
                      builder: (context, value, child) {
                        return Transform.scale(
                          scale: value,
                          child: Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  primaryColor.withValues( alpha: 0.2),
                                  secondaryColor.withValues( alpha: 0.1),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: primaryColor.withValues( alpha: 0.3),
                                width: 2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: primaryColor.withValues( alpha: 0.2),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Icon(
                              errorIcon,
                              size: 60,
                              color: primaryColor,
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 24),
                    
                    // Error title with animation
                    TweenAnimationBuilder<double>(
                      tween: Tween<double>(begin: 0.9, end: 1.0),
                      duration: const Duration(milliseconds: 600),
                      curve: Curves.easeOut,
                      builder: (context, value, child) {
                        return Transform.scale(
                          scale: value,
                          child: Text(
                            errorTitle,
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: primaryColor,
                              letterSpacing: 0.5,
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    // Error message
                    Text(
                      formattedError,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
                        height: 1.5,
                        color: secondaryColor.withValues( alpha: 0.8),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    
                    // Error suggestion if available
                    if (errorSuggestion.isNotEmpty) ...[  
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: primaryColor.withValues( alpha: 0.1),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: primaryColor.withValues( alpha: 0.2),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          errorSuggestion,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            fontStyle: FontStyle.italic,
                            color: secondaryColor.withValues( alpha: 0.7),
                          ),
                        ),
                      ),
                    ],
                    
                    const SizedBox(height: 32),
                    
                    // Action buttons
                    LayoutBuilder(
                      builder: (context, constraints) {
                        // Check if we need to use a column layout for small screens
                        final bool useColumnLayout = constraints.maxWidth < 320;
                        
                        return useColumnLayout
                          ? Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _buildTryAgainButton(primaryColor),
                                const SizedBox(height: 16),
                                _buildGoBackButton(primaryColor, secondaryColor),
                              ],
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min, // Use min to prevent overflow
                              children: [
                                _buildTryAgainButton(primaryColor),
                                const SizedBox(width: 16), // Reduced spacing
                                _buildGoBackButton(primaryColor, secondaryColor),
                              ],
                            );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
  
  // Helper method to format search time
  String _formatSearchTime(int seconds) {
    final int minutes = seconds ~/ 60;
    final int remainingSeconds = seconds % 60;
    if (minutes == 0) {
      return '${seconds}s';
    } else {
      return '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';
    }
  }
  
  // Helper method to build the Try Again button
  Widget _buildTryAgainButton(Color primaryColor) {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withValues( alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
            spreadRadius: 0,
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _startMatchmaking,
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16), // Reduced padding
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.refresh_rounded, size: 20), // Slightly smaller icon
            SizedBox(width: 8), // Reduced spacing
            Text(
              'Try Again',
              style: TextStyle(
                fontSize: 15, // Slightly smaller font
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  // Helper method to build the Go Back button
  Widget _buildGoBackButton(Color primaryColor, Color secondaryColor) {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues( alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
            spreadRadius: 0,
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: () {
          Navigator.pop(context);
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: secondaryColor,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16), // Reduced padding
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
            side: BorderSide(
              color: primaryColor.withValues( alpha: 0.3),
              width: 2,
            ),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.arrow_back_rounded, size: 20, color: secondaryColor), // Slightly smaller icon
            const SizedBox(width: 8), // Reduced spacing
            Text(
              'Go Back',
              style: TextStyle(
                fontSize: 15, // Slightly smaller font
                fontWeight: FontWeight.w600,
                color: secondaryColor,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
