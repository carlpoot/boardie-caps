import 'package:uuid/uuid.dart';

import '../../models/models.dart';
import '../user_repository.dart';
import 'mock_helpers.dart';
import 'mock_seed_data.dart';

class MockUserRepository implements UserRepository {
  final List<User> _users = List.of(MockSeedData.users);
  final Uuid _uuid = const Uuid();

  @override
  Future<List<User>> getAll() async => List.unmodifiable(_users);

  @override
  Future<User?> getById(String id) async =>
      _users.firstWhereOrNull((u) => u.userId == id);

  @override
  Future<User> create(User item) async {
    final toInsert = item.userId.isEmpty
        ? item.copyWith(userId: 'user-${_uuid.v4()}')
        : item;
    _users.add(toInsert);
    return toInsert;
  }

  @override
  Future<User> update(User item) async {
    final index = _users.indexWhere((u) => u.userId == item.userId);
    if (index == -1) {
      throw StateError('User ${item.userId} not found');
    }
    _users[index] = item;
    return item;
  }

  @override
  Future<void> delete(String id) async {
    _users.removeWhere((u) => u.userId == id);
  }

  @override
  Future<User?> getByEmail(String email) async =>
      _users.firstWhereOrNull((u) => u.email == email);

  @override
  Future<List<User>> getByRole(UserRole role) async =>
      _users.where((u) => u.role == role).toList();

  @override
  Future<List<User>> getByStatus(UserStatus status) async =>
      _users.where((u) => u.status == status).toList();
}
