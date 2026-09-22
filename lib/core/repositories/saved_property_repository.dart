import '../models/models.dart';
import 'crud_repository.dart';

abstract class SavedPropertyRepository
    extends CrudRepository<SavedProperty, String> {
  Future<List<SavedProperty>> getByStudent(String studentId);

  Future<List<SavedProperty>> getByProperty(String propertyId);

  Future<bool> isSaved(String studentId, String propertyId);
}
