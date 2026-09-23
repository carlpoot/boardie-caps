import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import 'property_browse_item.dart';

class PropertyCard extends StatelessWidget {
  const PropertyCard({
    super.key,
    required this.item,
    required this.onTap,
    this.selectionMode = false,
    this.selected = false,
  });

  final PropertyBrowseItem item;
  final VoidCallback onTap;

  /// When true, shows a selection checkmark overlay instead of behaving as
  /// a plain "open details" card -- used by the Compare Properties flow.
  final bool selectionMode;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final priceFormat =
        NumberFormat.currency(locale: 'en_PH', symbol: '₱', decimalDigits: 0);
    final property = item.property;
    final placeholderColor = Theme.of(context).colorScheme.surfaceContainerHighest;

    return SizedBox(
      width: 240,
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                children: [
                  AspectRatio(
                    aspectRatio: 16 / 9,
                    child: item.coverImageUrl == null
                        ? Container(
                            color: placeholderColor,
                            child: const Icon(Icons.home_outlined, size: 40),
                          )
                        : Image.network(
                            item.coverImageUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => Container(
                              color: placeholderColor,
                              child: const Icon(Icons.broken_image_outlined),
                            ),
                          ),
                  ),
                  if (selectionMode)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: CircleAvatar(
                        radius: 12,
                        backgroundColor:
                            selected ? Theme.of(context).colorScheme.primary : Colors.white70,
                        child: Icon(
                          selected ? Icons.check : Icons.circle_outlined,
                          size: 16,
                          color: selected ? Colors.white : Colors.black54,
                        ),
                      ),
                    ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            property.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                        ),
                        const SizedBox(width: 4),
                        _SlotsBadge(availableSlots: item.availableSlots),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      property.address,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    if (item.amenityNames.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      // Fixed-height horizontal scroll rather than a Wrap --
                      // a Wrap can spill onto a second line and blow this
                      // card's height budget when amenity names are long.
                      SizedBox(
                        height: 24,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: item.amenityNames.take(3).length,
                          separatorBuilder: (_, _) => const SizedBox(width: 4),
                          itemBuilder: (context, index) {
                            final name = item.amenityNames.take(3).toList()[index];
                            return Chip(
                              label: Text(name, style: AppTypography.caption),
                              visualDensity: VisualDensity.compact,
                              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              padding: EdgeInsets.zero,
                            );
                          },
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Text(
                      'From ${priceFormat.format(property.minPrice)}/mo',
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SlotsBadge extends StatelessWidget {
  const _SlotsBadge({required this.availableSlots});

  final int availableSlots;

  @override
  Widget build(BuildContext context) {
    final isFull = availableSlots <= 0;
    final color = isFull ? AppColors.statusFull : AppColors.statusAvailable;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        isFull ? 'Full' : '$availableSlots slot${availableSlots == 1 ? '' : 's'}',
        style: AppTypography.statusBadge.copyWith(color: color, fontSize: 11),
      ),
    );
  }
}
