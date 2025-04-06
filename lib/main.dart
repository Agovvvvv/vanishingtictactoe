import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vanishingtictactoe/core/utils/app_logger.dart';
import 'package:vanishingtictactoe/features/tournament/providers/tournament_provider.dart';
import 'package:vanishingtictactoe/main_navigation_controller.dart';
import 'core/config/firebase_options.dart';
import 'core/routes/app_routes.dart';
import 'core/navigation/navigation_service.dart';
import 'features/tutorial/screens/tutorial_screen.dart';
import 'shared/providers/user_provider.dart';
import 'shared/providers/hell_mode_provider.dart';
import 'shared/providers/mission_provider.dart';
import 'shared/providers/navigation_provider.dart';
import 'features/profile/services/presence_service.dart';
import 'package:vanishingtictactoe/features/profile/services/profile_customization_service.dart';
import 'package:vanishingtictactoe/core/utils/font_preloader.dart';
import 'package:vanishingtictactoe/features/friends/services/notification_service.dart';
import 'package:vanishingtictactoe/features/friends/services/global_notification_manager.dart';

const Color kPrimaryBlue = Color(0xFF2962FF);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  AppLogger.info('Initializing Firebase...');
  
  // Initialize Firebase with platform-specific options
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  AppLogger.info('Firebase initialized successfully');

  PresenceService().initialize();
  await FontPreloader.preloadFonts();

  final prefs = await SharedPreferences.getInstance();
  final tutorialCompleted = prefs.getBool('tutorial_completed') ?? false;

  runApp(VanishingTicTacToeApp(tutorialCompleted: tutorialCompleted));
}

class VanishingTicTacToeApp extends StatefulWidget {
  final bool tutorialCompleted;

  const VanishingTicTacToeApp({super.key, this.tutorialCompleted = false});

  @override
  State<VanishingTicTacToeApp> createState() => _VanishingTicTacToeAppState();
}



class _VanishingTicTacToeAppState extends State<VanishingTicTacToeApp> with WidgetsBindingObserver {
  final NotificationService _notificationService = NotificationService();
  final GlobalNotificationManager _notificationManager = GlobalNotificationManager();
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (!FontPreloader.areFontsLoaded) {
      FontPreloader.preloadFonts();
    }
    
    // Initialize the notification service after the app is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Wait a short delay to ensure the MaterialApp is fully initialized
      Future.delayed(const Duration(milliseconds: 100), () {
        if (navigatorKey.currentContext != null) {
          _notificationService.setGlobalContext(navigatorKey.currentContext!);
        }
      });
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _notificationService.dispose();
    _notificationManager.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.paused || state == AppLifecycleState.detached) {
      _syncPendingData();
    }
  }

  Future<void> _syncPendingData() async {
    try {
      final customizationService = ProfileCustomizationService();
      await customizationService.syncToServer();
    } catch (e) {
      AppLogger.error('Error syncing pending data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserProvider()..initialize()),
        ChangeNotifierProvider(create: (_) => HellModeProvider()),
        ChangeNotifierProvider(create: (_) => MissionProvider()),
        ChangeNotifierProvider(create: (_) => NavigationProvider.instance),
        ChangeNotifierProvider(create: (_) => TournamentProvider()),
      ],
      child: MaterialApp(
          navigatorKey: navigatorKey, // Use the NavigationService's navigator key
          scaffoldMessengerKey: scaffoldMessengerKey, // Use the global ScaffoldMessenger key
        title: 'Vanishing Tic Tac Toe',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          primaryColor: kPrimaryBlue,
          colorScheme: ColorScheme.fromSeed(seedColor: kPrimaryBlue, primary: kPrimaryBlue),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: kPrimaryBlue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
          inputDecorationTheme: InputDecorationTheme(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: kPrimaryBlue, width: 2),
            ),
          ),
        ),
          home: widget.tutorialCompleted ? const MainNavigationController() : const TutorialScreen(),
          routes: AppRoutes.getRoutes(),
      ),
    );
  }
}