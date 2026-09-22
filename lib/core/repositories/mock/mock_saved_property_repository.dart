import 'package:uuid/uuid.dart';

import '../../models/models.dart';
import '../saved_property_repository.dart';
import 'mock_helpers.dart';
import 'mock_seed_data.dart';

class MockSavedPropertyRepository implements SavedPropertyRepository {
  final List<SavedProperty> _saves = List.of(MockSeedData.savedProperties);
  final Uuid _uuid = const Uuid();

  @override
  Future<List<SavedProperty>> getAll() async => List.unmodifiable(_saves);

  @override
  Future<SavedProperty?> getById(String id) async =>
      _saves.firstWhereOrNull((s) => s.saveId == id);

  @override
  Future<SavedProperty> create(SavedProperty item) async {
    final toInsert = item.saveId.isEmpty
        ? item.copyWith(saveId: 'save-${_uuid.v4()}')
        : item;
    _saves.add(toInsert);
    return toInsert;
  }

  @override
  Future<SavedProperty> update(SavedProperty item) async {
    final index = _saves.indexWhere((s) => s.saveId == item.saveId);
    if (index == -1) {
      throw StateError('SavedProperty ${item.saveId} not found');
    }
    _saves[index] = item;
    return item;
  }

  @override
  Future<void> delete(String id) async {
    _saves.removeWhere((s) => s.saveId == id);
  }

  @override
  Future<List<SavedProperty>> getByStudent(String studentId) async =>
      _saves.where((s) => s.studentId == studentId).toList();

  @override
  Future<List<SavedProperty>> getByProperty(String propertyId) async =>
      _saves.where((s) => s.propertyId == propertyId).toList();

  @override
  Future<bool> isSaved(String studentId, String propertyId) async => _saves.any(
        (s) => s.studentId == studentId && s.propertyId == propertyId,
      );
}
