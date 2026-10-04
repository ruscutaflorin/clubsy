import 'package:clubsy/data/classes/club_data_health_model.dart';
import 'package:clubsy/data/classes/club_footfall_model.dart';
import 'package:clubsy/data/classes/club_model.dart';
import 'package:clubsy/data/classes/club_ranking_model.dart';
import 'package:clubsy/data/classes/pilot_metrics_model.dart';
import 'package:clubsy/data/classes/pilot_scorecard_model.dart';
import 'package:clubsy/services/api_client.dart';
import 'package:clubsy/services/auth_service.dart';

class AdminService {
  final ApiClient _api;

  AdminService({ApiClient? api})
    : _api = api ?? ApiClient(tokenProvider: AuthService().getToken);

  /// Every club, approved or not (the server returns all of them to admins).
  Future<List<ClubModel>> listAllClubs() async {
    final clubs = <ClubModel>[];
    var page = 1;
    var pages = 1;
    do {
      final data = await _api.get(
        '/clubs',
        query: {'limit': '50', 'page': '$page'},
      );
      clubs.addAll((data['clubs'] as List).map((c) => ClubModel.fromMap(c)));
      pages = (data['pages'] as num?)?.toInt() ?? 1;
      page++;
    } while (page <= pages);
    return clubs;
  }

  /// Creates a club; the response also carries its freshly generated QR.
  Future<({ClubModel club, String? qrCode})> createClub(
    Map<String, dynamic> fields,
  ) async {
    final data = await _api.post('/clubs', body: fields);
    return (
      club: ClubModel.fromMap(Map<String, dynamic>.from(data)),
      qrCode: data['qrCode'] as String?,
    );
  }

  Future<ClubModel> updateClub(String id, Map<String, dynamic> fields) async {
    final data = await _api.patch('/clubs/$id', body: fields);
    return ClubModel.fromMap(Map<String, dynamic>.from(data));
  }

  Future<void> approve(String id) => _api.patch('/clubs/$id/approve');

  Future<void> unapprove(String id) => _api.patch('/clubs/$id/unapprove');

  Future<String> getQr(String id) async {
    final data = await _api.get('/clubs/$id/qr');
    return data['qrCode'] as String;
  }

  Future<PilotMetricsModel> getMetrics(int days) async {
    final data = await _api.get('/admin/metrics', query: {'days': '$days'});
    return PilotMetricsModel.fromMap(Map<String, dynamic>.from(data));
  }

  Future<PilotScorecardModel> getPilotScorecard() async {
    final data = await _api.get('/admin/metrics/scorecard');
    return PilotScorecardModel.fromMap(Map<String, dynamic>.from(data));
  }

  Future<ClubRankingModel> getClubRanking() async {
    final data = await _api.get('/admin/clubs/ranking');
    return ClubRankingModel.fromJson(Map<String, dynamic>.from(data));
  }

  Future<ClubDataHealthModel> getClubDataHealth() async {
    final data = await _api.get('/admin/clubs/data-health');
    return ClubDataHealthModel.fromJson(Map<String, dynamic>.from(data));
  }

  Future<ClubFootfallModel> getClubFootfall(String id, {int weeks = 12}) async {
    final data = await _api.get('/admin/clubs/$id/footfall?weeks=$weeks');
    return ClubFootfallModel.fromMap(Map<String, dynamic>.from(data));
  }

  Future<String> getDisplayLink(String id) async {
    final data = await _api.get('/clubs/$id/display-link');
    return data['url'] as String;
  }

  Future<String> rotateQr(String id) async {
    final data = await _api.post('/clubs/$id/qr/rotate');
    return data['qrCode'] as String;
  }
}
