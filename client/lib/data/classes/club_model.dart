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
  final String? description;
  final List<String> genres;
  final Map<String, dynamic>? openingHours;
  final String? instagramUrl;
  final String? websiteUrl;
  final String timezone;

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
    this.description,
    this.genres = const [],
    this.openingHours,
    this.instagramUrl,
    this.websiteUrl,
    this.timezone = 'Europe/Bucharest',
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
      description: map['description'],
      genres: List<String>.from(map['genres'] ?? const []),
      openingHours: map['openingHours'] == null
          ? null
          : Map<String, dynamic>.from(map['openingHours']),
      instagramUrl: map['instagramUrl'],
      websiteUrl: map['websiteUrl'],
      timezone: map['timezone'] ?? 'Europe/Bucharest',
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'address': address,
    'city': city,
    'latitude': latitude,
    'longitude': longitude,
    'imageUrl': imageUrl,
    'isApproved': isApproved,
    'qrCode': qrCode,
    'description': description,
    'genres': genres,
    'openingHours': openingHours,
    'instagramUrl': instagramUrl,
    'websiteUrl': websiteUrl,
    'timezone': timezone,
  };
}
