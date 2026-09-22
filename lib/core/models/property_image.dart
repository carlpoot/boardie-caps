class PropertyImage {
  final String imageId;
  final String propertyId;
  final String imageUrl;

  const PropertyImage({
    required this.imageId,
    required this.propertyId,
    required this.imageUrl,
  });

  factory PropertyImage.fromMap(Map<String, dynamic> map) => PropertyImage(
        imageId: map['image_id'] as String,
        propertyId: map['property_id'] as String,
        imageUrl: map['image_url'] as String,
      );

  Map<String, dynamic> toMap() => {
        'image_id': imageId,
        'property_id': propertyId,
        'image_url': imageUrl,
      };

  PropertyImage copyWith({
    String? imageId,
    String? propertyId,
    String? imageUrl,
  }) =>
      PropertyImage(
        imageId: imageId ?? this.imageId,
        propertyId: propertyId ?? this.propertyId,
        imageUrl: imageUrl ?? this.imageUrl,
      );
}
