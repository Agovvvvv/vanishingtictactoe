import 'package:flutter/material.dart';

class EmptyStateWidget extends StatelessWidget {
  final IconData icon;
  final Color? color;
  final String message;
  final String? subMessage;
  final bool showHellMissions;
  final RefreshCallback refreshMissions;
  final BuildContext context;
  
  const EmptyStateWidget({
    super.key,
    required this.icon,
    required this.color,
    required this.message,
    this.subMessage,
    required this.showHellMissions,
    required this.refreshMissions,
    required this.context,
  });
  
  @override
  Widget build(BuildContext context) {
    final primaryColor = showHellMissions ? Colors.red.shade700 : Color(0xFF2962FF);
    
    return RefreshIndicator(
      onRefresh: refreshMissions,
      color: primaryColor,
      backgroundColor: Colors.white,
      strokeWidth: 3,
      displacement: 40,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.7,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: (color ?? primaryColor).withValues( alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Icon(
                        icon,
                        size: 64,
                        color: color ?? primaryColor,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.shade200,
                          blurRadius: 10,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Text(
                          message,
                          style: TextStyle(
                            fontSize: 20,
                            color: color ?? Colors.grey.shade800,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.3,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        if (subMessage != null) ...[                    
                          const SizedBox(height: 12),
                          Text(
                            subMessage ?? '',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w400,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: primaryColor.withValues( alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.arrow_downward_rounded,
                      color: primaryColor,
                      size: 32,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Pull to refresh',
                    style: TextStyle(
                      fontSize: 14,
                      color: primaryColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}