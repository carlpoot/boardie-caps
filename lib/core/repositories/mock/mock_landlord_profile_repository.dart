import 'package:uuid/uuid.dart';

import '../../models/models.dart';
import '../landlord_profile_repository.dart';
import 'mock_helpers.dart';
import 'mock_seed_data.dart';

class MockLandlordProfileRepository implements LandlordProfileRepository {
  final List<LandlordProfile> _profiles =
      List.of(MockSeedData.landlordProfiles);
  final Uuid _uuid = const Uuid();

  @override
  Future<List<LandlordProfile>> getAll() async => List.unmodifiable(_profiles);

  @override
  Future<LandlordProfile?> getById(String id) async =>
      _profiles.firstWhereOrNull((p) => p.landlordId == id);

  @override
  Future<LandlordProfile> create(LandlordProfile item) async {
    final toInsert = item.landlordId.isEmpty
        ? item.copyWith(landlordId: 'landlord-${_uuid.v4()}')
        : item;
    _profiles.add(toInsert);
    return toInsert;
  }

  @override
  Future<LandlordProfile> update(LandlordProfile item) async {
    final index = _profiles.indexWhere((p) => p.landlordId == item.landlordId);
    if (index == -1) {
      throw StateError('LandlordProfile ${item.landlordId} not found');
    }
    _profiles[index] = item;
    return item;
  }

  @override
  Future<void> delete(String id) async {
    _profiles.removeWhere((p) => p.landlordId == id);
  }

  @override
  Future<LandlordProfile?> getByUserId(String userId) async =>
      _profiles.firstWhereOrNull((p) => p.userId == userId);

  @override
  Future<List<LandlordProfile>> getByVerificationStatus(
    VerificationStatus status,
  ) async =>
      _profiles.where((p) => p.verificationStatus == status).toList();
}
