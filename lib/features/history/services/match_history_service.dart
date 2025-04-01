import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:vanishingtictactoe/features/game/models/computer_player.dart';

class MatchHistoryService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  // Add a debounce mechanism to prevent duplicate saves
  final Map<String, DateTime> _lastSaveTime = {};

  Future<void> saveMatchResult({
    required String userId,
    required GameDifficulty? difficulty,
    required String result,
    bool isHellMode = false,
  }) async {
    // Check if we've saved a match for this user/difficulty/result recently
    final key = '$userId-${difficulty?.name}-$result-${isHellMode ? 'hell' : 'normal'}';
    final now = DateTime.now();
    
    // If we saved a match in the last 2 seconds, skip this save to prevent duplicates
    if (_lastSaveTime.containsKey(key)) {
      final lastSave = _lastSaveTime[key]!;
      if (now.difference(lastSave).inSeconds < 2) {
        return; // Skip this save to prevent duplicate
      }
    }
    
    // Update the last save time
    _lastSaveTime[key] = now;
    
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('match_history')
        .add({
      'difficulty': difficulty!.name,
      'result': result,
      'timestamp': FieldValue.serverTimestamp(),
      'isHellMode': isHellMode,
    });
  }

  Stream<Map<String, int>> getMatchStats({
    required String userId,
    required GameDifficulty difficulty,
    bool isHellMode = false,
  }) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('match_history')
        .where('difficulty', isEqualTo: difficulty.name)
        .where('isHellMode', isEqualTo: isHellMode)
        .snapshots()
        .map((snapshot) {
      Map<String, int> stats = {
        'win': 0,
        'loss': 0,
        'draw': 0,
      };

      for (var doc in snapshot.docs) {
        final result = doc.data()['result'] as String;
        stats[result] = (stats[result] ?? 0) + 1;
      }

      return stats;
    });
  }

  Future<List<Map<String, dynamic>>> getRecentMatches({
    required String userId,
    required GameDifficulty difficulty,
    bool isHellMode = false,
    int limit = 10,
  }) async {
    final snapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('match_history')
        .where('difficulty', isEqualTo: difficulty.name)
        .where('isHellMode', isEqualTo: isHellMode)
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .get();

    return snapshot.docs
        .map((doc) => {
              ...doc.data(),
              'id': doc.id,
            })
        .toList();
  }
}
