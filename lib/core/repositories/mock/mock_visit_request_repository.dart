import 'package:uuid/uuid.dart';

import '../../models/models.dart';
import '../visit_request_repository.dart';
import 'mock_helpers.dart';
import 'mock_seed_data.dart';

class MockVisitRequestRepository implements VisitRequestRepository {
  final List<VisitRequest> _requests = List.of(MockSeedData.visitRequests);
  final Uuid _uuid = const Uuid();

  @override
  Future<List<VisitRequest>> getAll() async => List.unmodifiable(_requests);

  @override
  Future<VisitRequest?> getById(String id) async =>
      _requests.firstWhereOrNull((v) => v.visitId == id);

  @override
  Future<VisitRequest> create(VisitRequest item) async {
    final toInsert = item.visitId.isEmpty
        ? item.copyWith(visitId: 'visit-${_uuid.v4()}')
        : item;
    _requests.add(toInsert);
    return toInsert;
  }

  @override
  Future<VisitRequest> update(VisitRequest item) async {
    final index = _requests.indexWhere((v) => v.visitId == item.visitId);
    if (index == -1) {
      throw StateError('VisitRequest ${item.visitId} not found');
    }
    _requests[index] = item;
    return item;
  }

  @override
  Future<void> delete(String id) async {
    _requests.removeWhere((v) => v.visitId == id);
  }

  @override
  Future<List<VisitRequest>> getByStudent(String studentId) async =>
      _requests.where((v) => v.studentId == studentId).toList();

  @override
  Future<List<VisitRequest>> getByLandlord(String landlordId) async =>
      _requests.where((v) => v.landlordId == landlordId).toList();

  @override
  Future<List<VisitRequest>> getByProperty(String propertyId) async =>
      _requests.where((v) => v.propertyId == propertyId).toList();

  @override
  Future<List<VisitRequest>> getByStatus(VisitRequestStatus status) async =>
      _requests.where((v) => v.status == status).toList();
}
