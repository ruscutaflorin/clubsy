import 'package:flutter_test/flutter_test.dart';

import 'package:clubsy/data/classes/check_in_model.dart';
import 'package:clubsy/data/classes/club_model.dart';
import 'package:clubsy/data/classes/vibe_prompt.dart';

CheckInModel _ci(String id, DateTime at, {int? vibe}) => CheckInModel(
  id: id,
  clubId: 'c-$id',
  checkedInAt: at,
  verificationMethod: 'QR',
  distanceMeters: 10,
  vibe: vibe,
  club: ClubModel.fromMap({
    'id': 'c-$id',
    'name': 'Club $id',
    'address': '1 Main St',
    'city': 'Cluj',
    'latitude': 46,
    'longitude': 23.5,
    'imageUrl': 'http://img',
  }),
);

void main() {
  final lastNight = DateTime(2026, 10, 3, 23, 30);

  test('asks about last night from 06:00 the next morning', () {
    final c = _ci('a', lastNight);
    expect(pendingVibePrompt([c], DateTime(2026, 10, 4, 6))?.id, 'a');
    expect(pendingVibePrompt([c], DateTime(2026, 10, 4, 14))?.id, 'a');
  });

  test('stays quiet before 06:00 and for a check-in from tonight', () {
    final c = _ci('a', lastNight);
    expect(pendingVibePrompt([c], DateTime(2026, 10, 4, 3)), isNull);
    // Checked in after today's 06:00: it is not "last night" yet.
    final today = _ci('b', DateTime(2026, 10, 4, 7));
    expect(pendingVibePrompt([today], DateTime(2026, 10, 4, 9)), isNull);
  });

  test('skips rated, dismissed and stale check-ins; picks the newest', () {
    final rated = _ci('rated', lastNight, vibe: 4);
    final dismissed = _ci('dismissed', lastNight);
    final stale = _ci('stale', DateTime(2026, 10, 1, 23));
    final older = _ci('older', DateTime(2026, 10, 3, 22));
    final now = DateTime(2026, 10, 4, 10);
    expect(
      pendingVibePrompt(
        [rated, dismissed, stale],
        now,
        dismissedIds: {'dismissed'},
      ),
      isNull,
    );
    expect(
      pendingVibePrompt([older, _ci('newer', lastNight)], now)?.id,
      'newer',
    );
  });
}
