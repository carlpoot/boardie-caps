import 'package:uuid/uuid.dart';

import '../../models/models.dart';
import '../property_image_repository.dart';
import 'mock_helpers.dart';
import 'mock_seed_data.dart';

class MockPropertyImageRepository implements PropertyImageRepository {
  final List<PropertyImage> _images = List.of(MockSeedData.propertyImages);
  final Uuid _uuid = const Uuid();

  @override
  Future<List<PropertyImage>> getAll() async => List.unmodifiable(_images);

  @override
  Future<PropertyImage?> getById(String id) async =>
      _images.firstWhereOrNull((i) => i.imageId == id);

  @override
  Future<PropertyImage> create(PropertyImage item) async {
    final toInsert = item.imageId.isEmpty
        ? item.copyWith(imageId: 'image-${_uuid.v4()}')
        : item;
    _images.add(toInsert);
    return toInsert;
  }

  @override
  Future<PropertyImage> update(PropertyImage item) async {
    final index = _images.indexWhere((i) => i.imageId == item.imageId);
    if (index == -1) {
      throw StateError('PropertyImage ${item.imageId} not found');
    }
    _images[index] = item;
    return item;
  }

  @override
  Future<void> delete(String id) async {
    _images.removeWhere((i) => i.imageId == id);
  }

  @override
  Future<List<PropertyImage>> getByProperty(String propertyId) async =>
      _images.where((i) => i.propertyId == propertyId).toList();
}
