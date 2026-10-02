class TopClubMetric {
  final String id;
  final String name;
  final int count;
  final int uniqueVisitors;

  const TopClubMetric({
    required this.id,
    required this.name,
    required this.count,
    required this.uniqueVisitors,
  });

  factory TopClubMetric.fromMap(Map<String, dynamic> map) => TopClubMetric(
    id: map['id'] as String,
    name: map['name'] as String? ?? '',
    count: (map['count'] as num?)?.toInt() ?? 0,
    uniqueVisitors: (map['uniqueVisitors'] as num?)?.toInt() ?? 0,
  );
}

class DailyMetric {
  final String date;
  final int checkIns;
  final int activeUsers;

  const DailyMetric({
    required this.date,
    required this.checkIns,
    required this.activeUsers,
  });

  factory DailyMetric.fromMap(Map<String, dynamic> map) => DailyMetric(
    date: map['date'] as String,
    checkIns: (map['checkIns'] as num?)?.toInt() ?? 0,
    activeUsers: (map['activeUsers'] as num?)?.toInt() ?? 0,
  );
}

class PilotMetricsModel {
  final int days;
  final int signups;
  final int activeCheckInUsers;
  final int checkIns;
  final int nightsOut;
  final double activationRate;
  final int returningUsers;
  final List<TopClubMetric> topClubs;
  final List<DailyMetric> daily;

  const PilotMetricsModel({
    required this.days,
    required this.signups,
    required this.activeCheckInUsers,
    required this.checkIns,
    required this.nightsOut,
    required this.activationRate,
    required this.returningUsers,
    required this.topClubs,
    required this.daily,
  });

  factory PilotMetricsModel.fromMap(Map<String, dynamic> map) {
    int i(String k) => (map[k] as num?)?.toInt() ?? 0;
    return PilotMetricsModel(
      days: i('days'),
      signups: i('signups'),
      activeCheckInUsers: i('activeCheckInUsers'),
      checkIns: i('checkIns'),
      nightsOut: i('nightsOut'),
      activationRate: (map['activationRate'] as num?)?.toDouble() ?? 0,
      returningUsers: i('returningUsers'),
      topClubs: ((map['topClubs'] as List?) ?? [])
          .map((c) => TopClubMetric.fromMap(Map<String, dynamic>.from(c)))
          .toList(),
      daily: ((map['daily'] as List?) ?? [])
          .map((d) => DailyMetric.fromMap(Map<String, dynamic>.from(d)))
          .toList(),
    );
  }
}
