import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/models.dart';
import '../../../core/providers/repository_providers.dart';
import '../../../core/providers/service_providers.dart';
import '../../auth/providers/auth_notifier.dart';

/// A [RoomRequest] composed with its property/room/student names and its
/// live (expiry-aware) status for display -- not a Phase 1 ERD entity,
/// just a UI view-model. This is a DIFFERENT queue from
/// `landlordVisitRequestsProvider` -- RoomRequests and VisitRequests are
/// never merged.
class LandlordRoomRequestItem {
  const LandlordRoomRequestItem({
    required this.request,
    required this.propertyName,
    required this.roomType,
    required this.studentName,
    required this.effectiveStatus,
  });

  final RoomRequest request;
  final String propertyName;
  final String roomType;
  final String studentName;
  final RoomRequestStatus effectiveStatus;
}

/// Every room request made against the current landlord's rooms.
final landlordRoomRequestsProvider =
    FutureProvider<List<LandlordRoomRequestItem>>((ref) async {
  final landlordId = ref.watch(authNotifierProvider).landlordId;
  if (landlordId == null) return [];

  final roomRequestRepository = ref.watch(roomRequestRepositoryProvider);
  final propertyRepository = ref.watch(propertyRepositoryProvider);
  final roomRepository = ref.watch(roomRepositoryProvider);
  final studentProfileRepository = ref.watch(studentProfileRepositoryProvider);
  final userRepository = ref.watch(userRepositoryProvider);
  final service = ref.watch(roomRequestServiceProvider);

  final requests = await roomRequestRepository.getByLandlord(landlordId);
  final items = <LandlordRoomRequestItem>[];
  for (final request in requests) {
    final property = await propertyRepository.getById(request.propertyId);
    final room = await roomRepository.getById(request.roomId);
    final studentProfile = await studentProfileRepository.getById(request.studentId);
    final user =
        studentProfile == null ? null : await userRepository.getById(studentProfile.userId);
    items.add(LandlordRoomRequestItem(
      request: request,
      propertyName: property?.name ?? 'Unknown property',
      roomType: room?.roomType ?? 'Unknown room',
      studentName: user?.name ?? 'Unknown student',
      effectiveStatus: service.effectiveStatus(request),
    ));
  }
  items.sort((a, b) => b.request.createdAt.compareTo(a.request.createdAt));
  return items;
});

/// Throws [RoomRequestException] (from `room_request_service.dart`) if the
/// request is no longer pending.
Future<void> approveRoomRequestAsLandlord(WidgetRef ref, String requestId) async {
  await ref.read(roomRequestServiceProvider).approveRequest(requestId);
  ref.invalidate(landlordRoomRequestsProvider);
}

Future<void> declineRoomRequestAsLandlord(WidgetRef ref, String requestId) async {
  await ref.read(roomRequestServiceProvider).declineRequest(requestId);
  ref.invalidate(landlordRoomRequestsProvider);
}
