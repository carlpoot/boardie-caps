import '../models/models.dart';
import 'crud_repository.dart';

abstract class UserRepository extends CrudRepository<User, String> {
  Future<User?> getByEmail(String email);

  Future<List<User>> getByRole(UserRole role);

  Future<List<User>> getByStatus(UserStatus status);
}
