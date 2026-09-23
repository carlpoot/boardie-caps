import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/models.dart';
import '../../../core/providers/repository_providers.dart';

/// A `pending`-verification [Property] composed with its photos, its
/// owning landlord's own (separate) verification status, and any
/// `ReportedListings` still awaiting review against it. Not a Phase 1 ERD
/// entity, just a UI view-model.
class AdminPendingPropertyItem {
  const AdminPendingPropertyItem({
    required this.property,
    required this.images,
    required this.landlordProfile,
    required this.pendingReports,
  });

  final Property property;
  final List<PropertyImage> images;
  final LandlordProfile? landlordProfile;
  final List<ReportedListing> pendingReports;
}

/// Every `Properties` row with `verification_status = pending`, system-wide.
final adminPendingPropertiesProvider =
    FutureProvider<List<AdminPendingPropertyItem>>((ref) async {
  final propertyRepository = ref.watch(propertyRepositoryProvider);
  final imageRepository = ref.watch(propertyImageRepositoryProvider);
  final landlordProfileRepository = ref.watch(landlordProfileRepositoryProvider);
  final reportedListingRepository = ref.watch(reportedListingRepositoryProvider);

  final properties =
      await propertyRepository.getByVerificationStatus(VerificationStatus.pending);

  final items = <AdminPendingPropertyItem>[];
  for (final property in properties) {
    final images = await imageRepository.getByProperty(property.propertyId);
    final landlordProfile =
        await landlordProfileRepository.getById(property.landlordId);
    final reports = await reportedListingRepository.getByProperty(property.propertyId);
    items.add(AdminPendingPropertyItem(
      property: property,
      images: images,
      landlordProfile: landlordProfile,
      pendingReports: reports
          .where((r) => r.reviewStatus == ReportedListingReviewStatus.pending)
          .toList(),
    ));
  }
  items.sort((a, b) => a.property.createdAt.compareTo(b.property.createdAt));
  return items;
});

/// Sets `Properties.verification_status = verified`.
///
/// Deliberately callable regardless of any pending `ReportedListings`
/// against the property -- see the README for why a pending report is
/// surfaced to the admin as a warning (in [AdminPendingPropertyItem
/// .pendingReports]) rather than a hard block on this action.
Future<void> verifyProperty(WidgetRef ref, String propertyId) async {
  final repository = ref.read(propertyRepositoryProvider);
  final property = await repository.getById(propertyId);
  if (property == null) return;
  await repository.update(property.copyWith(verificationStatus: VerificationStatus.verified));
  ref.invalidate(adminPendingPropertiesProvider);
}

/// Sets `Properties.verification_status = rejected`.
///
/// Not restricted to properties currently `pending` -- this is also the
/// "separate explicit action" an admin uses from the Reported Listings
/// screen to act on an already-verified property in response to a report,
/// per the documented review/verification-independence decision (see the
/// README's Admin screens section).
Future<void> rejectProperty(WidgetRef ref, String propertyId) async {
  final repository = ref.read(propertyRepositoryProvider);
  final property = await repository.getById(propertyId);
  if (property == null) return;
  await repository.update(property.copyWith(verificationStatus: VerificationStatus.rejected));
  ref.invalidate(adminPendingPropertiesProvider);
}
