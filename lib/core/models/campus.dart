class Campus {
  final String campusId;
  final String name;
  final double latitude;
  final double longitude;

  const Campus({
    required this.campusId,
    required this.name,
    required this.latitude,
    required this.longitude,
  });

  factory Campus.fromMap(Map<String, dynamic> map) => Campus(
        campusId: map['campus_id'] as String,
        name: map['name'] as String,
        latitude: (map['latitude'] as num).toDouble(),
        longitude: (map['longitude'] as num).toDouble(),
      );

  Map<String, dynamic> toMap() => {
        'campus_id': campusId,
        'name': name,
        'latitude': latitude,
        'longitude': longitude,
      };

  Campus copyWith({
    String? campusId,
    String? name,
    double? latitude,
    double? longitude,
  }) =>
      Campus(
        campusId: campusId ?? this.campusId,
        name: name ?? this.name,
        latitude: latitude ?? this.latitude,
        longitude: longitude ?? this.longitude,
      );
}
