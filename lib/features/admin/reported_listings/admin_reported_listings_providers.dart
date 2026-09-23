import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/models.dart';
import '../../../core/providers/repository_providers.dart';

/// A `pending`-review [ReportedListing] composed with the reported
/// property's name/current verification status and the reporting user's
/// name. Not a Phase 1 ERD entity, just a UI view-model.
class AdminReportedListingItem {
  const AdminReportedListingItem({
    required this.report,
    required this.propertyName,
    required this.propertyVerificationStatus,
    required this.reporterName,
  });

  final ReportedListing report;
  final String propertyName;
  final VerificationStatus? propertyVerificationStatus;
  final String reporterName;
}

/// Every `ReportedListings` row with `review_status = pending`, system-wide.
final adminReportedListingsProvider =
    FutureProvider<List<AdminReportedListingItem>>((ref) async {
  final reportedListingRepository = ref.watch(reportedListingRepositoryProvider);
  final propertyRepository = ref.watch(propertyRepositoryProvider);
  final userRepository = ref.watch(userRepositoryProvider);

  final reports = await reportedListingRepository
      .getByReviewStatus(ReportedListingReviewStatus.pending);

  final items = <AdminReportedListingItem>[];
  for (final report in reports) {
    final property = await propertyRepository.getById(report.propertyId);
    final reporter = await userRepository.getById(report.reportedBy);
    items.add(AdminReportedListingItem(
      report: report,
      propertyName: property?.name ?? 'Unknown property',
      propertyVerificationStatus: property?.verificationStatus,
      reporterName: reporter?.name ?? 'Unknown user',
    ));
  }
  return items;
});

/// Sets `ReportedListings.review_status = reviewed` **only** -- this never
/// touches `Properties.verification_status`. See the README for why the
/// two are kept independent: rejecting the reported property is always a
/// separate, explicit admin action (the "Reject Property" button on this
/// same screen), never an automatic side effect of reviewing the report.
Future<void> markReportReviewed(WidgetRef ref, String reportIssueId) async {
  await _updateReviewStatus(ref, reportIssueId, ReportedListingReviewStatus.reviewed);
}

/// Sets `ReportedListings.review_status = dismissed` -- likewise never
/// touches `Properties.verification_status`.
Future<void> markReportDismissed(WidgetRef ref, String reportIssueId) async {
  await _updateReviewStatus(ref, reportIssueId, ReportedListingReviewStatus.dismissed);
}

Future<void> _updateReviewStatus(
  WidgetRef ref,
  String reportIssueId,
  ReportedListingReviewStatus status,
) async {
  final repository = ref.read(reportedListingRepositoryProvider);
  final report = await repository.getById(reportIssueId);
  if (report == null) return;
  await repository.update(report.copyWith(reviewStatus: status));
  ref.invalidate(adminReportedListingsProvider);
}
