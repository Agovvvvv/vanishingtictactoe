import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vanishingtictactoe/core/constants/app_colors.dart';
import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

class AnimatedTitleWidget extends StatefulWidget {
  const AnimatedTitleWidget({
    super.key,
    required this.text,
    this.isHellMode = false,
  });

  final String text;
  final bool isHellMode;

  @override
  State<AnimatedTitleWidget> createState() => _AnimatedTitleWidgetState();
}

class _AnimatedTitleWidgetState extends State<AnimatedTitleWidget> with TickerProviderStateMixin {
  // Main controllers
  AnimationController? _mainController;
  AnimationController? _shimmerController;
  AnimationController? _pulseController;
  AnimationController? _rotationController;
  
  // Animation collections
  late List<Animation<double>> _letterAnimations = [];
  late List<Animation<double>> _rotationAnimations = [];
  late List<Animation<double>> _scaleAnimations = [];
  
  // Effects management
  Timer? _bounceTimer;
  Timer? _emphasisTimer;
  
  // Track interaction state
  bool _isHovered = false;
  int? _emphasizedCharIndex;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  @override
  void didUpdateWidget(AnimatedTitleWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.text != oldWidget.text) {
      _initializeAnimations();
    }
  }

void _initializeAnimations() {
  // Clean up existing animations
  _disposeAnimations();
  
  // Create main controllers with varying durations
  _mainController = AnimationController(
    duration: const Duration(milliseconds: 1500),
    vsync: this,
  );
  
  _shimmerController = AnimationController(
    duration: const Duration(milliseconds: 2000),
    vsync: this,
  )..repeat();
  
  _pulseController = AnimationController(
    duration: const Duration(milliseconds: 3000),
    vsync: this,
  )..repeat(reverse: true);
  
  _rotationController = AnimationController(
    duration: const Duration(milliseconds: 8000),
    vsync: this,
  )..repeat();
  
  final textLength = widget.text.length;
  
  // Guard clause for empty text
  if (textLength == 0) {
    _letterAnimations = [];
    _rotationAnimations = [];
    _scaleAnimations = [];
    if (mounted) setState(() {});
    return;
  }
  
  // Create staggered animations for each letter
  _createLetterAnimations(textLength);
  
  // Start main animation sequence
  _mainController?.forward(from: 0.0);
  
  // Schedule random effects
  _scheduleRandomBounce();
  _scheduleRandomEmphasis();
}

void _createLetterAnimations(int textLength) {
  // Calculate staggered timing
  final stepSize = textLength <= 1 ? 0.1 : 0.8 / textLength;
  final animDuration = math.min(0.4, 1.0 / textLength);
  
  // Generate primary animations
  _letterAnimations = List.generate(textLength, (index) {
    final rawStart = index * stepSize;
    final rawEnd = rawStart + animDuration;
    
    // Ensure start and end are properly separated and within valid range
    final start = rawStart.clamp(0.0, 0.9);
    final end = math.min(rawEnd.clamp(start + 0.1, 1.0), 1.0);
    
    return CurvedAnimation(
      parent: _mainController!,
      curve: Interval(start, end, curve: Curves.easeOutBack),
    );
  });
  
  // Generate rotation animations with slight randomness
  _rotationAnimations = List.generate(textLength, (index) {
    final random = math.Random();
    final rotationAmount = (random.nextBool() ? 1 : -1) * (0.05 + random.nextDouble() * 0.05);
    
    // Ensure start and end are properly separated
    final start = (random.nextDouble() * 0.4).clamp(0.0, 0.4);
    final end = (0.6 + random.nextDouble() * 0.4).clamp(start + 0.1, 1.0);
    
    return Tween<double>(
      begin: -rotationAmount,
      end: rotationAmount,
    ).animate(
      CurvedAnimation(
        parent: _rotationController!,
        curve: Interval(start, end, curve: Curves.easeInOut),
      ),
    );
  });
  
  // Generate scale animations for emphasis
  _scaleAnimations = List.generate(textLength, (index) {
    // Ensure valid interval values with proper separation
    final start = (0.1 * index / math.max(textLength, 1)).clamp(0.0, 0.9);
    final end = math.min((0.1 + 0.1 * index / math.max(textLength, 1)).clamp(start + 0.1, 1.0), 1.0);
    
    return Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(
      CurvedAnimation(
        parent: _pulseController!,
        curve: Interval(start, end, curve: Curves.easeInOut),
      ),
    );
  });
}

void _scheduleRandomBounce() {
  _bounceTimer?.cancel();
  final randomDelay = Duration(milliseconds: 2000 + math.Random().nextInt(3000));
  
  _bounceTimer = Timer(randomDelay, () {
    if (!mounted || widget.text.isEmpty || _mainController == null) return;
    
    _mainController!.forward(from: 0.0).then((_) {
      if (mounted && _mainController != null) {
        _scheduleRandomBounce();
      }
    }).catchError((e) {
      if (e is! TickerCanceled) {
        print("Error during animation bounce: $e");
      }
    });
  });
}

void _scheduleRandomEmphasis() {
  _emphasisTimer?.cancel();
  
  if (widget.text.isEmpty) return;
  
  final randomDelay = Duration(milliseconds: 1000 + math.Random().nextInt(2000));
  _emphasisTimer = Timer(randomDelay, () {
    if (!mounted) return;
    
    setState(() {
      _emphasizedCharIndex = math.Random().nextInt(widget.text.length);
    });
    
    _emphasisTimer = Timer(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {
          _emphasizedCharIndex = null;
        });
        _scheduleRandomEmphasis();
      }
    });
  });
}

void _disposeAnimations() {
  _mainController?.dispose();
  _shimmerController?.dispose();
  _pulseController?.dispose();
  _rotationController?.dispose();
  _bounceTimer?.cancel();
  _emphasisTimer?.cancel();
  
  _mainController = null;
  _shimmerController = null;
  _pulseController = null;
  _rotationController = null;
}

@override
void dispose() {
  _disposeAnimations();
  super.dispose();
}

@override
Widget build(BuildContext context) {
  if (_mainController == null || widget.text.isEmpty || _letterAnimations.isEmpty) {
    return const SizedBox.shrink();
  }

  final primaryColor = AppColors.getPrimaryColor(widget.isHellMode);
  final secondaryColor = widget.isHellMode 
      ? Colors.orange 
      : primaryColor.withOpacity(0.7);

  Widget content = MouseRegion(
    onEnter: (_) => setState(() => _isHovered = true),
    onExit: (_) => setState(() => _isHovered = false),
    child: AnimatedBuilder(
      animation: _pulseController!,
      builder: (context, child) {
        final pulseValue = _pulseController!.value;
        
        return Container(
          constraints: const BoxConstraints(maxWidth: 320),
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
          decoration: BoxDecoration(
            // Glass morphism effect
            color: Colors.white.withOpacity(0.15),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withOpacity(0.7 + 0.1 * pulseValue),
                Colors.white.withOpacity(0.5 + 0.1 * pulseValue),
              ],
              stops: const [0.2, 0.9],
            ),
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              // Dynamic glow effect
              BoxShadow(
                color: primaryColor.withOpacity(0.15 + 0.1 * pulseValue),
                blurRadius: 15 + 5 * pulseValue,
                spreadRadius: 0.5 + 0.5 * pulseValue,
                offset: const Offset(0, 3),
              ),
              // Inner highlight
              BoxShadow(
                color: Colors.white.withOpacity(0.25 + 0.1 * pulseValue),
                blurRadius: 8,
                spreadRadius: -1,
                offset: const Offset(0, -1),
              ),
            ],
            border: Border.all(
              color: primaryColor.withOpacity(0.2 + 0.1 * pulseValue), 
              width: 1.5
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(25),
            child: BackdropFilter(
              filter: ui.ImageFilter.blur(sigmaX: 5, sigmaY: 5),
              child: _buildLettersRow(primaryColor, secondaryColor),
            ),
          ),
        );
      },
    ),
  );
  
  // Apply Hell Mode effects if needed
  if (widget.isHellMode) {
    content = _buildHellModeEffects(content);
  }
  
  return RepaintBoundary(child: content);
}

Widget _buildLettersRow(Color primaryColor, Color secondaryColor) {
  return Center(
    child: FittedBox(
      fit: BoxFit.scaleDown,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4.0),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: List.generate(widget.text.length, (index) {
            if (index >= _letterAnimations.length) {
              return const SizedBox.shrink();
            }
            
            return _buildAnimatedLetter(
              index: index,
              primaryColor: primaryColor,
              secondaryColor: secondaryColor,
              isEmphasis: _emphasizedCharIndex == index,
            );
          }),
        ),
      ),
    ),
  );
}

Widget _buildAnimatedLetter({
  required int index,
  required Color primaryColor,
  required Color secondaryColor,
  bool isEmphasis = false,
}) {
  // Create shimmer effect
  final shimmerValue = _shimmerController!.value;
  final shimmerOffset = (shimmerValue - 0.5) * 2.0;
  final isInShimmerRange = shimmerOffset.abs() < 0.3;
  
  return AnimatedBuilder(
    animation: Listenable.merge([
      _letterAnimations[index],
      _rotationAnimations[index],
      _scaleAnimations[index],
    ]),
    builder: (context, child) {
      // Get animation values
      final mainValue = _letterAnimations[index].value;
      final rotationValue = _rotationAnimations[index].value;
      final scaleValue = isEmphasis 
          ? 1.0 + 0.3 * math.sin(math.pi * 4 * _pulseController!.value) 
          : 1.0 + (0.05 * _scaleAnimations[index].value);
      
      // Apply multiple transformations
      return Transform(
        transform: Matrix4.identity()
          ..setEntry(3, 2, 0.001) // Perspective
          ..rotateX(0.05 * mainValue)
          ..rotateY(rotationValue)
          ..rotateZ(0.05 * math.sin(math.pi * mainValue))
          ..translate(
            0.0, 
            -5.0 * mainValue + (_isHovered ? -2.0 : 0.0),
            isEmphasis ? 8.0 : 0.0,
          )
          ..scale(scaleValue),
        alignment: Alignment.center,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: EdgeInsets.symmetric(
            horizontal: isEmphasis ? 1.0 : 0.0,
          ),
          child: ShaderMask(
            blendMode: BlendMode.srcIn,
            shaderCallback: (bounds) {
              return LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isInShimmerRange
                    ? [
                        secondaryColor,
                        primaryColor,
                        secondaryColor,
                      ]
                    : [
                        primaryColor,
                        primaryColor.withOpacity(0.8),
                      ],
                stops: isInShimmerRange
                    ? [0.0, 0.5, 1.0]
                    : [0.3, 0.9],
                transform: isInShimmerRange
                    ? GradientRotation(shimmerValue * math.pi * 2)
                    : null,
              ).createShader(bounds);
            },
            child: Text(
              widget.text[index],
              style: GoogleFonts.poppins(
                fontSize: 22,
                fontWeight: isEmphasis 
                    ? FontWeight.w900 
                    : FontWeight.w700,
                letterSpacing: 1.2,
                height: 1.2,
              ),
            ),
          ),
        ),
      );
    },
  );
}

Widget _buildHellModeEffects(Widget child) {
  if (!widget.isHellMode) return child;
  
  return Stack(
    children: [
      // Heat distortion effect
      AnimatedBuilder(
        animation: _pulseController!,
        builder: (context, _) {
          return ShaderMask(
            blendMode: BlendMode.srcATop,
            shaderCallback: (bounds) {
              return LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.red.withOpacity(0.1 + 0.1 * _pulseController!.value),
                  Colors.orange.withOpacity(0.1 + 0.1 * _pulseController!.value),
                  Colors.transparent,
                ],
                stops: const [0.0, 0.3, 0.7, 1.0],
              ).createShader(bounds);
            },
            child: child,
          );
        },
      ),
      
      // Ember particles would go here (requires CustomPainter)
    ],
  );
}
}
