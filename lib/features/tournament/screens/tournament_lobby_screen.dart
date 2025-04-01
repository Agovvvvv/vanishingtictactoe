import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:vanishingtictactoe/core/constants/app_colors.dart';
import 'package:vanishingtictactoe/core/utils/app_logger.dart';
import 'package:vanishingtictactoe/features/game/widgets/shared/hell_pattern_painter_widget.dart';
import 'package:vanishingtictactoe/features/tournament/providers/tournament_provider.dart';
import 'package:vanishingtictactoe/features/tournament/screens/tournament_draw_screen.dart';
import 'package:vanishingtictactoe/features/tournament/widgets/lobby/lobby_content_widget.dart';
import 'package:vanishingtictactoe/shared/providers/hell_mode_provider.dart';
import 'package:vanishingtictactoe/shared/widgets/app_button.dart';
import 'package:vanishingtictactoe/shared/widgets/app_scaffold.dart';

class TournamentLobbyScreen extends StatefulWidget {
  static const routeName = '/tournament-lobby';
  final String tournamentId;

  const TournamentLobbyScreen({
    super.key,
    required this.tournamentId,
  });

  @override
  State<TournamentLobbyScreen> createState() => _TournamentLobbyScreenState();
}

class _TournamentLobbyScreenState extends State<TournamentLobbyScreen> {
  bool _isStartingTournament = false;
  bool _isLeavingTournament = false;
  
  // Synchronous wrappers for async functions
  void _handleStartTournament() {
    _startTournament();
  }
  
  void _handleLeaveTournament() {
    _leaveTournament();
  }

  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadTournament();
      // Set up a timer to periodically check tournament status
      _refreshTimer = Timer.periodic(const Duration(seconds: 3), (_) {
        if (mounted) {
          _checkTournamentStatus();
        }
      });
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _checkTournamentStatus() async {
    try {
      final provider = context.read<TournamentProvider>();
      await provider.loadTournament(widget.tournamentId);
      
      // Check if tournament has started and navigate if needed
      if (provider.tournament != null && provider.tournament!.status == 'in_progress') {
        _refreshTimer?.cancel(); // Stop checking once we're navigating
        if (mounted) {
          Navigator.pushReplacementNamed(
            context,
            TournamentDrawScreen.routeName,
            arguments: widget.tournamentId,
          );
        }
      }
    } catch (e) {
      // Silent error handling for background checks
      AppLogger.error('Error checking tournament status: $e');
    }
  }

  @override
  void didUpdateWidget(TournamentLobbyScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    final provider = context.read<TournamentProvider>();
    
    // Check if tournament has started and navigate if needed
    if (provider.tournament != null && provider.tournament!.status == 'in_progress') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacementNamed(
          context,
          TournamentDrawScreen.routeName,
          arguments: widget.tournamentId,
        );
      });
    }
  }

  Future<void> _loadTournament() async {
    try {
      await context.read<TournamentProvider>().loadTournament(widget.tournamentId);
    } catch (e) {
      AppLogger.error('Error loading tournament: $e');
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load tournament: ${e.toString()}')),
      );
      
      // Navigate back if we can't load the tournament
      Navigator.pop(context);
    }
  }

  Future<void> _startTournament() async {
    if (_isStartingTournament) return;

    setState(() {
      _isStartingTournament = true;
    });

    try {
      await context.read<TournamentProvider>().startTournament();
      
      if (!mounted) return;
      
      // Navigate to tournament draw screen
      Navigator.pushReplacementNamed(
        context,
        TournamentDrawScreen.routeName,
        arguments: widget.tournamentId,
      );
    } catch (e) {
      AppLogger.error('Error starting tournament: $e');
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to start tournament: ${e.toString()}')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isStartingTournament = false;
        });
      }
    }
  }

  Future<void> _leaveTournament() async {
    if (_isLeavingTournament) return;

    setState(() {
      _isLeavingTournament = true;
    });

    try {
      await context.read<TournamentProvider>().leaveTournament();
      
      if (!mounted) return;
      
      // Navigate back
      Navigator.pop(context);
    } catch (e) {
      AppLogger.error('Error leaving tournament: $e');
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to leave tournament: ${e.toString()}')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLeavingTournament = false;
        });
      }
    }
  }



  @override
  Widget build(BuildContext context) {
    final hellModeProvider = Provider.of<HellModeProvider>(context);
    final isHellMode = hellModeProvider.isHellModeActive;
    final primaryColor = isHellMode ? Colors.red.shade800 : AppColors.primaryBlue;
    
    return AppScaffold(
      title: 'Tournament Lobby',
      body: Stack(
        children: [
          // Background pattern for hell mode
          if (isHellMode)
            Positioned.fill(
              child: Opacity(
                opacity: 0.05,
                child: CustomPaint(
                  painter: HellPatternPainter(),
                ),
              ),
            ),
          
          // Main content
          Consumer<TournamentProvider>(
            builder: (context, provider, child) {
              if (provider.isLoading) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 50,
                        height: 50,
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                          strokeWidth: 3,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Loading tournament...',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey.shade700,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                );
              }
              
              if (provider.tournament == null) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline_rounded,
                        size: 64,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Tournament not found',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'The tournament may have been deleted or expired',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey.shade600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 32),
                      AppButton(
                        text: 'Go Back',
                        icon: Icons.arrow_back_rounded,
                        onPressed: () => Navigator.pop(context),
                        customColor: primaryColor,
                        isOutlined: true,
                      ),
                    ],
                  ),
                );
              }
              
              return LobbyContentWidget(
                provider: provider, 
                primaryColor: primaryColor,
                isStartingTournament: _isStartingTournament,
                isLeavingTournament: _isLeavingTournament,
                onStartTournament: _handleStartTournament,
                onLeaveTournament: _handleLeaveTournament
              );
            },
          ),
        ],
      ),
    );
  }
}
