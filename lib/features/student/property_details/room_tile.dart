import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/models/models.dart';
import '../../../core/services/room_availability_service.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/status_display.dart';

class RoomTile extends StatelessWidget {
  const RoomTile({
    super.key,
    required this.room,
    required this.availability,
    required this.onRequestRoom,
  });

  final Room room;
  final RoomAvailability availability;
  final VoidCallback onRequestRoom;

  @override
  Widget build(BuildContext context) {
    final priceFormat =
        NumberFormat.currency(locale: 'en_PH', symbol: '₱', decimalDigits: 0);
    final color = availability.status.color;
    final canRequest = availability.availableSlots > 0 &&
        availability.status != RoomAvailabilityStatus.reserved;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(room.roomType, style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: 4),
                  Text(
                    '${priceFormat.format(room.rentPrice)}/mo',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${availability.status.label} · '
                      '${availability.availableSlots} slot'
                      '${availability.availableSlots == 1 ? '' : 's'}',
                      style: AppTypography.statusBadge.copyWith(color: color),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            OutlinedButton(
              onPressed: canRequest ? onRequestRoom : null,
              child: const Text('Request Room'),
            ),
          ],
        ),
      ),
    );
  }
}
