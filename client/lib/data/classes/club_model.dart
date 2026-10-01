class ClubModel {
  final String id;
  final String name;
  final String address;
  final String city;
  final double latitude;
  final double longitude;
  final String imageUrl;
  final bool isApproved;
  final String? qrCode;

  ClubModel({
    required this.id,
    required this.name,
    required this.address,
    required this.city,
    required this.latitude,
    required this.longitude,
    required this.imageUrl,
    required this.isApproved,
    this.qrCode,
  });

  factory ClubModel.fromMap(Map<String, dynamic> map) {
    return ClubModel(
      id: map['id'],
      name: map['name'],
      address: map['address'],
      city: map['city'],
      latitude: (map['latitude'] as num).toDouble(),
      longitude: (map['longitude'] as num).toDouble(),
      imageUrl: map['imageUrl'],
      isApproved: map['isApproved'] ?? false,
      qrCode: map['qrCode'],
    );
  }
}
