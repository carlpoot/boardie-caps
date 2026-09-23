import 'package:flutter_test/flutter_test.dart';

import 'package:boardie/core/models/models.dart';
import 'package:boardie/core/repositories/mock/mock_room_request_repository.dart';
import 'package:boardie/core/services/room_availability_service.dart';

Room _room({
  String roomId = 'room-x',
  int capacity = 2,
  int currentOccupancy = 0,
}) {
  return Room(
    roomId: roomId,
    propertyId: 'property-x',
    roomType: 'Solo',
    capacity: capacity,
    currentOccupancy: currentOccupancy,
    heldCount: 0,
    rentPrice: 1000,
    availabilityUpdatedAt: DateTime(2026, 1, 1),
  );
}

void main() {
  late MockRoomRequestRepository roomRequestRepository;
  late RoomAvailabilityService service;

  setUp(() {
    roomRequestRepository = MockRoomRequestRepository();
    service = RoomAvailabilityService(
      roomRequestRepository: roomRequestRepository,
    );
  });

  group('a room with no active holds', () {
    test('is available when occupancy is well under capacity', () async {
      final room = _room(roomId: 'room-002', capacity: 2, currentOccupancy: 1);
      final availability = await service.getAvailability(room);

      expect(availability.availableSlots, 1);
      expect(availability.status, RoomAvailabilityStatus.available);
    });

    test('is full once occupancy reaches capacity', () async {
      // Seeded room-003 has one RoomRequest, but it's status=expired, so it
      // must not count as an active hold.
      final room = _room(roomId: 'room-003', capacity: 1, currentOccupancy: 1);
      final availability = await service.getAvailability(room);

      expect(availability.availableSlots, 0);
      expect(availability.status, RoomAvailabilityStatus.full);
    });
  });

  test('a pending hold occupies a slot and can push the room to full',
      () async {
    // Seeded room-001 has one active RoomRequest (request-003, pending).
    final room = _room(roomId: 'room-001', capacity: 1, currentOccupancy: 0);
    final availability = await service.getAvailability(room);

    expect(availability.availableSlots, 0);
    expect(availability.status, RoomAvailabilityStatus.full);
  });

  test('a confirmed hold makes the room reserved regardless of occupancy',
      () async {
    // Seeded room-004 has one active RoomRequest (request-001, confirmed).
    final room = _room(roomId: 'room-004', capacity: 4, currentOccupancy: 3);
    final availability = await service.getAvailability(room);

    expect(availability.availableSlots, 0);
    expect(availability.status, RoomAvailabilityStatus.reserved);
  });

  test('available slots never go negative when overbooked', () async {
    final room = _room(roomId: 'room-999', capacity: 1, currentOccupancy: 5);
    final availability = await service.getAvailability(room);

    expect(availability.availableSlots, 0);
  });

  test('a room past the limited threshold but under capacity reads as limited',
      () async {
    final room = _room(roomId: 'room-998', capacity: 10, currentOccupancy: 8);
    final availability = await service.getAvailability(room);

    expect(availability.availableSlots, 2);
    expect(availability.status, RoomAvailabilityStatus.limited);
  });

  test('totalAvailableSlots sums availability across every room', () async {
    final rooms = [
      _room(roomId: 'room-a', capacity: 2, currentOccupancy: 1), // 1 open
      _room(roomId: 'room-b', capacity: 3, currentOccupancy: 3), // 0 open
      _room(roomId: 'room-c', capacity: 1, currentOccupancy: 0), // 1 open
    ];

    final total = await service.totalAvailableSlots(rooms);

    expect(total, 2);
  });
}
