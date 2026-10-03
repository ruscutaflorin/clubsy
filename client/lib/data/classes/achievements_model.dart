class BadgeModel {
  final String id;
  final String title;
  final String description;
  final DateTime? earnedAt;
  final int current;
  final int target;

  const BadgeModel({
    required this.id,
    required this.title,
    required this.description,
    this.earnedAt,
    this.current = 0,
    this.target = 1,
  });

  bool get earned => earnedAt != null;

  factory BadgeModel.fromMap(Map<String, dynamic> map) {
    final progress = (map['progress'] as Map?) ?? const {};
    final earnedAt = map['earnedAt'] as String?;
    return BadgeModel(
      id: map['id'] as String,
      title: map['title'] as String,
      description: (map['description'] as String?) ?? '',
      earnedAt: earnedAt == null ? null : DateTime.parse(earnedAt).toLocal(),
      current: (progress['current'] as num?)?.toInt() ?? 0,
      target: (progress['target'] as num?)?.toInt() ?? 1,
    );
  }
}

class ChallengeModel {
  final String id;
  final String title;
  final int current;
  final int target;
  final bool completed;
  final DateTime? endsAt;

  const ChallengeModel({
    required this.id,
    required this.title,
    required this.current,
    required this.target,
    required this.completed,
    this.endsAt,
  });

  factory ChallengeModel.fromMap(Map<String, dynamic> map) {
    final progress = (map['progress'] as Map?) ?? const {};
    final endsAt = map['endsAt'] as String?;
    return ChallengeModel(
      id: map['id'] as String,
      title: map['title'] as String,
      current: (progress['current'] as num?)?.toInt() ?? 0,
      target: (progress['target'] as num?)?.toInt() ?? 1,
      completed: map['completed'] == true,
      endsAt: endsAt == null ? null : DateTime.parse(endsAt).toLocal(),
    );
  }
}

class AchievementsModel {
  final int currentStreak;
  final int longestStreak;
  final bool streakAtRisk;
  final List<BadgeModel> badges;
  final List<ChallengeModel> challenges;
  final int points;

  const AchievementsModel({
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.streakAtRisk = false,
    this.badges = const [],
    this.challenges = const [],
    this.points = 0,
  });

  int get earnedCount => badges.where((b) => b.earned).length;

  factory AchievementsModel.fromMap(Map<String, dynamic> map) {
    final streak = (map['streak'] as Map?) ?? const {};
    return AchievementsModel(
      currentStreak: (streak['current'] as num?)?.toInt() ?? 0,
      longestStreak: (streak['longest'] as num?)?.toInt() ?? 0,
      streakAtRisk: streak['atRisk'] == true,
      badges: ((map['badges'] as List?) ?? const [])
          .map((b) => BadgeModel.fromMap(Map<String, dynamic>.from(b as Map)))
          .toList(),
      challenges: ((map['challenges'] as List?) ?? const [])
          .map(
            (c) => ChallengeModel.fromMap(Map<String, dynamic>.from(c as Map)),
          )
          .toList(),
      points: (map['points'] as num?)?.toInt() ?? 0,
    );
  }
}

/// Badges earned in [after] that weren't in [before]. Nothing is "new" when
/// there is no earlier snapshot to compare with.
List<BadgeModel> newlyEarned(
  AchievementsModel? before,
  AchievementsModel? after,
) {
  if (before == null || after == null) return const [];
  final had = before.badges.where((b) => b.earned).map((b) => b.id).toSet();
  return after.badges.where((b) => b.earned && !had.contains(b.id)).toList();
}

String badgeUnlockedText(BadgeModel badge) => 'Badge unlocked: ${badge.title}';
