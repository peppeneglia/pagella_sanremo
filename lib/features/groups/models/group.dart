class Group {
  final String id;
  final String name;
  final String emoji;
  final String code;
  final String ownerId;
  final DateTime createdAt;
  final int memberCount;

  Group({
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

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'emoji': emoji,
      'code': code,
      'owner_id': ownerId,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

class GroupMember {
  final String id;
  final String groupId;
  final String userId;
  final String username;
  final String? email;
  final DateTime joinedAt;
  final double? averageScore;
  final int totalVotes;

  GroupMember({
    required this.id,
    required this.groupId,
    required this.userId,
    required this.username,
    this.email,
    required this.joinedAt,
    this.averageScore,
    this.totalVotes = 0,
  });

  factory GroupMember.fromMap(Map<String, dynamic> map) {
    return GroupMember(
      id: map['id'] as String,
      groupId: map['group_id'] as String,
      userId: map['user_id'] as String,
      username: map['username'] as String? ?? 'Utente',
      email: map['email'] as String?,
      joinedAt: DateTime.parse(map['joined_at'] as String),
      averageScore: (map['average_score'] as num?)?.toDouble(),
      totalVotes: map['total_votes'] as int? ?? 0,
    );
  }
}

class MemberArtistVote {
  final String username;
  final double? canto;
  final double? testo;
  final double? look;

  MemberArtistVote({
    required this.username,
    this.canto,
    this.testo,
    this.look,
  });

  double? get average {
    final scores = [canto, testo, look].whereType<double>().toList();
    if (scores.isEmpty) return null;
    return scores.reduce((a, b) => a + b) / scores.length;
  }
}
