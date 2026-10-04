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

class DistanceHealth {
  final int count;
  final int? medianMeters;
  final int? p90Meters;
  final double? nearLimitShare;
  final String status;

  const DistanceHealth({
    required this.count,
    this.medianMeters,
    this.p90Meters,
    this.nearLimitShare,
    required this.status,
  });

  factory DistanceHealth.fromMap(Map<String, dynamic> map) => DistanceHealth(
    count: (map['count'] as num?)?.toInt() ?? 0,
    medianMeters: (map['medianMeters'] as num?)?.toInt(),
    p90Meters: (map['p90Meters'] as num?)?.toInt(),
    nearLimitShare: (map['nearLimitShare'] as num?)?.toDouble(),
    status: map['status'] as String? ?? 'insufficient',
  );
}

class VibeSummary {
  final int count;
  final double? average;
  final List<int>? distribution;

  const VibeSummary({required this.count, this.average, this.distribution});

  factory VibeSummary.fromMap(Map<String, dynamic> map) => VibeSummary(
    count: (map['count'] as num?)?.toInt() ?? 0,
    average: (map['average'] as num?)?.toDouble(),
    distribution: map['distribution'] is List
        ? (map['distribution'] as List).map((n) => (n as num).toInt()).toList()
        : null,
  );
}

class VisitFrequency {
  final int once;
  final int twice;
  final int threePlus;

  const VisitFrequency({this.once = 0, this.twice = 0, this.threePlus = 0});

  factory VisitFrequency.fromMap(Map<String, dynamic> map) => VisitFrequency(
    once: (map['once'] as num?)?.toInt() ?? 0,
    twice: (map['twice'] as num?)?.toInt() ?? 0,
    threePlus: (map['threePlus'] as num?)?.toInt() ?? 0,
  );
}

class ClubFootfallModel {
  final int totalCheckIns;
  final int uniqueVisitors;
  final double returningVisitorRate;
  final double firstTimeShare;
  final List<FootfallWeek> weekly;
  final List<int> byWeekday;
  final DistanceHealth? distance;
  final VibeSummary? vibe;
  final VisitFrequency visitFrequency;

  const ClubFootfallModel({
    this.visitFrequency = const VisitFrequency(),
    this.distance,
    this.vibe,
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
        distance: map['distance'] is Map
            ? DistanceHealth.fromMap(Map<String, dynamic>.from(map['distance']))
            : null,
        visitFrequency: map['visitFrequency'] is Map
            ? VisitFrequency.fromMap(
                Map<String, dynamic>.from(map['visitFrequency']),
              )
            : const VisitFrequency(),
        vibe: map['vibe'] is Map
            ? VibeSummary.fromMap(Map<String, dynamic>.from(map['vibe']))
            : null,
      );
}
