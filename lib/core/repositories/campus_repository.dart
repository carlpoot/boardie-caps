import '../models/models.dart';
import 'crud_repository.dart';

abstract class CampusRepository extends CrudRepository<Campus, String> {
  Future<List<Campus>> searchByName(String query);
}
