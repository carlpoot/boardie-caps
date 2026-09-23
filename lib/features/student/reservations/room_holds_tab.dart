import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/models.dart';
import '../room_requests/room_request_card.dart';
import '../room_requests/room_request_providers.dart';

/// The wireframe's four status filter tabs for Room Holds. "Active" lumps
/// pending+approved together (both are still-live holds); "Cancelled" also
/// covers `declined`, since the wireframe has no separate tab for it and
/// both represent "this hold did not go through".
enum _HoldFilter { active, confirmed, expired, cancelled }

extension on _HoldFilter {
  String get label => switch (this) {
        _HoldFilter.active => 'Active',
        _HoldFilter.confirmed => 'Confirmed',
        _HoldFilter.expired => 'Expired',
        _HoldFilter.cancelled => 'Cancelled',
      };

  bool matches(RoomRequestStatus status) => switch (this) {
        _HoldFilter.active =>
          status == RoomRequestStatus.pending || status == RoomRequestStatus.approved,
        _HoldFilter.confirmed => status == RoomRequestStatus.confirmed,
        _HoldFilter.expired => status == RoomRequestStatus.expired,
        _HoldFilter.cancelled =>
          status == RoomRequestStatus.cancelled || status == RoomRequestStatus.declined,
      };
}

class RoomHoldsTab extends ConsumerStatefulWidget {
  const RoomHoldsTab({super.key});

  @override
  ConsumerState<RoomHoldsTab> createState() => _RoomHoldsTabState();
}

class _RoomHoldsTabState extends ConsumerState<RoomHoldsTab> {
  _HoldFilter _filter = _HoldFilter.active;

  @override
  Widget build(BuildContext context) {
    final itemsAsync = ref.watch(studentRoomRequestsProvider);

    return Column(
      children: [
        SizedBox(
          height: 44,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemCount: _HoldFilter.values.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final filter = _HoldFilter.values[index];
              return ChoiceChip(
                label: Text(filter.label),
                selected: _filter == filter,
                onSelected: (_) => setState(() => _filter = filter),
              );
            },
          ),
        ),
        Expanded(
          child: itemsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => Center(child: Text('Could not load room holds: $error')),
            data: (items) {
              final filtered =
                  items.where((item) => _filter.matches(item.effectiveStatus)).toList();
              if (filtered.isEmpty) {
                return Center(child: Text('No ${_filter.label.toLowerCase()} room holds.'));
              }
              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                itemCount: filtered.length,
                itemBuilder: (context, index) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: RoomRequestCard(item: filtered[index]),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
