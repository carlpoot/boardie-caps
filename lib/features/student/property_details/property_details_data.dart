import '../../../core/models/models.dart';
import '../../../core/services/room_availability_service.dart';

/// Everything the Property Details screen needs, composed in one fetch.
/// Not a Phase 1 ERD entity -- just a UI view-model.
class PropertyDetailsData {
  const PropertyDetailsData({
    required this.property,
    required this.images,
    required this.amenities,
    required this.rooms,
    required this.roomAvailabilities,
    required this.isSaved,
  });

  final Property property;
  final List<PropertyImage> images;
  final List<Amenity> amenities;
  final List<Room> rooms;

  /// Keyed by `room_id`.
  final Map<String, RoomAvailability> roomAvailabilities;

  final bool isSaved;
}
