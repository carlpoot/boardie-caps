// Shared enums for Boardie domain models.
//
// Every enum stores/parses its wire value as the exact snake_case string
// used in the ERD so that `fromMap`/`toMap` round-trip cleanly with a
// future Firestore backend.

// TODO: confirm enum values
enum UserRole {
  guest,
  student,
  landlord,
  admin;

  String get value => name;

  static UserRole fromValue(String value) => UserRole.values.firstWhere(
        (e) => e.value == value,
        orElse: () => throw ArgumentError('Unknown UserRole: $value'),
      );
}

// TODO: confirm enum values
enum UserStatus {
  active,
  suspended;

  String get value => name;

  static UserStatus fromValue(String value) => UserStatus.values.firstWhere(
        (e) => e.value == value,
        orElse: () => throw ArgumentError('Unknown UserStatus: $value'),
      );
}

/// Used by both `LandlordProfiles.verification_status` and
/// `Properties.verification_status`.
// TODO: confirm enum values
enum VerificationStatus {
  pending,
  verified,
  rejected;

  String get value => name;

  static VerificationStatus fromValue(String value) =>
      VerificationStatus.values.firstWhere(
        (e) => e.value == value,
        orElse: () => throw ArgumentError('Unknown VerificationStatus: $value'),
      );
}

/// Derived from `current_occupancy` vs `capacity` — NOT a stored field.
/// `reserved` is driven separately by an active `confirmed` RoomRequest.
/// Matches the map legend in the wireframes: Available / Limited / Full / Reserved.
// TODO: confirm enum values
enum RoomAvailabilityStatus {
  available,
  limited,
  full,
  reserved;

  String get value => name;
}

// TODO: confirm enum values
enum VisitRequestStatus {
  pending,
  accepted,
  rescheduled,
  declined,
  completed,
  cancelled;

  String get value => name;

  static VisitRequestStatus fromValue(String value) =>
      VisitRequestStatus.values.firstWhere(
        (e) => e.value == value,
        orElse: () => throw ArgumentError('Unknown VisitRequestStatus: $value'),
      );
}

// TODO: confirm enum values
enum RoomRequestStatus {
  pending,
  approved,
  confirmed,
  declined,
  expired,
  cancelled;

  String get value => name;

  static RoomRequestStatus fromValue(String value) =>
      RoomRequestStatus.values.firstWhere(
        (e) => e.value == value,
        orElse: () => throw ArgumentError('Unknown RoomRequestStatus: $value'),
      );
}

// TODO: confirm enum values
enum ReportedListingReviewStatus {
  pending,
  reviewed,
  dismissed;

  String get value => name;

  static ReportedListingReviewStatus fromValue(String value) =>
      ReportedListingReviewStatus.values.firstWhere(
        (e) => e.value == value,
        orElse: () =>
            throw ArgumentError('Unknown ReportedListingReviewStatus: $value'),
      );
}
