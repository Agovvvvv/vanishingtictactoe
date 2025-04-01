class TournamentGame {
  final String id;
  final String matchId;
  final String tournamentId;
  final String player1Id;
  final String player2Id;
  final String? winnerId;
  final String status; // 'waiting', 'in_progress', 'completed'
  final List<String> board;
  final String currentTurn;

  TournamentGame({
    required this.id,
    required this.matchId,
    required this.tournamentId,
    required this.player1Id,
    required this.player2Id,
    this.winnerId,
    required this.status,
    required this.board,
    required this.currentTurn,
  });

  factory TournamentGame.fromMap(Map<String, dynamic> map) {
    return TournamentGame(
      id: map['id'] ?? '',
      matchId: map['match_id'] ?? '',
      tournamentId: map['tournament_id'] ?? '',
      player1Id: map['player1_id'] ?? '',
      player2Id: map['player2_id'] ?? '',
      winnerId: map['winner_id'],
      status: map['status'] ?? 'waiting',
      board: (map['board'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? List.filled(9, ''),
      currentTurn: map['current_turn'] ?? 'X',
    );
  }


  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'match_id': matchId,
      'tournament_id': tournamentId,
      'player1_id': player1Id,
      'player2_id': player2Id,
      'winner_id': winnerId,
      'status': status,
      'board': board,
      'current_turn': currentTurn,
    };
  }
}
