import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class LocalMatchHistoryService {
  static const String _key = 'two_player_matches';

  Future<void> saveMatch({
    required String player1,
    required String player2,
    required String winner,
    required bool player1WentFirst,
    String? player1Symbol,
    String? player2Symbol,
    bool isHellMode = false,
    bool vanishingEffectEnabled = true, // Add parameter with default value true
  }) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> matches = prefs.getStringList(_key) ?? [];

    // If player2 went first, swap the order in the display
    final displayPlayer1 = player1WentFirst ? player1 : player2;
    final displayPlayer2 = player1WentFirst ? player2 : player1;
    final displayPlayer1Symbol = player1WentFirst ? (player1Symbol ?? 'X') : (player2Symbol ?? 'O');
    final displayPlayer2Symbol = player1WentFirst ? (player2Symbol ?? 'O') : (player1Symbol ?? 'X');

    final now = DateTime.now().toIso8601String();
    final match = {
      'player1': displayPlayer1,
      'player2': displayPlayer2,
      'winner': winner,
      'player1_symbol': displayPlayer1Symbol,
      'player2_symbol': displayPlayer2Symbol,
      'timestamp': now,
      'is_hell_mode': isHellMode,
      'vanishingEffectEnabled': vanishingEffectEnabled, // Add this field to the match data
    };

    // Add new match at the beginning
    matches.insert(0, jsonEncode(match));

    // Remove any matches older than 5 days
    final fiveDaysAgo = DateTime.now().subtract(const Duration(days: 5));
    matches = matches.where((matchJson) {
      final matchData = jsonDecode(matchJson) as Map<String, dynamic>;
      final timestamp = DateTime.parse(matchData['timestamp'] as String);
      return timestamp.isAfter(fiveDaysAgo);
    }).toList();

    await prefs.setStringList(_key, matches);
  }

  Future<List<Map<String, dynamic>>> getRecentMatches() async {
    final prefs = await SharedPreferences.getInstance();
    final matches = prefs.getStringList(_key) ?? [];
    
    // Get only the 10 most recent matches (or fewer if less than 10 exist)
    final recentMatches = matches.take(10).toList();

    return recentMatches
        .map((match) => Map<String, dynamic>.from(jsonDecode(match)))
        .toList();
  }

  Future<void> clearHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
