import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/routing/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/status_display.dart';
import 'landlord_rooms_providers.dart';

class LandlordRoomsScreen extends ConsumerWidget {
  const LandlordRoomsScreen({super.key, required this.propertyId});

  final String propertyId;

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref, String roomId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete room?'),
        content: const Text('This removes the room permanently. This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
          TextButton(
            key: const Key('confirm_delete_room_button'),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await deleteRoom(ref, propertyId, roomId);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final roomsAsync = ref.watch(propertyRoomsProvider(propertyId));
    final availabilitiesAsync = ref.watch(propertyRoomAvailabilitiesProvider(propertyId));
    final priceFormat =
        NumberFormat.currency(locale: 'en_PH', symbol: '₱', decimalDigits: 0);

    return Scaffold(
      appBar: AppBar(title: const Text('Rooms')),
      body: roomsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Could not load rooms: $error')),
        data: (rooms) {
          if (rooms.isEmpty) {
            return const Center(child: Text('No rooms yet. Tap + to add one.'));
          }
          return availabilitiesAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => Center(child: Text('Could not load availability: $error')),
            data: (availabilities) {
              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
                itemCount: rooms.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final room = rooms[index];
                  final availability = availabilities[room.roomId];
                  final color = availability?.status.color ?? AppColors.statusNeutral;

                  return Card(
                    child: ListTile(
                      title: Text(room.roomType),
                      subtitle: Text(
                        'Capacity ${room.capacity} · Occupancy ${room.currentOccupancy} · '
                        '${priceFormat.format(room.rentPrice)}/mo',
                      ),
                      isThreeLine: false,
                      onTap: () => context.push(
                        AppRoutes.landlordRoomForm(propertyId),
                        extra: room,
                      ),
                      leading: availability == null
                          ? null
                          : CircleAvatar(
                              backgroundColor: color.withValues(alpha: 0.15),
                              child: Text(
                                '${availability.availableSlots}',
                                style: AppTypography.titleSmall.copyWith(color: color),
                              ),
                            ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (availability != null)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: color.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                availability.status.label,
                                style: AppTypography.statusBadge.copyWith(color: color),
                              ),
                            ),
                          IconButton(
                            key: Key('delete_room_${room.roomId}'),
                            icon: const Icon(Icons.delete_outline),
                            onPressed: () => _confirmDelete(context, ref, room.roomId),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        key: const Key('add_room_fab'),
        onPressed: () => context.push(AppRoutes.landlordRoomForm(propertyId)),
        child: const Icon(Icons.add),
      ),
    );
  }
}
