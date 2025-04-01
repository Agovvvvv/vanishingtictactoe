import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vanishingtictactoe/core/constants/app_colors.dart';
import 'package:vanishingtictactoe/features/tournament/models/tournament_match.dart';
import 'package:vanishingtictactoe/features/tournament/models/tournament_player.dart';
import 'package:vanishingtictactoe/features/tournament/providers/tournament_provider.dart';
import 'package:vanishingtictactoe/features/tournament/screens/tournament_bracket_screen.dart';
import 'package:vanishingtictactoe/shared/widgets/app_scaffold.dart';
import 'package:vanishingtictactoe/shared/widgets/loading_indicator.dart';

class TournamentDrawScreen extends StatefulWidget {
  static const routeName = '/tournament-draw';
  final String tournamentId;
  final bool isHellMode;

  const TournamentDrawScreen({
    Key? key,
    required this.tournamentId,
    this.isHellMode = false,
  }) : super(key: key);

  @override
  State<TournamentDrawScreen> createState() => _TournamentDrawScreenState();
}

class _TournamentDrawScreenState extends State<TournamentDrawScreen> with TickerProviderStateMixin {
  bool _isDrawComplete = false;
  List<TournamentPlayer> _players = [];
  List<TournamentMatch> _matches = [];
  
  // Animation controllers
  late AnimationController _shuffleController;
  late AnimationController _matchupController;
  late AnimationController _pulseController;
  late AnimationController _scaleController;
  
  // Animations
  late Animation<double> _shuffleAnimation;
  late Animation<double> _matchupAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _scaleAnimation;
  
  // Timer for auto-navigation
  Timer? _navigationTimer;
  
  // Get primary color based on hell mode
  Color get _primaryColor => AppColors.getPrimaryColor(widget.isHellMode);

  @override
  void initState() {
    super.initState();
    
    // Initialize animation controllers
    _shuffleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );
    
    _matchupController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    
    // Initialize animations
    _shuffleAnimation = CurvedAnimation(
      parent: _shuffleController,
      curve: Curves.easeInOut,
    );
    
    _matchupAnimation = CurvedAnimation(
      parent: _matchupController,
      curve: Curves.easeOutBack,
    );
    
    _pulseAnimation = Tween<double>(
      begin: 0.95,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
    
    _scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    ));
    
    // Add listeners
    _shuffleController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _matchupController.forward();
        _scaleController.forward();
      }
    });
    
    _matchupController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() {
          _isDrawComplete = true;
        });
        
        // Auto-navigate after 3 seconds
        _navigationTimer = Timer(const Duration(seconds: 3), () {
          if (mounted) {
            Navigator.pushReplacementNamed(
              context,
              TournamentBracketScreen.routeName,
              arguments: widget.tournamentId,
            );
          }
        });
      }
    });
    
    // Load tournament data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadTournament();
    });
  }

  @override
  void dispose() {
    _shuffleController.dispose();
    _matchupController.dispose();
    _pulseController.dispose();
    _scaleController.dispose();
    _navigationTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadTournament() async {
    try {
      final provider = context.read<TournamentProvider>();
      await provider.loadTournament(widget.tournamentId);
      
      if (!mounted) return;
      
      final tournament = provider.tournament;
      if (tournament == null) {
        Navigator.pop(context);
        return;
      }
      
      setState(() {
        _players = tournament.players;
        _matches = tournament.matches.where((m) => m.round == 1).toList();
      });
      
      // Start animation with a slight delay for better UX
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) {
          _shuffleController.forward();
        }
      });
    } catch (e) {
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load tournament: $e'),
          backgroundColor: widget.isHellMode ? Colors.red.shade700 : AppColors.primaryBlue,
        ),
      );
      
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: widget.isHellMode ? 'Hell Tournament Draw' : 'Tournament Draw',
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: widget.isHellMode
                ? [Colors.white, Colors.red.shade50]
                : [Colors.white, Colors.blue.shade50],
          ),
        ),
        child: Consumer<TournamentProvider>(
          builder: (context, provider, child) {
            if (provider.isLoading) {
              return const Center(child: LoadingIndicator());
            }
            
            if (provider.tournament == null) {
              return Center(child: Text(
                'Tournament not found',
                style: TextStyle(color: _primaryColor),
              ));
            }
            
            return _buildDrawContent(context);
          },
        ),
      ),
    );
  }

  Widget _buildDrawContent(BuildContext context) {
    return SingleChildScrollView(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minHeight: MediaQuery.of(context).size.height - 100, // Subtract app bar height
        ),
        child: Column(
          children: [
            const SizedBox(height: 24),
            _buildHeader(),
            const SizedBox(height: 40),
            _isDrawComplete
                ? _buildMatchups()
                : _buildShufflingPlayers(),
            const SizedBox(height: 60), // Increased spacing before footer
            _buildFooter(),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        AnimatedBuilder(
          animation: _pulseAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _pulseAnimation.value,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _primaryColor.withValues(alpha: 0.1),
                  boxShadow: [
                    BoxShadow(
                      color: _primaryColor.withValues(alpha: 0.2),
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Icon(
                  widget.isHellMode ? Icons.local_fire_department : Icons.shuffle,
                  size: 60,
                  color: _primaryColor,
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            gradient: LinearGradient(
              colors: widget.isHellMode
                  ? [Colors.red.shade700, Colors.red.shade900]
                  : [AppColors.primaryBlue, AppColors.primaryBlue.withValues(alpha: 0.7)],
            ),
            boxShadow: [
              BoxShadow(
                color: _primaryColor.withValues(alpha: 0.4),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Text(
            _isDrawComplete ? 'Tournament Draw Complete!' : 'Drawing Tournament Matchups...',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }

  Widget _buildShufflingPlayers() {
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.5,
      child: AnimatedBuilder(
        animation: _shuffleAnimation,
        builder: (context, child) {
          return Center(
            child: Wrap(
              spacing: 24,
              runSpacing: 24,
              alignment: WrapAlignment.center,
              children: List.generate(_players.length, (index) {
                // Calculate position and rotation for shuffling effect
                final offsetX = sin((_shuffleAnimation.value * 12) + index) * 120 * (1 - _shuffleAnimation.value);
                final offsetY = cos((_shuffleAnimation.value * 12) + index) * 120 * (1 - _shuffleAnimation.value);
                final rotation = sin((_shuffleAnimation.value * 8) + index) * pi * (1 - _shuffleAnimation.value);
                
                return Transform(
                  transform: Matrix4.identity()
                    ..translate(offsetX, offsetY)
                    ..rotateZ(rotation),
                  alignment: Alignment.center,
                  child: _buildPlayerCard(_players[index]),
                );
              }),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMatchups() {
    if (_matches.length < 2) {
      return SizedBox(
        height: 200,
        child: Center(child: Text(
          'Waiting for matchups...',
          style: TextStyle(color: _primaryColor, fontWeight: FontWeight.bold),
        )),
      );
    }
    
    return AnimatedBuilder(
      animation: _matchupAnimation,
      builder: (context, child) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedBuilder(
              animation: _scaleAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _scaleAnimation.value,
                  child: _buildMatchupItem(_matches[0], 0),
                );
              },
            ),
            const SizedBox(height: 40),
            AnimatedBuilder(
              animation: _scaleAnimation,
              builder: (context, child) {
                // Slightly delayed animation for second matchup
                final delayedScale = _scaleAnimation.value > 0.3 
                    ? (_scaleAnimation.value - 0.3) / 0.7 
                    : 0.0;
                return Transform.scale(
                  scale: delayedScale,
                  child: _buildMatchupItem(_matches[1], 1),
                );
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildMatchupItem(TournamentMatch match, int index) {
    final player1 = _players.firstWhere((p) => p.id == match.player1Id, orElse: () => TournamentPlayer(id: '', name: 'Unknown', seed: 0));
    final player2 = _players.firstWhere((p) => p.id == match.player2Id, orElse: () => TournamentPlayer(id: '', name: 'Unknown', seed: 0));
    
    // Delay second matchup animation slightly
    final animationValue = index == 0 
        ? _matchupAnimation.value 
        : _matchupAnimation.value > 0.3 ? (_matchupAnimation.value - 0.3) / 0.7 : 0.0;
    
    return Opacity(
      opacity: animationValue,
      child: Transform.scale(
        scale: 0.8 + (0.2 * animationValue),
        child: Container(
          width: MediaQuery.of(context).size.width * 0.85, // Limit width to 85% of screen
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: widget.isHellMode
                  ? [Colors.white, Colors.red.shade50]
                  : [Colors.white, Colors.blue.shade50],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: _primaryColor.withValues(alpha: 0.2),
                blurRadius: 12,
                spreadRadius: 2,
                offset: const Offset(0, 6),
              ),
            ],
            border: Border.all(
              color: _primaryColor.withValues(alpha: 0.3),
              width: 2,
            ),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                decoration: BoxDecoration(
                  color: _primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Semifinal ${index + 1}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: _primaryColor,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildPlayerMatchupCard(player1),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _primaryColor.withValues(alpha: 0.1),
                      ),
                      child: Text(
                        'VS',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: _primaryColor,
                        ),
                      ),
                    ),
                    _buildPlayerMatchupCard(player2),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlayerCard(TournamentPlayer player) {
    return Container(
      width: 150,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: widget.isHellMode
              ? [Colors.white, Colors.red.shade50]
              : [Colors.white, Colors.blue.shade50],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: _primaryColor.withValues(alpha: 0.15),
            blurRadius: 8,
            spreadRadius: 1,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: _primaryColor.withValues(alpha: 0.2),
          width: 1.5,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: widget.isHellMode
                    ? [Colors.red.shade600, Colors.red.shade800]
                    : [AppColors.primaryBlue, AppColors.primaryBlue.withValues(alpha: 0.7)],
              ),
              boxShadow: [
                BoxShadow(
                  color: _primaryColor.withValues(alpha: 0.3),
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: CircleAvatar(
              backgroundColor: Colors.transparent,
              radius: 30,
              child: Text(
                player.name.isNotEmpty ? player.name.substring(0, 1).toUpperCase() : '?',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 24,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            player.name,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: _primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _primaryColor.withValues(alpha: 0.2),
              ),
            ),
            child: Text(
              'Seed #${player.seed}',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: _primaryColor,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerMatchupCard(TournamentPlayer player) {
    return Container(
      width: 100, // Reduced width from 120 to 100
      padding: const EdgeInsets.all(10), // Reduced padding from 12 to 10
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: widget.isHellMode
              ? [Colors.white, Colors.red.shade50]
              : [Colors.white, Colors.blue.shade50],
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: _primaryColor.withValues(alpha: 0.1),
            blurRadius: 4,
            spreadRadius: 0,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: _primaryColor.withValues(alpha: 0.2),
          width: 1.5,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: widget.isHellMode
                    ? [Colors.red.shade600, Colors.red.shade800]
                    : [AppColors.primaryBlue, AppColors.primaryBlue.withValues(alpha: 0.7)],
              ),
            ),
            child: CircleAvatar(
              backgroundColor: Colors.transparent,
              radius: 22,
              child: Text(
                player.name.isNotEmpty ? player.name.substring(0, 1).toUpperCase() : '?',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            player.name,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: _primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'Seed #${player.seed}',
              style: TextStyle(
                fontSize: 12,
                color: _primaryColor,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 24),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: _primaryColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
              color: _primaryColor.withValues(alpha: 0.2),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: _primaryColor.withValues(alpha: 0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _isDrawComplete 
                    ? Icons.arrow_forward 
                    : Icons.shuffle,
                color: _primaryColor,
                size: 18,
              ),
              const SizedBox(width: 12),
              Flexible(
                child: Text(
                  _isDrawComplete
                      ? 'Proceeding to tournament bracket...'
                      : 'Determining random matchups...',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _primaryColor,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
