import 'package:uuid/uuid.dart';

import '../../models/models.dart';
import '../student_profile_repository.dart';
import 'mock_helpers.dart';
import 'mock_seed_data.dart';

class MockStudentProfileRepository implements StudentProfileRepository {
  final List<StudentProfile> _profiles =
      List.of(MockSeedData.studentProfiles);
  final Uuid _uuid = const Uuid();

  @override
  Future<List<StudentProfile>> getAll() async => List.unmodifiable(_profiles);

  @override
  Future<StudentProfile?> getById(String id) async =>
      _profiles.firstWhereOrNull((p) => p.studentId == id);

  @override
  Future<StudentProfile> create(StudentProfile item) async {
    final toInsert = item.studentId.isEmpty
        ? item.copyWith(studentId: 'student-${_uuid.v4()}')
        : item;
    _profiles.add(toInsert);
    return toInsert;
  }

  @override
  Future<StudentProfile> update(StudentProfile item) async {
    final index = _profiles.indexWhere((p) => p.studentId == item.studentId);
    if (index == -1) {
      throw StateError('StudentProfile ${item.studentId} not found');
    }
    _profiles[index] = item;
    return item;
  }

  @override
  Future<void> delete(String id) async {
    _profiles.removeWhere((p) => p.studentId == id);
  }

  @override
  Future<StudentProfile?> getByUserId(String userId) async =>
      _profiles.firstWhereOrNull((p) => p.userId == userId);

  @override
  Future<List<StudentProfile>> getByCampus(String campusId) async =>
      _profiles.where((p) => p.campusId == campusId).toList();
}
