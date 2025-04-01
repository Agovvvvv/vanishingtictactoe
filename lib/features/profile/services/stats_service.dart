import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:vanishingtictactoe/shared/models/user_account.dart';

class StatsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get user stats
  Future<Map<String, GameStats>> getUserStats(String userId) async {
    final doc = await _firestore.collection('users').doc(userId).get(const GetOptions(source: Source.cache));
    if (!doc.exists) {
      throw Exception('User not found');
    }

    final data = doc.data()!;
    final vsComputerStats = GameStats.fromJson(_extractStats(data, 'vsComputerStats'));
    final onlineStats = GameStats.fromJson(_extractStats(data, 'onlineStats'));

    return {
      'vsComputerStats': vsComputerStats,
      'onlineStats': onlineStats,
    };
  }

  // Helper method to safely extract stats from Firestore data
  Map<String, dynamic> _extractStats(Map<String, dynamic> data, String key) => data[key] is Map<String, dynamic> ? data[key] : <String, dynamic>{};
}