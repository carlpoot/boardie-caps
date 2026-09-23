import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/routing/app_router.dart';
import '../home/student_browse_providers.dart';

/// Placeholder for the Map tab: a distance-sorted list for now. The real
/// GoogleMap widget arrives in a later phase -- this widget is the only
/// thing that needs to change when it does, since callers just embed
/// `MapView` without caring how it's implemented.
class MapView extends ConsumerWidget {
  const MapView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itemsAsync = ref.watch(studentBrowsePropertiesProvider);

    return itemsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text('Could not load properties: $error')),
      data: (items) {
        if (items.isEmpty) {
          return const Center(child: Text('No properties to show yet.'));
        }

        final sorted = [...items]
          ..sort((a, b) {
            final distanceA = a.distanceFromCampusKm ?? double.infinity;
            final distanceB = b.distanceFromCampusKm ?? double.infinity;
            return distanceA.compareTo(distanceB);
          });

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: sorted.length,
          separatorBuilder: (_, _) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final item = sorted[index];
            final distanceText = item.distanceFromCampusKm == null
                ? 'Distance unknown'
                : '${item.distanceFromCampusKm!.toStringAsFixed(1)} km from campus';

            return ListTile(
              leading: const Icon(Icons.location_on_outlined),
              title: Text(item.property.name),
              subtitle: Text('${item.property.address}\n$distanceText'),
              isThreeLine: true,
              trailing: Text(
                item.availableSlots <= 0 ? 'Full' : '${item.availableSlots} slots',
              ),
              onTap: () => context
                  .push(AppRoutes.studentPropertyDetails(item.property.propertyId)),
            );
          },
        );
      },
    );
  }
}
