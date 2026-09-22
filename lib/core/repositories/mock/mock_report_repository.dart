import 'package:uuid/uuid.dart';

import '../../models/models.dart';
import '../report_repository.dart';
import 'mock_helpers.dart';
import 'mock_seed_data.dart';

class MockReportRepository implements ReportRepository {
  final List<Report> _reports = List.of(MockSeedData.reports);
  final Uuid _uuid = const Uuid();

  @override
  Future<List<Report>> getAll() async => List.unmodifiable(_reports);

  @override
  Future<Report?> getById(String id) async =>
      _reports.firstWhereOrNull((r) => r.reportId == id);

  @override
  Future<Report> create(Report item) async {
    final toInsert = item.reportId.isEmpty
        ? item.copyWith(reportId: 'report-${_uuid.v4()}')
        : item;
    _reports.add(toInsert);
    return toInsert;
  }

  @override
  Future<Report> update(Report item) async {
    final index = _reports.indexWhere((r) => r.reportId == item.reportId);
    if (index == -1) {
      throw StateError('Report ${item.reportId} not found');
    }
    _reports[index] = item;
    return item;
  }

  @override
  Future<void> delete(String id) async {
    _reports.removeWhere((r) => r.reportId == id);
  }

  @override
  Future<List<Report>> getByCreatedBy(String userId) async =>
      _reports.where((r) => r.createdBy == userId).toList();

  @override
  Future<List<Report>> getByType(String reportType) async =>
      _reports.where((r) => r.reportType == reportType).toList();
}
