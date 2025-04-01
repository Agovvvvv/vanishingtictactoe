import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vanishingtictactoe/shared/providers/hell_mode_provider.dart';

class HellModeToggle extends StatefulWidget {
  final VoidCallback onToggle;
  
  const HellModeToggle({
    super.key,
    required this.onToggle,
  });

  @override
  State<HellModeToggle> createState() => _HellModeToggleState();
}

class _HellModeToggleState extends State<HellModeToggle> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Get the current hell mode state from the provider
    final hellModeProvider = Provider.of<HellModeProvider>(context);
    final isHellModeActive = hellModeProvider.isHellModeActive;
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: GestureDetector(
        onTapDown: (_) {
          setState(() => _isPressed = true);
          _animationController.forward();
        },
        onTapUp: (_) {
          setState(() => _isPressed = false);
          _animationController.reverse();
        },
        onTapCancel: () {
          setState(() => _isPressed = false);
          _animationController.reverse();
        },
        onTap: widget.onToggle,
        child: AnimatedBuilder(
          animation: _scaleAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: child,
            );
          },
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFE74C3C), Color(0xFFc0392b)],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFE74C3C).withValues( alpha: _isPressed ? 0.2 : 0.4),
                  spreadRadius: _isPressed ? 1 : 2,
                  blurRadius: _isPressed ? 4 : 10,
                  offset: _isPressed ? const Offset(0, 2) : const Offset(0, 4),
                ),
              ],
              border: Border.all(
                color: Colors.red.shade700.withValues( alpha: 0.5),
                width: 1.5,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Stack(
                  children: [
                    Icon(
                      Icons.whatshot,
                      size: 26,
                      color: Colors.red.shade900.withValues( alpha: 0.5),
                    ),
                    const Icon(
                      Icons.whatshot,
                      size: 24,
                      color: Colors.yellow,
                    ),
                  ],
                ),
                const SizedBox(width: 12),
                Text(
                  // Changed text to ON/OFF instead of ACTIVATE/DEACTIVATE
                  isHellModeActive ? 'HELL MODE ON' : 'HELL MODE OFF',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    letterSpacing: 0.5,
                    shadows: [
                      Shadow(
                        offset: Offset(1.0, 1.0),
                        blurRadius: 3.0,
                        color: Color.fromARGB(128, 0, 0, 0),
                      ),
                    ],
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