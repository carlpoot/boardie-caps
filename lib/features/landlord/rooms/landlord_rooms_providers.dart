import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/models.dart';
import '../../../core/providers/repository_providers.dart';
import '../../../core/providers/service_providers.dart';
import '../../../core/services/room_availability_service.dart';

final propertyRoomsProvider =
    FutureProvider.family<List<Room>, String>((ref, propertyId) {
  return ref.watch(roomRepositoryProvider).getByProperty(propertyId);
});

/// Availability for every room in [propertyId], computed through the exact
/// same [RoomAvailabilityService] the student side uses (see Phase 3a/3b) --
/// so the badge shown here and the one shown to students never disagree.
final propertyRoomAvailabilitiesProvider =
    FutureProvider.family<Map<String, RoomAvailability>, String>((ref, propertyId) async {
  final roomRepository = ref.watch(roomRepositoryProvider);
  final availabilityService = ref.watch(roomAvailabilityServiceProvider);

  final rooms = await roomRepository.getByProperty(propertyId);
  final result = <String, RoomAvailability>{};
  for (final room in rooms) {
    result[room.roomId] = await availabilityService.getAvailability(room);
  }
  return result;
});

/// `held_count` is intentionally never a parameter here -- it's derived
/// from active `RoomRequests`, not something a landlord sets directly. Every
/// write recalculates `availability_updated_at`.
Future<void> createRoom(
  WidgetRef ref, {
  required String propertyId,
  required String roomType,
  required int capacity,
  required int currentOccupancy,
  required num rentPrice,
}) async {
  await ref.read(roomRepositoryProvider).create(Room(
        roomId: '',
        propertyId: propertyId,
        roomType: roomType,
        capacity: capacity,
        currentOccupancy: currentOccupancy,
        heldCount: 0,
        rentPrice: rentPrice,
        availabilityUpdatedAt: DateTime.now(),
      ));

  ref.invalidate(propertyRoomsProvider(propertyId));
  ref.invalidate(propertyRoomAvailabilitiesProvider(propertyId));
}

Future<void> updateRoom(
  WidgetRef ref,
  Room existing, {
  required String roomType,
  required int capacity,
  required int currentOccupancy,
  required num rentPrice,
}) async {
  await ref.read(roomRepositoryProvider).update(existing.copyWith(
        roomType: roomType,
        capacity: capacity,
        currentOccupancy: currentOccupancy,
        rentPrice: rentPrice,
        availabilityUpdatedAt: DateTime.now(),
      ));

  ref.invalidate(propertyRoomsProvider(existing.propertyId));
  ref.invalidate(propertyRoomAvailabilitiesProvider(existing.propertyId));
}

Future<void> deleteRoom(WidgetRef ref, String propertyId, String roomId) async {
  await ref.read(roomRepositoryProvider).delete(roomId);
  ref.invalidate(propertyRoomsProvider(propertyId));
  ref.invalidate(propertyRoomAvailabilitiesProvider(propertyId));
}
