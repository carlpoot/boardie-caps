import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/models/models.dart';
import 'compare_properties_data.dart';
import 'compare_properties_providers.dart';

const _statusLabels = {
  RoomAvailabilityStatus.available: 'Available',
  RoomAvailabilityStatus.limited: 'Limited',
  RoomAvailabilityStatus.full: 'Full',
  RoomAvailabilityStatus.reserved: 'Reserved',
};

/// Side-by-side comparison of 2-3 properties (from Browse or Saved). No
/// supporting wireframe prose for this use case -- this is a working
/// interpretation of what "compare" should surface, flagged back per the
/// task's own note.
class ComparePropertiesScreen extends ConsumerWidget {
  const ComparePropertiesScreen({super.key, required this.propertyIds});

  final List<String> propertyIds;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final idsKey = propertyIds.join(',');
    final dataAsync = ref.watch(comparePropertiesProvider(idsKey));
    final priceFormat =
        NumberFormat.currency(locale: 'en_PH', symbol: '₱', decimalDigits: 0);

    return Scaffold(
      appBar: AppBar(title: const Text('Compare Properties')),
      body: dataAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Could not load comparison: $error')),
        data: (items) {
          if (items.isEmpty) {
            return const Center(child: Text('No properties selected to compare.'));
          }
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: items
                  .map((item) => Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: _ComparisonColumn(item: item, priceFormat: priceFormat),
                      ))
                  .toList(),
            ),
          );
        },
      ),
    );
  }
}

class _ComparisonColumn extends StatelessWidget {
  const _ComparisonColumn({required this.item, required this.priceFormat});

  final ComparePropertyItem item;
  final NumberFormat priceFormat;

  Widget _row(String label, String value) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(color: Colors.black54)),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                value,
                textAlign: TextAlign.right,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    final property = item.property;

    return SizedBox(
      width: 260,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(property.name, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 4),
              Text(property.address, style: Theme.of(context).textTheme.bodySmall),
              const Divider(height: 24),
              _row('Min. price', '${priceFormat.format(property.minPrice)}/mo'),
              _row(
                'From campus',
                item.distanceFromCampusKm == null
                    ? 'Unknown'
                    : '${item.distanceFromCampusKm!.toStringAsFixed(1)} km',
              ),
              const SizedBox(height: 12),
              Text('Amenities', style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: 4),
              if (item.amenityNames.isEmpty)
                const Text('None listed')
              else
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: item.amenityNames
                      .map((a) => Chip(label: Text(a, style: const TextStyle(fontSize: 11))))
                      .toList(),
                ),
              const SizedBox(height: 12),
              Text('Rooms', style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: 4),
              if (item.rooms.isEmpty) const Text('No rooms listed'),
              ...item.rooms.map((entry) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(entry.room.roomType, style: Theme.of(context).textTheme.bodySmall),
                        ),
                        Text(
                          _statusLabels[entry.availability.status]!,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  )),
            ],
          ),
        ),
      ),
    );
  }
}
