class FootfallWeek {
  final String weekStart;
  final int checkIns;
  final int uniqueVisitors;

  const FootfallWeek({
    required this.weekStart,
    required this.checkIns,
    required this.uniqueVisitors,
  });

  factory FootfallWeek.fromMap(Map<String, dynamic> map) => FootfallWeek(
    weekStart: map['weekStart'] as String? ?? '',
    checkIns: (map['checkIns'] as num?)?.toInt() ?? 0,
    uniqueVisitors: (map['uniqueVisitors'] as num?)?.toInt() ?? 0,
  );
}

class ClubFootfallModel {
  final int totalCheckIns;
  final int uniqueVisitors;
  final double returningVisitorRate;
  final double firstTimeShare;
  final List<FootfallWeek> weekly;
  final List<int> byWeekday;

  const ClubFootfallModel({
    required this.totalCheckIns,
    required this.uniqueVisitors,
    required this.returningVisitorRate,
    required this.firstTimeShare,
    required this.weekly,
    required this.byWeekday,
  });

  factory ClubFootfallModel.fromMap(Map<String, dynamic> map) =>
      ClubFootfallModel(
        totalCheckIns: (map['totalCheckIns'] as num?)?.toInt() ?? 0,
        uniqueVisitors: (map['uniqueVisitors'] as num?)?.toInt() ?? 0,
        returningVisitorRate:
            (map['returningVisitorRate'] as num?)?.toDouble() ?? 0,
        firstTimeShare: (map['firstTimeShare'] as num?)?.toDouble() ?? 0,
        weekly: ((map['weekly'] as List?) ?? [])
            .map((w) => FootfallWeek.fromMap(Map<String, dynamic>.from(w)))
            .toList(),
        byWeekday: ((map['byWeekday'] as List?) ?? [])
            .map((n) => (n as num).toInt())
            .toList(),
      );
}
