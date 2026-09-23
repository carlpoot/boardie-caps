import '../models/models.dart';
import '../repositories/room_request_repository.dart';

/// Thrown when [RoomRequestService] rejects a request/hold/confirm/cancel
/// action against a business rule (the 4-hold cap, an invalid status
/// transition, etc).
class RoomRequestException implements Exception {
  const RoomRequestException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// All student-facing `RoomRequests` business rules, kept out of widgets so
/// they're independently testable and reusable (Phase 4's landlord side and
/// any future screen need the exact same cap/expiry/confirm rules).
///
/// **Design note on live expiry (flagged back per the task's own ask):**
/// A hold's `held_until` can pass without anything ever writing
/// `status = 'expired'` back to the row -- there's no scheduled job in the
/// mock phase to do that. Rather than mutate rows as a side effect of a
/// read (which every other read-time computation in this codebase avoids --
/// see `RoomAvailabilityService`, which works the same way), this service
/// treats expiry as **purely a read-time computation** via [effectiveStatus]
/// and [isLiveExpired]. Everything that needs to know a request's "real"
/// current status -- the 4-hold cap, the Reservations screen's filters --
/// goes through those helpers instead of trusting `RoomRequest.status`
/// directly. When the Firebase phase adds a scheduled Cloud Function to
/// actually flip stale rows to `expired`, that function should own writing
/// the field; this client-side logic wouldn't need to change since it
/// already treats a live-expired row as expired regardless of what's
/// stored.
class RoomRequestService {
  const RoomRequestService({required this.roomRequestRepository});

  final RoomRequestRepository roomRequestRepository;

  /// "select up to 4, confirm one, cancel the rest".
  static const maxActiveHolds = 4;

  /// How long a new hold lasts before it's treated as expired, absent a
  /// landlord response. Configurable per the task's own note.
  static const defaultHoldDuration = Duration(hours: 24);

  static const _activeStatuses = {
    RoomRequestStatus.pending,
    RoomRequestStatus.approved,
  };

  /// True if [request] is stored as pending/approved but its hold window
  /// has already passed -- i.e. it *should* read as expired even though
  /// nothing has written that back yet.
  bool isLiveExpired(RoomRequest request, {DateTime? now}) {
    final effectiveNow = now ?? DateTime.now();
    return _activeStatuses.contains(request.status) &&
        request.heldUntil != null &&
        request.heldUntil!.isBefore(effectiveNow);
  }

  /// [request]'s status as it should be treated right now, folding in live
  /// expiry. Use this instead of `request.status` anywhere the distinction
  /// matters (the cap check, the Reservations "Expired" filter).
  RoomRequestStatus effectiveStatus(RoomRequest request, {DateTime? now}) {
    if (isLiveExpired(request, now: now)) return RoomRequestStatus.expired;
    return request.status;
  }

  bool _isActive(RoomRequestStatus status) =>
      status == RoomRequestStatus.pending || status == RoomRequestStatus.approved;

  /// How many of [studentId]'s holds currently count against
  /// [maxActiveHolds], after folding in live expiry.
  Future<int> countActiveHolds(String studentId, {DateTime? now}) async {
    final requests = await roomRequestRepository.getByStudent(studentId);
    return requests.where((r) => _isActive(effectiveStatus(r, now: now))).length;
  }

  /// Creates a new hold (`status = pending`), enforcing the 4-active-holds
  /// cap. A hold whose `held_until` has already passed does NOT count
  /// against the cap even if its stored status is still pending/approved.
  Future<RoomRequest> requestRoom({
    required String studentId,
    required Room room,
    required String landlordId,
    Duration holdDuration = defaultHoldDuration,
    DateTime? now,
  }) async {
    final effectiveNow = now ?? DateTime.now();
    final activeCount = await countActiveHolds(studentId, now: effectiveNow);
    if (activeCount >= maxActiveHolds) {
      throw RoomRequestException(
        'You already have $maxActiveHolds active room holds. Cancel or '
        'confirm one before requesting another.',
      );
    }

    return roomRequestRepository.create(RoomRequest(
      requestId: '',
      studentId: studentId,
      roomId: room.roomId,
      propertyId: room.propertyId,
      landlordId: landlordId,
      status: RoomRequestStatus.pending,
      heldUntil: effectiveNow.add(holdDuration),
      createdAt: effectiveNow,
    ));
  }

  /// Confirms [requestId] (only valid once the landlord has approved it),
  /// and auto-cancels every one of that student's OTHER still-active holds
  /// -- the "select up to 4, confirm one, cancel the rest" rule.
  Future<void> confirmRequest(String requestId, {DateTime? now}) async {
    final effectiveNow = now ?? DateTime.now();
    final request = await roomRequestRepository.getById(requestId);
    if (request == null) {
      throw const RoomRequestException('Room request not found.');
    }
    if (effectiveStatus(request, now: effectiveNow) != RoomRequestStatus.approved) {
      throw const RoomRequestException(
        'This request can only be confirmed after the landlord approves it.',
      );
    }

    await roomRequestRepository.update(request.copyWith(
      status: RoomRequestStatus.confirmed,
      confirmedAt: effectiveNow,
    ));

    final others = await roomRequestRepository.getByStudent(request.studentId);
    for (final other in others) {
      if (other.requestId == request.requestId) continue;
      if (_isActive(effectiveStatus(other, now: effectiveNow))) {
        await roomRequestRepository.update(other.copyWith(status: RoomRequestStatus.cancelled));
      }
    }
  }

  /// Cancels [requestId], as long as it's currently pending or approved.
  Future<void> cancelRequest(String requestId, {DateTime? now}) async {
    final request = await roomRequestRepository.getById(requestId);
    if (request == null) {
      throw const RoomRequestException('Room request not found.');
    }
    if (!_isActive(effectiveStatus(request, now: now))) {
      throw const RoomRequestException('This request can no longer be cancelled.');
    }

    await roomRequestRepository.update(request.copyWith(status: RoomRequestStatus.cancelled));
  }
}
