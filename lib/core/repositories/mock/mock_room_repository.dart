import 'package:uuid/uuid.dart';

import '../../models/models.dart';
import '../room_repository.dart';
import 'mock_helpers.dart';
import 'mock_seed_data.dart';

class MockRoomRepository implements RoomRepository {
  final List<Room> _rooms = List.of(MockSeedData.rooms);
  final Uuid _uuid = const Uuid();

  @override
  Future<List<Room>> getAll() async => List.unmodifiable(_rooms);

  @override
  Future<Room?> getById(String id) async =>
      _rooms.firstWhereOrNull((r) => r.roomId == id);

  @override
  Future<Room> create(Room item) async {
    final toInsert =
        item.roomId.isEmpty ? item.copyWith(roomId: 'room-${_uuid.v4()}') : item;
    _rooms.add(toInsert);
    return toInsert;
  }

  @override
  Future<Room> update(Room item) async {
    final index = _rooms.indexWhere((r) => r.roomId == item.roomId);
    if (index == -1) {
      throw StateError('Room ${item.roomId} not found');
    }
    _rooms[index] = item;
    return item;
  }

  @override
  Future<void> delete(String id) async {
    _rooms.removeWhere((r) => r.roomId == id);
  }

  @override
  Future<List<Room>> getByProperty(String propertyId) async =>
      _rooms.where((r) => r.propertyId == propertyId).toList();

  @override
  Future<List<Room>> getByRoomType(String roomType) async =>
      _rooms.where((r) => r.roomType == roomType).toList();
}
