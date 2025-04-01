import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vanishingtictactoe/shared/providers/hell_mode_provider.dart';

// Helper method to build the login prompt widget
class LoginPromptWidget extends StatelessWidget {
    final String message;
    
    const LoginPromptWidget({
      super.key,
      required this.message,
    });
    
    @override
    Widget build(BuildContext context) {
      final hellModeActive = Provider.of<HellModeProvider>(context).isHellModeActive;
      final primaryColor = hellModeActive ? Colors.red : Colors.blue;
      
      return Container(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: hellModeActive
            ? [Colors.white.withValues( alpha: 0.9), Colors.red.shade50.withValues( alpha: 0.7)]
            : [Colors.white.withValues( alpha: 0.9), Colors.blue.shade50.withValues( alpha: 0.7)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: primaryColor.withValues( alpha: 0.3),
          width: 2.0,
        ),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withValues( alpha: 0.15),
            blurRadius: 20,
            offset: const Offset(0, 10),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.account_circle_outlined,
            size: 48,
            color: hellModeActive ? Colors.red.shade300 : Colors.blue.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: hellModeActive ? Colors.red.shade800 : Colors.blue.shade800,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              // Navigate to login screen or show login dialog
              // This would be implemented based on your app's authentication flow
              Navigator.pushNamed(context, '/login');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: hellModeActive ? Colors.red.shade600 : Colors.blue.shade600,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: const Text('Log In', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}