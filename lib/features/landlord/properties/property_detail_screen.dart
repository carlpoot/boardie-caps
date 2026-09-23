import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/models/models.dart';
import '../../../core/routing/app_router.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/status_display.dart';
import 'landlord_properties_providers.dart';

class PropertyDetailScreen extends ConsumerWidget {
  const PropertyDetailScreen({super.key, required this.propertyId});

  final String propertyId;

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete property?'),
        content: const Text('This removes the listing permanently. This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            key: const Key('confirm_delete_property_button'),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await deleteProperty(ref, propertyId);
      if (context.mounted) Navigator.of(context).pop();
    }
  }

  Future<void> _addAmenityDialog(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Amenity'),
        content: TextField(
          key: const Key('amenity_name_field'),
          controller: controller,
          decoration: const InputDecoration(labelText: 'Amenity name'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
          TextButton(
            key: const Key('confirm_add_amenity_button'),
            onPressed: () => Navigator.of(context).pop(controller.text.trim()),
            child: const Text('Add'),
          ),
        ],
      ),
    );
    if (name != null && name.isNotEmpty) {
      await addAmenity(ref, propertyId, name);
    }
  }

  Future<void> _addImageDialog(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController();
    final url = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Photo'),
        content: TextField(
          key: const Key('image_url_field'),
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Image URL',
            helperText: 'Mock for now -- paste a link. Real photo upload arrives with '
                'Firebase Storage.',
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
          TextButton(
            key: const Key('confirm_add_image_button'),
            onPressed: () => Navigator.of(context).pop(controller.text.trim()),
            child: const Text('Add'),
          ),
        ],
      ),
    );
    if (url != null && url.isNotEmpty) {
      await addPropertyImage(ref, propertyId, url);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final propertyAsync = ref.watch(landlordPropertyByIdProvider(propertyId));
    final amenitiesAsync = ref.watch(propertyAmenitiesProvider(propertyId));
    final imagesAsync = ref.watch(propertyImagesProvider(propertyId));
    final priceFormat =
        NumberFormat.currency(locale: 'en_PH', symbol: '₱', decimalDigits: 0);

    return propertyAsync.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, _) =>
          Scaffold(body: Center(child: Text('Could not load property: $error'))),
      data: (property) {
        if (property == null) {
          return const Scaffold(body: Center(child: Text('Property not found.')));
        }

        return Scaffold(
          appBar: AppBar(
            title: Text(property.name),
            actions: [
              IconButton(
                key: const Key('edit_property_button'),
                icon: const Icon(Icons.edit_outlined),
                onPressed: () =>
                    context.push(AppRoutes.landlordPropertyForm, extra: property),
              ),
              IconButton(
                key: const Key('delete_property_button'),
                icon: const Icon(Icons.delete_outline),
                onPressed: () => _confirmDelete(context, ref),
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _VerificationBadge(status: property.verificationStatus),
              const SizedBox(height: 12),
              Text(property.address),
              const SizedBox(height: 4),
              Text('${property.storeys} storey${property.storeys == 1 ? '' : 's'}'),
              const SizedBox(height: 4),
              Text('From ${priceFormat.format(property.minPrice)}/mo'),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  key: const Key('manage_rooms_button'),
                  icon: const Icon(Icons.meeting_room_outlined),
                  label: const Text('Manage Rooms'),
                  onPressed: () =>
                      context.push(AppRoutes.landlordPropertyRooms(propertyId)),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Text('Amenities', style: Theme.of(context).textTheme.titleSmall),
                  const Spacer(),
                  TextButton.icon(
                    key: const Key('add_amenity_button'),
                    icon: const Icon(Icons.add),
                    label: const Text('Add'),
                    onPressed: () => _addAmenityDialog(context, ref),
                  ),
                ],
              ),
              amenitiesAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => Text('Could not load amenities: $error'),
                data: (amenities) => amenities.isEmpty
                    ? const Text('No amenities yet.')
                    : Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: amenities
                            .map((a) => Chip(
                                  key: Key('amenity_chip_${a.amenityId}'),
                                  label: Text(a.amenityName),
                                  onDeleted: () =>
                                      removeAmenity(ref, propertyId, a.amenityId),
                                  deleteButtonTooltipMessage: 'Remove',
                                ))
                            .toList(),
                      ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Text('Photos', style: Theme.of(context).textTheme.titleSmall),
                  const Spacer(),
                  TextButton.icon(
                    key: const Key('add_image_button'),
                    icon: const Icon(Icons.add_photo_alternate_outlined),
                    label: const Text('Add'),
                    onPressed: () => _addImageDialog(context, ref),
                  ),
                ],
              ),
              imagesAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => Text('Could not load photos: $error'),
                data: (images) => images.isEmpty
                    ? const Text('No photos yet.')
                    : SizedBox(
                        height: 100,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: images.length,
                          separatorBuilder: (_, _) => const SizedBox(width: 8),
                          itemBuilder: (context, index) {
                            final image = images[index];
                            final placeholderColor =
                                Theme.of(context).colorScheme.surfaceContainerHighest;
                            return Stack(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(
                                    image.imageUrl,
                                    width: 100,
                                    height: 100,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, _, _) => Container(
                                      width: 100,
                                      height: 100,
                                      color: placeholderColor,
                                      child: const Icon(Icons.broken_image_outlined),
                                    ),
                                  ),
                                ),
                                Positioned(
                                  top: 2,
                                  right: 2,
                                  child: GestureDetector(
                                    key: Key('remove_image_${image.imageId}'),
                                    onTap: () =>
                                        removePropertyImage(ref, propertyId, image.imageId),
                                    child: const CircleAvatar(
                                      radius: 10,
                                      backgroundColor: Colors.black54,
                                      child: Icon(Icons.close, size: 14, color: Colors.white),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _VerificationBadge extends StatelessWidget {
  const _VerificationBadge({required this.status});

  final VerificationStatus status;

  @override
  Widget build(BuildContext context) {
    final color = status.color;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        status.label,
        style: AppTypography.labelLarge.copyWith(color: color),
      ),
    );
  }
}
