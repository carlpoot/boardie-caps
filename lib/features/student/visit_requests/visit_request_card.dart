import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/models/models.dart';
import 'visit_request_providers.dart';

class VisitRequestCard extends ConsumerWidget {
  const VisitRequestCard({super.key, required this.item});

  final VisitRequestListItem item;

  static const _cancellableStatuses = {
    VisitRequestStatus.pending,
    VisitRequestStatus.accepted,
    VisitRequestStatus.rescheduled,
  };

  static const _statusLabels = {
    VisitRequestStatus.pending: 'Pending',
    VisitRequestStatus.accepted: 'Accepted',
    VisitRequestStatus.rescheduled: 'Rescheduled',
    VisitRequestStatus.declined: 'Declined',
    VisitRequestStatus.completed: 'Completed',
    VisitRequestStatus.cancelled: 'Cancelled',
  };

  static const _statusColors = {
    VisitRequestStatus.pending: Colors.orange,
    VisitRequestStatus.accepted: Colors.green,
    VisitRequestStatus.rescheduled: Colors.blue,
    VisitRequestStatus.declined: Colors.red,
    VisitRequestStatus.completed: Colors.blueGrey,
    VisitRequestStatus.cancelled: Colors.grey,
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final request = item.request;
    final dateFormat = DateFormat('EEE, MMM d, y · h:mm a');
    final color = _statusColors[request.status]!;

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
                    _statusLabels[request.status]!,
                    style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12),
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
