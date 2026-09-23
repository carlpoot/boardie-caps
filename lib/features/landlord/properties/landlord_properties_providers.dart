import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/models.dart';
import '../../../core/providers/repository_providers.dart';
import '../../auth/providers/auth_notifier.dart';

/// Every property owned by the current landlord.
final landlordPropertiesProvider = FutureProvider<List<Property>>((ref) async {
  final landlordId = ref.watch(authNotifierProvider).landlordId;
  if (landlordId == null) return [];
  return ref.watch(propertyRepositoryProvider).getByLandlord(landlordId);
});

/// A single property by id, independent of whether the full list above has
/// resolved yet -- used by the detail/edit/rooms screens.
final landlordPropertyByIdProvider =
    FutureProvider.family<Property?, String>((ref, propertyId) {
  return ref.watch(propertyRepositoryProvider).getById(propertyId);
});

final propertyAmenitiesProvider =
    FutureProvider.family<List<Amenity>, String>((ref, propertyId) {
  return ref.watch(amenityRepositoryProvider).getByProperty(propertyId);
});

final propertyImagesProvider =
    FutureProvider.family<List<PropertyImage>, String>((ref, propertyId) {
  return ref.watch(propertyImageRepositoryProvider).getByProperty(propertyId);
});

/// Creates a new `Properties` row for the current landlord.
/// `verification_status` always starts `pending` -- only an admin can move
/// it to `verified` (Phase 5).
Future<Property> createProperty(
  WidgetRef ref, {
  required String name,
  required String address,
  required double latitude,
  required double longitude,
  required int storeys,
  required num minPrice,
}) async {
  final landlordId = ref.read(authNotifierProvider).landlordId;
  if (landlordId == null) {
    throw StateError('Only a signed-in landlord can create a property.');
  }

  final property = await ref.read(propertyRepositoryProvider).create(Property(
        propertyId: '',
        landlordId: landlordId,
        name: name,
        address: address,
        latitude: latitude,
        longitude: longitude,
        storeys: storeys,
        verificationStatus: VerificationStatus.pending,
        minPrice: minPrice,
        createdAt: DateTime.now(),
      ));

  ref.invalidate(landlordPropertiesProvider);
  return property;
}

Future<void> updateProperty(
  WidgetRef ref,
  Property existing, {
  required String name,
  required String address,
  required double latitude,
  required double longitude,
  required int storeys,
  required num minPrice,
}) async {
  await ref.read(propertyRepositoryProvider).update(existing.copyWith(
        name: name,
        address: address,
        latitude: latitude,
        longitude: longitude,
        storeys: storeys,
        minPrice: minPrice,
      ));

  ref.invalidate(landlordPropertiesProvider);
  ref.invalidate(landlordPropertyByIdProvider(existing.propertyId));
}

Future<void> deleteProperty(WidgetRef ref, String propertyId) async {
  await ref.read(propertyRepositoryProvider).delete(propertyId);
  ref.invalidate(landlordPropertiesProvider);
}

Future<void> addAmenity(WidgetRef ref, String propertyId, String amenityName) async {
  await ref.read(amenityRepositoryProvider).create(Amenity(
        amenityId: '',
        propertyId: propertyId,
        amenityName: amenityName,
      ));
  ref.invalidate(propertyAmenitiesProvider(propertyId));
}

Future<void> removeAmenity(WidgetRef ref, String propertyId, String amenityId) async {
  await ref.read(amenityRepositoryProvider).delete(amenityId);
  ref.invalidate(propertyAmenitiesProvider(propertyId));
}

/// [imageUrl] is a mock stand-in (the landlord pastes a link) rather than a
/// real upload -- real Firebase Storage upload comes in a later phase. See
/// the README for why this phase doesn't wire an OS file picker.
Future<void> addPropertyImage(WidgetRef ref, String propertyId, String imageUrl) async {
  await ref.read(propertyImageRepositoryProvider).create(PropertyImage(
        imageId: '',
        propertyId: propertyId,
        imageUrl: imageUrl,
      ));
  ref.invalidate(propertyImagesProvider(propertyId));
}

Future<void> removePropertyImage(WidgetRef ref, String propertyId, String imageId) async {
  await ref.read(propertyImageRepositoryProvider).delete(imageId);
  ref.invalidate(propertyImagesProvider(propertyId));
}
