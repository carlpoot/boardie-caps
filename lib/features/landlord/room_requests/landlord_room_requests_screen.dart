import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/models/models.dart';
import '../../../core/services/room_request_service.dart';
import 'landlord_room_requests_providers.dart';

const _statusOrder = [
  RoomRequestStatus.pending,
  RoomRequestStatus.approved,
  RoomRequestStatus.confirmed,
  RoomRequestStatus.declined,
  RoomRequestStatus.expired,
  RoomRequestStatus.cancelled,
];

const _statusLabels = {
  RoomRequestStatus.pending: 'Pending',
  RoomRequestStatus.approved: 'Approved',
  RoomRequestStatus.confirmed: 'Confirmed',
  RoomRequestStatus.declined: 'Declined',
  RoomRequestStatus.expired: 'Expired',
  RoomRequestStatus.cancelled: 'Cancelled',
};

/// Respond to Room Requests: every RoomRequest against the landlord's
/// rooms, grouped by (live) status. This is a DIFFERENT queue from Visit
/// Requests -- never merged in the UI. Approve only opens the door for the
/// student's own Confirm action; a landlord can never set `confirmed`
/// directly (enforced in `RoomRequestService`, not just here).
class LandlordRoomRequestsScreen extends ConsumerWidget {
  const LandlordRoomRequestsScreen({super.key});

  void _showError(BuildContext context, RoomRequestException e) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(e.message)));
  }

  Future<void> _approve(BuildContext context, WidgetRef ref, String requestId) async {
    try {
      await approveRoomRequestAsLandlord(ref, requestId);
    } on RoomRequestException catch (e) {
      if (context.mounted) _showError(context, e);
    }
  }

  Future<void> _decline(BuildContext context, WidgetRef ref, String requestId) async {
    try {
      await declineRoomRequestAsLandlord(ref, requestId);
    } on RoomRequestException catch (e) {
      if (context.mounted) _showError(context, e);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itemsAsync = ref.watch(landlordRoomRequestsProvider);
    final dateFormat = DateFormat('EEE, MMM d, y · h:mm a');

    return itemsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text('Could not load room requests: $error')),
      data: (items) {
        if (items.isEmpty) {
          return const Center(child: Text('No room requests yet.'));
        }

        final grouped = <RoomRequestStatus, List<LandlordRoomRequestItem>>{};
        for (final item in items) {
          grouped.putIfAbsent(item.effectiveStatus, () => []).add(item);
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
                            Text('Room: ${item.roomType}'),
                            Text('Student: ${item.studentName}'),
                            if (item.request.heldUntil != null &&
                                status == RoomRequestStatus.pending)
                              Text(
                                'Held until: '
                                '${dateFormat.format(item.request.heldUntil!)}',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            if (status == RoomRequestStatus.pending) ...[
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  TextButton(
                                    key: Key('decline_room_request_${item.request.requestId}'),
                                    onPressed: () =>
                                        _decline(context, ref, item.request.requestId),
                                    child: const Text('Decline'),
                                  ),
                                  FilledButton(
                                    key: Key('approve_room_request_${item.request.requestId}'),
                                    onPressed: () =>
                                        _approve(context, ref, item.request.requestId),
                                    child: const Text('Approve'),
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
