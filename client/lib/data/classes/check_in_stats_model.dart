class MostVisitedClub {
  final String id;
  final String name;
  final int visits;

  MostVisitedClub({required this.id, required this.name, required this.visits});

  factory MostVisitedClub.fromMap(Map<String, dynamic> map) {
    return MostVisitedClub(
      id: map['id'],
      name: map['name'],
      visits: map['visits'],
    );
  }
}

class CheckInStatsModel {
  final int totalCheckIns;
  final int uniqueClubs;
  final int uniqueCities;
  final MostVisitedClub? mostVisitedClub;
  final DateTime? firstCheckInAt;

  CheckInStatsModel({
    required this.totalCheckIns,
    required this.uniqueClubs,
    required this.uniqueCities,
    this.mostVisitedClub,
    this.firstCheckInAt,
  });

  factory CheckInStatsModel.fromMap(Map<String, dynamic> map) {
    return CheckInStatsModel(
      totalCheckIns: map['totalCheckIns'],
      uniqueClubs: map['uniqueClubs'],
      uniqueCities: map['uniqueCities'],
      mostVisitedClub: map['mostVisitedClub'] != null
          ? MostVisitedClub.fromMap(map['mostVisitedClub'])
          : null,
      firstCheckInAt: map['firstCheckInAt'] != null
          ? DateTime.parse(map['firstCheckInAt'])
          : null,
    );
  }
}
