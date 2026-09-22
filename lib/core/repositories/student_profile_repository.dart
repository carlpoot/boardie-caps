import '../models/models.dart';
import 'crud_repository.dart';

abstract class StudentProfileRepository
    extends CrudRepository<StudentProfile, String> {
  Future<StudentProfile?> getByUserId(String userId);

  Future<List<StudentProfile>> getByCampus(String campusId);
}
