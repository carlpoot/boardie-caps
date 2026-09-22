import '../models/models.dart';
import 'crud_repository.dart';

abstract class PropertyImageRepository
    extends CrudRepository<PropertyImage, String> {
  Future<List<PropertyImage>> getByProperty(String propertyId);
}
