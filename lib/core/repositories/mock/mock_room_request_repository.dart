import 'package:uuid/uuid.dart';

import '../../models/models.dart';
import '../room_request_repository.dart';
import 'mock_helpers.dart';
import 'mock_seed_data.dart';

class MockRoomRequestRepository implements RoomRequestRepository {
  final List<RoomRequest> _requests = List.of(MockSeedData.roomRequests);
  final Uuid _uuid = const Uuid();

  static const _activeStatuses = {
    RoomRequestStatus.pending,
    RoomRequestStatus.approved,
    RoomRequestStatus.confirmed,
  };

  @override
  Future<List<RoomRequest>> getAll() async => List.unmodifiable(_requests);

  @override
  Future<RoomRequest?> getById(String id) async =>
      _requests.firstWhereOrNull((r) => r.requestId == id);

  @override
  Future<RoomRequest> create(RoomRequest item) async {
    final toInsert = item.requestId.isEmpty
        ? item.copyWith(requestId: 'request-${_uuid.v4()}')
        : item;
    _requests.add(toInsert);
    return toInsert;
  }

  @override
  Future<RoomRequest> update(RoomRequest item) async {
    final index = _requests.indexWhere((r) => r.requestId == item.requestId);
    if (index == -1) {
      throw StateError('RoomRequest ${item.requestId} not found');
    }
    _requests[index] = item;
    return item;
  }

  @override
  Future<void> delete(String id) async {
    _requests.removeWhere((r) => r.requestId == id);
  }

  @override
  Future<List<RoomRequest>> getByStudent(String studentId) async =>
      _requests.where((r) => r.studentId == studentId).toList();

  @override
  Future<List<RoomRequest>> getByLandlord(String landlordId) async =>
      _requests.where((r) => r.landlordId == landlordId).toList();

  @override
  Future<List<RoomRequest>> getByRoom(String roomId) async =>
      _requests.where((r) => r.roomId == roomId).toList();

  @override
  Future<List<RoomRequest>> getByStatus(RoomRequestStatus status) async =>
      _requests.where((r) => r.status == status).toList();

  @override
  Future<List<RoomRequest>> getActiveHoldsForRoom(String roomId) async {
    final now = DateTime.now();
    return _requests
        .where((r) =>
            r.roomId == roomId &&
            _activeStatuses.contains(r.status) &&
            (r.heldUntil == null || r.heldUntil!.isAfter(now)))
        .toList();
  }
}
