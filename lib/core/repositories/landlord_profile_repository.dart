import '../models/models.dart';
import 'crud_repository.dart';

abstract class LandlordProfileRepository
    extends CrudRepository<LandlordProfile, String> {
  Future<LandlordProfile?> getByUserId(String userId);

  Future<List<LandlordProfile>> getByVerificationStatus(
    VerificationStatus status,
  );
}
