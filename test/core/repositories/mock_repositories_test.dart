import 'package:flutter_test/flutter_test.dart';

import 'package:boardie/core/models/models.dart';
import 'package:boardie/core/repositories/mock/mock_repositories.dart';

void main() {
  group('Model fromMap/toMap round-trip', () {
    test('User round-trips through map', () {
      const user = User(
        userId: 'user-999',
        name: 'Test User',
        email: 'test@boardie.io',
        contactNo: '09170000000',
        role: UserRole.student,
        status: UserStatus.active,
      );
      final map = user.toMap();
      expect(map['role'], 'student');
      expect(map['status'], 'active');
      final rebuilt = User.fromMap(map);
      expect(rebuilt.userId, user.userId);
      expect(rebuilt.role, user.role);
    });

    test('Property round-trips nullable utilities_updated_at', () {
      final property = Property(
        propertyId: 'property-999',
        landlordId: 'landlord-001',
        name: 'Test Property',
        address: 'Test Address',
        latitude: 13.14,
        longitude: 123.74,
        storeys: 2,
        verificationStatus: VerificationStatus.pending,
        minPrice: 3000,
        utilitiesUpdatedAt: null,
        createdAt: DateTime(2026, 1, 1),
      );
      final map = property.toMap();
      expect(map['utilities_updated_at'], isNull);
      final rebuilt = Property.fromMap(map);
      expect(rebuilt.utilitiesUpdatedAt, isNull);
      expect(rebuilt.createdAt, property.createdAt);
    });

    test('StudentProfile preferences map round-trips', () {
      final profile = MockSeedData.studentProfiles.first;
      final rebuilt = StudentProfile.fromMap(profile.toMap());
      expect(rebuilt.preferences, profile.preferences);
    });
  });

  group('MockUserRepository', () {
    test('seeded with sample rows and supports CRUD', () async {
      final repo = MockUserRepository();
      final all = await repo.getAll();
      expect(all.length, greaterThanOrEqualTo(5));

      final byEmail = await repo.getByEmail('grace.admin@boardie.io');
      expect(byEmail, isNotNull);
      expect(byEmail!.role, UserRole.admin);

      final students = await repo.getByRole(UserRole.student);
      expect(students, isNotEmpty);
      expect(students.every((u) => u.role == UserRole.student), isTrue);

      final created = await repo.create(const User(
        userId: '',
        name: 'New User',
        email: 'new@boardie.io',
        contactNo: '09170000001',
        role: UserRole.student,
        status: UserStatus.active,
      ));
      expect(created.userId, isNotEmpty);
      expect(await repo.getById(created.userId), isNotNull);

      await repo.delete(created.userId);
      expect(await repo.getById(created.userId), isNull);
    });
  });

  group('MockPropertyRepository', () {
    test('getByLandlord and getByVerificationStatus filter correctly',
        () async {
      final repo = MockPropertyRepository();
      final landlordProperties = await repo.getByLandlord('landlord-001');
      expect(landlordProperties, isNotEmpty);
      expect(
        landlordProperties.every((p) => p.landlordId == 'landlord-001'),
        isTrue,
      );

      final verified =
          await repo.getByVerificationStatus(VerificationStatus.verified);
      expect(verified, isNotEmpty);
      expect(
        verified.every((p) => p.verificationStatus == VerificationStatus.verified),
        isTrue,
      );
    });
  });

  group('MockRoomRequestRepository', () {
    test('getActiveHoldsForRoom returns only pending/approved/confirmed',
        () async {
      final repo = MockRoomRequestRepository();

      final activeForRoom004 = await repo.getActiveHoldsForRoom('room-004');
      expect(activeForRoom004, isNotEmpty);
      expect(
        activeForRoom004.every((r) =>
            r.status == RoomRequestStatus.pending ||
            r.status == RoomRequestStatus.approved ||
            r.status == RoomRequestStatus.confirmed),
        isTrue,
      );

      // room-003's only request is expired with a past held_until, so it
      // should NOT show up as an active hold.
      final activeForRoom003 = await repo.getActiveHoldsForRoom('room-003');
      expect(activeForRoom003, isEmpty);
    });
  });

  group('MockSavedPropertyRepository', () {
    test('isSaved reflects seeded saves', () async {
      final repo = MockSavedPropertyRepository();
      expect(await repo.isSaved('student-001', 'property-002'), isTrue);
      expect(await repo.isSaved('student-001', 'property-005'), isFalse);
    });
  });

  group('Room.occupancyStatus', () {
    test('derives available/limited/full from occupancy vs capacity', () {
      final now = DateTime(2026, 1, 1);
      final full = Room(
        roomId: 'r1',
        propertyId: 'p1',
        roomType: 'Solo',
        capacity: 1,
        currentOccupancy: 1,
        heldCount: 0,
        rentPrice: 1000,
        availabilityUpdatedAt: now,
      );
      expect(full.occupancyStatus, RoomAvailabilityStatus.full);

      final available = Room(
        roomId: 'r2',
        propertyId: 'p1',
        roomType: 'Shared',
        capacity: 4,
        currentOccupancy: 1,
        heldCount: 0,
        rentPrice: 1000,
        availabilityUpdatedAt: now,
      );
      expect(available.occupancyStatus, RoomAvailabilityStatus.available);
    });
  });
}
