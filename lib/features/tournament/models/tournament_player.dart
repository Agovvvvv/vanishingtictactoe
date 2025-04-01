class TournamentPlayer {
  final String id;
  final String name;
  final String? avatarUrl;
  final bool isReady; // For starting matches
  final int seed; // For bracket positioning

  TournamentPlayer({
    required this.id,
    required this.name,
    this.avatarUrl,
    this.isReady = false,
    required this.seed,
  });

  factory TournamentPlayer.fromMap(Map<String, dynamic> map) {
    return TournamentPlayer(
      id: map['id'] ?? '',
      name: map['name'] ?? 'Player',
      avatarUrl: map['avatar_url'],
      isReady: map['is_ready'] ?? false,
      seed: map['seed'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'avatar_url': avatarUrl,
      'is_ready': isReady,
      'seed': seed,
    };
  }

  TournamentPlayer copyWith({
    String? id,
    String? name,
    String? avatarUrl,
    bool? isReady,
    int? seed,
  }) {
    return TournamentPlayer(
      id: id ?? this.id,
      name: name ?? this.name,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      isReady: isReady ?? this.isReady,
      seed: seed ?? this.seed,
    );
  }
}
