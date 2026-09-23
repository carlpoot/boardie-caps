import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:printing/printing.dart';

import '../../../core/models/models.dart';
import '../../../core/providers/repository_providers.dart';
import '../../auth/providers/auth_notifier.dart';
import 'admin_report_pdf_builder.dart';

/// The three report types this phase's task calls for.
const kAdminReportTypeUsers = 'users';
const kAdminReportTypeListingVerification = 'listing_verification';
const kAdminReportTypeReportedListings = 'reported_listings';

const kAdminReportTypes = [
  kAdminReportTypeUsers,
  kAdminReportTypeListingVerification,
  kAdminReportTypeReportedListings,
];

String adminReportTypeLabel(String type) => switch (type) {
      kAdminReportTypeUsers => 'Users',
      kAdminReportTypeListingVerification => 'Listing Verification',
      kAdminReportTypeReportedListings => 'Reported Listings',
      _ => type,
    };

/// Every report this admin has generated. `Reports.created_by` is a
/// `Users.user_id` -- same convention as the landlord side.
final adminReportsProvider = FutureProvider<List<Report>>((ref) async {
  final userId = ref.watch(authNotifierProvider).user?.userId;
  if (userId == null) return [];
  return ref.watch(reportRepositoryProvider).getByCreatedBy(userId);
});

/// Gathers every `Properties` row, system-wide, with its owning landlord's
/// name resolved for display.
///
/// Pulled out of [_buildPdfBytes] as its own top-level function specifically
/// so a test can call it directly and assert on the rows it returns --
/// `Printing.layoutPdf`'s `onLayout` callback (which is what actually
/// invokes `_buildPdfBytes`) never fires under `flutter_test` (there's no
/// platform channel, so the call fails before rendering), so nothing
/// reachable only through `generateAdminReport`/`_buildPdfBytes` is
/// otherwise exercised by a widget test at all. This is the one seam that
/// proves the `listing_verification` report is genuinely system-wide --
/// spanning every landlord, not scoped to one -- rather than just asserting
/// a `Reports` row got created.
Future<List<({Property property, String landlordName})>> gatherListingVerificationRows(
  WidgetRef ref,
) async {
  final propertyRepository = ref.read(propertyRepositoryProvider);
  final landlordProfileRepository = ref.read(landlordProfileRepositoryProvider);
  final userRepository = ref.read(userRepositoryProvider);

  final properties = await propertyRepository.getAll();
  final rows = <({Property property, String landlordName})>[];
  for (final property in properties) {
    final landlordProfile = await landlordProfileRepository.getById(property.landlordId);
    final landlordUser =
        landlordProfile == null ? null : await userRepository.getById(landlordProfile.userId);
    rows.add((property: property, landlordName: landlordUser?.name ?? 'Unknown landlord'));
  }
  return rows;
}

/// Gathers system-wide data (every user/property/reported-listing, not
/// scoped to any one landlord or student) and builds the requested report's
/// PDF bytes.
Future<Uint8List> _buildPdfBytes(WidgetRef ref, String reportType) async {
  switch (reportType) {
    case kAdminReportTypeUsers:
      final users = await ref.read(userRepositoryProvider).getAll();
      return buildUsersReportPdf(users);

    case kAdminReportTypeListingVerification:
      final rows = await gatherListingVerificationRows(ref);
      return buildListingVerificationReportPdf(rows);

    case kAdminReportTypeReportedListings:
      final reportedListingRepository = ref.read(reportedListingRepositoryProvider);
      final propertyRepository = ref.read(propertyRepositoryProvider);
      final userRepository = ref.read(userRepositoryProvider);

      final reported = await reportedListingRepository.getAll();
      final rows =
          <({ReportedListing report, String propertyName, String reporterName})>[];
      for (final report in reported) {
        final property = await propertyRepository.getById(report.propertyId);
        final reporter = await userRepository.getById(report.reportedBy);
        rows.add((
          report: report,
          propertyName: property?.name ?? 'Unknown property',
          reporterName: reporter?.name ?? 'Unknown user',
        ));
      }
      return buildReportedListingsReportPdf(rows);

    default:
      throw ArgumentError('Unknown report type: $reportType');
  }
}

/// Builds the PDF and records a `Reports` row (`created_by` = the admin's
/// own `Users.user_id`).
///
/// Same print-dialog-timing fix as the landlord side
/// ([landlord_reports_providers.dart](../../landlord/reports/landlord_reports_providers.dart)):
/// `Printing.layoutPdf` fires as the FIRST thing this does, synchronously
/// off the tap and before any other `await`, so the browser's short-lived
/// "user activation" window for a print/popup dialog hasn't closed by the
/// time it's requested. It's fire-and-forget (never awaited) since the
/// dialog can stay open indefinitely and must not block recording the
/// `Reports` row.
Future<Report> generateAdminReport(WidgetRef ref, String reportType) async {
  final userId = ref.read(authNotifierProvider).user?.userId;
  if (userId == null) {
    throw StateError('Only a signed-in admin can generate a report.');
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
  ref.invalidate(adminReportsProvider);

  return report;
}
