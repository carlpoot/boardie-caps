import '../models/models.dart';
import 'crud_repository.dart';

abstract class PropertyRepository extends CrudRepository<Property, String> {
  Future<List<Property>> getByLandlord(String landlordId);

  Future<List<Property>> getByVerificationStatus(VerificationStatus status);

  Future<List<Property>> searchByName(String query);
}
