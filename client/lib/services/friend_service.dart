import 'package:clubsy/data/classes/friend_model.dart';
import 'package:clubsy/services/api_client.dart';
import 'package:clubsy/services/auth_service.dart';

class FriendService {
  final ApiClient _api;

  FriendService({ApiClient? api})
    : _api = api ?? ApiClient(tokenProvider: AuthService().getToken);

  Future<FriendsOverview> getFriends() async {
    final data = await _api.get('/friends');
    return FriendsOverview.fromMap(data as Map<String, dynamic>);
  }

  /// The server answers the same way for unknown, known and duplicate
  /// usernames, so success only means "request accepted for processing".
  Future<void> sendRequest(String username) async {
    await _api.post('/friends/requests', body: {'username': username});
  }

  Future<void> accept(String id) => _api.post('/friends/requests/$id/accept');

  Future<void> decline(String id) => _api.post('/friends/requests/$id/decline');

  Future<void> cancel(String id) => _api.delete('/friends/requests/$id');

  Future<void> unfriend(String id) => _api.delete('/friends/$id');

  Future<List<FriendEntry>> getBlocked() async {
    final data = await _api.get('/blocks');
    return ((data['blocked'] as List?) ?? [])
        .map((e) => FriendEntry.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> block(String userId) =>
      _api.post('/blocks', body: {'userId': userId});

  Future<void> unblock(String userId) => _api.delete('/blocks/$userId');

  Future<void> report(String userId, String reason, {String? details}) =>
      _api.post(
        '/reports',
        body: {
          'userId': userId,
          'reason': reason,
          if (details != null && details.isNotEmpty) 'details': details,
        },
      );
}
