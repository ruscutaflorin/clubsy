import 'package:clubsy/data/classes/club_model.dart';

class CheckInModel {
  final String id;
  final String clubId;
  final DateTime checkedInAt;
  final String verificationMethod;
  final double distanceMeters;
  final ClubModel club;

  CheckInModel({
    required this.id,
    required this.clubId,
    required this.checkedInAt,
    required this.verificationMethod,
    required this.distanceMeters,
    required this.club,
  });

  factory CheckInModel.fromMap(Map<String, dynamic> map) {
    return CheckInModel(
      id: map['id'],
      clubId: map['clubId'],
      checkedInAt: DateTime.parse(map['checkedInAt']),
      verificationMethod: map['verificationMethod'],
      distanceMeters: (map['distanceMeters'] as num).toDouble(),
      club: ClubModel.fromMap(map['club']),
    );
  }
}
