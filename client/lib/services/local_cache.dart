import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:clubsy/data/classes/check_in_model.dart';
import 'package:clubsy/data/classes/check_in_stats_model.dart';
import 'package:clubsy/data/classes/club_model.dart';

class CachedData {
  final List<ClubModel> clubs;
  final List<CheckInModel> checkIns;
  final CheckInStatsModel? stats;
  final DateTime savedAt;

  CachedData({
    required this.clubs,
    required this.checkIns,
    required this.stats,
    required this.savedAt,
  });
}

/// Last successful clubs, check-ins and stats, so the map still shows the
/// user's pins without a connection. One key each, each with a `savedAt`.
class LocalCache {
  static const clubsKey = 'cache_clubs';
  static const checkInsKey = 'cache_check_ins';
  static const statsKey = 'cache_stats';

  Future<void> write({
    required List<ClubModel> clubs,
    required List<CheckInModel> checkIns,
    required CheckInStatsModel? stats,
    required DateTime savedAt,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    String wrap(Object? data) =>
        json.encode({'savedAt': savedAt.toIso8601String(), 'data': data});
    await prefs.setString(clubsKey, wrap(clubs.map((c) => c.toMap()).toList()));
    await prefs.setString(
      checkInsKey,
      wrap(checkIns.map((c) => c.toMap()).toList()),
    );
    if (stats != null) await prefs.setString(statsKey, wrap(stats.toMap()));
  }

  /// Returns null when nothing usable is cached.
  Future<CachedData?> read() async {
    final prefs = await SharedPreferences.getInstance();
    final rawClubs = prefs.getString(clubsKey);
    final rawCheckIns = prefs.getString(checkInsKey);
    if (rawClubs == null || rawCheckIns == null) return null;
    final clubsJson = json.decode(rawClubs) as Map<String, dynamic>;
    final checkInsJson = json.decode(rawCheckIns) as Map<String, dynamic>;
    final rawStats = prefs.getString(statsKey);
    final statsJson = rawStats == null
        ? null
        : json.decode(rawStats) as Map<String, dynamic>;
    return CachedData(
      clubs: (clubsJson['data'] as List)
          .map((e) => ClubModel.fromMap(e as Map<String, dynamic>))
          .toList(),
      checkIns: (checkInsJson['data'] as List)
          .map((e) => CheckInModel.fromMap(e as Map<String, dynamic>))
          .toList(),
      stats: statsJson == null
          ? null
          : CheckInStatsModel.fromMap(statsJson['data']),
      savedAt: DateTime.parse(clubsJson['savedAt'] as String),
    );
  }

  Future<void> clear() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(clubsKey);
      await prefs.remove(checkInsKey);
      await prefs.remove(statsKey);
    } catch (_) {
      // Nothing to clear if storage is unavailable.
    }
  }
}
