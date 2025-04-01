import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:vanishingtictactoe/shared/models/user_account.dart';
import 'stat_card.dart';

class StatsSection extends StatefulWidget {
  final String title;
  final GameStats stats;
  final IconData icon;

  const StatsSection({
    super.key,
    required this.title,
    required this.stats,
    required this.icon,
  });

  @override
  State<StatsSection> createState() => _StatsSectionState();
}

class _StatsSectionState extends State<StatsSection> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    
    // Initialize animation controller
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    
    // Create fade animation
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.1, 0.8, curve: Curves.easeOut),
    ));
    
    // Create slide animation
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.1, 0.8, curve: Curves.easeOutQuart),
    ));
    
    // Start the animation
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.blue.shade100.withValues( alpha: 0.3),
                blurRadius: 15,
                offset: const Offset(0, 6),
                spreadRadius: 0,
              ),
            ],
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white,
                Colors.blue.shade50.withValues( alpha: 0.5),
              ],
            ),
            border: Border.all(
              color: Colors.blue.shade100.withValues( alpha: 0.5),
              width: 1.5,
            ),
          ),
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 16), // Reduced bottom padding
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with icon and title
              Row(
                children: [
                  RepaintBoundary(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.blue.shade200.withValues( alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Icon(
                        widget.icon, 
                        color: Colors.blue.shade700,
                        size: 28,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    widget.title,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade800,
                      letterSpacing: 0.5,
                      shadows: [
                        Shadow(
                          color: Colors.blue.shade200.withValues( alpha: 0.3),
                          offset: const Offset(0, 1),
                          blurRadius: 2,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 20), // Reduced spacing
              
              // Stats grid with animated items
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.only(bottom: 0), // Remove default padding
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 20,
                  crossAxisSpacing: 20,
                  childAspectRatio: 1.5,
                ),
                itemCount: 6,
                itemBuilder: (context, index) {
                  // Apply staggered animation to each grid item
                  return AnimatedBuilder(
                    animation: _animationController,
                    builder: (context, child) {
                      // Calculate delay based on index
                      final delay = 0.2 + (index * 0.1);
                      final startInterval = delay;
                      final endInterval = startInterval + 0.2;
                      
                      final curvedAnimation = CurvedAnimation(
                        parent: _animationController,
                        curve: Interval(startInterval, endInterval, curve: Curves.easeOutQuart),
                      );
                      
                      return FadeTransition(
                        opacity: Tween<double>(begin: 0.0, end: 1.0).animate(curvedAnimation),
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0, 0.3),
                            end: Offset.zero,
                          ).animate(curvedAnimation),
                          child: child,
                        ),
                      );
                    },
                    child: _buildStatCard(index),
                  );
                },
              ),
              
              // Last played info with animation
              if (widget.stats.lastPlayed != null)
                Padding(
                  padding: const EdgeInsets.only(top: 10), // Reduced top margin from default
                  child: AnimatedBuilder(
                    animation: _animationController,
                    builder: (context, child) {
                      return FadeTransition(
                        opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
                          CurvedAnimation(
                            parent: _animationController,
                            curve: const Interval(0.7, 1.0, curve: Curves.easeOut),
                          ),
                        ),
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0, 0.2),
                            end: Offset.zero,
                          ).animate(
                            CurvedAnimation(
                              parent: _animationController,
                              curve: const Interval(0.7, 1.0, curve: Curves.easeOutQuart),
                            ),
                          ),
                          child: child,
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.grey.shade200,
                          width: 1.0,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.access_time_rounded,
                            size: 16,
                            color: Colors.grey.shade600,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Last Played: ${DateFormat('dd/MM/yyyy').format(widget.stats.lastPlayed!)}',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w500,
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

  Widget _buildStatCard(int index) {
    switch (index) {
      case 0:
        return StatCard(
          title: 'Matches Played',
          value: widget.stats.gamesPlayed.toString(),
          icon: Icons.sports_esports,
          color: Colors.blue,
        );
      case 1:
        return StatCard(
          title: 'Games Won',
          value: widget.stats.gamesWon.toString(),
          icon: Icons.emoji_events,
          color: Colors.amber,
        );
      case 2:
        return StatCard(
          title: 'Win Rate',
          value: '${widget.stats.winRate.toStringAsFixed(1)}%',
          icon: Icons.trending_up,
          color: Colors.green,
        );
      case 3:
        return StatCard(
          title: 'Win Streak',
          value: widget.stats.currentWinStreak.toString(),
          icon: Icons.whatshot,
          color: Colors.orange,
        );
      case 4:
        return StatCard(
          title: 'Best Streak',
          value: widget.stats.highestWinStreak.toString(),
          icon: Icons.star,
          color: Colors.purple,
        );
      case 5:
        return StatCard(
          title: 'Avg Moves to Win',
          value: widget.stats.winningGames > 0
              ? widget.stats.averageMovesToWin.toStringAsFixed(1)
              : '-',
          icon: Icons.route,
          color: Colors.teal,
        );
      default:
        return const SizedBox();
    }
  }
}