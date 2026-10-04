import 'package:clubsy/data/classes/club_model.dart';

class CheckInModel {
  final String id;
  final String clubId;
  final DateTime checkedInAt;
  final String verificationMethod;
  final double distanceMeters;
  final ClubModel club;
  final String? note;
  final int? vibe;
  final bool hiddenFromFriends;

  CheckInModel({
    required this.id,
    required this.clubId,
    required this.checkedInAt,
    required this.verificationMethod,
    required this.distanceMeters,
    required this.club,
    this.note,
    this.vibe,
    this.hiddenFromFriends = false,
  });

  factory CheckInModel.fromMap(Map<String, dynamic> map) {
    return CheckInModel(
      id: map['id'],
      clubId: map['clubId'],
      checkedInAt: DateTime.parse(map['checkedInAt']),
      verificationMethod: map['verificationMethod'],
      distanceMeters: (map['distanceMeters'] as num).toDouble(),
      club: ClubModel.fromMap(map['club']),
      note: map['note'] as String?,
      vibe: (map['vibe'] as num?)?.toInt(),
      hiddenFromFriends: map['hiddenFromFriends'] == true,
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'clubId': clubId,
    'checkedInAt': checkedInAt.toIso8601String(),
    'verificationMethod': verificationMethod,
    'distanceMeters': distanceMeters,
    'club': club.toMap(),
    'note': note,
    'vibe': vibe,
    'hiddenFromFriends': hiddenFromFriends,
  };

  CheckInModel withHidden(bool hidden) => CheckInModel(
    id: id,
    clubId: clubId,
    checkedInAt: checkedInAt,
    verificationMethod: verificationMethod,
    distanceMeters: distanceMeters,
    club: club,
    note: note,
    vibe: vibe,
    hiddenFromFriends: hidden,
  );

  /// A copy with the diary fields replaced as given. The server returns the
  /// full record on update, so `null` here means "cleared", not "unchanged".
  CheckInModel withDiary({String? note, int? vibe}) => CheckInModel(
    id: id,
    clubId: clubId,
    checkedInAt: checkedInAt,
    verificationMethod: verificationMethod,
    distanceMeters: distanceMeters,
    club: club,
    note: note,
    vibe: vibe,
    hiddenFromFriends: hiddenFromFriends,
  );
}
