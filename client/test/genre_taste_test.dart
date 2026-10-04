import 'package:clubsy/data/classes/check_in_model.dart';
import 'package:clubsy/data/classes/club_model.dart';
import 'package:clubsy/data/classes/genre_taste.dart';
import 'package:flutter_test/flutter_test.dart';

CheckInModel ci(String clubId, DateTime at, List<String> genres) =>
    CheckInModel(
      id: '$clubId-$at',
      clubId: clubId,
      checkedInAt: at,
      verificationMethod: 'QR',
      distanceMeters: 10,
      club: ClubModel(
        id: clubId,
        name: clubId,
        address: '1 Main St',
        city: 'Cluj',
        latitude: 46,
        longitude: 23.5,
        imageUrl: 'http://img',
        isApproved: true,
        genres: genres,
      ),
    );

void main() {
  test('two techno clubs on one night count techno once', () {
    final r = genreNights([
      ci('a', DateTime(2026, 9, 5, 22), ['techno']),
      ci('b', DateTime(2026, 9, 6, 1), ['techno']),
    ]);
    expect(r, [(genre: 'techno', nights: 1)]);
  });

  test('sorts by nights then name', () {
    final r = genreNights([
      ci('a', DateTime(2026, 9, 5, 22), ['techno', 'house']),
      ci('b', DateTime(2026, 9, 12, 22), ['house']),
    ]);
    expect(r, [(genre: 'house', nights: 2), (genre: 'techno', nights: 1)]);
  });

  test('no genres and empty list add nothing', () {
    expect(genreNights([ci('a', DateTime(2026, 9, 5, 22), [])]), isEmpty);
    expect(genreNights([]), isEmpty);
    expect(yourSoundText([]), isNull);
  });

  test('yourSoundText caps at 3 genres', () {
    final text = yourSoundText([
      (genre: 'techno', nights: 4),
      (genre: 'house', nights: 3),
      (genre: 'latin', nights: 2),
      (genre: 'pop', nights: 1),
    ]);
    expect(text, 'Your sound: techno · house · latin');
  });

  group('similarClubs', () {
    ClubModel club(
      String id,
      List<String> genres, {
      String city = 'Cluj',
      bool approved = true,
    }) => ClubModel(
      id: id,
      name: id,
      address: '1 Main St',
      city: city,
      latitude: 46,
      longitude: 23.5,
      imageUrl: 'http://img',
      isApproved: approved,
      genres: genres,
    );

    final me = club('me', ['techno', 'house']);

    test('ranks more shared genres first and excludes non-matches', () {
      final r = similarClubs(me, [
        me,
        club('techno-only', ['techno']),
        club('both', ['house', 'techno']),
        club('bucharest', ['techno'], city: 'Bucharest'),
        club('pending', ['techno'], approved: false),
        club('latin', ['latin']),
      ]);
      expect(r.map((e) => e.club.id), ['both', 'techno-only']);
      expect(r.first.shared, ['techno', 'house']);
    });

    test('ignores case and surrounding spaces, and respects limit', () {
      final spaced = club('me2', ['Techno ']);
      final r = similarClubs(spaced, [
        club('a', [' techno']),
        club('b', ['TECHNO']),
      ], limit: 1);
      expect(r.map((e) => e.club.id), ['a']);
      expect(r.first.shared, ['Techno']);
    });

    test('a club with no genres has no similar clubs', () {
      expect(
        similarClubs(club('x', []), [
          club('a', ['techno']),
        ]),
        isEmpty,
      );
    });
  });
}
