import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/routing/app_router.dart';
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

  List<PropertyBrowseItem> _applyFilters(List<PropertyBrowseItem> items) {
    var filtered = items;

    final query = _searchQuery.trim().toLowerCase();
    if (query.isNotEmpty) {
      filtered = filtered
          .where((item) =>
              item.property.name.toLowerCase().contains(query) ||
              item.property.address.toLowerCase().contains(query))
          .toList();
    }

    if (_selectedFilter == _nearCampusFilterKey) {
      filtered = filtered
          .where((item) =>
              item.distanceFromCampusKm != null &&
              item.distanceFromCampusKm! <= _nearCampusThresholdKm)
          .toList();
    } else if (_selectedFilter != _allFilterKey) {
      filtered =
          filtered.where((item) => item.roomTypes.contains(_selectedFilter)).toList();
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final itemsAsync = ref.watch(studentBrowsePropertiesProvider);

    return SafeArea(
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
                final roomTypes = items.expand((item) => item.roomTypes).toSet().toList()
                  ..sort();
                final chips = [_allFilterKey, _nearCampusFilterKey, ...roomTypes];

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
                      onSelected: (_) => setState(() => _selectedFilter = key),
                    );
                  },
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Nearby Boarding Houses',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: itemsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) =>
                  Center(child: Text('Could not load properties: $error')),
              data: (items) {
                final filtered = _applyFilters(items);
                if (filtered.isEmpty) {
                  return const Center(child: Text('No properties match your filters.'));
                }
                return ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: filtered.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 12),
                  itemBuilder: (context, index) {
                    final item = filtered[index];
                    return PropertyCard(
                      item: item,
                      onTap: () => context
                          .push(AppRoutes.studentPropertyDetails(item.property.propertyId)),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
