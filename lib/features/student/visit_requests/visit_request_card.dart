import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/models/models.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/status_display.dart';
import 'visit_request_providers.dart';

class VisitRequestCard extends ConsumerWidget {
  const VisitRequestCard({super.key, required this.item});

  final VisitRequestListItem item;

  static const _cancellableStatuses = {
    VisitRequestStatus.pending,
    VisitRequestStatus.accepted,
    VisitRequestStatus.rescheduled,
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final request = item.request;
    final dateFormat = DateFormat('EEE, MMM d, y · h:mm a');
    final color = request.status.color;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    item.propertyName,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    request.status.label,
                    style: AppTypography.statusBadge.copyWith(color: color),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text('Requested: ${dateFormat.format(request.requestedDatetime)}'),
            if (request.respondedDatetime != null) ...[
              const SizedBox(height: 2),
              Text(
                'Responded: ${dateFormat.format(request.respondedDatetime!)}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
            if (_cancellableStatuses.contains(request.status)) ...[
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  key: Key('cancel_visit_${request.visitId}'),
                  onPressed: () => cancelVisitRequest(ref, request.visitId),
                  child: const Text('Cancel'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
