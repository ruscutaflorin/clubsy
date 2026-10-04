/// One friend's past night: the club and the night's date, never a time.
class FeedNight {
  final String id;
  final String nightDate;
  final String clubId;
  final String clubName;
  final String? city;
  final String friendLabel;

  const FeedNight({
    required this.id,
    required this.nightDate,
    required this.clubId,
    required this.clubName,
    required this.city,
    required this.friendLabel,
  });

  factory FeedNight.fromMap(Map<String, dynamic> map) {
    final club = map['club'] as Map<String, dynamic>;
    final user = (map['user'] as Map<String, dynamic>?) ?? const {};
    final username = user['username'] as String?;
    return FeedNight(
      id: map['id'] as String,
      nightDate: map['nightDate'] as String,
      clubId: club['id'] as String,
      clubName: club['name'] as String,
      city: club['city'] as String?,
      friendLabel: username != null
          ? '@$username'
          : (user['name'] as String?) ?? '',
    );
  }
}

class FeedPage {
  final List<FeedNight> nights;
  final bool hasMore;

  /// Clubs both viewer and friend have been to; only sent for a friend's page 1.
  final int sharedClubCount;

  const FeedPage({
    this.nights = const [],
    this.hasMore = false,
    this.sharedClubCount = 0,
  });

  factory FeedPage.fromMap(Map<String, dynamic> map) => FeedPage(
    nights: ((map['nights'] as List?) ?? [])
        .map((e) => FeedNight.fromMap(e as Map<String, dynamic>))
        .toList(),
    hasMore: map['hasMore'] == true,
    sharedClubCount: (map['sharedClubCount'] as num?)?.toInt() ?? 0,
  );
}
