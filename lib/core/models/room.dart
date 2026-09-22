import 'enums.dart';

class Room {
  final String roomId;
  final String propertyId;
  final String roomType;
  final int capacity;
  final int currentOccupancy;
  final int heldCount;
  final num rentPrice;
  final DateTime availabilityUpdatedAt;

  const Room({
    required this.roomId,
    required this.propertyId,
    required this.roomType,
    required this.capacity,
    required this.currentOccupancy,
    required this.heldCount,
    required this.rentPrice,
    required this.availabilityUpdatedAt,
  });

  factory Room.fromMap(Map<String, dynamic> map) => Room(
        roomId: map['room_id'] as String,
        propertyId: map['property_id'] as String,
        roomType: map['room_type'] as String,
        capacity: map['capacity'] as int,
        currentOccupancy: map['current_occupancy'] as int,
        heldCount: map['held_count'] as int,
        rentPrice: map['rent_price'] as num,
        availabilityUpdatedAt:
            DateTime.parse(map['availability_updated_at'] as String),
      );

  Map<String, dynamic> toMap() => {
        'room_id': roomId,
        'property_id': propertyId,
        'room_type': roomType,
        'capacity': capacity,
        'current_occupancy': currentOccupancy,
        'held_count': heldCount,
        'rent_price': rentPrice,
        'availability_updated_at': availabilityUpdatedAt.toIso8601String(),
      };

  Room copyWith({
    String? roomId,
    String? propertyId,
    String? roomType,
    int? capacity,
    int? currentOccupancy,
    int? heldCount,
    num? rentPrice,
    DateTime? availabilityUpdatedAt,
  }) =>
      Room(
        roomId: roomId ?? this.roomId,
        propertyId: propertyId ?? this.propertyId,
        roomType: roomType ?? this.roomType,
        capacity: capacity ?? this.capacity,
        currentOccupancy: currentOccupancy ?? this.currentOccupancy,
        heldCount: heldCount ?? this.heldCount,
        rentPrice: rentPrice ?? this.rentPrice,
        availabilityUpdatedAt:
            availabilityUpdatedAt ?? this.availabilityUpdatedAt,
      );

  /// Derived status from [currentOccupancy] vs [capacity].
  ///
  /// This does NOT account for the `reserved` state, which additionally
  /// depends on whether there is an active `confirmed` RoomRequest for this
  /// room — see `RoomRequestRepository.getActiveHoldsForRoom`. Callers that
  /// need the full map-legend status (Available / Limited / Full / Reserved)
  /// should combine this with that repository lookup.
  RoomAvailabilityStatus get occupancyStatus {
    if (currentOccupancy >= capacity) return RoomAvailabilityStatus.full;
    if (currentOccupancy >= capacity * 0.7) {
      return RoomAvailabilityStatus.limited;
    }
    return RoomAvailabilityStatus.available;
  }
}
