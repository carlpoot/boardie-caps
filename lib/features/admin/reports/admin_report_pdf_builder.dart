import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../../core/models/models.dart';

/// Pure PDF-byte builders (no Riverpod/BuildContext dependency), one per
/// admin `report_type`, mirroring the landlord side's
/// [report_pdf_builder.dart](../../landlord/reports/report_pdf_builder.dart)
/// so both stay directly unit-testable without the `printing` package's
/// platform channel. Unlike the landlord reports, every row here spans the
/// whole platform -- none of these take a `landlord_id`/scoping parameter.
final _dateFormat = DateFormat('MMM d, y · h:mm a');

pw.Widget _reportHeader(String title) => pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(title, style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
        pw.Text('Generated: ${_dateFormat.format(DateTime.now())}'),
        pw.SizedBox(height: 16),
      ],
    );

/// report_type = "users" -- every `Users` row, system-wide.
Future<Uint8List> buildUsersReportPdf(List<User> users) async {
  final doc = pw.Document();
  doc.addPage(
    pw.MultiPage(
      build: (context) => [
        _reportHeader('Users Report'),
        pw.TableHelper.fromTextArray(
          headers: ['Name', 'Email', 'Role', 'Status', 'Contact No.'],
          data: users
              .map((u) => [u.name, u.email, u.role.value, u.status.value, u.contactNo])
              .toList(),
        ),
      ],
    ),
  );
  return doc.save();
}

/// report_type = "listing_verification" -- every `Properties` row,
/// system-wide, with its owning landlord's name for context.
Future<Uint8List> buildListingVerificationReportPdf(
  List<({Property property, String landlordName})> rows,
) async {
  final doc = pw.Document();
  doc.addPage(
    pw.MultiPage(
      build: (context) => [
        _reportHeader('Listing Verification Report'),
        pw.TableHelper.fromTextArray(
          headers: ['Name', 'Landlord', 'Address', 'Status', 'Created'],
          data: rows
              .map((r) => [
                    r.property.name,
                    r.landlordName,
                    r.property.address,
                    r.property.verificationStatus.value,
                    _dateFormat.format(r.property.createdAt),
                  ])
              .toList(),
        ),
      ],
    ),
  );
  return doc.save();
}

/// report_type = "reported_listings" -- every `ReportedListings` row,
/// system-wide, regardless of `review_status`.
Future<Uint8List> buildReportedListingsReportPdf(
  List<({ReportedListing report, String propertyName, String reporterName})> rows,
) async {
  final doc = pw.Document();
  doc.addPage(
    pw.MultiPage(
      build: (context) => [
        _reportHeader('Reported Listings Report'),
        pw.TableHelper.fromTextArray(
          headers: ['Property', 'Reported By', 'Reason', 'Review Status'],
          data: rows
              .map((r) => [
                    r.propertyName,
                    r.reporterName,
                    r.report.reason,
                    r.report.reviewStatus.value,
                  ])
              .toList(),
        ),
      ],
    ),
  );
  return doc.save();
}
