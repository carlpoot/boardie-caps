import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/models.dart';
import '../../../core/providers/repository_providers.dart';
import '../../../core/providers/service_providers.dart';
import '../../../core/services/distance_utils.dart';
import '../../../core/services/room_availability_service.dart';
import '../home/student_browse_providers.dart';
import 'compare_properties_data.dart';

/// Keyed by a comma-joined, order-preserving string of property ids rather
/// than a `List<String>` -- a `List` compares by identity by default, which
/// would silently defeat Riverpod's family caching (and could even cause
/// re-fetch loops) every time a new list instance with the same ids is
/// passed in. A plain `String` compares by value, avoiding that entirely.
final comparePropertiesProvider =
    FutureProvider.family<List<ComparePropertyItem>, String>((ref, idsKey) async {
  final propertyIds = idsKey.isEmpty ? const <String>[] : idsKey.split(',');

  final propertyRepository = ref.watch(propertyRepositoryProvider);
  final amenityRepository = ref.watch(amenityRepositoryProvider);
  final roomRepository = ref.watch(roomRepositoryProvider);
  final availabilityService = ref.watch(roomAvailabilityServiceProvider);
  final campus = await ref.watch(currentStudentCampusProvider.future);

  final items = <ComparePropertyItem>[];
  for (final id in propertyIds) {
    final property = await propertyRepository.getById(id);
    if (property == null) continue;

    final amenities = await amenityRepository.getByProperty(id);
    final rooms = await roomRepository.getByProperty(id);
    final roomEntries = <({Room room, RoomAvailability availability})>[];
    for (final room in rooms) {
      roomEntries.add((room: room, availability: await availabilityService.getAvailability(room)));
    }

    items.add(ComparePropertyItem(
      property: property,
      amenityNames: amenities.map((a) => a.amenityName).toList(),
      distanceFromCampusKm: campus == null
          ? null
          : haversineDistanceKm(
              property.latitude,
              property.longitude,
              campus.latitude,
              campus.longitude,
            ),
      rooms: roomEntries,
    ));
  }
  return items;
});
