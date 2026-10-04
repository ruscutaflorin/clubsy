import 'dart:async';

import 'package:get/get.dart';
import 'package:clubsy/data/classes/achievements_model.dart';
import 'package:clubsy/data/classes/club_model.dart';
import 'package:clubsy/data/classes/check_in_model.dart';
import 'package:clubsy/data/classes/check_in_outcome.dart';
import 'package:clubsy/data/classes/check_in_stats_model.dart';
import 'package:clubsy/data/classes/genre_taste.dart';
import 'package:clubsy/data/classes/city_progress_model.dart';
import 'package:clubsy/data/classes/vibe_prompt.dart';
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
  final Rxn<AchievementsModel> achievements = Rxn<AchievementsModel>();

  /// Session-only: the streak nudge stays hidden once dismissed.
  final streakNudgeDismissed = false.obs;
  final cityProgress = <CityProgressModel>[].obs;
  final isLoading = false.obs;
  final visitedOnly = false.obs;

  /// The "Want to go" map filter; takes precedence over [visitedOnly].
  final wantToGoOnly = false.obs;

  /// Ids of the caller's favourite clubs, kept in step with the server.
  final favoriteIds = <String>{}.obs;

  /// Why the last [refresh] failed, or null when it succeeded.
  final loadError = RxnString();

  /// True when the last failure was "no response" (no network / timeout).
  final isOffline = false.obs;

  /// When the data currently shown was last fetched from the server.
  final Rxn<DateTime> dataSavedAt = Rxn<DateTime>();

  /// Set by the check-in success sheet's "View on map"; the map page centres
  /// on it and clears it.
  final Rxn<ClubModel> focusedClub = Rxn<ClubModel>();

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
      _syncFavorites();
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
        _loadAchievements(),
        _loadCityProgress(),
      ]);
      clubs.value = results[0] as List<ClubModel>;
      _syncFavorites();
      myCheckIns.value = results[1] as List<CheckInModel>;
      stats.value = results[2] as CheckInStatsModel;
      achievements.value =
          results[3] as AchievementsModel? ?? achievements.value;
      cityProgress.value =
          results[4] as List<CityProgressModel>? ?? cityProgress.toList();
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

  void _syncFavorites() {
    favoriteIds.assignAll([
      for (final club in clubs)
        if (club.isFavorite) club.id,
    ]);
  }

  /// Hearts or un-hearts a club. Optimistic: the set changes at once and is
  /// restored (rethrowing) if the server call fails.
  Future<void> toggleFavorite(String clubId) async {
    final wasFavorite = favoriteIds.contains(clubId);
    if (wasFavorite) {
      favoriteIds.remove(clubId);
    } else {
      favoriteIds.add(clubId);
    }
    try {
      await _clubService.setFavorite(clubId, !wasFavorite);
    } catch (_) {
      if (wasFavorite) {
        favoriteIds.add(clubId);
      } else {
        favoriteIds.remove(clubId);
      }
      rethrow;
    }
  }

  Future<
    ({
      CheckInModel record,
      CheckInOutcome outcome,
      List<BadgeModel> unlocked,
      bool tickedOffList,
      List<String> newGenres,
    })
  >
  checkIn({
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
    // Computed before the new record joins the history.
    final outcome = checkInOutcome(
      clubId,
      myCheckIns.toList(),
      city: checkInRecord.club.city,
    );
    var genres = checkInRecord.club.genres;
    if (genres.isEmpty) {
      genres = clubs.firstWhereOrNull((c) => c.id == clubId)?.genres ?? [];
    }
    // A first-ever check-in isn't a "first" for every genre.
    final firstGenres = myCheckIns.isEmpty
        ? <String>[]
        : newGenres(genres, myCheckIns.toList());
    myCheckIns.insert(0, checkInRecord);
    // Fire and forget: the success UI must not wait on (or fail with) stats.
    unawaited(_refreshStats());
    final before = achievements.value;
    final after = await _loadAchievements();
    if (after != null) achievements.value = after;
    return (
      record: checkInRecord,
      outcome: outcome,
      unlocked: newlyEarned(before, after),
      tickedOffList: outcome.isFirstVisit && favoriteIds.contains(clubId),
      newGenres: firstGenres,
    );
  }

  /// Check-ins whose morning "How was it?" card was skipped this session.
  final dismissedVibeIds = <String>{}.obs;

  CheckInModel? get vibePrompt => pendingVibePrompt(
    myCheckIns,
    DateTime.now(),
    dismissedIds: dismissedVibeIds.toSet(),
  );

  /// Saves a note and/or vibe on a check-in. Optimistic: the list updates at
  /// once and is restored (rethrowing) if the server call fails.
  Future<void> updateDiary(String id, {String? note, int? vibe}) async {
    final index = myCheckIns.indexWhere((c) => c.id == id);
    if (index < 0) return;
    final before = myCheckIns[index];
    myCheckIns[index] = before.withDiary(
      note: note == null
          ? before.note
          : (note.trim().isEmpty ? null : note.trim()),
      vibe: vibe ?? before.vibe,
    );
    try {
      final saved = await _checkInService.updateCheckIn(
        id,
        note: note,
        vibe: vibe,
      );
      final i = myCheckIns.indexWhere((c) => c.id == id);
      if (i >= 0) myCheckIns[i] = saved;
    } catch (_) {
      final i = myCheckIns.indexWhere((c) => c.id == id);
      if (i >= 0) myCheckIns[i] = before;
      rethrow;
    }
  }

  /// Hides or shows one check-in for friends. Optimistic, restored (rethrowing)
  /// if the server call fails.
  Future<void> setHiddenFromFriends(String id, bool hidden) async {
    final index = myCheckIns.indexWhere((c) => c.id == id);
    if (index < 0) return;
    final before = myCheckIns[index];
    myCheckIns[index] = before.withHidden(hidden);
    try {
      final saved = await _checkInService.updateCheckIn(
        id,
        hiddenFromFriends: hidden,
      );
      final i = myCheckIns.indexWhere((c) => c.id == id);
      if (i >= 0) myCheckIns[i] = saved;
    } catch (_) {
      final i = myCheckIns.indexWhere((c) => c.id == id);
      if (i >= 0) myCheckIns[i] = before;
      rethrow;
    }
  }

  /// Removes a check-in from the map. Optimistic: the list updates at once and
  /// is restored (rethrowing) if the server call fails.
  Future<void> removeCheckIn(String id) async {
    final index = myCheckIns.indexWhere((c) => c.id == id);
    if (index < 0) return;
    final removed = myCheckIns[index];
    myCheckIns.removeAt(index);
    try {
      await _checkInService.deleteCheckIn(id);
    } catch (_) {
      myCheckIns.insert(index.clamp(0, myCheckIns.length), removed);
      rethrow;
    }
    await _refreshStats();
    final after = await _loadAchievements();
    if (after != null) achievements.value = after;
  }

  /// Null when achievements can't be loaded: they're never worth failing a
  /// refresh or a check-in over.
  Future<AchievementsModel?> _loadAchievements() async {
    try {
      return await _checkInService.getMyAchievements();
    } catch (_) {
      return null;
    }
  }

  /// Null when city progress can't be loaded: not worth failing a refresh over.
  Future<List<CityProgressModel>?> _loadCityProgress() async {
    try {
      return await _checkInService.getMyCities();
    } catch (_) {
      return null;
    }
  }

  Future<void> _refreshStats() async {
    try {
      stats.value = await _checkInService.getMyStats();
      final cities = await _loadCityProgress();
      if (cities != null) cityProgress.value = cities;
    } catch (_) {
      // Stale stats are fixed by the next full refresh().
    }
  }
}
