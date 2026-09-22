import '../models/models.dart';
import 'crud_repository.dart';

abstract class VisitRequestRepository
    extends CrudRepository<VisitRequest, String> {
  Future<List<VisitRequest>> getByStudent(String studentId);

  Future<List<VisitRequest>> getByLandlord(String landlordId);

  Future<List<VisitRequest>> getByProperty(String propertyId);

  Future<List<VisitRequest>> getByStatus(VisitRequestStatus status);
}
