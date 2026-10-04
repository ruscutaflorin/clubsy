import 'package:clubsy/data/classes/club_data_health_model.dart';
import 'package:clubsy/services/admin_service.dart';
import 'package:clubsy/views/pages/admin/admin_club_data_health_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeService implements AdminService {
  final ClubDataHealthModel model;
  _FakeService(this.model);

  @override
  Future<ClubDataHealthModel> getClubDataHealth() async => model;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  testWidgets('shows possible duplicates', (tester) async {
    final model = ClubDataHealthModel.fromJson({
      'nearDuplicates': [
        {
          'a': {'id': 'a', 'name': 'Club X'},
          'b': {'id': 'b', 'name': 'Club X Bar'},
          'meters': 12,
          'sameName': false,
        },
      ],
    });
    await tester.pumpWidget(
      MaterialApp(home: AdminClubDataHealthPage(service: _FakeService(model))),
    );
    await tester.pumpAndSettle();
    expect(find.text('Possible duplicates'), findsOneWidget);
    expect(find.textContaining('12 m'), findsOneWidget);
    expect(find.text('Invalid coordinates'), findsNothing);
  });

  testWidgets('shows an all-clear when the response has no issue lists', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: AdminClubDataHealthPage(
          service: _FakeService(ClubDataHealthModel.fromJson({})),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('No data issues found'), findsOneWidget);
  });
}
