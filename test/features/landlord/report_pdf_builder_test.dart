import 'package:flutter_test/flutter_test.dart';

import 'package:boardie/core/models/models.dart';
import 'package:boardie/core/services/room_availability_service.dart';
import 'package:boardie/features/landlord/reports/report_pdf_builder.dart';
import 'package:boardie/features/landlord/room_requests/landlord_room_requests_providers.dart';
import 'package:boardie/features/landlord/visit_requests/landlord_visit_requests_providers.dart';

Property _property() => Property(
      propertyId: 'property-x',
      landlordId: 'landlord-x',
      name: 'Test Property',
      address: '123 Test St',
      latitude: 13.14,
      longitude: 123.74,
      storeys: 2,
      verificationStatus: VerificationStatus.verified,
      minPrice: 3000,
      createdAt: DateTime(2026, 1, 1),
    );

Room _room() => Room(
      roomId: 'room-x',
      propertyId: 'property-x',
      roomType: 'Solo',
      capacity: 2,
      currentOccupancy: 1,
      heldCount: 0,
      rentPrice: 1500,
      availabilityUpdatedAt: DateTime(2026, 1, 1),
    );

/// Every real PDF starts with this magic header.
void _expectValidPdf(List<int> bytes) {
  expect(bytes, isNotEmpty);
  expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
}

void main() {
  test('buildListingsReportPdf produces a valid, non-empty PDF', () async {
    final bytes = await buildListingsReportPdf([_property()]);
    _expectValidPdf(bytes);
  });

  test('buildRoomAvailabilityReportPdf produces a valid, non-empty PDF', () async {
    final bytes = await buildRoomAvailabilityReportPdf([
      (
        property: _property(),
        room: _room(),
        availability: const RoomAvailability(
          availableSlots: 1,
          status: RoomAvailabilityStatus.available,
        ),
      ),
    ]);
    _expectValidPdf(bytes);
  });

  test('buildOccupancyReportPdf produces a valid, non-empty PDF', () async {
    final bytes = await buildOccupancyReportPdf([(property: _property(), room: _room())]);
    _expectValidPdf(bytes);
  });

  test('buildReservationReportPdf covers both VisitRequests and RoomRequests',
      () async {
    final visitRequest = VisitRequest(
      visitId: 'visit-x',
      studentId: 'student-x',
      propertyId: 'property-x',
      landlordId: 'landlord-x',
      status: VisitRequestStatus.pending,
      requestedDatetime: DateTime(2026, 2, 1),
      createdAt: DateTime(2026, 1, 1),
    );
    final roomRequest = RoomRequest(
      requestId: 'request-x',
      studentId: 'student-x',
      roomId: 'room-x',
      propertyId: 'property-x',
      landlordId: 'landlord-x',
      status: RoomRequestStatus.pending,
      createdAt: DateTime(2026, 1, 1),
    );

    final bytes = await buildReservationReportPdf(
      visitRequests: [
        LandlordVisitRequestItem(
          request: visitRequest,
          propertyName: 'Test Property',
          studentName: 'Test Student',
        ),
      ],
      roomRequests: [
        LandlordRoomRequestItem(
          request: roomRequest,
          propertyName: 'Test Property',
          roomType: 'Solo',
          studentName: 'Test Student',
          effectiveStatus: RoomRequestStatus.pending,
        ),
      ],
    );
    _expectValidPdf(bytes);
  });

  test('report builders handle an empty data set without throwing', () async {
    _expectValidPdf(await buildListingsReportPdf([]));
    _expectValidPdf(await buildRoomAvailabilityReportPdf([]));
    _expectValidPdf(await buildOccupancyReportPdf([]));
    _expectValidPdf(await buildReservationReportPdf(visitRequests: [], roomRequests: []));
  });
}
