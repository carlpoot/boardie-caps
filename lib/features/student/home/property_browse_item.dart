import '../../../core/models/models.dart';

/// A UI-composed view of a [Property] for the browse list and map
/// placeholder -- not a Phase 1 ERD entity, just an aggregation of
/// everything a PropertyCard (or the map list) needs to render in one
/// shot, computed once per fetch rather than per widget rebuild.
class PropertyBrowseItem {
  const PropertyBrowseItem({
    required this.property,
    required this.coverImageUrl,
    required this.amenityNames,
    required this.roomTypes,
    required this.availableSlots,
    required this.distanceFromCampusKm,
  });

  final Property property;
  final String? coverImageUrl;
  final List<String> amenityNames;
  final Set<String> roomTypes;
  final int availableSlots;
  final double? distanceFromCampusKm;
}
