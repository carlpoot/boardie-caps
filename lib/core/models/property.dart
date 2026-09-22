import 'enums.dart';

class Property {
  final String propertyId;
  final String landlordId;
  final String name;
  final String address;
  final double latitude;
  final double longitude;
  final int storeys;
  final VerificationStatus verificationStatus;
  final num minPrice;
  final DateTime? utilitiesUpdatedAt;
  final DateTime createdAt;

  const Property({
    required this.propertyId,
    required this.landlordId,
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.storeys,
    required this.verificationStatus,
    required this.minPrice,
    this.utilitiesUpdatedAt,
    required this.createdAt,
  });

  factory Property.fromMap(Map<String, dynamic> map) => Property(
        propertyId: map['property_id'] as String,
        landlordId: map['landlord_id'] as String,
        name: map['name'] as String,
        address: map['address'] as String,
        latitude: (map['latitude'] as num).toDouble(),
        longitude: (map['longitude'] as num).toDouble(),
        storeys: map['storeys'] as int,
        verificationStatus:
            VerificationStatus.fromValue(map['verification_status'] as String),
        minPrice: map['min_price'] as num,
        utilitiesUpdatedAt: map['utilities_updated_at'] == null
            ? null
            : DateTime.parse(map['utilities_updated_at'] as String),
        createdAt: DateTime.parse(map['created_at'] as String),
      );

  Map<String, dynamic> toMap() => {
        'property_id': propertyId,
        'landlord_id': landlordId,
        'name': name,
        'address': address,
        'latitude': latitude,
        'longitude': longitude,
        'storeys': storeys,
        'verification_status': verificationStatus.value,
        'min_price': minPrice,
        'utilities_updated_at': utilitiesUpdatedAt?.toIso8601String(),
        'created_at': createdAt.toIso8601String(),
      };

  Property copyWith({
    String? propertyId,
    String? landlordId,
    String? name,
    String? address,
    double? latitude,
    double? longitude,
    int? storeys,
    VerificationStatus? verificationStatus,
    num? minPrice,
    DateTime? utilitiesUpdatedAt,
    DateTime? createdAt,
  }) =>
      Property(
        propertyId: propertyId ?? this.propertyId,
        landlordId: landlordId ?? this.landlordId,
        name: name ?? this.name,
        address: address ?? this.address,
        latitude: latitude ?? this.latitude,
        longitude: longitude ?? this.longitude,
        storeys: storeys ?? this.storeys,
        verificationStatus: verificationStatus ?? this.verificationStatus,
        minPrice: minPrice ?? this.minPrice,
        utilitiesUpdatedAt: utilitiesUpdatedAt ?? this.utilitiesUpdatedAt,
        createdAt: createdAt ?? this.createdAt,
      );
}
