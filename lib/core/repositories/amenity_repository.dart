import '../models/models.dart';
import 'crud_repository.dart';

abstract class AmenityRepository extends CrudRepository<Amenity, String> {
  Future<List<Amenity>> getByProperty(String propertyId);
}
