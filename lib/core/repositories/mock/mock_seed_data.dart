import '../../models/models.dart';

/// Static, deterministic sample data shared by every mock repository so that
/// foreign keys stay consistent across entities (e.g. a seeded [Room]
/// always points at a [Property] that also exists in [mockProperties]).
///
/// Addresses are Legazpi City / Daraga, Albay; prices are PHP; the sample
/// campus is Bicol University, as requested in the spec.
class MockSeedData {
  MockSeedData._();

  static final DateTime _seedNow = DateTime(2026, 9, 1);

  // ---------------------------------------------------------------------
  // Campuses
  // ---------------------------------------------------------------------
  static final List<Campus> campuses = [
    const Campus(
      campusId: 'campus-001',
      name: 'Bicol University',
      latitude: 13.1417,
      longitude: 123.7272,
    ),
    const Campus(
      campusId: 'campus-002',
      name: 'Aquinas University of Legazpi',
      latitude: 13.1439,
      longitude: 123.7345,
    ),
  ];

  // ---------------------------------------------------------------------
  // Users
  // ---------------------------------------------------------------------
  static final List<User> users = [
    const User(
      userId: 'user-001',
      name: 'Grace Imperial',
      email: 'grace.admin@boardie.io',
      contactNo: '09171234501',
      role: UserRole.admin,
      status: UserStatus.active,
    ),
    const User(
      userId: 'user-002',
      name: 'Ramon Bicol',
      email: 'ramon.landlord@boardie.io',
      contactNo: '09171234502',
      role: UserRole.landlord,
      status: UserStatus.active,
    ),
    const User(
      userId: 'user-003',
      name: 'Liza Formento',
      email: 'liza.landlord@boardie.io',
      contactNo: '09171234503',
      role: UserRole.landlord,
      status: UserStatus.active,
    ),
    const User(
      userId: 'user-004',
      name: 'Dante Rosales',
      email: 'dante.landlord@boardie.io',
      contactNo: '09171234504',
      role: UserRole.landlord,
      status: UserStatus.suspended,
    ),
    const User(
      userId: 'user-005',
      name: 'Anna Marasigan',
      email: 'anna.student@boardie.io',
      contactNo: '09171234505',
      role: UserRole.student,
      status: UserStatus.active,
    ),
    const User(
      userId: 'user-006',
      name: 'Miguel Salceda',
      email: 'miguel.student@boardie.io',
      contactNo: '09171234506',
      role: UserRole.student,
      status: UserStatus.active,
    ),
    const User(
      userId: 'user-007',
      name: 'Bea Oliveros',
      email: 'bea.student@boardie.io',
      contactNo: '09171234507',
      role: UserRole.student,
      status: UserStatus.active,
    ),
    const User(
      userId: 'user-008',
      name: 'Carlo Nierva',
      email: 'carlo.student@boardie.io',
      contactNo: '09171234508',
      role: UserRole.student,
      status: UserStatus.active,
    ),
  ];

  // ---------------------------------------------------------------------
  // LandlordProfiles
  // ---------------------------------------------------------------------
  static final List<LandlordProfile> landlordProfiles = [
    const LandlordProfile(
      landlordId: 'landlord-001',
      userId: 'user-002',
      contactNo: '09221234501',
      verificationStatus: VerificationStatus.verified,
    ),
    const LandlordProfile(
      landlordId: 'landlord-002',
      userId: 'user-003',
      contactNo: '09221234502',
      verificationStatus: VerificationStatus.pending,
    ),
    const LandlordProfile(
      landlordId: 'landlord-003',
      userId: 'user-004',
      contactNo: '09221234503',
      verificationStatus: VerificationStatus.rejected,
    ),
  ];

  // ---------------------------------------------------------------------
  // StudentProfiles
  // ---------------------------------------------------------------------
  static final List<StudentProfile> studentProfiles = [
    const StudentProfile(
      studentId: 'student-001',
      userId: 'user-005',
      campusId: 'campus-001',
      preferences: {'budget_max': 4000, 'room_type': 'solo'},
    ),
    const StudentProfile(
      studentId: 'student-002',
      userId: 'user-006',
      campusId: 'campus-001',
      preferences: {'budget_max': 3000, 'room_type': 'shared'},
    ),
    const StudentProfile(
      studentId: 'student-003',
      userId: 'user-007',
      campusId: 'campus-002',
      preferences: {'budget_max': 5000, 'amenities': ['wifi', 'aircon']},
    ),
    const StudentProfile(
      studentId: 'student-004',
      userId: 'user-008',
      campusId: 'campus-001',
      preferences: {'budget_max': 3500, 'room_type': 'shared'},
    ),
  ];

  // ---------------------------------------------------------------------
  // Properties
  // ---------------------------------------------------------------------
  static final List<Property> properties = [
    Property(
      propertyId: 'property-001',
      landlordId: 'landlord-001',
      name: 'Casa Bicolana Dormitory',
      address: 'Rizal St, Legazpi City, Albay',
      latitude: 13.1391,
      longitude: 123.7438,
      storeys: 3,
      verificationStatus: VerificationStatus.verified,
      minPrice: 3500,
      utilitiesUpdatedAt: _seedNow.subtract(const Duration(days: 5)),
      createdAt: _seedNow.subtract(const Duration(days: 200)),
    ),
    Property(
      propertyId: 'property-002',
      landlordId: 'landlord-001',
      name: 'Embarcadero Student Suites',
      address: 'Washington Dr, Legazpi City, Albay',
      latitude: 13.1524,
      longitude: 123.7532,
      storeys: 2,
      verificationStatus: VerificationStatus.verified,
      minPrice: 4500,
      utilitiesUpdatedAt: _seedNow.subtract(const Duration(days: 10)),
      createdAt: _seedNow.subtract(const Duration(days: 180)),
    ),
    Property(
      propertyId: 'property-003',
      landlordId: 'landlord-002',
      name: 'Daraga Hillside Boarding House',
      address: 'Purok 3, Daraga, Albay',
      latitude: 13.1569,
      longitude: 123.6961,
      storeys: 2,
      verificationStatus: VerificationStatus.pending,
      minPrice: 3000,
      utilitiesUpdatedAt: null,
      createdAt: _seedNow.subtract(const Duration(days: 60)),
    ),
    Property(
      propertyId: 'property-004',
      landlordId: 'landlord-002',
      name: 'BU Gate Transient Rooms',
      address: 'Rawis, Legazpi City, Albay',
      latitude: 13.1465,
      longitude: 123.7301,
      storeys: 1,
      verificationStatus: VerificationStatus.verified,
      minPrice: 2800,
      utilitiesUpdatedAt: _seedNow.subtract(const Duration(days: 2)),
      createdAt: _seedNow.subtract(const Duration(days: 90)),
    ),
    Property(
      propertyId: 'property-005',
      landlordId: 'landlord-003',
      name: 'Mayon View Apartments',
      address: 'Km 8, Daraga, Albay',
      latitude: 13.1614,
      longitude: 123.6875,
      storeys: 3,
      verificationStatus: VerificationStatus.rejected,
      minPrice: 5000,
      utilitiesUpdatedAt: _seedNow.subtract(const Duration(days: 30)),
      createdAt: _seedNow.subtract(const Duration(days: 120)),
    ),
    Property(
      propertyId: 'property-006',
      landlordId: 'landlord-001',
      name: 'Albay Park Residences',
      address: 'Bonifacio St, Legazpi City, Albay',
      latitude: 13.1355,
      longitude: 123.7355,
      storeys: 4,
      verificationStatus: VerificationStatus.verified,
      minPrice: 4000,
      utilitiesUpdatedAt: _seedNow.subtract(const Duration(days: 1)),
      createdAt: _seedNow.subtract(const Duration(days: 45)),
    ),
  ];

  // ---------------------------------------------------------------------
  // Rooms
  // ---------------------------------------------------------------------
  static final List<Room> rooms = [
    Room(
      roomId: 'room-001',
      propertyId: 'property-001',
      roomType: 'Solo',
      capacity: 1,
      currentOccupancy: 0,
      heldCount: 0,
      rentPrice: 3500,
      availabilityUpdatedAt: _seedNow.subtract(const Duration(days: 5)),
    ),
    Room(
      roomId: 'room-002',
      propertyId: 'property-001',
      roomType: 'Shared (2-bed)',
      capacity: 2,
      currentOccupancy: 1,
      heldCount: 0,
      rentPrice: 2800,
      availabilityUpdatedAt: _seedNow.subtract(const Duration(days: 5)),
    ),
    Room(
      roomId: 'room-003',
      propertyId: 'property-002',
      roomType: 'Solo',
      capacity: 1,
      currentOccupancy: 1,
      heldCount: 0,
      rentPrice: 4500,
      availabilityUpdatedAt: _seedNow.subtract(const Duration(days: 10)),
    ),
    Room(
      roomId: 'room-004',
      propertyId: 'property-002',
      roomType: 'Shared (4-bed)',
      capacity: 4,
      currentOccupancy: 3,
      heldCount: 1,
      rentPrice: 3200,
      availabilityUpdatedAt: _seedNow.subtract(const Duration(days: 3)),
    ),
    Room(
      roomId: 'room-005',
      propertyId: 'property-003',
      roomType: 'Shared (2-bed)',
      capacity: 2,
      currentOccupancy: 0,
      heldCount: 0,
      rentPrice: 3000,
      availabilityUpdatedAt: _seedNow.subtract(const Duration(days: 60)),
    ),
    Room(
      roomId: 'room-006',
      propertyId: 'property-004',
      roomType: 'Solo',
      capacity: 1,
      currentOccupancy: 1,
      heldCount: 0,
      rentPrice: 2800,
      availabilityUpdatedAt: _seedNow.subtract(const Duration(days: 2)),
    ),
    Room(
      roomId: 'room-007',
      propertyId: 'property-004',
      roomType: 'Shared (3-bed)',
      capacity: 3,
      currentOccupancy: 3,
      heldCount: 0,
      rentPrice: 2500,
      availabilityUpdatedAt: _seedNow.subtract(const Duration(days: 2)),
    ),
    Room(
      roomId: 'room-008',
      propertyId: 'property-005',
      roomType: 'Solo',
      capacity: 1,
      currentOccupancy: 0,
      heldCount: 0,
      rentPrice: 5000,
      availabilityUpdatedAt: _seedNow.subtract(const Duration(days: 30)),
    ),
    Room(
      roomId: 'room-009',
      propertyId: 'property-006',
      roomType: 'Shared (2-bed)',
      capacity: 2,
      currentOccupancy: 1,
      heldCount: 1,
      rentPrice: 4000,
      availabilityUpdatedAt: _seedNow.subtract(const Duration(days: 1)),
    ),
    Room(
      roomId: 'room-010',
      propertyId: 'property-006',
      roomType: 'Solo',
      capacity: 1,
      currentOccupancy: 0,
      heldCount: 0,
      rentPrice: 4800,
      availabilityUpdatedAt: _seedNow.subtract(const Duration(days: 1)),
    ),
  ];

  // ---------------------------------------------------------------------
  // Amenities
  // ---------------------------------------------------------------------
  static final List<Amenity> amenities = [
    const Amenity(
        amenityId: 'amenity-001',
        propertyId: 'property-001',
        amenityName: 'Free WiFi'),
    const Amenity(
        amenityId: 'amenity-002',
        propertyId: 'property-001',
        amenityName: 'CCTV Security'),
    const Amenity(
        amenityId: 'amenity-003',
        propertyId: 'property-002',
        amenityName: 'Air Conditioning'),
    const Amenity(
        amenityId: 'amenity-004',
        propertyId: 'property-002',
        amenityName: 'Study Lounge'),
    const Amenity(
        amenityId: 'amenity-005',
        propertyId: 'property-003',
        amenityName: 'Free WiFi'),
    const Amenity(
        amenityId: 'amenity-006',
        propertyId: 'property-004',
        amenityName: 'Motorcycle Parking'),
    const Amenity(
        amenityId: 'amenity-007',
        propertyId: 'property-005',
        amenityName: 'Balcony View of Mayon'),
    const Amenity(
        amenityId: 'amenity-008',
        propertyId: 'property-006',
        amenityName: 'Elevator'),
    const Amenity(
        amenityId: 'amenity-009',
        propertyId: 'property-006',
        amenityName: 'Laundry Area'),
  ];

  // ---------------------------------------------------------------------
  // PropertyImages
  // ---------------------------------------------------------------------
  static final List<PropertyImage> propertyImages = [
    const PropertyImage(
      imageId: 'image-001',
      propertyId: 'property-001',
      imageUrl: 'https://picsum.photos/seed/property-001-a/800/600',
    ),
    const PropertyImage(
      imageId: 'image-002',
      propertyId: 'property-001',
      imageUrl: 'https://picsum.photos/seed/property-001-b/800/600',
    ),
    const PropertyImage(
      imageId: 'image-003',
      propertyId: 'property-002',
      imageUrl: 'https://picsum.photos/seed/property-002-a/800/600',
    ),
    const PropertyImage(
      imageId: 'image-004',
      propertyId: 'property-003',
      imageUrl: 'https://picsum.photos/seed/property-003-a/800/600',
    ),
    const PropertyImage(
      imageId: 'image-005',
      propertyId: 'property-004',
      imageUrl: 'https://picsum.photos/seed/property-004-a/800/600',
    ),
    const PropertyImage(
      imageId: 'image-006',
      propertyId: 'property-005',
      imageUrl: 'https://picsum.photos/seed/property-005-a/800/600',
    ),
    const PropertyImage(
      imageId: 'image-007',
      propertyId: 'property-006',
      imageUrl: 'https://picsum.photos/seed/property-006-a/800/600',
    ),
    const PropertyImage(
      imageId: 'image-008',
      propertyId: 'property-006',
      imageUrl: 'https://picsum.photos/seed/property-006-b/800/600',
    ),
  ];

  // ---------------------------------------------------------------------
  // VisitRequests
  // ---------------------------------------------------------------------
  static final List<VisitRequest> visitRequests = [
    VisitRequest(
      visitId: 'visit-001',
      studentId: 'student-001',
      propertyId: 'property-001',
      landlordId: 'landlord-001',
      status: VisitRequestStatus.completed,
      requestedDatetime: _seedNow.subtract(const Duration(days: 20)),
      respondedDatetime: _seedNow.subtract(const Duration(days: 19)),
      createdAt: _seedNow.subtract(const Duration(days: 21)),
    ),
    VisitRequest(
      visitId: 'visit-002',
      studentId: 'student-002',
      propertyId: 'property-002',
      landlordId: 'landlord-001',
      status: VisitRequestStatus.accepted,
      requestedDatetime: _seedNow.add(const Duration(days: 2)),
      respondedDatetime: _seedNow.subtract(const Duration(days: 1)),
      createdAt: _seedNow.subtract(const Duration(days: 3)),
    ),
    VisitRequest(
      visitId: 'visit-003',
      studentId: 'student-003',
      propertyId: 'property-004',
      landlordId: 'landlord-002',
      status: VisitRequestStatus.pending,
      requestedDatetime: _seedNow.add(const Duration(days: 5)),
      respondedDatetime: null,
      createdAt: _seedNow.subtract(const Duration(days: 1)),
    ),
    VisitRequest(
      visitId: 'visit-004',
      studentId: 'student-004',
      propertyId: 'property-006',
      landlordId: 'landlord-001',
      status: VisitRequestStatus.declined,
      requestedDatetime: _seedNow.subtract(const Duration(days: 10)),
      respondedDatetime: _seedNow.subtract(const Duration(days: 9)),
      createdAt: _seedNow.subtract(const Duration(days: 11)),
    ),
    VisitRequest(
      visitId: 'visit-005',
      studentId: 'student-001',
      propertyId: 'property-003',
      landlordId: 'landlord-002',
      status: VisitRequestStatus.rescheduled,
      requestedDatetime: _seedNow.add(const Duration(days: 1)),
      respondedDatetime: _seedNow.subtract(const Duration(hours: 12)),
      createdAt: _seedNow.subtract(const Duration(days: 4)),
    ),
    VisitRequest(
      visitId: 'visit-006',
      studentId: 'student-002',
      propertyId: 'property-005',
      landlordId: 'landlord-003',
      status: VisitRequestStatus.cancelled,
      requestedDatetime: _seedNow.subtract(const Duration(days: 15)),
      respondedDatetime: null,
      createdAt: _seedNow.subtract(const Duration(days: 16)),
    ),
  ];

  // ---------------------------------------------------------------------
  // RoomRequests
  // ---------------------------------------------------------------------
  static final List<RoomRequest> roomRequests = [
    RoomRequest(
      requestId: 'request-001',
      studentId: 'student-002',
      roomId: 'room-004',
      propertyId: 'property-002',
      landlordId: 'landlord-001',
      status: RoomRequestStatus.confirmed,
      heldUntil: null,
      approvedAt: _seedNow.subtract(const Duration(days: 6)),
      confirmedAt: _seedNow.subtract(const Duration(days: 5)),
      createdAt: _seedNow.subtract(const Duration(days: 7)),
    ),
    RoomRequest(
      requestId: 'request-002',
      studentId: 'student-004',
      roomId: 'room-009',
      propertyId: 'property-006',
      landlordId: 'landlord-001',
      status: RoomRequestStatus.approved,
      // Anchored to real wall-clock time (not _seedNow) so this hold still
      // reads as "active" no matter how long after the seed date the app
      // is actually run -- see RoomRequestRepository.getActiveHoldsForRoom.
      heldUntil: DateTime.now().add(const Duration(days: 2)),
      approvedAt: _seedNow.subtract(const Duration(days: 1)),
      confirmedAt: null,
      createdAt: _seedNow.subtract(const Duration(days: 2)),
    ),
    RoomRequest(
      requestId: 'request-003',
      studentId: 'student-001',
      roomId: 'room-001',
      propertyId: 'property-001',
      landlordId: 'landlord-001',
      status: RoomRequestStatus.pending,
      // See the note on request-002 above.
      heldUntil: DateTime.now().add(const Duration(days: 1)),
      approvedAt: null,
      confirmedAt: null,
      createdAt: _seedNow.subtract(const Duration(hours: 6)),
    ),
    RoomRequest(
      requestId: 'request-004',
      studentId: 'student-003',
      roomId: 'room-006',
      propertyId: 'property-004',
      landlordId: 'landlord-002',
      status: RoomRequestStatus.declined,
      heldUntil: null,
      approvedAt: null,
      confirmedAt: null,
      createdAt: _seedNow.subtract(const Duration(days: 8)),
    ),
    RoomRequest(
      requestId: 'request-005',
      studentId: 'student-002',
      roomId: 'room-003',
      propertyId: 'property-002',
      landlordId: 'landlord-001',
      status: RoomRequestStatus.expired,
      heldUntil: _seedNow.subtract(const Duration(days: 1)),
      approvedAt: _seedNow.subtract(const Duration(days: 4)),
      confirmedAt: null,
      createdAt: _seedNow.subtract(const Duration(days: 5)),
    ),
    RoomRequest(
      requestId: 'request-006',
      studentId: 'student-004',
      roomId: 'room-005',
      propertyId: 'property-003',
      landlordId: 'landlord-002',
      status: RoomRequestStatus.cancelled,
      heldUntil: null,
      approvedAt: null,
      confirmedAt: null,
      createdAt: _seedNow.subtract(const Duration(days: 12)),
    ),
  ];

  // ---------------------------------------------------------------------
  // SavedProperties
  // ---------------------------------------------------------------------
  static final List<SavedProperty> savedProperties = [
    SavedProperty(
      saveId: 'save-001',
      studentId: 'student-001',
      propertyId: 'property-002',
      savedAt: _seedNow.subtract(const Duration(days: 10)),
    ),
    SavedProperty(
      saveId: 'save-002',
      studentId: 'student-001',
      propertyId: 'property-006',
      savedAt: _seedNow.subtract(const Duration(days: 8)),
    ),
    SavedProperty(
      saveId: 'save-003',
      studentId: 'student-002',
      propertyId: 'property-001',
      savedAt: _seedNow.subtract(const Duration(days: 7)),
    ),
    SavedProperty(
      saveId: 'save-004',
      studentId: 'student-003',
      propertyId: 'property-004',
      savedAt: _seedNow.subtract(const Duration(days: 3)),
    ),
    SavedProperty(
      saveId: 'save-005',
      studentId: 'student-004',
      propertyId: 'property-006',
      savedAt: _seedNow.subtract(const Duration(days: 2)),
    ),
    SavedProperty(
      saveId: 'save-006',
      studentId: 'student-002',
      propertyId: 'property-003',
      savedAt: _seedNow.subtract(const Duration(days: 1)),
    ),
  ];

  // ---------------------------------------------------------------------
  // ReportedListings
  // ---------------------------------------------------------------------
  static final List<ReportedListing> reportedListings = [
    const ReportedListing(
      reportIssueId: 'reportissue-001',
      propertyId: 'property-005',
      reportedBy: 'user-005',
      reason: 'Listing photos do not match the actual unit.',
      reviewStatus: ReportedListingReviewStatus.pending,
    ),
    const ReportedListing(
      reportIssueId: 'reportissue-002',
      propertyId: 'property-003',
      reportedBy: 'user-006',
      reason: 'Landlord asked for payment before a signed contract.',
      reviewStatus: ReportedListingReviewStatus.reviewed,
    ),
    const ReportedListing(
      reportIssueId: 'reportissue-003',
      propertyId: 'property-004',
      reportedBy: 'user-007',
      reason: 'Advertised price does not match what was quoted.',
      reviewStatus: ReportedListingReviewStatus.dismissed,
    ),
    const ReportedListing(
      reportIssueId: 'reportissue-004',
      propertyId: 'property-005',
      reportedBy: 'user-008',
      reason: 'Property appears to already be closed/demolished.',
      reviewStatus: ReportedListingReviewStatus.pending,
    ),
  ];

  // ---------------------------------------------------------------------
  // Reports
  // ---------------------------------------------------------------------
  static final List<Report> reports = [
    Report(
      reportId: 'report-001',
      createdBy: 'user-001',
      reportType: 'monthly_verification_summary',
      dateGenerated: _seedNow.subtract(const Duration(days: 30)),
      fileUrl: 'https://files.boardie.io/reports/report-001.pdf',
    ),
    Report(
      reportId: 'report-002',
      createdBy: 'user-001',
      reportType: 'flagged_listings_summary',
      dateGenerated: _seedNow.subtract(const Duration(days: 15)),
      fileUrl: 'https://files.boardie.io/reports/report-002.pdf',
    ),
    Report(
      reportId: 'report-003',
      createdBy: 'user-001',
      reportType: 'active_room_requests_summary',
      dateGenerated: _seedNow.subtract(const Duration(days: 7)),
      fileUrl: 'https://files.boardie.io/reports/report-003.pdf',
    ),
    Report(
      reportId: 'report-004',
      createdBy: 'user-001',
      reportType: 'landlord_verification_audit',
      dateGenerated: _seedNow,
      fileUrl: 'https://files.boardie.io/reports/report-004.pdf',
    ),
  ];
}
