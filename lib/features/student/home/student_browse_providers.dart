import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/models.dart';
import '../../../core/providers/repository_providers.dart';
import '../../../core/providers/service_providers.dart';
import '../../../core/services/distance_utils.dart';
import '../../auth/providers/auth_notifier.dart';
import 'property_browse_item.dart';

/// The current student's campus, used for the "Near BU" filter and the map
/// placeholder's distance text. Null if there's no student session or the
/// linked profile/campus can't be found.
final currentStudentCampusProvider = FutureProvider<Campus?>((ref) async {
  final studentId = ref.watch(authNotifierProvider).studentId;
  if (studentId == null) return null;

  final profile =
      await ref.watch(studentProfileRepositoryProvider).getById(studentId);
  if (profile == null) return null;

  return ref.watch(campusRepositoryProvider).getById(profile.campusId);
});

/// Every verified property, composed with everything the browse list and
/// map placeholder need. Fetched once and filtered/sorted client-side by
/// whatever screen watches it, rather than re-querying per filter change.
///
/// Only `verified` properties are included -- pending/rejected listings
/// aren't shown to students, matching what "Browse Listings" should mean
/// for a public-facing catalog.
final studentBrowsePropertiesProvider =
    FutureProvider<List<PropertyBrowseItem>>((ref) async {
  final propertyRepository = ref.watch(propertyRepositoryProvider);
  final roomRepository = ref.watch(roomRepositoryProvider);
  final amenityRepository = ref.watch(amenityRepositoryProvider);
  final imageRepository = ref.watch(propertyImageRepositoryProvider);
  final availabilityService = ref.watch(roomAvailabilityServiceProvider);
  final campus = await ref.watch(currentStudentCampusProvider.future);

  final properties = await propertyRepository
      .getByVerificationStatus(VerificationStatus.verified);

  final items = <PropertyBrowseItem>[];
  for (final property in properties) {
    final rooms = await roomRepository.getByProperty(property.propertyId);
    final amenities =
        await amenityRepository.getByProperty(property.propertyId);
    final images = await imageRepository.getByProperty(property.propertyId);
    final availableSlots = await availabilityService.totalAvailableSlots(rooms);

    items.add(PropertyBrowseItem(
      property: property,
      coverImageUrl: images.isEmpty ? null : images.first.imageUrl,
      amenityNames: amenities.map((a) => a.amenityName).toList(),
      roomTypes: rooms.map((r) => r.roomType).toSet(),
      availableSlots: availableSlots,
      distanceFromCampusKm: campus == null
          ? null
          : haversineDistanceKm(
              property.latitude,
              property.longitude,
              campus.latitude,
              campus.longitude,
            ),
    ));
  }

  return items;
});
