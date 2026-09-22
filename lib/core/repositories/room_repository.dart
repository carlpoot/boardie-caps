import '../models/models.dart';
import 'crud_repository.dart';

abstract class RoomRepository extends CrudRepository<Room, String> {
  Future<List<Room>> getByProperty(String propertyId);

  Future<List<Room>> getByRoomType(String roomType);
}
