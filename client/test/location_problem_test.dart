import 'package:flutter_test/flutter_test.dart';

import 'package:clubsy/data/classes/location_problem.dart';

void main() {
  test('every problem has its own message', () {
    final messages = LocationProblem.values.map(locationProblemMessage).toSet();
    expect(messages.length, LocationProblem.values.length);
  });
}
