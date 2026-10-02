class ScorecardCriterion {
  final String id;
  final String label;
  final num? value;
  final num target;
  final bool met;

  const ScorecardCriterion({
    required this.id,
    required this.label,
    required this.value,
    required this.target,
    required this.met,
  });

  factory ScorecardCriterion.fromMap(Map<String, dynamic> map) =>
      ScorecardCriterion(
        id: map['id'] as String,
        label: map['label'] as String? ?? '',
        value: map['value'] as num?,
        target: map['target'] as num? ?? 0,
        met: map['met'] as bool? ?? false,
      );
}

class WacuWeek {
  final String weekStart;
  final int activeUsers;

  const WacuWeek({required this.weekStart, required this.activeUsers});

  factory WacuWeek.fromMap(Map<String, dynamic> map) => WacuWeek(
    weekStart: map['weekStart'] as String? ?? '',
    activeUsers: (map['activeUsers'] as num?)?.toInt() ?? 0,
  );
}

class PilotScorecardModel {
  final List<ScorecardCriterion> criteria;
  final List<WacuWeek> wacu;

  const PilotScorecardModel({required this.criteria, required this.wacu});

  factory PilotScorecardModel.fromMap(Map<String, dynamic> map) =>
      PilotScorecardModel(
        criteria: ((map['criteria'] as List?) ?? [])
            .map(
              (c) => ScorecardCriterion.fromMap(Map<String, dynamic>.from(c)),
            )
            .toList(),
        wacu: ((map['wacu'] as List?) ?? [])
            .map((w) => WacuWeek.fromMap(Map<String, dynamic>.from(w)))
            .toList(),
      );
}
