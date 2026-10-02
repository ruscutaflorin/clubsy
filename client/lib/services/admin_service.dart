import 'package:clubsy/data/classes/club_model.dart';
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

  Future<String> rotateQr(String id) async {
    final data = await _api.post('/clubs/$id/qr/rotate');
    return data['qrCode'] as String;
  }
}
