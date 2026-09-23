import '../../../core/models/models.dart';
import '../../../core/services/room_availability_service.dart';

/// Everything the Compare Properties screen needs for one property -- not a
/// Phase 1 ERD entity, just a UI view-model.
class ComparePropertyItem {
  const ComparePropertyItem({
    required this.property,
    required this.amenityNames,
    required this.distanceFromCampusKm,
    required this.rooms,
  });

  final Property property;
  final List<String> amenityNames;
  final double? distanceFromCampusKm;
  final List<({Room room, RoomAvailability availability})> rooms;
}
