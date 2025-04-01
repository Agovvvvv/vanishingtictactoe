import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:vanishingtictactoe/features/tournament/models/tournament_match.dart';
import 'package:vanishingtictactoe/features/tournament/models/tournament_player.dart';

class Tournament {
  final String id;
  final String creatorId;
  final List<TournamentPlayer> players;
  final List<TournamentMatch> matches;
  final String status; // 'waiting', 'in_progress', 'completed'
  final DateTime createdAt;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final String? winnerId;
  final String code; // Join code for the tournament

  Tournament({
    required this.id,
    required this.creatorId,
    required this.players,
    required this.matches,
    required this.status,
    required this.createdAt,
    this.startedAt,
    this.completedAt,
    this.winnerId,
    required this.code,
  });

  factory Tournament.fromMap(String id, Map<String, dynamic> map) {
    return Tournament(
      id: id,
      creatorId: map['creator_id'] ?? '',
      players: (map['players'] as List<dynamic>?)
              ?.map((player) => TournamentPlayer.fromMap(player))
              .toList() ??
          [],
      matches: (map['matches'] as List<dynamic>?)
              ?.map((match) => TournamentMatch.fromMap(match))
              .toList() ??
          [],
      status: map['status'] ?? 'waiting',
      createdAt: (map['created_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
      startedAt: (map['started_at'] as Timestamp?)?.toDate(),
      completedAt: (map['completed_at'] as Timestamp?)?.toDate(),
      winnerId: map['winner_id'],
      code: map['code'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'creator_id': creatorId,
      'players': players.map((player) => player.toMap()).toList(),
      'matches': matches.map((match) => match.toMap()).toList(),
      'status': status,
      'created_at': Timestamp.fromDate(createdAt),
      'started_at': startedAt != null ? Timestamp.fromDate(startedAt!) : null,
      'completed_at': completedAt != null ? Timestamp.fromDate(completedAt!) : null,
      'winner_id': winnerId,
      'code': code,
    };
  }

  Tournament copyWith({
    String? id,
    String? creatorId,
    List<TournamentPlayer>? players,
    List<TournamentMatch>? matches,
    String? status,
    DateTime? createdAt,
    DateTime? startedAt,
    DateTime? completedAt,
    String? winnerId,
    String? code,
  }) {
    return Tournament(
      id: id ?? this.id,
      creatorId: creatorId ?? this.creatorId,
      players: players ?? this.players,
      matches: matches ?? this.matches,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      winnerId: winnerId ?? this.winnerId,
      code: code ?? this.code,
    );
  }
}




