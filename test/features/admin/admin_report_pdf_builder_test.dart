import 'package:flutter_test/flutter_test.dart';

import 'package:boardie/core/models/models.dart';
import 'package:boardie/features/admin/reports/admin_report_pdf_builder.dart';

User _user() => const User(
      userId: 'user-x',
      name: 'Test User',
      email: 'test.user@boardie.io',
      contactNo: '09170000000',
      role: UserRole.student,
      status: UserStatus.active,
    );

Property _property() => Property(
      propertyId: 'property-x',
      landlordId: 'landlord-x',
      name: 'Test Property',
      address: '123 Test St',
      latitude: 13.14,
      longitude: 123.74,
      storeys: 2,
      verificationStatus: VerificationStatus.pending,
      minPrice: 3000,
      createdAt: DateTime(2026, 1, 1),
    );

ReportedListing _reportedListing() => const ReportedListing(
      reportIssueId: 'reportissue-x',
      propertyId: 'property-x',
      reportedBy: 'user-x',
      reason: 'Test reason',
      reviewStatus: ReportedListingReviewStatus.pending,
    );

/// Every real PDF starts with this magic header.
void _expectValidPdf(List<int> bytes) {
  expect(bytes, isNotEmpty);
  expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
}

void main() {
  test('buildUsersReportPdf produces a valid, non-empty PDF', () async {
    _expectValidPdf(await buildUsersReportPdf([_user()]));
  });

  test('buildListingVerificationReportPdf produces a valid, non-empty PDF', () async {
    _expectValidPdf(await buildListingVerificationReportPdf([
      (property: _property(), landlordName: 'Test Landlord'),
    ]));
  });

  test('buildReportedListingsReportPdf produces a valid, non-empty PDF', () async {
    _expectValidPdf(await buildReportedListingsReportPdf([
      (
        report: _reportedListing(),
        propertyName: 'Test Property',
        reporterName: 'Test Reporter',
      ),
    ]));
  });

  test('report builders handle an empty data set without throwing', () async {
    _expectValidPdf(await buildUsersReportPdf([]));
    _expectValidPdf(await buildListingVerificationReportPdf([]));
    _expectValidPdf(await buildReportedListingsReportPdf([]));
  });
}
