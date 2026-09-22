import '../models/models.dart';
import 'crud_repository.dart';

abstract class ReportedListingRepository
    extends CrudRepository<ReportedListing, String> {
  Future<List<ReportedListing>> getByProperty(String propertyId);

  Future<List<ReportedListing>> getByReviewStatus(
    ReportedListingReviewStatus status,
  );

  Future<List<ReportedListing>> getByReportedBy(String userId);
}
