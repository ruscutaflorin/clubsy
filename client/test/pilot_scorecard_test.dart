import 'package:clubsy/data/classes/pilot_scorecard_model.dart';
import 'package:clubsy/views/pages/admin/admin_metrics_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final fixture = PilotScorecardModel.fromMap({
    'criteria': [
      {
        'id': 'partner_clubs',
        'label': 'Partner clubs',
        'value': 10,
        'target': 10,
        'met': true,
      },
      {
        'id': 'signups',
        'label': 'Signups',
        'value': 120,
        'target': 200,
        'met': false,
      },
      {
        'id': 'activation',
        'label': 'Activation (14 days)',
        'value': null,
        'target': 0.4,
        'met': false,
      },
      {
        'id': 'retention',
        'label': '2+ nights in 30 days',
        'value': 0.3,
        'target': 0.25,
        'met': true,
      },
    ],
    'wacu': [
      for (var i = 0; i < 8; i++)
        {'weekStart': '2026-08-0${i + 1}T00:00:00.000Z', 'activeUsers': i},
    ],
  });

  test('parses a fixture with a null value', () {
    expect(fixture.criteria, hasLength(4));
    expect(fixture.criteria[2].value, isNull);
    expect(fixture.criteria[3].met, isTrue);
    expect(fixture.wacu, hasLength(8));
  });

  testWidgets('renders the scorecard section', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: PilotScorecardSection(scorecard: fixture)),
      ),
    );
    expect(find.text('Pilot exit criteria'), findsOneWidget);
    expect(find.text('10 / 10'), findsOneWidget);
    expect(find.text('—'), findsOneWidget);
    expect(find.text('30% / 25%'), findsOneWidget);
    expect(find.byIcon(Icons.check_circle), findsNWidgets(2));
  });
}
