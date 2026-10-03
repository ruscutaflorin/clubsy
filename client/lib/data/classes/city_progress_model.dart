class CityProgressModel {
  final String city;
  final int visitedClubs;
  final int totalClubs;
  final DateTime? lastVisitedAt;

  CityProgressModel({
    required this.city,
    required this.visitedClubs,
    required this.totalClubs,
    this.lastVisitedAt,
  });

  factory CityProgressModel.fromMap(Map<String, dynamic> map) {
    return CityProgressModel(
      city: map['city'],
      visitedClubs: map['visitedClubs'],
      totalClubs: map['totalClubs'],
      lastVisitedAt: map['lastVisitedAt'] != null
          ? DateTime.parse(map['lastVisitedAt'])
          : null,
    );
  }

  /// 0..1 for a progress bar; 0 when the city has no approved clubs.
  double get fraction =>
      totalClubs == 0 ? 0 : (visitedClubs / totalClubs).clamp(0.0, 1.0);
}
