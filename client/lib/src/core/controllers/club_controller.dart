import 'package:get/get.dart';
import 'package:clubsy/data/classes/club_model.dart';
import 'package:clubsy/data/classes/check_in_model.dart';
import 'package:clubsy/data/classes/check_in_stats_model.dart';
import 'package:clubsy/services/club_service.dart';
import 'package:clubsy/services/check_in_service.dart';

class ClubController extends GetxController {
  final _clubService = ClubService();
  final _checkInService = CheckInService();

  final clubs = <ClubModel>[].obs;
  final myCheckIns = <CheckInModel>[].obs;
  final Rxn<CheckInStatsModel> stats = Rxn<CheckInStatsModel>();
  final isLoading = false.obs;

  Set<String> get visitedClubIds => myCheckIns.map((c) => c.clubId).toSet();

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
  }) async {
    final checkInRecord = await _checkInService.checkIn(
      clubId: clubId,
      qrPayload: qrPayload,
      latitude: latitude,
      longitude: longitude,
    );
    myCheckIns.insert(0, checkInRecord);
    return checkInRecord;
  }
}
