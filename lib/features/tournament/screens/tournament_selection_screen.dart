import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vanishingtictactoe/core/constants/app_colors.dart';
import 'package:vanishingtictactoe/core/utils/app_logger.dart';
import 'package:vanishingtictactoe/features/tournament/providers/tournament_provider.dart';
import 'package:vanishingtictactoe/features/tournament/screens/tournament_bracket_screen.dart';
import 'package:vanishingtictactoe/features/tournament/screens/tournament_lobby_screen.dart';
import 'package:vanishingtictactoe/features/tournament/widgets/active_tournaments_widget.dart';
import 'package:vanishingtictactoe/features/tournament/widgets/selection/tournament_card_widget.dart';
import 'package:vanishingtictactoe/shared/providers/hell_mode_provider.dart';
import 'package:vanishingtictactoe/shared/providers/user_provider.dart';
import 'package:vanishingtictactoe/shared/widgets/app_button.dart';
import 'package:vanishingtictactoe/shared/widgets/app_scaffold.dart';
import 'package:vanishingtictactoe/shared/widgets/app_text_field.dart';
import 'package:vanishingtictactoe/shared/widgets/loading_indicator.dart';

class TournamentSelectionScreen extends StatefulWidget {
  static const routeName = '/tournament-selection';

  const TournamentSelectionScreen({super.key});

  @override
  State<TournamentSelectionScreen> createState() => _TournamentSelectionScreenState();
}

// Hell mode background pattern painter
class TournamentPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.red.shade900.withValues(alpha: 0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    
    final double spacing = 40;
    
    // Draw diagonal lines
    for (double i = -size.height; i <= size.width + size.height; i += spacing) {
      canvas.drawLine(
        Offset(i, 0),
        Offset(i + size.height, size.height),
        paint,
      );
    }
    
    // Draw flame symbols at intersections
    final flamePaint = Paint()
      ..color = Colors.red.shade800.withValues(alpha: 0.1)
      ..style = PaintingStyle.fill;
    
    for (double x = 0; x <= size.width; x += spacing * 2) {
      for (double y = 0; y <= size.height; y += spacing * 2) {
        final path = Path();
        path.moveTo(x, y - 5);
        path.quadraticBezierTo(x + 3, y - 8, x + 6, y - 5);
        path.quadraticBezierTo(x + 9, y - 8, x + 12, y - 5);
        path.quadraticBezierTo(x + 6, y + 5, x, y - 5);
        canvas.drawPath(path, flamePaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _TournamentSelectionScreenState extends State<TournamentSelectionScreen> {
  final TextEditingController _codeController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;
  List<Map<String, dynamic>> _myTournaments = [];

  @override
  void initState() {
    super.initState();
    // Use post-frame callback to avoid calling setState during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadMyTournaments();
    });
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _loadMyTournaments() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final user = context.read<UserProvider>().user;
      if (user == null) {
        setState(() {
          _errorMessage = 'You must be logged in to view tournaments';
          _isLoading = false;
        });
        return;
      }

      final provider = context.read<TournamentProvider>();
      final tournaments = await provider.getMyTournaments();
      
      AppLogger.info('Loaded ${tournaments.length} tournaments');
      for (var tournament in tournaments) {
        AppLogger.info('Tournament: ${tournament['id']}, Status: ${tournament['status']}, Players: ${tournament['players']?.length}');
      }
      
      setState(() {
        _myTournaments = tournaments;
        _isLoading = false;
      });
    } catch (e) {
      AppLogger.error('Error loading tournaments: $e');
      setState(() {
        _errorMessage = 'Failed to load tournaments: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Future<void> _joinTournament() async {
    final code = _codeController.text.trim();
    if (code.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a tournament code')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final provider = context.read<TournamentProvider>();
      final tournamentId = await provider.joinTournamentByCode(code);
      
      if (!mounted) return;
      
      setState(() {
        _isLoading = false;
      });
      
      if (tournamentId != null) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => TournamentLobbyScreen(tournamentId: tournamentId),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tournament not found or you are already a participant')),
        );
      }
    } catch (e) {
      AppLogger.error('Error joining tournament: $e');
      if (!mounted) return;
      
      setState(() {
        _errorMessage = 'Failed to join tournament: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Future<void> _createTournament() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final provider = context.read<TournamentProvider>();
      final tournamentId = await provider.createTournament();
      
      if (!mounted) return;
      
      setState(() {
        _isLoading = false;
      });
      
      if (tournamentId != null) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => TournamentLobbyScreen(tournamentId: tournamentId),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to create tournament')),
        );
      }
    } catch (e) {
      AppLogger.error('Error creating tournament: $e');
      if (!mounted) return;
      
      setState(() {
        _errorMessage = 'Failed to create tournament: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  void _navigateToTournament(String tournamentId) {
    // Find the tournament status to determine which screen to show
    final tournament = _myTournaments.firstWhere(
      (t) => t['id'] == tournamentId,
      orElse: () => {'status': 'waiting'},
    );
    
    final status = tournament['status'] as String? ?? 'waiting';
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => status == 'waiting'
            ? TournamentLobbyScreen(tournamentId: tournamentId)
            : TournamentBracketScreen(tournamentId: tournamentId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hellModeProvider = Provider.of<HellModeProvider>(context);
    final isHellMode = hellModeProvider.isHellModeActive;
    final primaryColor = AppColors.getPrimaryColor(isHellMode);
    
    return AppScaffold(
      title: 'Tournaments',
      body: Stack(
        children: [
          // Background pattern for hell mode
          if (isHellMode)
            Positioned.fill(
              child: CustomPaint(
                painter: TournamentPatternPainter(),
              ),
            ),
          
          // Main content
          _isLoading
              ? const Center(child: LoadingIndicator())
              : _errorMessage != null
                  ? Center(
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.red.shade200),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.error_outline, color: Colors.red.shade700, size: 48),
                            const SizedBox(height: 16),
                            Text(
                              _errorMessage!,
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.red.shade700, fontSize: 16),
                            ),
                            const SizedBox(height: 16),
                            AppButton(
                              text: 'Try Again',
                              icon: Icons.refresh,
                              onPressed: _loadMyTournaments,
                              customColor: Colors.red.shade700,
                            ),
                          ],
                        ),
                      ),
                    )
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Header with animation
                          TweenAnimationBuilder<double>(
                            tween: Tween<double>(begin: 0.0, end: 1.0),
                            duration: const Duration(milliseconds: 800),
                            curve: Curves.easeOutQuart,
                            builder: (context, value, child) {
                              return Opacity(
                                opacity: value,
                                child: Transform.translate(
                                  offset: Offset(0, 20 * (1 - value)),
                                  child: Container(
                                    margin: const EdgeInsets.only(bottom: 24),
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: [
                                          primaryColor.withValues(alpha: 0.7),
                                          primaryColor,
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(20),
                                      boxShadow: [
                                        BoxShadow(
                                          color: primaryColor.withValues(alpha: 0.3),
                                          blurRadius: 10,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: Colors.white.withValues(alpha: 0.2),
                                            shape: BoxShape.circle,
                                          ),
                                          child: Icon(
                                            isHellMode ? Icons.local_fire_department_rounded : Icons.emoji_events_rounded,
                                            color: Colors.white,
                                            size: 32,
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                isHellMode ? 'HELL TOURNAMENTS' : 'TOURNAMENTS',
                                                style: const TextStyle(
                                                  fontSize: 24,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.white,
                                                  letterSpacing: 1.0,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                'Compete with friends in exciting matches',
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  color: Colors.white.withValues(alpha: 0.9),
                                                  letterSpacing: 0.5,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                          
                          // Join Tournament Section
                          TweenAnimationBuilder<double>(
                            tween: Tween<double>(begin: 0.0, end: 1.0),
                            duration: const Duration(milliseconds: 800),
                            curve: Curves.easeOutQuart,
                            builder: (context, value, child) {
                              return Opacity(
                                opacity: value,
                                child: Transform.translate(
                                  offset: Offset(0, 30 * (1 - value)),
                                  child: child!,
                                ),
                              );
                            },
                            child: Card(
                              elevation: 8,
                              shadowColor: primaryColor.withValues(alpha: 0.3),
                              margin: const EdgeInsets.only(bottom: 24),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(20),
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      Colors.white,
                                      isHellMode ? Colors.red.shade50 : Colors.blue.shade50,
                                    ],
                                  ),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(24),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Section header
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.login_rounded, 
                                            color: primaryColor,
                                            size: 24
                                          ),
                                          const SizedBox(width: 10),
                                          Text(
                                            'Tournament Code',
                                            style: TextStyle(
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.grey.shade800,
                                              letterSpacing: 0.5,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 24),
                                      
                                      // Code input with animation
                                      TweenAnimationBuilder<double>(
                                        tween: Tween<double>(begin: 0.95, end: 1.0),
                                        duration: const Duration(milliseconds: 1000),
                                        curve: Curves.elasticOut,
                                        builder: (context, value, child) {
                                          return Transform.scale(
                                            scale: value,
                                            child: AppTextField(
                                              controller: _codeController,
                                              label: 'Tournament Code',
                                              hintText: 'Enter tournament code',
                                              prefixIcon: Icon(
                                                Icons.code_rounded,
                                                color: primaryColor,
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                      const SizedBox(height: 20),
                                      
                                      // Join button with animation
                                      TweenAnimationBuilder<double>(
                                        tween: Tween<double>(begin: 0.95, end: 1.0),
                                        duration: const Duration(milliseconds: 1000),
                                        curve: Curves.elasticOut,
                                        builder: (context, value, child) {
                                          return Transform.scale(
                                            scale: value,
                                            child: AppButton(
                                              onPressed: _joinTournament,
                                              text: isHellMode ? 'JOIN HELL TOURNAMENT' : 'JOIN TOURNAMENT',
                                              icon: Icons.login_rounded,
                                              isFullWidth: true,
                                              customColor: primaryColor,
                                            ),
                                          );
                                        },
                                      ),
                                      const SizedBox(height: 16),
                                      
                                      // Hint text
                                      Center(
                                        child: Text(
                                          'Enter a code shared by a friend to join their tournament',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontStyle: FontStyle.italic,
                                            color: Colors.grey.shade600,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                      
                      // Create Tournament Button
                      Card(
                        elevation: 4,
                        margin: const EdgeInsets.only(bottom: 24),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Create New Tournament',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'Start a new tournament and invite friends to join using the tournament code.',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                ),
                              ),
                              const SizedBox(height: 16),
                              AppButton(
                                onPressed: _createTournament,
                                text: 'Create Tournament',
                                icon: Icons.add,
                                isFullWidth: true,
                              ),
                              const SizedBox(height: 8),
                            ],
                          ),
                        ),
                      ),
                      
                      // Active Tournaments Widget
                      if (_myTournaments.isNotEmpty) ...[  
                        ActiveTournamentsWidget(
                          tournaments: _myTournaments,
                          onRefresh: _loadMyTournaments,
                        ),
                      ],
                      
                      const SizedBox(height: 24),
                      
                      // Completed Tournaments Section
                      if (_myTournaments.where((t) => t['status'] == 'completed').isNotEmpty) ...[
                        const Padding(
                          padding: EdgeInsets.only(bottom: 16),
                          child: Text(
                            'Completed Tournaments',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        ..._myTournaments
                            .where((t) => t['status'] == 'completed')
                            .map((tournament) => TournamentCardWidget(
                                                  tournament: tournament,
                                                  onNavigateToTournament: _navigateToTournament,)),
                      ],
                      
                      if (_myTournaments.isEmpty)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.all(24),
                            child: Text(
                              'You have no tournaments',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
    ],
    ),
    );
  }

  
}
