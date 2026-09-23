import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/models/models.dart';
import '../../../core/services/room_request_service.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/status_display.dart';
import 'room_request_providers.dart';

class RoomRequestCard extends ConsumerWidget {
  const RoomRequestCard({super.key, required this.item});

  final RoomRequestListItem item;

  static const _cancellable = {RoomRequestStatus.pending, RoomRequestStatus.approved};

  void _showError(BuildContext context, RoomRequestException e) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(e.message)));
  }

  Future<void> _confirm(BuildContext context, WidgetRef ref) async {
    try {
      await confirmRoomRequest(ref, item.request.requestId);
      if (context.mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(const SnackBar(
            content: Text('Room request confirmed. Your other holds were cancelled.'),
          ));
      }
    } on RoomRequestException catch (e) {
      if (context.mounted) _showError(context, e);
    }
  }

  Future<void> _cancel(BuildContext context, WidgetRef ref) async {
    try {
      await cancelRoomRequest(ref, item.request.requestId);
    } on RoomRequestException catch (e) {
      if (context.mounted) _showError(context, e);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final request = item.request;
    final status = item.effectiveStatus;
    final color = status.color;
    final dateFormat = DateFormat('EEE, MMM d, y · h:mm a');

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.propertyName, style: Theme.of(context).textTheme.titleSmall),
                      Text(item.roomType, style: Theme.of(context).textTheme.bodySmall),
                    ],
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
                    status.label,
                    style: AppTypography.statusBadge.copyWith(color: color),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            if (request.heldUntil != null && _cancellable.contains(status))
              Text('Held until: ${dateFormat.format(request.heldUntil!)}'),
            if (request.confirmedAt != null)
              Text('Confirmed: ${dateFormat.format(request.confirmedAt!)}'),
            if (_cancellable.contains(status) || status == RoomRequestStatus.approved) ...[
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (_cancellable.contains(status))
                    TextButton(
                      key: Key('cancel_room_request_${request.requestId}'),
                      onPressed: () => _cancel(context, ref),
                      child: const Text('Cancel'),
                    ),
                  if (status == RoomRequestStatus.approved) ...[
                    const SizedBox(width: 8),
                    FilledButton(
                      key: Key('confirm_room_request_${request.requestId}'),
                      onPressed: () => _confirm(context, ref),
                      child: const Text('Confirm'),
                    ),
                  ],
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
