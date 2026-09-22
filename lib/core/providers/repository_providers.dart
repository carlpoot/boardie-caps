import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../repositories/repositories.dart';
import '../repositories/mock/mock_repositories.dart';

/// Repository providers.
///
/// Every provider here exposes the *abstract* repository interface, backed
/// today by an in-memory mock implementation. When Firebase is wired up in
/// a later phase, only the `override` on the right-hand side of each
/// provider needs to change (e.g. to a `FirestoreUserRepository`) — no UI
/// code that depends on `userRepositoryProvider` etc. needs to change.
final userRepositoryProvider = Provider<UserRepository>(
  (ref) => MockUserRepository(),
);

final landlordProfileRepositoryProvider = Provider<LandlordProfileRepository>(
  (ref) => MockLandlordProfileRepository(),
);

final studentProfileRepositoryProvider = Provider<StudentProfileRepository>(
  (ref) => MockStudentProfileRepository(),
);

final campusRepositoryProvider = Provider<CampusRepository>(
  (ref) => MockCampusRepository(),
);

final propertyRepositoryProvider = Provider<PropertyRepository>(
  (ref) => MockPropertyRepository(),
);

final roomRepositoryProvider = Provider<RoomRepository>(
  (ref) => MockRoomRepository(),
);

final amenityRepositoryProvider = Provider<AmenityRepository>(
  (ref) => MockAmenityRepository(),
);

final propertyImageRepositoryProvider = Provider<PropertyImageRepository>(
  (ref) => MockPropertyImageRepository(),
);

final visitRequestRepositoryProvider = Provider<VisitRequestRepository>(
  (ref) => MockVisitRequestRepository(),
);

final roomRequestRepositoryProvider = Provider<RoomRequestRepository>(
  (ref) => MockRoomRequestRepository(),
);

final savedPropertyRepositoryProvider = Provider<SavedPropertyRepository>(
  (ref) => MockSavedPropertyRepository(),
);

final reportedListingRepositoryProvider = Provider<ReportedListingRepository>(
  (ref) => MockReportedListingRepository(),
);

final reportRepositoryProvider = Provider<ReportRepository>(
  (ref) => MockReportRepository(),
);
