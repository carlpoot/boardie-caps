import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/routing/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../compare_properties/compare_selection_provider.dart';
import 'profile_providers.dart';

class SavedPropertiesScreen extends ConsumerStatefulWidget {
  const SavedPropertiesScreen({super.key});

  @override
  ConsumerState<SavedPropertiesScreen> createState() => _SavedPropertiesScreenState();
}

class _SavedPropertiesScreenState extends ConsumerState<SavedPropertiesScreen> {
  bool _compareMode = false;

  void _toggleCompareMode() {
    setState(() => _compareMode = !_compareMode);
    if (!_compareMode) ref.read(compareSelectionProvider.notifier).state = {};
  }

  void _toggleSelection(String propertyId) {
    final current = ref.read(compareSelectionProvider);
    final next = {...current};
    if (next.contains(propertyId)) {
      next.remove(propertyId);
    } else if (next.length < maxCompareSelection) {
      next.add(propertyId);
    } else {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text('You can compare up to $maxCompareSelection properties.')));
      return;
    }
    ref.read(compareSelectionProvider.notifier).state = next;
  }

  Future<void> _unsave(String propertyId) async {
    await unsaveProperty(ref, propertyId);
    if (mounted) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text('Removed from saved properties.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final propertiesAsync = ref.watch(studentSavedPropertiesProvider);
    final selectedIds = ref.watch(compareSelectionProvider);
    final priceFormat =
        NumberFormat.currency(locale: 'en_PH', symbol: '₱', decimalDigits: 0);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Saved Properties'),
        actions: [
          // Explicit onPrimary color, not the themed TextButton foreground
          // (which is brand blue) -- this button sits on the AppBar's own
          // blue background, where it needs to contrast instead of match.
          TextButton(
            key: const Key('toggle_saved_compare_mode_button'),
            onPressed: _toggleCompareMode,
            child: Text(
              _compareMode ? 'Cancel' : 'Compare',
              style: const TextStyle(color: AppColors.onPrimary),
            ),
          ),
        ],
      ),
      body: propertiesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Could not load saved properties: $error')),
        data: (properties) {
          if (properties.isEmpty) {
            return const Center(child: Text('No saved properties yet.'));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: properties.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final property = properties[index];
              final propertyId = property.propertyId;
              return Card(
                child: ListTile(
                  leading: _compareMode
                      ? Checkbox(
                          key: Key('compare_checkbox_$propertyId'),
                          value: selectedIds.contains(propertyId),
                          onChanged: (_) => _toggleSelection(propertyId),
                        )
                      : null,
                  title: Text(property.name),
                  subtitle: Text(
                    '${property.address}\nFrom ${priceFormat.format(property.minPrice)}/mo',
                  ),
                  isThreeLine: true,
                  trailing: _compareMode
                      ? null
                      : IconButton(
                          key: Key('unsave_$propertyId'),
                          icon: const Icon(Icons.favorite),
                          color: AppColors.favorite,
                          tooltip: 'Remove from saved',
                          onPressed: () => _unsave(propertyId),
                        ),
                  onTap: _compareMode
                      ? () => _toggleSelection(propertyId)
                      : () => context.push(AppRoutes.studentPropertyDetails(propertyId)),
                ),
              );
            },
          );
        },
      ),
      bottomNavigationBar: _compareMode
          ? Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  key: const Key('compare_selected_from_saved_button'),
                  onPressed: selectedIds.length >= 2
                      ? () =>
                          context.push(AppRoutes.studentCompare, extra: selectedIds.toList())
                      : null,
                  child: Text('Compare (${selectedIds.length})'),
                ),
              ),
            )
          : null,
    );
  }
}
