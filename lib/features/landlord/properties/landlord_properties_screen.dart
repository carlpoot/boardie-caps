import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/routing/app_router.dart';
import '../../../core/theme/status_display.dart';
import 'landlord_properties_providers.dart';

class LandlordPropertiesScreen extends ConsumerWidget {
  const LandlordPropertiesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final propertiesAsync = ref.watch(landlordPropertiesProvider);
    final priceFormat =
        NumberFormat.currency(locale: 'en_PH', symbol: '₱', decimalDigits: 0);

    return Scaffold(
      body: propertiesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) =>
            Center(child: Text('Could not load your properties: $error')),
        data: (properties) {
          if (properties.isEmpty) {
            return const Center(child: Text('You have no properties yet. Tap + to add one.'));
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
            itemCount: properties.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final property = properties[index];
              return Card(
                child: ListTile(
                  title: Text(property.name),
                  subtitle: Text(
                    '${property.address}\n'
                    'From ${priceFormat.format(property.minPrice)}/mo · '
                    '${property.verificationStatus.label}',
                  ),
                  isThreeLine: true,
                  onTap: () =>
                      context.push(AppRoutes.landlordPropertyDetails(property.propertyId)),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        key: const Key('add_property_fab'),
        onPressed: () => context.push(AppRoutes.landlordPropertyForm),
        child: const Icon(Icons.add),
      ),
    );
  }
}
