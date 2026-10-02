import 'dart:async';

import 'package:get/get.dart';
import 'package:clubsy/data/classes/club_model.dart';
import 'package:clubsy/data/classes/check_in_model.dart';
import 'package:clubsy/data/classes/check_in_stats_model.dart';
import 'package:clubsy/data/classes/visit_summary.dart';
import 'package:clubsy/services/api_client.dart';
import 'package:clubsy/services/club_service.dart';
import 'package:clubsy/services/local_cache.dart';
import 'package:clubsy/services/check_in_service.dart';

class ClubController extends GetxController {
  final ClubService _clubService;
  final CheckInService _checkInService;

  final LocalCache _cache;

  ClubController({
    ClubService? clubService,
    CheckInService? checkInService,
    LocalCache? cache,
  }) : _clubService = clubService ?? ClubService(),
       _checkInService = checkInService ?? CheckInService(),
       _cache = cache ?? LocalCache();

  final clubs = <ClubModel>[].obs;
  final myCheckIns = <CheckInModel>[].obs;
  final Rxn<CheckInStatsModel> stats = Rxn<CheckInStatsModel>();
  final isLoading = false.obs;
  final visitedOnly = false.obs;

  /// Why the last [refresh] failed, or null when it succeeded.
  final loadError = RxnString();

  /// True when the last failure was "no response" (no network / timeout).
  final isOffline = false.obs;

  /// When the data currently shown was last fetched from the server.
  final Rxn<DateTime> dataSavedAt = Rxn<DateTime>();

  Set<String> get visitedClubIds => myCheckIns.map((c) => c.clubId).toSet();

  VisitSummary? visitSummaryFor(String clubId) =>
      visitSummaryForClub(clubId, myCheckIns);

  @override
  void onInit() {
    super.onInit();
    _hydrate();
  }

  Future<void> _hydrate() async {
    try {
      final cached = await _cache.read();
      // A network refresh that finished first wins over the cache.
      if (cached == null || dataSavedAt.value != null) return;
      clubs.value = cached.clubs;
      myCheckIns.value = cached.checkIns;
      stats.value = cached.stats;
      dataSavedAt.value = cached.savedAt;
    } catch (_) {
      // A broken cache is not worth surfacing.
    }
  }

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
      loadError.value = null;
      isOffline.value = false;
      dataSavedAt.value = DateTime.now();
      try {
        await _cache.write(
          clubs: clubs.toList(),
          checkIns: myCheckIns.toList(),
          stats: stats.value,
          savedAt: dataSavedAt.value!,
        );
      } catch (_) {
        // Caching is best-effort.
      }
    } on ApiException catch (e) {
      // Not signed in yet (app just started): WidgetTree pages call refresh()
      // again once the user is signed in.
      if (e.message == 'Not authenticated') return;
      loadError.value = e.message;
      isOffline.value = e.statusCode == 0;
    } catch (_) {
      loadError.value = connectionErrorMessage;
      isOffline.value = true;
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
