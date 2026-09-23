import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/models.dart';
import '../../../core/providers/repository_providers.dart';
import '../../auth/providers/auth_notifier.dart';

/// A [VisitRequest] composed with its property and student names for
/// display -- not a Phase 1 ERD entity, just a UI view-model.
class LandlordVisitRequestItem {
  const LandlordVisitRequestItem({
    required this.request,
    required this.propertyName,
    required this.studentName,
  });

  final VisitRequest request;
  final String propertyName;
  final String studentName;
}

/// Every visit request made against the current landlord's properties.
final landlordVisitRequestsProvider =
    FutureProvider<List<LandlordVisitRequestItem>>((ref) async {
  final landlordId = ref.watch(authNotifierProvider).landlordId;
  if (landlordId == null) return [];

  final visitRequestRepository = ref.watch(visitRequestRepositoryProvider);
  final propertyRepository = ref.watch(propertyRepositoryProvider);
  final studentProfileRepository = ref.watch(studentProfileRepositoryProvider);
  final userRepository = ref.watch(userRepositoryProvider);

  final requests = await visitRequestRepository.getByLandlord(landlordId);
  final items = <LandlordVisitRequestItem>[];
  for (final request in requests) {
    final property = await propertyRepository.getById(request.propertyId);
    final studentProfile = await studentProfileRepository.getById(request.studentId);
    final user =
        studentProfile == null ? null : await userRepository.getById(studentProfile.userId);
    items.add(LandlordVisitRequestItem(
      request: request,
      propertyName: property?.name ?? 'Unknown property',
      studentName: user?.name ?? 'Unknown student',
    ));
  }
  items.sort((a, b) => b.request.createdAt.compareTo(a.request.createdAt));
  return items;
});

Future<void> acceptVisitRequest(WidgetRef ref, String visitId) async {
  final repository = ref.read(visitRequestRepositoryProvider);
  final current = await repository.getById(visitId);
  if (current == null) return;
  await repository.update(current.copyWith(
    status: VisitRequestStatus.accepted,
    respondedDatetime: DateTime.now(),
  ));
  ref.invalidate(landlordVisitRequestsProvider);
}

Future<void> declineVisitRequest(WidgetRef ref, String visitId) async {
  final repository = ref.read(visitRequestRepositoryProvider);
  final current = await repository.getById(visitId);
  if (current == null) return;
  await repository.update(current.copyWith(
    status: VisitRequestStatus.declined,
    respondedDatetime: DateTime.now(),
  ));
  ref.invalidate(landlordVisitRequestsProvider);
}

/// The ERD has no separate "proposed datetime" field, so rescheduling
/// overwrites `requested_datetime` with the landlord's new proposed time.
Future<void> rescheduleVisitRequest(
  WidgetRef ref,
  String visitId,
  DateTime newRequestedDatetime,
) async {
  final repository = ref.read(visitRequestRepositoryProvider);
  final current = await repository.getById(visitId);
  if (current == null) return;
  await repository.update(current.copyWith(
    status: VisitRequestStatus.rescheduled,
    respondedDatetime: DateTime.now(),
    requestedDatetime: newRequestedDatetime,
  ));
  ref.invalidate(landlordVisitRequestsProvider);
}
