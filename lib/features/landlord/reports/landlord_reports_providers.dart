import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:printing/printing.dart';

import '../../../core/models/models.dart';
import '../../../core/providers/repository_providers.dart';
import '../../../core/providers/service_providers.dart';
import '../../../core/services/room_availability_service.dart';
import '../../auth/providers/auth_notifier.dart';
import '../room_requests/landlord_room_requests_providers.dart';
import '../visit_requests/landlord_visit_requests_providers.dart';
import 'report_pdf_builder.dart';

/// The four report types the manuscript's Table 1 calls for.
const kReportTypeListings = 'listings';
const kReportTypeRoomAvailability = 'room_availability';
const kReportTypeOccupancy = 'occupancy';
const kReportTypeReservation = 'reservation';

const kReportTypes = [
  kReportTypeListings,
  kReportTypeRoomAvailability,
  kReportTypeOccupancy,
  kReportTypeReservation,
];

String reportTypeLabel(String type) => switch (type) {
      kReportTypeListings => 'Property Listings',
      kReportTypeRoomAvailability => 'Room Availability',
      kReportTypeOccupancy => 'Occupancy',
      kReportTypeReservation => 'Reservations',
      _ => type,
    };

/// Every report this landlord has generated. `Reports.created_by` is a
/// `Users.user_id`, not a `landlord_id` -- scoped accordingly.
final landlordReportsProvider = FutureProvider<List<Report>>((ref) async {
  final userId = ref.watch(authNotifierProvider).user?.userId;
  if (userId == null) return [];
  return ref.watch(reportRepositoryProvider).getByCreatedBy(userId);
});

/// Gathers this landlord's own data (never another landlord's) and builds
/// the requested report's PDF bytes.
Future<Uint8List> _buildPdfBytes(WidgetRef ref, String reportType) async {
  final landlordId = ref.read(authNotifierProvider).landlordId;
  if (landlordId == null) {
    throw StateError('Only a signed-in landlord can generate a report.');
  }

  final propertyRepository = ref.read(propertyRepositoryProvider);
  final roomRepository = ref.read(roomRepositoryProvider);
  final availabilityService = ref.read(roomAvailabilityServiceProvider);

  final properties = await propertyRepository.getByLandlord(landlordId);

  switch (reportType) {
    case kReportTypeListings:
      return buildListingsReportPdf(properties);

    case kReportTypeRoomAvailability:
      final rows = <({Property property, Room room, RoomAvailability availability})>[];
      for (final property in properties) {
        final rooms = await roomRepository.getByProperty(property.propertyId);
        for (final room in rooms) {
          rows.add((
            property: property,
            room: room,
            availability: await availabilityService.getAvailability(room),
          ));
        }
      }
      return buildRoomAvailabilityReportPdf(rows);

    case kReportTypeOccupancy:
      final rows = <({Property property, Room room})>[];
      for (final property in properties) {
        final rooms = await roomRepository.getByProperty(property.propertyId);
        for (final room in rooms) {
          rows.add((property: property, room: room));
        }
      }
      return buildOccupancyReportPdf(rows);

    case kReportTypeReservation:
      final visitRequests = await ref.read(landlordVisitRequestsProvider.future);
      final roomRequests = await ref.read(landlordRoomRequestsProvider.future);
      return buildReservationReportPdf(
        visitRequests: visitRequests,
        roomRequests: roomRequests,
      );

    default:
      throw ArgumentError('Unknown report type: $reportType');
  }
}

/// Builds the PDF and records a `Reports` row (`created_by` = the
/// landlord's own `Users.user_id`).
///
/// The native print/share dialog (via `printing`) is kicked off as the
/// FIRST thing this does, before any other `await`, and its own PDF-byte
/// computation happens lazily inside `onLayout` rather than ahead of time.
/// On web, browsers only allow a print/popup dialog within a short-lived
/// "user activation" window after a real click -- a couple of `await`s
/// beforehand (e.g. building the PDF, writing to the repository) is enough
/// for that window to close, silently no-op'ing the dialog with no error.
/// Firing it first, synchronously off the tap, keeps it inside that
/// window. It's also never awaited here regardless -- the dialog stays
/// open until the user dismisses it, which could be indefinitely, and
/// generating/recording the report must not block on that. If no platform
/// channel is available at all (e.g. a widget test), that fire-and-forget
/// call simply fails silently; the Reports row is still recorded.
Future<Report> generateReport(WidgetRef ref, String reportType) async {
  final userId = ref.read(authNotifierProvider).user?.userId;
  if (userId == null) {
    throw StateError('Only a signed-in landlord can generate a report.');
  }

  unawaited(
    Printing.layoutPdf(onLayout: (_) => _buildPdfBytes(ref, reportType))
        .catchError((_) => false),
  );

  final report = await ref.read(reportRepositoryProvider).create(Report(
        reportId: '',
        createdBy: userId,
        reportType: reportType,
        dateGenerated: DateTime.now(),
        fileUrl:
            'local://reports/$reportType-${DateTime.now().millisecondsSinceEpoch}.pdf',
      ));
  ref.invalidate(landlordReportsProvider);

  return report;
}
