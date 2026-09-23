import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/status_display.dart';
import 'admin_verification_providers.dart';

/// Verify Listings: every `Properties` row with `verification_status =
/// pending`, system-wide. `LandlordProfiles.verification_status` (identity
/// verification) is shown for context only -- it is a separate field on a
/// separate entity from `Properties.verification_status` (per-listing
/// verification) and this screen never writes to it.
///
/// A pending `ReportedListings` row against the property is a **warning,
/// not a hard block**, on the Verify action -- see the confirm dialog and
/// the README for why.
class AdminVerificationScreen extends ConsumerWidget {
  const AdminVerificationScreen({super.key});

  Future<void> _confirmVerify(
    BuildContext context,
    WidgetRef ref,
    AdminPendingPropertyItem item,
  ) async {
    final hasWarning = item.pendingReports.isNotEmpty;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Verify this listing?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('"${item.property.name}" will become visible to students as verified.'),
            if (hasWarning) ...[
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.warning_amber_rounded, color: AppColors.statusLimited, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${item.pendingReports.length} report'
                      '${item.pendingReports.length == 1 ? '' : 's'} against this listing '
                      'still await review:',
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.statusLimited,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              for (final report in item.pendingReports)
                Padding(
                  padding: const EdgeInsets.only(left: 28, top: 2),
                  child: Text('• ${report.reason}', style: AppTypography.bodySmall),
                ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            key: Key('confirm_verify_property_${item.property.propertyId}'),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Verify'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await verifyProperty(ref, item.property.propertyId);
    }
  }

  Future<void> _confirmReject(
    BuildContext context,
    WidgetRef ref,
    AdminPendingPropertyItem item,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject this listing?'),
        content: Text('"${item.property.name}" will be marked rejected.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            key: Key('confirm_reject_property_${item.property.propertyId}'),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Reject'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await rejectProperty(ref, item.property.propertyId);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itemsAsync = ref.watch(adminPendingPropertiesProvider);

    return itemsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text('Could not load pending listings: $error')),
      data: (items) {
        if (items.isEmpty) {
          return const Center(child: Text('No listings awaiting verification.'));
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: items.length,
          separatorBuilder: (_, _) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final item = items[index];
            return _PendingPropertyCard(
              item: item,
              onVerify: () => _confirmVerify(context, ref, item),
              onReject: () => _confirmReject(context, ref, item),
            );
          },
        );
      },
    );
  }
}

class _PendingPropertyCard extends StatelessWidget {
  const _PendingPropertyCard({
    required this.item,
    required this.onVerify,
    required this.onReject,
  });

  final AdminPendingPropertyItem item;
  final VoidCallback onVerify;
  final VoidCallback onReject;

  @override
  Widget build(BuildContext context) {
    final property = item.property;
    final placeholderColor = Theme.of(context).colorScheme.surfaceContainerHighest;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(property.name, style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 2),
            Text(property.address, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 8),
            if (item.images.isEmpty)
              const Text('No photos uploaded yet.')
            else
              SizedBox(
                height: 80,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: item.images.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final image = item.images[index];
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        image.imageUrl,
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => Container(
                          width: 80,
                          height: 80,
                          color: placeholderColor,
                          child: const Icon(Icons.broken_image_outlined),
                        ),
                      ),
                    );
                  },
                ),
              ),
            const SizedBox(height: 8),
            if (item.landlordProfile != null)
              Row(
                children: [
                  Text(
                    'Landlord identity verification: ',
                    style: AppTypography.bodySmall.copyWith(color: AppColors.onSurfaceMuted),
                  ),
                  Text(
                    item.landlordProfile!.verificationStatus.label,
                    style: AppTypography.bodySmall.copyWith(
                      color: item.landlordProfile!.verificationStatus.color,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            if (item.pendingReports.isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.warning_amber_rounded, size: 16, color: AppColors.statusLimited),
                  const SizedBox(width: 4),
                  Text(
                    '${item.pendingReports.length} unreviewed report'
                    '${item.pendingReports.length == 1 ? '' : 's'}',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.statusLimited,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  key: Key('reject_property_${property.propertyId}'),
                  onPressed: onReject,
                  child: const Text('Reject'),
                ),
                FilledButton(
                  key: Key('verify_property_${property.propertyId}'),
                  onPressed: onVerify,
                  child: const Text('Verify'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
