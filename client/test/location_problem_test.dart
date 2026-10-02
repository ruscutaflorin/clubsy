import 'package:flutter_test/flutter_test.dart';

import 'package:clubsy/data/classes/location_problem.dart';

void main() {
  test('every problem has its own message', () {
    final messages = LocationProblem.values.map(locationProblemMessage).toSet();
    expect(messages.length, LocationProblem.values.length);
  });

  test('wording of each problem', () {
    expect(
      locationProblemMessage(LocationProblem.permissionDenied),
      'Location permission is required to check in',
    );
    expect(
      locationProblemMessage(LocationProblem.permissionDeniedForever),
      contains('app settings'),
    );
    expect(
      locationProblemMessage(LocationProblem.servicesDisabled),
      contains('Location services'),
    );
    expect(
      locationProblemMessage(LocationProblem.timeout),
      "Couldn't get a GPS fix — step outside the entrance and try again",
    );
    expect(
      locationProblemMessage(LocationProblem.mocked),
      "Mock locations aren't allowed for check-ins",
    );
  });
}
