import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/models.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../verification/admin_verification_providers.dart';
import 'admin_reported_listings_providers.dart';

/// Review Reported Listings: every `ReportedListings` row with
/// `review_status = pending`, system-wide.
///
/// **Documented decision:** marking a report `reviewed` or `dismissed`
/// NEVER cascades into `Properties.verification_status` -- the ERD/spec
/// doesn't say it should, and auto-rejecting a listing just because a
/// report was acknowledged would be a surprising, hard-to-reverse side
/// effect of what's meant to be a simple triage action. Acting on the
/// property is always the separate, explicit "Reject Property" button
/// below, independent of whether the report itself has been marked
/// reviewed/dismissed yet.
class AdminReportedListingsScreen extends ConsumerWidget {
  const AdminReportedListingsScreen({super.key});

  Future<void> _confirmRejectProperty(
    BuildContext context,
    WidgetRef ref,
    AdminReportedListingItem item,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject this listing?'),
        content: Text(
          '"${item.propertyName}" will be marked rejected because of this report. '
          'This is separate from marking the report itself reviewed or dismissed.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            key: Key('confirm_reject_property_from_report_${item.report.reportIssueId}'),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Reject'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await rejectProperty(ref, item.report.propertyId);
      // rejectProperty only invalidates adminPendingPropertiesProvider (the
      // Verify Listings screen's own data) -- this screen also renders the
      // property's verification_status inline, so it needs its own refresh.
      ref.invalidate(adminReportedListingsProvider);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itemsAsync = ref.watch(adminReportedListingsProvider);

    return itemsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text('Could not load reported listings: $error')),
      data: (items) {
        if (items.isEmpty) {
          return const Center(child: Text('No reported listings awaiting review.'));
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: items.length,
          separatorBuilder: (_, _) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final item = items[index];
            final alreadyRejected =
                item.propertyVerificationStatus == VerificationStatus.rejected;
            return Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.propertyName, style: Theme.of(context).textTheme.titleSmall),
                    const SizedBox(height: 4),
                    Text(
                      'Reported by: ${item.reporterName}',
                      style: AppTypography.bodySmall.copyWith(color: AppColors.onSurfaceMuted),
                    ),
                    const SizedBox(height: 4),
                    Text(item.report.reason),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (!alreadyRejected) ...[
                          TextButton(
                            key: Key('reject_property_from_report_${item.report.reportIssueId}'),
                            onPressed: () => _confirmRejectProperty(context, ref, item),
                            child: const Text('Reject Property'),
                          ),
                          const SizedBox(width: 8),
                        ],
                        OutlinedButton(
                          key: Key('dismiss_report_${item.report.reportIssueId}'),
                          onPressed: () => markReportDismissed(ref, item.report.reportIssueId),
                          child: const Text('Dismiss'),
                        ),
                        const SizedBox(width: 8),
                        FilledButton(
                          key: Key('review_report_${item.report.reportIssueId}'),
                          onPressed: () => markReportReviewed(ref, item.report.reportIssueId),
                          child: const Text('Mark Reviewed'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
