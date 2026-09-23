import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../../core/models/models.dart';
import '../../../core/services/room_availability_service.dart';
import '../room_requests/landlord_room_requests_providers.dart';
import '../visit_requests/landlord_visit_requests_providers.dart';

/// Pure PDF-byte builders (no Riverpod/BuildContext dependency), one per
/// `report_type`, so they're directly unit-testable without needing the
/// `printing` package's platform channel.
final _dateFormat = DateFormat('MMM d, y · h:mm a');

// The pdf package's built-in base-14 fonts (Helvetica) have no glyph for
// the peso sign (U+20B1), so PDF output uses the "PHP" prefix instead of
// the '₱' symbol the rest of the UI uses -- otherwise the character is
// silently dropped from the rendered page.
final _priceFormat = NumberFormat.currency(locale: 'en_PH', symbol: 'PHP ', decimalDigits: 0);

pw.Widget _reportHeader(String title) => pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(title, style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
        pw.Text('Generated: ${_dateFormat.format(DateTime.now())}'),
        pw.SizedBox(height: 16),
      ],
    );

/// report_type = "listings".
Future<Uint8List> buildListingsReportPdf(List<Property> properties) async {
  final doc = pw.Document();
  doc.addPage(
    pw.MultiPage(
      build: (context) => [
        _reportHeader('Property Listings Report'),
        pw.TableHelper.fromTextArray(
          headers: ['Name', 'Address', 'Storeys', 'Min Price', 'Status', 'Created'],
          data: properties
              .map((p) => [
                    p.name,
                    p.address,
                    '${p.storeys}',
                    _priceFormat.format(p.minPrice),
                    p.verificationStatus.value,
                    _dateFormat.format(p.createdAt),
                  ])
              .toList(),
        ),
      ],
    ),
  );
  return doc.save();
}

/// report_type = "room_availability" -- the same live [RoomAvailability]
/// computation the student side sees, per property.
Future<Uint8List> buildRoomAvailabilityReportPdf(
  List<({Property property, Room room, RoomAvailability availability})> rows,
) async {
  final doc = pw.Document();
  doc.addPage(
    pw.MultiPage(
      build: (context) => [
        _reportHeader('Room Availability Report'),
        pw.TableHelper.fromTextArray(
          headers: ['Property', 'Room', 'Status', 'Available Slots'],
          data: rows
              .map((r) => [
                    r.property.name,
                    r.room.roomType,
                    r.availability.status.value,
                    '${r.availability.availableSlots}',
                  ])
              .toList(),
        ),
      ],
    ),
  );
  return doc.save();
}

/// report_type = "occupancy" -- raw capacity/current_occupancy utilization,
/// distinct from the request-driven availability status above.
Future<Uint8List> buildOccupancyReportPdf(
  List<({Property property, Room room})> rows,
) async {
  final doc = pw.Document();
  doc.addPage(
    pw.MultiPage(
      build: (context) => [
        _reportHeader('Occupancy Report'),
        pw.TableHelper.fromTextArray(
          headers: ['Property', 'Room', 'Capacity', 'Occupied', 'Occupancy Rate'],
          data: rows.map((r) {
            final rate = r.room.capacity == 0
                ? 0
                : (r.room.currentOccupancy / r.room.capacity * 100).round();
            return [
              r.property.name,
              r.room.roomType,
              '${r.room.capacity}',
              '${r.room.currentOccupancy}',
              '$rate%',
            ];
          }).toList(),
        ),
      ],
    ),
  );
  return doc.save();
}

/// report_type = "reservation" -- covers BOTH `VisitRequests` and
/// `RoomRequests`. The manuscript predates the split between the two, so
/// neither alone fully captures "reservations"; see the README for this
/// decision, flagged back per the task's own ask.
Future<Uint8List> buildReservationReportPdf({
  required List<LandlordVisitRequestItem> visitRequests,
  required List<LandlordRoomRequestItem> roomRequests,
}) async {
  final doc = pw.Document();
  doc.addPage(
    pw.MultiPage(
      build: (context) => [
        _reportHeader('Reservations Report'),
        pw.Text(
          'Visit Requests',
          style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
        ),
        pw.TableHelper.fromTextArray(
          headers: ['Property', 'Student', 'Requested', 'Status'],
          data: visitRequests
              .map((v) => [
                    v.propertyName,
                    v.studentName,
                    _dateFormat.format(v.request.requestedDatetime),
                    v.request.status.value,
                  ])
              .toList(),
        ),
        pw.SizedBox(height: 16),
        pw.Text(
          'Room Requests',
          style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
        ),
        pw.TableHelper.fromTextArray(
          headers: ['Property', 'Room', 'Student', 'Status'],
          data: roomRequests
              .map((r) => [
                    r.propertyName,
                    r.roomType,
                    r.studentName,
                    r.effectiveStatus.value,
                  ])
              .toList(),
        ),
      ],
    ),
  );
  return doc.save();
}
