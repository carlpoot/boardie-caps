import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/routing/app_router.dart';
import '../compare_properties/compare_selection_provider.dart';
import 'property_browse_item.dart';
import 'property_card.dart';
import 'student_browse_providers.dart';

/// "Near BU" filter threshold, in km. Bicol-area cities are compact enough
/// that a couple of kilometers is a meaningful walking/tricycle-ride cutoff.
const _nearCampusThresholdKm = 2.0;

const _allFilterKey = 'all';
const _nearCampusFilterKey = 'near_campus';

class HomeTabScreen extends ConsumerStatefulWidget {
  const HomeTabScreen({super.key});

  @override
  ConsumerState<HomeTabScreen> createState() => _HomeTabScreenState();
}

class _HomeTabScreenState extends ConsumerState<HomeTabScreen> {
  String _searchQuery = '';
  String _selectedFilter = _allFilterKey;
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
        ..showSnackBar(
          SnackBar(
            content: Text(
              'You can compare up to $maxCompareSelection properties.',
            ),
          ),
        );
      return;
    }
    ref.read(compareSelectionProvider.notifier).state = next;
  }

  List<PropertyBrowseItem> _applyFilters(List<PropertyBrowseItem> items) {
    var filtered = items;

    final query = _searchQuery.trim().toLowerCase();
    if (query.isNotEmpty) {
      filtered = filtered
          .where(
            (item) =>
                item.property.name.toLowerCase().contains(query) ||
                item.property.address.toLowerCase().contains(query),
          )
          .toList();
    }

    if (_selectedFilter == _nearCampusFilterKey) {
      filtered = filtered
          .where(
            (item) =>
                item.distanceFromCampusKm != null &&
                item.distanceFromCampusKm! <= _nearCampusThresholdKm,
          )
          .toList();
    } else if (_selectedFilter != _allFilterKey) {
      filtered = filtered
          .where((item) => item.roomTypes.contains(_selectedFilter))
          .toList();
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final itemsAsync = ref.watch(studentBrowsePropertiesProvider);

    return SafeArea(
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: TextField(
                decoration: const InputDecoration(
                  hintText: 'Search by name or address',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                onChanged: (value) => setState(() => _searchQuery = value),
              ),
            ),
            SizedBox(
              height: 40,
              child: itemsAsync.when(
                loading: () => const SizedBox.shrink(),
                error: (_, _) => const SizedBox.shrink(),
                data: (items) {
                  final roomTypes =
                      items.expand((item) => item.roomTypes).toSet().toList()
                        ..sort();
                  final chips = [
                    _allFilterKey,
                    _nearCampusFilterKey,
                    ...roomTypes,
                  ];

                  return ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: chips.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final key = chips[index];
                      final label = switch (key) {
                        _allFilterKey => 'All',
                        _nearCampusFilterKey => 'Near BU',
                        _ => key,
                      };
                      return ChoiceChip(
                        label: Text(label),
                        selected: _selectedFilter == key,
                        onSelected: (_) =>
                            setState(() => _selectedFilter = key),
                      );
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Nearby Boarding Houses',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  TextButton(
                    key: const Key('toggle_compare_mode_button'),
                    onPressed: _toggleCompareMode,
                    child: Text(_compareMode ? 'Cancel' : 'Compare'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            // Fixed height rather than Expanded: this is a horizontally
            // scrolling rail with intrinsically-sized cards, not a region
            // that should stretch to fill whatever space is left over --
            // that made it fragile to any change in the surrounding layout
            // (like the compare bar below). The whole tab scrolls if the
            // viewport is short, instead of this card list overflowing.
            SizedBox(
              height: 300,
              child: itemsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) =>
                    Center(child: Text('Could not load properties: $error')),
                data: (items) {
                  final filtered = _applyFilters(items);
                  if (filtered.isEmpty) {
                    return const Center(
                      child: Text('No properties match your filters.'),
                    );
                  }
                  final selectedIds = ref.watch(compareSelectionProvider);
                  return ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: filtered.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 12),
                    itemBuilder: (context, index) {
                      final item = filtered[index];
                      final propertyId = item.property.propertyId;
                      return PropertyCard(
                        item: item,
                        selectionMode: _compareMode,
                        selected: selectedIds.contains(propertyId),
                        onTap: _compareMode
                            ? () => _toggleSelection(propertyId)
                            : () => context.push(
                                AppRoutes.studentPropertyDetails(propertyId),
                              ),
                      );
                    },
                  );
                },
              ),
            ),
            if (_compareMode)
              Padding(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    key: const Key('compare_selected_button'),
                    onPressed: ref.watch(compareSelectionProvider).length >= 2
                        ? () => context.push(
                            AppRoutes.studentCompare,
                            extra: ref.read(compareSelectionProvider).toList(),
                          )
                        : null,
                    child: Text(
                      'Compare (${ref.watch(compareSelectionProvider).length})',
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
