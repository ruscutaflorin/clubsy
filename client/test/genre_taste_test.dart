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
}
