import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/models/models.dart';
import 'landlord_visit_requests_providers.dart';

const _statusOrder = [
  VisitRequestStatus.pending,
  VisitRequestStatus.accepted,
  VisitRequestStatus.rescheduled,
  VisitRequestStatus.declined,
  VisitRequestStatus.completed,
  VisitRequestStatus.cancelled,
];

const _statusLabels = {
  VisitRequestStatus.pending: 'Pending',
  VisitRequestStatus.accepted: 'Accepted',
  VisitRequestStatus.rescheduled: 'Rescheduled',
  VisitRequestStatus.declined: 'Declined',
  VisitRequestStatus.completed: 'Completed',
  VisitRequestStatus.cancelled: 'Cancelled',
};

/// Respond to Visit Requests: every VisitRequest against the landlord's
/// properties, grouped by status. Actions only apply to `pending` requests
/// -- once a landlord has responded, the record is left as-is.
class LandlordVisitRequestsScreen extends ConsumerWidget {
  const LandlordVisitRequestsScreen({super.key});

  Future<void> _reschedule(BuildContext context, WidgetRef ref, String visitId) async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: now.add(const Duration(days: 1)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 90)),
    );
    if (date == null || !context.mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 10, minute: 0),
    );
    if (time == null) return;

    final newDatetime = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    await rescheduleVisitRequest(ref, visitId, newDatetime);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itemsAsync = ref.watch(landlordVisitRequestsProvider);
    final dateFormat = DateFormat('EEE, MMM d, y · h:mm a');

    return itemsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text('Could not load visit requests: $error')),
      data: (items) {
        if (items.isEmpty) {
          return const Center(child: Text('No visit requests yet.'));
        }

        final grouped = <VisitRequestStatus, List<LandlordVisitRequestItem>>{};
        for (final item in items) {
          grouped.putIfAbsent(item.request.status, () => []).add(item);
        }

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          children: [
            for (final status in _statusOrder)
              if (grouped[status] != null) ...[
                Padding(
                  padding: const EdgeInsets.only(top: 8, bottom: 8),
                  child: Text(
                    _statusLabels[status]!,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
                for (final item in grouped[status]!)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.propertyName,
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                            Text('Student: ${item.studentName}'),
                            Text(
                              'Requested: ${dateFormat.format(item.request.requestedDatetime)}',
                            ),
                            if (item.request.respondedDatetime != null)
                              Text(
                                'Responded: '
                                '${dateFormat.format(item.request.respondedDatetime!)}',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            if (item.request.status == VisitRequestStatus.pending) ...[
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  TextButton(
                                    key: Key('decline_visit_${item.request.visitId}'),
                                    onPressed: () =>
                                        declineVisitRequest(ref, item.request.visitId),
                                    child: const Text('Decline'),
                                  ),
                                  TextButton(
                                    key: Key('reschedule_visit_${item.request.visitId}'),
                                    onPressed: () =>
                                        _reschedule(context, ref, item.request.visitId),
                                    child: const Text('Reschedule'),
                                  ),
                                  FilledButton(
                                    key: Key('accept_visit_${item.request.visitId}'),
                                    onPressed: () =>
                                        acceptVisitRequest(ref, item.request.visitId),
                                    child: const Text('Accept'),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
          ],
        );
      },
    );
  }
}
