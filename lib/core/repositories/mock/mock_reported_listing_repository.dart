import 'package:uuid/uuid.dart';

import '../../models/models.dart';
import '../reported_listing_repository.dart';
import 'mock_helpers.dart';
import 'mock_seed_data.dart';

class MockReportedListingRepository implements ReportedListingRepository {
  final List<ReportedListing> _reports =
      List.of(MockSeedData.reportedListings);
  final Uuid _uuid = const Uuid();

  @override
  Future<List<ReportedListing>> getAll() async => List.unmodifiable(_reports);

  @override
  Future<ReportedListing?> getById(String id) async =>
      _reports.firstWhereOrNull((r) => r.reportIssueId == id);

  @override
  Future<ReportedListing> create(ReportedListing item) async {
    final toInsert = item.reportIssueId.isEmpty
        ? item.copyWith(reportIssueId: 'reportissue-${_uuid.v4()}')
        : item;
    _reports.add(toInsert);
    return toInsert;
  }

  @override
  Future<ReportedListing> update(ReportedListing item) async {
    final index =
        _reports.indexWhere((r) => r.reportIssueId == item.reportIssueId);
    if (index == -1) {
      throw StateError('ReportedListing ${item.reportIssueId} not found');
    }
    _reports[index] = item;
    return item;
  }

  @override
  Future<void> delete(String id) async {
    _reports.removeWhere((r) => r.reportIssueId == id);
  }

  @override
  Future<List<ReportedListing>> getByProperty(String propertyId) async =>
      _reports.where((r) => r.propertyId == propertyId).toList();

  @override
  Future<List<ReportedListing>> getByReviewStatus(
    ReportedListingReviewStatus status,
  ) async =>
      _reports.where((r) => r.reviewStatus == status).toList();

  @override
  Future<List<ReportedListing>> getByReportedBy(String userId) async =>
      _reports.where((r) => r.reportedBy == userId).toList();
}
