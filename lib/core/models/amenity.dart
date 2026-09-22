class Amenity {
  final String amenityId;
  final String propertyId;
  final String amenityName;

  const Amenity({
    required this.amenityId,
    required this.propertyId,
    required this.amenityName,
  });

  factory Amenity.fromMap(Map<String, dynamic> map) => Amenity(
        amenityId: map['amenity_id'] as String,
        propertyId: map['property_id'] as String,
        amenityName: map['amenity_name'] as String,
      );

  Map<String, dynamic> toMap() => {
        'amenity_id': amenityId,
        'property_id': propertyId,
        'amenity_name': amenityName,
      };

  Amenity copyWith({
    String? amenityId,
    String? propertyId,
    String? amenityName,
  }) =>
      Amenity(
        amenityId: amenityId ?? this.amenityId,
        propertyId: propertyId ?? this.propertyId,
        amenityName: amenityName ?? this.amenityName,
      );
}
