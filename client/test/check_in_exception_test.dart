import 'dart:convert';

import 'package:clubsy/services/check_in_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:clubsy/views/pages/check_in_page.dart';

void main() {
  group('CheckInException.fromResponse', () {
    test('a 400 with distanceMeters includes the distance in the message', () {
      final error = CheckInException.fromResponse(
        400,
        json.encode({
          'message': "You're too far from this club to check in",
          'distanceMeters': 420.3,
        }),
      );
      expect(error.distanceMeters, 420.3);
      expect(checkInFailureMessage(error), contains('420'));
    });

    test('a 400 with field errors uses the first errors[].msg', () {
      final error = CheckInException.fromResponse(
        400,
        json.encode({
          'errors': [
            {'msg': 'qrPayload is required'},
            {'msg': 'clubId is required'},
          ],
        }),
      );
      expect(error.distanceMeters, isNull);
      expect(error.message, 'qrPayload is required');
      expect(checkInFailureMessage(error), 'qrPayload is required');
    });

    test('a 404 with message uses that message', () {
      final error = CheckInException.fromResponse(
        404,
        json.encode({'message': 'Club not found'}),
      );
      expect(error.message, 'Club not found');
      expect(checkInFailureMessage(error), 'Club not found');
    });

    test('a non-JSON body falls back to a generic message', () {
      final error = CheckInException.fromResponse(500, 'not json');
      expect(error.message, 'Failed to check in');
      expect(checkInFailureMessage(error), 'Failed to check in');
    });
  });

  group('checkInFailureMessage', () {
    test('rounds a fractional distance for display', () {
      final error = CheckInException(message: 'too far', distanceMeters: 419.6);
      expect(checkInFailureMessage(error), "You're ~420 m away — get within 150 m of the entrance");
    });

    test('falls back to Exception.toString for a non-CheckInException error', () {
      expect(checkInFailureMessage(Exception('boom')), 'boom');
    });
  });
}
