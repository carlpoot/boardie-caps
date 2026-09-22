import '../models/models.dart';
import 'crud_repository.dart';

abstract class ReportRepository extends CrudRepository<Report, String> {
  Future<List<Report>> getByCreatedBy(String userId);

  Future<List<Report>> getByType(String reportType);
}
