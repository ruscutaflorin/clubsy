import 'dart:async';

import 'package:get/get.dart';
import 'package:clubsy/data/classes/club_model.dart';
import 'package:clubsy/data/classes/check_in_model.dart';
import 'package:clubsy/data/classes/check_in_stats_model.dart';
import 'package:clubsy/data/classes/visit_summary.dart';
import 'package:clubsy/services/club_service.dart';
import 'package:clubsy/services/check_in_service.dart';

class ClubController extends GetxController {
  final ClubService _clubService;
  final CheckInService _checkInService;

  ClubController({ClubService? clubService, CheckInService? checkInService})
    : _clubService = clubService ?? ClubService(),
      _checkInService = checkInService ?? CheckInService();

  final clubs = <ClubModel>[].obs;
  final myCheckIns = <CheckInModel>[].obs;
  final Rxn<CheckInStatsModel> stats = Rxn<CheckInStatsModel>();
  final isLoading = false.obs;
  final visitedOnly = false.obs;

  Set<String> get visitedClubIds => myCheckIns.map((c) => c.clubId).toSet();

  VisitSummary? visitSummaryFor(String clubId) =>
      visitSummaryForClub(clubId, myCheckIns);

  @override
  Future<void> refresh() async {
    isLoading.value = true;
    try {
      final results = await Future.wait([
        _clubService.getClubs(),
        _checkInService.getMyCheckIns(),
        _checkInService.getMyStats(),
      ]);
      clubs.value = results[0] as List<ClubModel>;
      myCheckIns.value = results[1] as List<CheckInModel>;
      stats.value = results[2] as CheckInStatsModel;
    } catch (_) {
      // Not authenticated yet (app just started, user hasn't logged in) —
      // WidgetTree pages call refresh() again once the user is signed in.
    } finally {
      isLoading.value = false;
    }
  }

  Future<CheckInModel> checkIn({
    required String clubId,
    required String qrPayload,
    required double latitude,
    required double longitude,
    bool? isMocked,
    double? accuracyMeters,
  }) async {
    final checkInRecord = await _checkInService.checkIn(
      clubId: clubId,
      qrPayload: qrPayload,
      latitude: latitude,
      longitude: longitude,
      isMocked: isMocked,
      accuracyMeters: accuracyMeters,
    );
    myCheckIns.insert(0, checkInRecord);
    // Fire and forget: the success UI must not wait on (or fail with) stats.
    unawaited(_refreshStats());
    return checkInRecord;
  }

  Future<void> _refreshStats() async {
    try {
      stats.value = await _checkInService.getMyStats();
    } catch (_) {
      // Stale stats are fixed by the next full refresh().
    }
  }
}
