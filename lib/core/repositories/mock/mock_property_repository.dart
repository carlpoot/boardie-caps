import 'package:uuid/uuid.dart';

import '../../models/models.dart';
import '../property_repository.dart';
import 'mock_helpers.dart';
import 'mock_seed_data.dart';

class MockPropertyRepository implements PropertyRepository {
  final List<Property> _properties = List.of(MockSeedData.properties);
  final Uuid _uuid = const Uuid();

  @override
  Future<List<Property>> getAll() async => List.unmodifiable(_properties);

  @override
  Future<Property?> getById(String id) async =>
      _properties.firstWhereOrNull((p) => p.propertyId == id);

  @override
  Future<Property> create(Property item) async {
    final toInsert = item.propertyId.isEmpty
        ? item.copyWith(propertyId: 'property-${_uuid.v4()}')
        : item;
    _properties.add(toInsert);
    return toInsert;
  }

  @override
  Future<Property> update(Property item) async {
    final index =
        _properties.indexWhere((p) => p.propertyId == item.propertyId);
    if (index == -1) {
      throw StateError('Property ${item.propertyId} not found');
    }
    _properties[index] = item;
    return item;
  }

  @override
  Future<void> delete(String id) async {
    _properties.removeWhere((p) => p.propertyId == id);
  }

  @override
  Future<List<Property>> getByLandlord(String landlordId) async =>
      _properties.where((p) => p.landlordId == landlordId).toList();

  @override
  Future<List<Property>> getByVerificationStatus(
    VerificationStatus status,
  ) async =>
      _properties.where((p) => p.verificationStatus == status).toList();

  @override
  Future<List<Property>> searchByName(String query) async {
    final lower = query.toLowerCase();
    return _properties
        .where((p) => p.name.toLowerCase().contains(lower))
        .toList();
  }
}
