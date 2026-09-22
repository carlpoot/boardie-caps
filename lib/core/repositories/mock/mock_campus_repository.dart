import 'package:uuid/uuid.dart';

import '../../models/models.dart';
import '../campus_repository.dart';
import 'mock_helpers.dart';
import 'mock_seed_data.dart';

class MockCampusRepository implements CampusRepository {
  final List<Campus> _campuses = List.of(MockSeedData.campuses);
  final Uuid _uuid = const Uuid();

  @override
  Future<List<Campus>> getAll() async => List.unmodifiable(_campuses);

  @override
  Future<Campus?> getById(String id) async =>
      _campuses.firstWhereOrNull((c) => c.campusId == id);

  @override
  Future<Campus> create(Campus item) async {
    final toInsert = item.campusId.isEmpty
        ? item.copyWith(campusId: 'campus-${_uuid.v4()}')
        : item;
    _campuses.add(toInsert);
    return toInsert;
  }

  @override
  Future<Campus> update(Campus item) async {
    final index = _campuses.indexWhere((c) => c.campusId == item.campusId);
    if (index == -1) {
      throw StateError('Campus ${item.campusId} not found');
    }
    _campuses[index] = item;
    return item;
  }

  @override
  Future<void> delete(String id) async {
    _campuses.removeWhere((c) => c.campusId == id);
  }

  @override
  Future<List<Campus>> searchByName(String query) async {
    final lower = query.toLowerCase();
    return _campuses.where((c) => c.name.toLowerCase().contains(lower)).toList();
  }
}
