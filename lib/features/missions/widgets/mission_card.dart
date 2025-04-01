import 'package:flutter/material.dart';
import 'package:vanishingtictactoe/features/missions/models/mission.dart';

class MissionCard extends StatefulWidget {
  final Mission mission;
  final VoidCallback onClaim;
  final bool showAnimation;

  const MissionCard({
    super.key,
    required this.mission,
    required this.onClaim,
    this.showAnimation = false,
  });

  @override
  State<MissionCard> createState() => _MissionCardState();
}

class _MissionCardState extends State<MissionCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _progressAnimation;
  late Animation<double> _checkAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    
    _progressAnimation = Tween<double>(
      begin: 0.0,
      end: widget.mission.progressPercentage / 100,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));
    
    _checkAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.5, 1.0, curve: Curves.elasticOut),
    ));
    
    _scaleAnimation = Tween<double>(
      begin: 0.95,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.5, curve: Curves.easeOutQuad),
    ));
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
    ));
    
    _controller.forward();
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isHellMode = widget.mission.category == MissionCategory.hell;
    final Color primaryColor = isHellMode ? Colors.red.shade800 : Colors.blue;
    final Color secondaryColor = isHellMode ? Colors.red.shade600 : Colors.blue.shade600;
    final Color backgroundColor = isHellMode ? Colors.red.shade50 : Colors.blue.shade50;
    final IconData typeIcon = widget.mission.type == MissionType.daily
        ? Icons.today
        : Icons.date_range;
    final IconData categoryIcon = isHellMode
        ? Icons.whatshot
        : Icons.games;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Opacity(
            opacity: _fadeAnimation.value,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              transform: widget.mission.completed 
                  ? (Matrix4.identity()..scale(1.02)) // Slightly larger for completed missions
                  : Matrix4.identity(),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: widget.mission.completed 
                          ? Colors.green.withValues( alpha: 0.2) 
                          : primaryColor.withValues( alpha: 0.15),
                      blurRadius: widget.mission.completed ? 15 : 10,
                      offset: const Offset(0, 5),
                      spreadRadius: widget.mission.completed ? 1 : 0,
                    ),
                  ],
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: widget.mission.completed
                        ? [Colors.white, Colors.green.shade50]
                        : [Colors.white, backgroundColor],
                  ),
                  border: Border.all(
                    color: widget.mission.completed 
                        ? Colors.green.withValues( alpha: 0.3) 
                        : primaryColor.withValues( alpha: 0.2),
                    width: widget.mission.completed ? 2 : 1.5,
                  ),
                ),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        // Category icon with enhanced container
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: widget.mission.completed
                                ? Colors.green.shade50
                                : primaryColor.withValues( alpha: 0.1),
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: (widget.mission.completed
                                    ? Colors.green
                                    : primaryColor).withValues( alpha: 0.15),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Icon(
                            categoryIcon,
                            color: widget.mission.completed ? Colors.green : primaryColor,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.mission.title,
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: widget.mission.completed ? Colors.green.shade700 : primaryColor,
                                  letterSpacing: 0.5,
                                  shadows: [
                                    Shadow(
                                      color: (widget.mission.completed ? Colors.green : primaryColor).withValues( alpha: 0.2),
                                      offset: const Offset(0, 1),
                                      blurRadius: 2,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: (widget.mission.completed ? Colors.green : secondaryColor).withValues( alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      typeIcon,
                                      color: widget.mission.completed ? Colors.green.shade600 : secondaryColor,
                                      size: 14,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      widget.mission.type == MissionType.daily ? 'Daily' : 'Weekly',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                        color: widget.mission.completed ? Colors.green.shade600 : secondaryColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (widget.showAnimation && widget.mission.completed)
                          _buildCompletionAnimation(),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: (widget.mission.completed ? Colors.green : primaryColor).withValues( alpha: 0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: (widget.mission.completed ? Colors.green : primaryColor).withValues( alpha: 0.1),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        widget.mission.description,
                        style: TextStyle(
                          fontSize: 15,
                          color: Colors.grey[800],
                          height: 1.4,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    _buildProgressSection(primaryColor),
                    const SizedBox(height: 20),
                    if (widget.mission.completed && !widget.mission.rewardClaimed)
                      _buildClaimButton(primaryColor)
                    else if (widget.mission.completed && widget.mission.rewardClaimed)
                      _buildClaimedLabel()
                    else
                      _buildExpiryInfo(context, primaryColor),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildProgressSection(Color primaryColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.trending_up_rounded,
                    color: Colors.grey.shade700,
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Progress',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade700,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.amber.withValues( alpha: 0.2),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.star_rounded,
                    color: Colors.amber,
                    size: 18,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '+${widget.mission.xpReward} XP',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.amber.shade800,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        AnimatedBuilder(
          animation: _progressAnimation,
          builder: (context, child) {
            return Stack(
              children: [
                // Background track
                Container(
                  height: 16,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                // Progress bar
                FractionallySizedBox(
                  widthFactor: _progressAnimation.value,
                  child: Container(
                    height: 16,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: widget.mission.completed
                            ? [Colors.green.shade400, Colors.green.shade600]
                            : [primaryColor.withValues( alpha: 0.8), primaryColor],
                      ),
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: (widget.mission.completed ? Colors.green : primaryColor).withValues( alpha: 0.3),
                          blurRadius: 6,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: widget.mission.completed
                        ? Center(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.check_circle_outline_rounded,
                                  color: Colors.white,
                                  size: 12,
                                ),
                                const SizedBox(width: 4),
                                Flexible(
                                  child: Text(
                                    'COMPLETED',
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )
                        : null,
                  ),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: (widget.mission.completed ? Colors.green : primaryColor).withValues( alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${widget.mission.currentCount}/${widget.mission.targetCount}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: widget.mission.completed ? Colors.green.shade700 : primaryColor,
                ),
              ),
            ),
            Text(
              '${widget.mission.progressPercentage.toStringAsFixed(0)}%',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: widget.mission.completed ? Colors.green.shade700 : Colors.grey.shade700,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildClaimButton(Color primaryColor) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: widget.onClaim,
        icon: const Icon(Icons.celebration_rounded, color: Colors.white),
        label: const Text(
          'CLAIM REWARD',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.0,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green.shade600,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 4,
          shadowColor: Colors.green.withValues( alpha: 0.4),
        ),
      ),
    );
  }
  
  Widget _buildClaimedLabel() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.grey.shade100,
            Colors.grey.shade200,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade300.withValues( alpha: 0.5),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.verified_rounded,
            color: Colors.grey.shade600,
            size: 20,
          ),
          const SizedBox(width: 10),
          Text(
            'REWARD CLAIMED',
            style: TextStyle(
              color: Colors.grey.shade700,
              fontWeight: FontWeight.bold,
              fontSize: 15,
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpiryInfo(BuildContext context, Color primaryColor) {
    final now = DateTime.now();
    final difference = widget.mission.expiresAt.difference(now);
    
    String expiryText;
    IconData expiryIcon;
    Color expiryColor;
    
    if (difference.inDays > 0) {
      expiryText = 'Expires in ${difference.inDays} days';
      expiryIcon = Icons.calendar_today_rounded;
      expiryColor = Colors.grey.shade700;
    } else if (difference.inHours > 0) {
      expiryText = 'Expires in ${difference.inHours} hours';
      expiryIcon = Icons.access_time_rounded;
      expiryColor = difference.inHours < 12 ? Colors.orange.shade700 : Colors.grey.shade700;
    } else if (difference.inMinutes > 0) {
      expiryText = 'Expires in ${difference.inMinutes} minutes';
      expiryIcon = Icons.alarm_rounded;
      expiryColor = Colors.red.shade700;
    } else {
      expiryText = 'Expiring soon';
      expiryIcon = Icons.alarm_on_rounded;
      expiryColor = Colors.red.shade700;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: expiryColor.withValues( alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: expiryColor.withValues( alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            expiryIcon,
            size: 18,
            color: expiryColor,
          ),
          const SizedBox(width: 8),
          Text(
            expiryText,
            style: TextStyle(
              fontSize: 14,
              color: expiryColor,
              fontWeight: difference.inHours < 12 ? FontWeight.w600 : FontWeight.w500,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompletionAnimation() {
    return AnimatedBuilder(
      animation: _checkAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _checkAnimation.value,
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.green.shade400,
                  Colors.green.shade600,
                ],
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.green.withValues( alpha: 0.4),
                  blurRadius: 8,
                  spreadRadius: 1,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: const Icon(
              Icons.check_rounded,
              color: Colors.white,
              size: 22,
            ),
          ),
        );
      },
    );
  }
}
