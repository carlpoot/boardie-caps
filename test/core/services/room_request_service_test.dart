import 'package:flutter_test/flutter_test.dart';

import 'package:boardie/core/models/models.dart';
import 'package:boardie/core/repositories/mock/mock_room_request_repository.dart';
import 'package:boardie/core/services/room_request_service.dart';

Room _room({String roomId = 'room-x', int capacity = 2}) => Room(
      roomId: roomId,
      propertyId: 'property-x',
      roomType: 'Solo',
      capacity: capacity,
      currentOccupancy: 0,
      heldCount: 0,
      rentPrice: 1000,
      availabilityUpdatedAt: DateTime(2026, 1, 1),
    );

void main() {
  late MockRoomRequestRepository repository;
  late RoomRequestService service;
  final now = DateTime(2026, 6, 1, 12);

  setUp(() {
    repository = MockRoomRequestRepository();
    service = RoomRequestService(roomRequestRepository: repository);
  });

  group('requestRoom', () {
    test('creates a pending hold with the default 24h window', () async {
      final request = await service.requestRoom(
        studentId: 'student-test',
        room: _room(),
        landlordId: 'landlord-test',
        now: now,
      );

      expect(request.status, RoomRequestStatus.pending);
      expect(request.heldUntil, now.add(const Duration(hours: 24)));
      expect(request.requestId, isNotEmpty);
    });

    test('rejects a 5th active hold for the same student', () async {
      for (var i = 0; i < 4; i++) {
        await service.requestRoom(
          studentId: 'student-cap',
          room: _room(roomId: 'room-$i'),
          landlordId: 'landlord-test',
          now: now,
        );
      }

      expect(
        () => service.requestRoom(
          studentId: 'student-cap',
          room: _room(roomId: 'room-4'),
          landlordId: 'landlord-test',
          now: now,
        ),
        throwsA(isA<RoomRequestException>()),
      );
    });

    test('a live-expired hold does not count against the cap', () async {
      // Fill up 4 holds, then check much later, after they've all silently
      // expired even though their stored status is still pending.
      for (var i = 0; i < 4; i++) {
        await service.requestRoom(
          studentId: 'student-expired',
          room: _room(roomId: 'room-$i'),
          landlordId: 'landlord-test',
          now: now,
        );
      }

      final muchLater = now.add(const Duration(days: 2));
      final fifth = await service.requestRoom(
        studentId: 'student-expired',
        room: _room(roomId: 'room-4'),
        landlordId: 'landlord-test',
        now: muchLater,
      );

      expect(fifth.status, RoomRequestStatus.pending);
    });
  });

  group('effectiveStatus / isLiveExpired', () {
    test('a pending hold past its held_until reads as expired', () async {
      final request = await service.requestRoom(
        studentId: 'student-a',
        room: _room(),
        landlordId: 'landlord-test',
        now: now,
      );

      final later = now.add(const Duration(hours: 25));
      expect(service.isLiveExpired(request, now: later), isTrue);
      expect(service.effectiveStatus(request, now: later), RoomRequestStatus.expired);
    });

    test('a confirmed request never reads as expired even past held_until',
        () async {
      final confirmed = RoomRequest(
        requestId: 'r1',
        studentId: 'student-a',
        roomId: 'room-1',
        propertyId: 'property-1',
        landlordId: 'landlord-1',
        status: RoomRequestStatus.confirmed,
        heldUntil: now.subtract(const Duration(days: 5)),
        confirmedAt: now,
        createdAt: now,
      );

      expect(service.isLiveExpired(confirmed, now: now), isFalse);
      expect(service.effectiveStatus(confirmed, now: now), RoomRequestStatus.confirmed);
    });
  });

  group('confirmRequest', () {
    test('only succeeds when the request is approved', () async {
      final pending = await service.requestRoom(
        studentId: 'student-b',
        room: _room(),
        landlordId: 'landlord-test',
        now: now,
      );

      expect(
        () => service.confirmRequest(pending.requestId, now: now),
        throwsA(isA<RoomRequestException>()),
      );
    });

    test('confirms the target and cancels all other active holds', () async {
      final target = await repository.create(RoomRequest(
        requestId: '',
        studentId: 'student-c',
        roomId: 'room-target',
        propertyId: 'property-x',
        landlordId: 'landlord-test',
        status: RoomRequestStatus.approved,
        heldUntil: now.add(const Duration(hours: 24)),
        createdAt: now,
      ));

      final otherPending = await service.requestRoom(
        studentId: 'student-c',
        room: _room(roomId: 'room-other-1'),
        landlordId: 'landlord-test',
        now: now,
      );
      final otherApproved = await repository.create(RoomRequest(
        requestId: '',
        studentId: 'student-c',
        roomId: 'room-other-2',
        propertyId: 'property-x',
        landlordId: 'landlord-test',
        status: RoomRequestStatus.approved,
        heldUntil: now.add(const Duration(hours: 24)),
        createdAt: now,
      ));
      // Already live-expired -- should be left alone; it isn't "active" so
      // it's not part of what confirm() cancels.
      final alreadyExpired = await repository.create(RoomRequest(
        requestId: '',
        studentId: 'student-c',
        roomId: 'room-other-3',
        propertyId: 'property-x',
        landlordId: 'landlord-test',
        status: RoomRequestStatus.pending,
        heldUntil: now.subtract(const Duration(hours: 1)),
        createdAt: now,
      ));
      // Another student's active hold -- must never be touched.
      final otherStudent = await service.requestRoom(
        studentId: 'student-someone-else',
        room: _room(roomId: 'room-other-4'),
        landlordId: 'landlord-test',
        now: now,
      );

      await service.confirmRequest(target.requestId, now: now);

      final updatedTarget = await repository.getById(target.requestId);
      expect(updatedTarget!.status, RoomRequestStatus.confirmed);
      expect(updatedTarget.confirmedAt, now);

      final updatedOtherPending = await repository.getById(otherPending.requestId);
      expect(updatedOtherPending!.status, RoomRequestStatus.cancelled);

      final updatedOtherApproved = await repository.getById(otherApproved.requestId);
      expect(updatedOtherApproved!.status, RoomRequestStatus.cancelled);

      final updatedExpired = await repository.getById(alreadyExpired.requestId);
      expect(updatedExpired!.status, RoomRequestStatus.pending); // untouched

      final updatedOtherStudent = await repository.getById(otherStudent.requestId);
      expect(updatedOtherStudent!.status, RoomRequestStatus.pending); // untouched
    });
  });

  group('cancelRequest', () {
    test('cancels an active hold', () async {
      final request = await service.requestRoom(
        studentId: 'student-d',
        room: _room(),
        landlordId: 'landlord-test',
        now: now,
      );

      await service.cancelRequest(request.requestId, now: now);

      final updated = await repository.getById(request.requestId);
      expect(updated!.status, RoomRequestStatus.cancelled);
    });

    test('rejects cancelling an already-confirmed request', () async {
      final confirmed = await repository.create(RoomRequest(
        requestId: '',
        studentId: 'student-e',
        roomId: 'room-1',
        propertyId: 'property-x',
        landlordId: 'landlord-test',
        status: RoomRequestStatus.confirmed,
        confirmedAt: now,
        createdAt: now,
      ));

      expect(
        () => service.cancelRequest(confirmed.requestId, now: now),
        throwsA(isA<RoomRequestException>()),
      );
    });
  });

  group('countActiveHolds', () {
    test('excludes live-expired holds', () async {
      await service.requestRoom(
        studentId: 'student-f',
        room: _room(roomId: 'r1'),
        landlordId: 'l',
        now: now,
      );
      await service.requestRoom(
        studentId: 'student-f',
        room: _room(roomId: 'r2'),
        landlordId: 'l',
        now: now,
      );

      expect(await service.countActiveHolds('student-f', now: now), 2);
      expect(
        await service.countActiveHolds(
          'student-f',
          now: now.add(const Duration(hours: 25)),
        ),
        0,
      );
    });
  });
}
