class Group {
  final String id;
  final String name;
  final String emoji;
  final String code;
  final String ownerId;
  final DateTime createdAt;
  final int memberCount;

  const Group({
    required this.id,
    required this.name,
    required this.emoji,
    required this.code,
    required this.ownerId,
    required this.createdAt,
    this.memberCount = 0,
  });

  factory Group.fromMap(Map<String, dynamic> map) {
    return Group(
      id: map['id'] as String,
      name: map['name'] as String,
      emoji: map['emoji'] as String? ?? '👥',
      code: map['code'] as String,
      ownerId: map['owner_id'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
      memberCount: map['member_count'] as int? ?? 0,
    );
  }
}

/// Voto di un singolo membro del gruppo per un artista in una serata.
class MemberArtistVote {
  final String username;
  final double? canto;
  final double? testo;
  final double? look;

  const MemberArtistVote({
    required this.username,
    this.canto,
    this.testo,
    this.look,
  });

  /// Media delle categorie votate, `null` se nessuna categoria ha un voto.
  double? get average {
    final scores = [canto, testo, look].whereType<double>().toList();
    if (scores.isEmpty) return null;
    return scores.reduce((a, b) => a + b) / scores.length;
  }
}
