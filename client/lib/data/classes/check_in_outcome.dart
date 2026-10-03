import 'package:clubsy/data/classes/check_in_model.dart';

/// What a check-in meant for the user's map, computed from the history as it
/// was *before* the new record was added.
class CheckInOutcome {
  final bool isFirstVisit;
  final int visitNumber;
  final int totalClubsVisited;
  final bool isNewCity;

  /// The city of the club, shown in the "first in Cluj" line.
  final String? city;

  const CheckInOutcome({
    required this.isFirstVisit,
    required this.visitNumber,
    required this.totalClubsVisited,
    required this.isNewCity,
    this.city,
  });
}

/// [city] is the checked-in club's city; without it [CheckInOutcome.isNewCity]
/// is never true.
CheckInOutcome checkInOutcome(
  String clubId,
  List<CheckInModel> previousCheckIns, {
  String? city,
}) {
  final earlierVisits = previousCheckIns
      .where((c) => c.clubId == clubId)
      .length;
  final isFirstVisit = earlierVisits == 0;
  final visitedIds = previousCheckIns.map((c) => c.clubId).toSet();
  final cityKey = city?.trim().toLowerCase();
  final seenCity =
      cityKey == null ||
      previousCheckIns.any((c) => c.club.city.trim().toLowerCase() == cityKey);
  return CheckInOutcome(
    isFirstVisit: isFirstVisit,
    visitNumber: earlierVisits + 1,
    totalClubsVisited: visitedIds.length + (isFirstVisit ? 1 : 0),
    isNewCity: !seenCity,
    city: city,
  );
}
