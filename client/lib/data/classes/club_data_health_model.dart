class ClubRef {
  final String id;
  final String name;

  const ClubRef({required this.id, required this.name});

  factory ClubRef.fromJson(Map<String, dynamic> json) => ClubRef(
    id: (json['id'] as String?) ?? '',
    name: (json['name'] as String?) ?? '',
  );
}

class InvalidCoordinatesEntry {
  final String id;
  final String name;
  final String city;

  const InvalidCoordinatesEntry({
    required this.id,
    required this.name,
    required this.city,
  });

  factory InvalidCoordinatesEntry.fromJson(Map<String, dynamic> json) =>
      InvalidCoordinatesEntry(
        id: (json['id'] as String?) ?? '',
        name: (json['name'] as String?) ?? '',
        city: (json['city'] as String?) ?? '',
      );
}

class NearDuplicateEntry {
  final ClubRef a;
  final ClubRef b;
  final int meters;
  final bool sameName;

  const NearDuplicateEntry({
    required this.a,
    required this.b,
    required this.meters,
    required this.sameName,
  });

  factory NearDuplicateEntry.fromJson(Map<String, dynamic> json) =>
      NearDuplicateEntry(
        a: ClubRef.fromJson(Map<String, dynamic>.from(json['a'] as Map)),
        b: ClubRef.fromJson(Map<String, dynamic>.from(json['b'] as Map)),
        meters: (json['meters'] as num?)?.toInt() ?? 0,
        sameName: (json['sameName'] as bool?) ?? false,
      );
}

class FarFromCityEntry {
  final String id;
  final String name;
  final String city;
  final double km;

  const FarFromCityEntry({
    required this.id,
    required this.name,
    required this.city,
    required this.km,
  });

  factory FarFromCityEntry.fromJson(Map<String, dynamic> json) =>
      FarFromCityEntry(
        id: (json['id'] as String?) ?? '',
        name: (json['name'] as String?) ?? '',
        city: (json['city'] as String?) ?? '',
        km: (json['km'] as num?)?.toDouble() ?? 0,
      );
}

class ClubDataHealthModel {
  final List<InvalidCoordinatesEntry> invalidCoordinates;
  final List<NearDuplicateEntry> nearDuplicates;
  final List<FarFromCityEntry> farFromCity;

  const ClubDataHealthModel({
    required this.invalidCoordinates,
    required this.nearDuplicates,
    required this.farFromCity,
  });

  bool get isEmpty =>
      invalidCoordinates.isEmpty &&
      nearDuplicates.isEmpty &&
      farFromCity.isEmpty;

  factory ClubDataHealthModel.fromJson(Map<String, dynamic> json) {
    List<T> parse<T>(String key, T Function(Map<String, dynamic>) f) =>
        ((json[key] as List?) ?? [])
            .map((e) => f(Map<String, dynamic>.from(e as Map)))
            .toList();
    return ClubDataHealthModel(
      invalidCoordinates: parse(
        'invalidCoordinates',
        InvalidCoordinatesEntry.fromJson,
      ),
      nearDuplicates: parse('nearDuplicates', NearDuplicateEntry.fromJson),
      farFromCity: parse('farFromCity', FarFromCityEntry.fromJson),
    );
  }
}
