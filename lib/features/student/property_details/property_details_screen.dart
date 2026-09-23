import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/models/models.dart';
import '../../../core/providers/repository_providers.dart';
import '../../auth/providers/auth_notifier.dart';
import 'property_details_providers.dart';
import 'room_tile.dart';

class PropertyDetailsScreen extends ConsumerWidget {
  const PropertyDetailsScreen({super.key, required this.propertyId});

  final String propertyId;

  Future<void> _toggleSave(WidgetRef ref, bool currentlySaved) async {
    final studentId = ref.read(authNotifierProvider).studentId;
    if (studentId == null) return;

    final repository = ref.read(savedPropertyRepositoryProvider);
    if (currentlySaved) {
      final saves = await repository.getByStudent(studentId);
      for (final save in saves.where((s) => s.propertyId == propertyId)) {
        await repository.delete(save.saveId);
      }
    } else {
      await repository.create(SavedProperty(
        saveId: '',
        studentId: studentId,
        propertyId: propertyId,
        savedAt: DateTime.now(),
      ));
    }
    ref.invalidate(propertyDetailsProvider(propertyId));
  }

  void _showComingSoon(BuildContext context, String feature) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text('$feature are coming in a later phase.')));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dataAsync = ref.watch(propertyDetailsProvider(propertyId));
    final priceFormat =
        NumberFormat.currency(locale: 'en_PH', symbol: '₱', decimalDigits: 0);
    final placeholderColor = Theme.of(context).colorScheme.surfaceContainerHighest;

    return Scaffold(
      body: dataAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) =>
            Center(child: Text('Could not load this property: $error')),
        data: (data) {
          if (data == null) {
            return const Center(child: Text('Property not found.'));
          }
          final property = data.property;

          return CustomScrollView(
            slivers: [
              SliverAppBar(
                pinned: true,
                expandedHeight: 220,
                actions: [
                  IconButton(
                    key: const Key('save_property_button'),
                    icon: Icon(data.isSaved ? Icons.favorite : Icons.favorite_border),
                    color: data.isSaved ? Colors.redAccent : null,
                    onPressed: () => _toggleSave(ref, data.isSaved),
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: data.images.isEmpty
                      ? Container(color: placeholderColor)
                      : PageView(
                          children: data.images
                              .map((image) => Image.network(
                                    image.imageUrl,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, _, _) =>
                                        Container(color: placeholderColor),
                                  ))
                              .toList(),
                        ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(property.name, style: Theme.of(context).textTheme.headlineSmall),
                      const SizedBox(height: 4),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.location_on_outlined, size: 16),
                          const SizedBox(width: 4),
                          Expanded(child: Text(property.address)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'From ${priceFormat.format(property.minPrice)}/mo',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      if (data.amenities.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        Text('Amenities', style: Theme.of(context).textTheme.titleSmall),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: data.amenities
                              .map((a) => Chip(label: Text(a.amenityName)))
                              .toList(),
                        ),
                      ],
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          key: const Key('request_visit_button'),
                          icon: const Icon(Icons.event_available_outlined),
                          label: const Text('Request Visit'),
                          onPressed: () => _showComingSoon(context, 'Visit requests'),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text('Rooms', style: Theme.of(context).textTheme.titleSmall),
                      const SizedBox(height: 8),
                      ...data.rooms.map((room) {
                        final availability = data.roomAvailabilities[room.roomId]!;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: RoomTile(
                            room: room,
                            availability: availability,
                            onRequestRoom: () => _showComingSoon(context, 'Room requests'),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
