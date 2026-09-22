import '../models/models.dart';
import 'crud_repository.dart';

abstract class RoomRequestRepository
    extends CrudRepository<RoomRequest, String> {
  Future<List<RoomRequest>> getByStudent(String studentId);

  Future<List<RoomRequest>> getByLandlord(String landlordId);

  Future<List<RoomRequest>> getByRoom(String roomId);

  Future<List<RoomRequest>> getByStatus(RoomRequestStatus status);

  /// Requests for [roomId] that currently occupy a hold slot, i.e. status is
  /// `pending`, `approved`, or `confirmed`, and (when set) `held_until` has
  /// not yet passed. Used to derive the room's `reserved` map-legend state.
  Future<List<RoomRequest>> getActiveHoldsForRoom(String roomId);
}
