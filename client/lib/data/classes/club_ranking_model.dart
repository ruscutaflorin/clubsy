class ClubRankingEntry {
  final String id;
  final String name;
  final String city;
  final int checkIns;
  final int uniqueVisitors;
  final int previousCheckIns;
  final int change;

  const ClubRankingEntry({
    required this.id,
    required this.name,
    required this.city,
    required this.checkIns,
    required this.uniqueVisitors,
    required this.previousCheckIns,
    required this.change,
  });

  factory ClubRankingEntry.fromJson(Map<String, dynamic> json) =>
      ClubRankingEntry(
        id: json['id'] as String,
        name: json['name'] as String,
        city: (json['city'] as String?) ?? '',
        checkIns: (json['checkIns'] as num?)?.toInt() ?? 0,
        uniqueVisitors: (json['uniqueVisitors'] as num?)?.toInt() ?? 0,
        previousCheckIns: (json['previousCheckIns'] as num?)?.toInt() ?? 0,
        change: (json['change'] as num?)?.toInt() ?? 0,
      );
}

class ClubRankingModel {
  final int weeks;
  final List<ClubRankingEntry> clubs;

  const ClubRankingModel({required this.weeks, required this.clubs});

  factory ClubRankingModel.fromJson(Map<String, dynamic> json) =>
      ClubRankingModel(
        weeks: (json['weeks'] as num?)?.toInt() ?? 4,
        clubs: ((json['clubs'] as List?) ?? [])
            .map((c) => ClubRankingEntry.fromJson(Map<String, dynamic>.from(c)))
            .toList(),
      );
}
