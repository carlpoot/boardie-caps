import 'package:uuid/uuid.dart';

import '../../models/models.dart';
import '../amenity_repository.dart';
import 'mock_helpers.dart';
import 'mock_seed_data.dart';

class MockAmenityRepository implements AmenityRepository {
  final List<Amenity> _amenities = List.of(MockSeedData.amenities);
  final Uuid _uuid = const Uuid();

  @override
  Future<List<Amenity>> getAll() async => List.unmodifiable(_amenities);

  @override
  Future<Amenity?> getById(String id) async =>
      _amenities.firstWhereOrNull((a) => a.amenityId == id);

  @override
  Future<Amenity> create(Amenity item) async {
    final toInsert = item.amenityId.isEmpty
        ? item.copyWith(amenityId: 'amenity-${_uuid.v4()}')
        : item;
    _amenities.add(toInsert);
    return toInsert;
  }

  @override
  Future<Amenity> update(Amenity item) async {
    final index = _amenities.indexWhere((a) => a.amenityId == item.amenityId);
    if (index == -1) {
      throw StateError('Amenity ${item.amenityId} not found');
    }
    _amenities[index] = item;
    return item;
  }

  @override
  Future<void> delete(String id) async {
    _amenities.removeWhere((a) => a.amenityId == id);
  }

  @override
  Future<List<Amenity>> getByProperty(String propertyId) async =>
      _amenities.where((a) => a.propertyId == propertyId).toList();
}
