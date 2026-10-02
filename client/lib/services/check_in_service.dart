import 'package:clubsy/data/classes/check_in_model.dart';
import 'package:clubsy/data/classes/check_in_stats_model.dart';
import 'package:clubsy/services/api_client.dart';
import 'package:clubsy/services/auth_service.dart';

/// A failed check-in attempt, carrying enough of the server's response for
/// the UI to show why: how far away the user was, or which field was
/// rejected, rather than a bare "Failed to check in".
class CheckInException extends ApiException {
  final double? distanceMeters;

  CheckInException({
    required String message,
    this.distanceMeters,
    List<String> fieldErrors = const [],
    int statusCode = 0,
    Map<String, dynamic>? body,
  }) : super(statusCode, message, fieldErrors: fieldErrors, body: body);

  /// Parses a check-in error response body. Never throws: a non-JSON or
  /// unexpected body falls back to a generic message.
  factory CheckInException.fromResponse(int status, String body) {
    final e = ApiException.fromResponse(
      status,
      body,
      fallback: 'Failed to check in',
    );
    return CheckInException.from(e);
  }

  factory CheckInException.from(ApiException e) => CheckInException(
    message: e.message,
    statusCode: e.statusCode,
    fieldErrors: e.fieldErrors,
    body: e.body,
    distanceMeters: (e.body?['distanceMeters'] as num?)?.toDouble(),
  );
}

class CheckInService {
  final ApiClient _api;

  CheckInService({ApiClient? api})
    : _api = api ?? ApiClient(tokenProvider: AuthService().getToken);

  Future<CheckInModel> checkIn({
    required String clubId,
    required String qrPayload,
    required double latitude,
    required double longitude,
    bool? isMocked,
    double? accuracyMeters,
  }) async {
    try {
      final data = await _api.post(
        '/check-ins',
        body: {
          'clubId': clubId,
          'qrPayload': qrPayload,
          'latitude': latitude,
          'longitude': longitude,
          'isMocked': ?isMocked,
          'accuracyMeters': ?accuracyMeters,
        },
      );
      return CheckInModel.fromMap(data);
    } on CheckInException {
      rethrow;
    } on ApiException catch (e) {
      throw CheckInException.from(e);
    }
  }

  Future<List<CheckInModel>> getMyCheckIns() async {
    final data = await _api.get('/check-ins/me');
    return (data['checkIns'] as List)
        .map((checkIn) => CheckInModel.fromMap(checkIn))
        .toList();
  }

  Future<CheckInStatsModel> getMyStats() async {
    final data = await _api.get('/check-ins/me/stats');
    return CheckInStatsModel.fromMap(data);
  }
}
