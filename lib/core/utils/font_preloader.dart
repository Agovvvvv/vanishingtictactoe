import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// A utility class to preload Google Fonts to avoid loading delays during animations
class FontPreloader {
  static bool _fontsLoaded = false;
  
  // Cached TextStyles for each font
  static late final TextStyle pressStart2p;
  static late final TextStyle bangers;
  static late final TextStyle pacifico;
  static late final TextStyle rubikMoonrocks;
  static late final TextStyle permanentMarker;
  static late final TextStyle orbitron;
  static late final TextStyle poppins;
  
  /// Preloads all Google Fonts used in the app
  static Future<void> preloadFonts() async {
    if (_fontsLoaded) return;
    
    // Load all fonts in parallel
    await Future.wait([
      _loadFont('Press Start 2P'),
      _loadFont('Bangers'),
      _loadFont('Pacifico'),
      _loadFont('Rubik Moonrocks'),
      _loadFont('Permanent Marker'),
      _loadFont('Orbitron'),
      _loadFont('Poppins'),
    ]);
    
    // Initialize cached TextStyles
    pressStart2p = GoogleFonts.pressStart2p();
    bangers = GoogleFonts.bangers();
    pacifico = GoogleFonts.pacifico();
    rubikMoonrocks = GoogleFonts.rubikMoonrocks();
    permanentMarker = GoogleFonts.permanentMarker();
    orbitron = GoogleFonts.orbitron();
    poppins = GoogleFonts.poppins();
    
    _fontsLoaded = true;
  }
  
  /// Helper method to load a specific font
  static Future<void> _loadFont(String fontFamily) async {
    try {
      await GoogleFonts.pendingFonts([fontFamily]);
    } catch (e) {
      debugPrint('Error loading font $fontFamily: $e');
    }
  }
  
  /// Creates a TextStyle with the specified font and properties
  /// This uses the preloaded font to avoid loading delays
  static TextStyle getTextStyle({
    required String fontFamily,
    double? fontSize,
    Color? color,
    FontWeight? fontWeight,
    List<Shadow>? shadows,
    double? letterSpacing,
    Paint? foreground,
  }) {
    // Get the base style from the preloaded fonts
    TextStyle baseStyle;
    
    switch (fontFamily) {
      case 'Press Start 2P':
        baseStyle = pressStart2p;
        break;
      case 'Bangers':
        baseStyle = bangers;
        break;
      case 'Pacifico':
        baseStyle = pacifico;
        break;
      case 'Rubik Moonrocks':
        baseStyle = rubikMoonrocks;
        break;
      case 'Permanent Marker':
        baseStyle = permanentMarker;
        break;
      case 'Orbitron':
        baseStyle = orbitron;
        break;
      case 'Poppins':
        baseStyle = poppins;
        break;
      default:
        throw ArgumentError('Unknown font family: $fontFamily');
    }
    
    // Apply the specified properties
    return baseStyle.copyWith(
      fontSize: fontSize,
      color: foreground == null ? color : null,
      fontWeight: fontWeight,
      shadows: shadows,
      letterSpacing: letterSpacing,
      foreground: foreground,
    );
  }
  
  /// Checks if fonts are loaded
  static bool get areFontsLoaded => _fontsLoaded;
}
