import 'package:flutter/material.dart';
import 'package:vanishingtictactoe/features/auth/screens/forgot_password_screen.dart';
import 'package:vanishingtictactoe/features/auth/screens/login_screen.dart';
import 'package:vanishingtictactoe/features/auth/screens/register_screen.dart';
import 'package:vanishingtictactoe/features/friends/screens/add_friend_screen.dart';
import 'package:vanishingtictactoe/features/friends/screens/notifications_screen.dart';
import 'package:vanishingtictactoe/features/game/screens/Computer/difficulty_selection_screen.dart';
import 'package:vanishingtictactoe/features/game/screens/Friendly_match/friendly_match_screen.dart';
import 'package:vanishingtictactoe/features/game/screens/2Players/two_players_screen.dart';
import 'package:vanishingtictactoe/features/online/screens/online_screen.dart';
import 'package:vanishingtictactoe/features/profile/screens/level_roadmap_screen.dart';
import 'package:vanishingtictactoe/features/tournament/screens/tournament_bracket_screen.dart';
import 'package:vanishingtictactoe/features/tournament/screens/tournament_draw_screen.dart';
import 'package:vanishingtictactoe/features/tournament/screens/tournament_lobby_screen.dart';
import 'package:vanishingtictactoe/features/tournament/screens/tournament_match_screen.dart';
import 'package:vanishingtictactoe/features/tutorial/screens/hell_tutorial_screen.dart';
import 'package:vanishingtictactoe/main_navigation_controller.dart';

class AppRoutes {
  // Route names as constants
  static const String login = '/login';
  static const String addFriend = '/add-friend';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';
  static const String twoPlayersHistory = '/two-players-history';
  static const String difficultySelection = '/difficulty-selection';
  static const String missions = '/missions';
  static const String notifications = '/notifications';
  static const String friendlyMatch = '/friendly_match';
  static const String online = '/online';
  static const String levelRoadmap = '/level-roadmap';
  static const String gameModeSelection = '/game/mode-selection';
  static const String hellTutorial = '/hell-tutorial';
  static const String main = '/main';
  
  // Tournament routes
  static const String tournamentLobby = '/tournament-lobby';
  static const String tournamentDraw = '/tournament-draw';
  static const String tournamentBracket = '/tournament-bracket';
  static const String tournamentMatch = '/tournament-match';
  

  // Route map
  static Map<String, WidgetBuilder> getRoutes() {
    return {
      
      
      // Only include screens that are accessed outside the main navigation flow
      login: (context) => const LoginScreen(),
      addFriend: (context) => const AddFriendScreen(),
      register: (context) => const RegisterScreen(),
      forgotPassword: (context) => const ForgotPasswordScreen(),
      twoPlayersHistory: (context) => const TwoPlayersHistoryScreen(),
      difficultySelection: (context) => const DifficultySelectionScreen(),
      notifications: (context) => const NotificationsScreen(),
      friendlyMatch: (context) => const FriendlyMatchScreen(),
      online: (context) => const OnlineScreen(),
      levelRoadmap: (context) => const LevelRoadmapScreen(),
      hellTutorial: (context) => const HellTutorialScreen(),
      main: (context) => const MainNavigationController(),
      
      // Tournament routes
      tournamentLobby: (context) => TournamentLobbyScreen(
        tournamentId: ModalRoute.of(context)!.settings.arguments as String,
      ),
      tournamentDraw: (context) => TournamentDrawScreen(
        tournamentId: ModalRoute.of(context)!.settings.arguments as String,
      ),
      tournamentBracket: (context) => TournamentBracketScreen(
        tournamentId: ModalRoute.of(context)!.settings.arguments as String,
      ),
      tournamentMatch: (context) {
        final args = ModalRoute.of(context)!.settings.arguments as Map<String, String>;
        return TournamentMatchScreen(
          tournamentId: args['tournamentId']!,
          matchId: args['matchId']!,
          gameId: args['gameId']!,
        );
      },
    };
  }
}