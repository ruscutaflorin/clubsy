import 'package:clubsy/data/classes/club_model.dart';
import 'package:clubsy/services/api_client.dart';
import 'package:clubsy/services/auth_service.dart';

class ClubService {
  final ApiClient _api;

  ClubService({ApiClient? api})
    : _api = api ?? ApiClient(tokenProvider: AuthService().getToken);

  Future<List<ClubModel>> getClubs({String? search, String? city}) async {
    final data = await _api.get(
      '/clubs',
      query: {
        if (search != null && search.isNotEmpty) 'search': search,
        if (city != null && city.isNotEmpty) 'city': city,
        'limit': '100',
      },
    );
    return (data['clubs'] as List)
        .map((club) => ClubModel.fromMap(club))
        .toList();
  }

  Future<void> setFavorite(String id, bool favorite) async {
    if (favorite) {
      await _api.put('/clubs/$id/favorite');
    } else {
      await _api.delete('/clubs/$id/favorite');
    }
  }

  Future<ClubModel> getClubById(String id) async {
    final data = await _api.get('/clubs/$id');
    return ClubModel.fromMap(data);
  }
}
