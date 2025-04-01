class TournamentMatch {
  final String id;
  final String tournamentId;
  final String player1Id;
  final String player2Id;
  final String? winnerId;
  final String status; // 'waiting', 'in_progress', 'completed'
  final int round; // 1 for semifinals, 2 for final
  final int matchNumber; // 1 or 2 for semifinals, 1 for final
  final List<String> gameIds; // IDs of the individual games (best of 3)
  final int player1Wins;
  final int player2Wins;
  final bool player1Ready;
  final bool player2Ready;

  TournamentMatch({
    required this.id,
    required this.tournamentId,
    required this.player1Id,
    required this.player2Id,
    this.winnerId,
    required this.status,
    required this.round,
    required this.matchNumber,
    required this.gameIds,
    this.player1Wins = 0,
    this.player2Wins = 0,
    this.player1Ready = false,
    this.player2Ready = false,
  });

  factory TournamentMatch.fromMap(Map<String, dynamic> map) {
    return TournamentMatch(
      id: map['id'] ?? '',
      tournamentId: map['tournament_id'] ?? '',
      player1Id: map['player1_id'] ?? '',
      player2Id: map['player2_id'] ?? '',
      winnerId: map['winner_id'],
      status: map['status'] ?? 'waiting',
      round: map['round'] ?? 1,
      matchNumber: map['match_number'] ?? 1,
      gameIds: (map['game_ids'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      player1Wins: map['player1_wins'] ?? 0,
      player2Wins: map['player2_wins'] ?? 0,
      player1Ready: map['player1_ready'] ?? false,
      player2Ready: map['player2_ready'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'tournament_id': tournamentId,
      'player1_id': player1Id,
      'player2_id': player2Id,
      'winner_id': winnerId,
      'status': status,
      'round': round,
      'match_number': matchNumber,
      'game_ids': gameIds,
      'player1_wins': player1Wins,
      'player2_wins': player2Wins,
      'player1_ready': player1Ready,
      'player2_ready': player2Ready,
    };
  }

  TournamentMatch copyWith({
    String? id,
    String? tournamentId,
    String? player1Id,
    String? player2Id,
    String? winnerId,
    String? status,
    int? round,
    int? matchNumber,
    List<String>? gameIds,
    int? player1Wins,
    int? player2Wins,
    bool? player1Ready,
    bool? player2Ready,
  }) {
    return TournamentMatch(
      id: id ?? this.id,
      tournamentId: tournamentId ?? this.tournamentId,
      player1Id: player1Id ?? this.player1Id,
      player2Id: player2Id ?? this.player2Id,
      winnerId: winnerId ?? this.winnerId,
      status: status ?? this.status,
      round: round ?? this.round,
      matchNumber: matchNumber ?? this.matchNumber,
      gameIds: gameIds ?? this.gameIds,
      player1Wins: player1Wins ?? this.player1Wins,
      player2Wins: player2Wins ?? this.player2Wins,
      player1Ready: player1Ready ?? this.player1Ready,
      player2Ready: player2Ready ?? this.player2Ready,
    );
  }
}