import 'package:clubsy/data/classes/feed_model.dart';
import 'package:clubsy/services/api_client.dart';
import 'package:clubsy/services/auth_service.dart';

class FeedService {
  final ApiClient _api;

  FeedService({ApiClient? api})
    : _api = api ?? ApiClient(tokenProvider: AuthService().getToken);

  Future<FeedPage> getFeed({int page = 1}) async {
    final data = await _api.get('/feed?page=$page');
    return FeedPage.fromMap(data as Map<String, dynamic>);
  }

  Future<int> friendCountForClub(String clubId) async {
    final data = await _api.get('/feed/clubs/$clubId/friends-count');
    return (data['count'] as num?)?.toInt() ?? 0;
  }
}
