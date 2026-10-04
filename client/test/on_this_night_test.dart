import 'package:clubsy/data/classes/check_in_model.dart';
import 'package:clubsy/data/classes/club_model.dart';
import 'package:clubsy/data/classes/on_this_night.dart';
import 'package:clubsy/src/core/controllers/club_controller.dart';
import 'package:clubsy/views/pages/check_in_history_page.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

ClubModel _club(String id) => ClubModel(
  id: id,
  name: 'Club $id',
  address: 'a',
  city: 'c',
  latitude: 0,
  longitude: 0,
  imageUrl: '',
  isApproved: true,
);

CheckInModel _ci(String id, String clubId, DateTime at) => CheckInModel(
  id: id,
  clubId: clubId,
  checkedInAt: at,
  verificationMethod: 'qr',
  distanceMeters: 1,
  club: _club(clubId),
);

class _FakeClubController extends ClubController {
  @override
  // ignore: must_call_super
  void onInit() {}
}

void main() {
  final now = DateTime(2026, 10, 2, 12);

  test('finds a check-in exactly one year ago at 23:00', () {
    final r = onThisNight([_ci('1', 'a', DateTime(2025, 10, 2, 23))], now);
    expect(r, hasLength(1));
    expect(r.first.label, '1 year ago');
    expect(r.first.nightDate, DateTime(2025, 10, 2));
    expect(r.first.clubNames, ['Club a']);
  });

  test('02:00 the morning after belongs to the previous evening', () {
    final r = onThisNight([_ci('1', 'a', DateTime(2025, 10, 3, 2))], now);
    expect(r.single.label, '1 year ago');
  });

  test('364 days ago is not found', () {
    final at = now.subtract(const Duration(days: 364));
    expect(onThisNight([_ci('1', 'a', at)], now), isEmpty);
  });

  test('29 Feb surfaces on 28 Feb the next year', () {
    final r = onThisNight([
      _ci('1', 'a', DateTime(2024, 2, 29, 23)),
    ], DateTime(2025, 2, 28, 12));
    expect(r.single.label, '1 year ago');
    expect(r.single.nightDate, DateTime(2024, 2, 29));
  });

  test('31 March gives no month-ago memory', () {
    final r = onThisNight([
      _ci('1', 'a', DateTime(2026, 2, 28, 23)),
    ], DateTime(2026, 3, 31, 12));
    expect(r, isEmpty);
  });

  test('one month ago and multiple years are labelled', () {
    final r = onThisNight([
      _ci('1', 'a', DateTime(2026, 9, 2, 23)),
      _ci('2', 'a', DateTime(2024, 10, 2, 23)),
    ], now);
    expect(r.map((m) => m.label), ['1 month ago', '2 years ago']);
  });

  test('two clubs on the same past night share one memory', () {
    final r = onThisNight([
      _ci('1', 'a', DateTime(2025, 10, 2, 22)),
      _ci('2', 'b', DateTime(2025, 10, 3, 1)),
    ], now);
    expect(r, hasLength(1));
    expect(r.first.clubNames, ['Club a', 'Club b']);
  });

  Future<void> pump(WidgetTester tester, List<CheckInModel> list) async {
    Get.reset();
    final controller = _FakeClubController();
    controller.myCheckIns.value = list;
    Get.put<ClubController>(controller);
    await tester.pumpWidget(GetMaterialApp(home: CheckInHistoryPage(now: now)));
  }

  testWidgets('history page shows the On this night card', (tester) async {
    await pump(tester, [
      _ci('1', 'a', DateTime(now.year - 1, now.month, now.day, 12)),
    ]);
    expect(find.text('On this night'), findsOneWidget);
    expect(find.text('1 year ago'), findsOneWidget);
    expect(find.text('Club a'), findsWidgets);
  });

  testWidgets('history page has no card when nothing matches', (tester) async {
    final other = DateTime(
      now.year - 1,
      now.month,
      now.day,
    ).add(const Duration(days: 40));
    await pump(tester, [_ci('1', 'a', other)]);
    expect(find.text('On this night'), findsNothing);
  });
}
