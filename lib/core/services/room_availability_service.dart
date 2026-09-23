import '../models/models.dart';
import '../repositories/room_request_repository.dart';

/// A room's live availability: how many slots are actually open right now,
/// and which map-legend status (Available / Limited / Full / Reserved) that
/// corresponds to.
class RoomAvailability {
  const RoomAvailability({
    required this.availableSlots,
    required this.status,
  });

  final int availableSlots;
  final RoomAvailabilityStatus status;
}

/// Computes a [Room]'s real-time availability from `capacity`,
/// `current_occupancy`, and any active `RoomRequests` holding a slot.
///
/// This is shared, not per-feature, because Phase 3b (room requests),
/// Phase 4 (landlord room management), and the Phase 8 map all need the
/// exact same "how many slots are actually open" calculation.
class RoomAvailabilityService {
  const RoomAvailabilityService({required this.roomRequestRepository});

  final RoomRequestRepository roomRequestRepository;

  /// A room counts as "limited" once effective occupancy crosses this
  /// fraction of capacity -- matches `Room.occupancyStatus`'s threshold.
  static const _limitedThreshold = 0.7;

  Future<RoomAvailability> getAvailability(Room room) async {
    final activeHolds =
        await roomRequestRepository.getActiveHoldsForRoom(room.roomId);

    final rawSlots = room.capacity - room.currentOccupancy - activeHolds.length;
    final availableSlots = rawSlots < 0 ? 0 : rawSlots;

    final hasConfirmedHold =
        activeHolds.any((r) => r.status == RoomRequestStatus.confirmed);

    // Pending/approved holds occupy a slot the same as an actual occupant
    // for the purpose of "is this room full/limited", even though they
    // aren't a firm booking the way a confirmed hold is.
    final effectiveOccupancy = room.currentOccupancy + activeHolds.length;

    final RoomAvailabilityStatus status;
    if (hasConfirmedHold) {
      status = RoomAvailabilityStatus.reserved;
    } else if (effectiveOccupancy >= room.capacity) {
      status = RoomAvailabilityStatus.full;
    } else if (effectiveOccupancy >= room.capacity * _limitedThreshold) {
      status = RoomAvailabilityStatus.limited;
    } else {
      status = RoomAvailabilityStatus.available;
    }

    return RoomAvailability(availableSlots: availableSlots, status: status);
  }

  /// Total open slots across every room in a property -- e.g. for a
  /// PropertyCard's "3 slots" badge.
  Future<int> totalAvailableSlots(List<Room> rooms) async {
    var total = 0;
    for (final room in rooms) {
      total += (await getAvailability(room)).availableSlots;
    }
    return total;
  }
}
