import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/models.dart';
import '../../../core/providers/repository_providers.dart';
import '../../auth/providers/auth_notifier.dart';

/// A [VisitRequest] composed with its property's name for display -- not a
/// Phase 1 ERD entity, just a UI view-model.
class VisitRequestListItem {
  const VisitRequestListItem({
    required this.request,
    required this.propertyName,
  });

  final VisitRequest request;
  final String propertyName;
}

/// The current student's own visit requests, newest first.
final studentVisitRequestsProvider =
    FutureProvider<List<VisitRequestListItem>>((ref) async {
  final studentId = ref.watch(authNotifierProvider).studentId;
  if (studentId == null) return [];

  final visitRequestRepository = ref.watch(visitRequestRepositoryProvider);
  final propertyRepository = ref.watch(propertyRepositoryProvider);

  final requests = await visitRequestRepository.getByStudent(studentId);
  final items = <VisitRequestListItem>[];
  for (final request in requests) {
    final property = await propertyRepository.getById(request.propertyId);
    items.add(VisitRequestListItem(
      request: request,
      propertyName: property?.name ?? 'Unknown property',
    ));
  }
  items.sort((a, b) => b.request.createdAt.compareTo(a.request.createdAt));
  return items;
});

/// Creates a `VisitRequests` row for the current student and refreshes
/// [studentVisitRequestsProvider].
Future<void> createVisitRequest(
  WidgetRef ref, {
  required Property property,
  required DateTime requestedDatetime,
}) async {
  final studentId = ref.read(authNotifierProvider).studentId;
  if (studentId == null) {
    throw StateError('Only a signed-in student can request a visit.');
  }

  final repository = ref.read(visitRequestRepositoryProvider);
  await repository.create(VisitRequest(
    visitId: '',
    studentId: studentId,
    propertyId: property.propertyId,
    landlordId: property.landlordId,
    status: VisitRequestStatus.pending,
    requestedDatetime: requestedDatetime,
    createdAt: DateTime.now(),
  ));

  ref.invalidate(studentVisitRequestsProvider);
}

/// Cancels one of the current student's visit requests.
Future<void> cancelVisitRequest(WidgetRef ref, String visitId) async {
  final repository = ref.read(visitRequestRepositoryProvider);
  final current = await repository.getById(visitId);
  if (current == null) return;

  await repository.update(current.copyWith(status: VisitRequestStatus.cancelled));
  ref.invalidate(studentVisitRequestsProvider);
}
