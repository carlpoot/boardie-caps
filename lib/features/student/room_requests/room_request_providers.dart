import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/models.dart';
import '../../../core/providers/repository_providers.dart';
import '../../../core/providers/service_providers.dart';
import '../../auth/providers/auth_notifier.dart';

/// A [RoomRequest] composed with its property/room names and its live
/// (expiry-aware) status for display -- not a Phase 1 ERD entity, just a
/// UI view-model.
class RoomRequestListItem {
  const RoomRequestListItem({
    required this.request,
    required this.propertyName,
    required this.roomType,
    required this.effectiveStatus,
  });

  final RoomRequest request;
  final String propertyName;
  final String roomType;
  final RoomRequestStatus effectiveStatus;
}

/// The current student's own room requests/holds, newest first, with live
/// expiry already folded into [RoomRequestListItem.effectiveStatus] via
/// [RoomRequestService.effectiveStatus].
final studentRoomRequestsProvider =
    FutureProvider<List<RoomRequestListItem>>((ref) async {
  final studentId = ref.watch(authNotifierProvider).studentId;
  if (studentId == null) return [];

  final roomRequestRepository = ref.watch(roomRequestRepositoryProvider);
  final propertyRepository = ref.watch(propertyRepositoryProvider);
  final roomRepository = ref.watch(roomRepositoryProvider);
  final service = ref.watch(roomRequestServiceProvider);

  final requests = await roomRequestRepository.getByStudent(studentId);
  final items = <RoomRequestListItem>[];
  for (final request in requests) {
    final property = await propertyRepository.getById(request.propertyId);
    final room = await roomRepository.getById(request.roomId);
    items.add(RoomRequestListItem(
      request: request,
      propertyName: property?.name ?? 'Unknown property',
      roomType: room?.roomType ?? 'Unknown room',
      effectiveStatus: service.effectiveStatus(request),
    ));
  }
  items.sort((a, b) => b.request.createdAt.compareTo(a.request.createdAt));
  return items;
});

/// Requests a hold on [room] for the current student.
/// Throws [RoomRequestException] if the 4-active-holds cap is hit.
Future<void> requestRoomHold(
  WidgetRef ref, {
  required Room room,
  required String landlordId,
}) async {
  final studentId = ref.read(authNotifierProvider).studentId;
  if (studentId == null) {
    throw StateError('Only a signed-in student can request a room.');
  }

  final service = ref.read(roomRequestServiceProvider);
  await service.requestRoom(studentId: studentId, room: room, landlordId: landlordId);
  ref.invalidate(studentRoomRequestsProvider);
}

/// Confirms a room request. Throws [RoomRequestException] if it isn't
/// currently approved.
Future<void> confirmRoomRequest(WidgetRef ref, String requestId) async {
  final service = ref.read(roomRequestServiceProvider);
  await service.confirmRequest(requestId);
  ref.invalidate(studentRoomRequestsProvider);
}

/// Cancels a room request. Throws [RoomRequestException] if it's no longer
/// active.
Future<void> cancelRoomRequest(WidgetRef ref, String requestId) async {
  final service = ref.read(roomRequestServiceProvider);
  await service.cancelRequest(requestId);
  ref.invalidate(studentRoomRequestsProvider);
}
