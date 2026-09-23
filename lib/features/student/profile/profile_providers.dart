import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/models.dart';
import '../../../core/providers/repository_providers.dart';
import '../../auth/providers/auth_notifier.dart';
import '../home/student_browse_providers.dart';

/// Everything the Profile screen (Figure E5) needs, composed in one fetch.
/// Not a Phase 1 ERD entity -- just a UI view-model.
class StudentProfileSummary {
  const StudentProfileSummary({
    required this.user,
    required this.profile,
    required this.campus,
    required this.savedCount,
    required this.savedPreview,
  });

  final User user;
  final StudentProfile profile;
  final Campus? campus;
  final int savedCount;

  /// Up to 3 saved properties, for a compact preview row.
  final List<Property> savedPreview;
}

final studentProfileSummaryProvider = FutureProvider<StudentProfileSummary?>((ref) async {
  final authState = ref.watch(authNotifierProvider);
  final user = authState.user;
  final studentId = authState.studentId;
  if (user == null || studentId == null) return null;

  final profile = await ref.watch(studentProfileRepositoryProvider).getById(studentId);
  if (profile == null) return null;

  final campus = await ref.watch(campusRepositoryProvider).getById(profile.campusId);
  final saves = await ref.watch(savedPropertyRepositoryProvider).getByStudent(studentId);

  final propertyRepository = ref.watch(propertyRepositoryProvider);
  final preview = <Property>[];
  for (final save in saves.take(3)) {
    final property = await propertyRepository.getById(save.propertyId);
    if (property != null) preview.add(property);
  }

  return StudentProfileSummary(
    user: user,
    profile: profile,
    campus: campus,
    savedCount: saves.length,
    savedPreview: preview,
  );
});

/// The current student's full saved-properties list, for the dedicated
/// "View All" screen.
final studentSavedPropertiesProvider = FutureProvider<List<Property>>((ref) async {
  final studentId = ref.watch(authNotifierProvider).studentId;
  if (studentId == null) return [];

  final saves = await ref.watch(savedPropertyRepositoryProvider).getByStudent(studentId);
  final propertyRepository = ref.watch(propertyRepositoryProvider);

  final properties = <Property>[];
  for (final save in saves) {
    final property = await propertyRepository.getById(save.propertyId);
    if (property != null) properties.add(property);
  }
  return properties;
});

/// Unsaves [propertyId] for the current student.
Future<void> unsaveProperty(WidgetRef ref, String propertyId) async {
  final studentId = ref.read(authNotifierProvider).studentId;
  if (studentId == null) return;

  final repository = ref.read(savedPropertyRepositoryProvider);
  final saves = await repository.getByStudent(studentId);
  for (final save in saves.where((s) => s.propertyId == propertyId)) {
    await repository.delete(save.saveId);
  }
  ref.invalidate(studentSavedPropertiesProvider);
  ref.invalidate(studentProfileSummaryProvider);
}

/// Every seeded campus plus the student's current pick, for the Set Campus
/// Anchor picker.
final campusAnchorScreenDataProvider =
    FutureProvider<({List<Campus> campuses, String currentCampusId})>((ref) async {
  final studentId = ref.watch(authNotifierProvider).studentId!;
  final profile = await ref.watch(studentProfileRepositoryProvider).getById(studentId);
  final campuses = await ref.watch(campusRepositoryProvider).getAll();
  return (campuses: campuses, currentCampusId: profile!.campusId);
});

/// Writes [campusId] to the current student's `StudentProfiles.campus_id`
/// and refreshes everything derived from it (the profile summary, and the
/// distance-based Home/Map data, since both depend on the student's campus).
Future<void> setCampusAnchor(WidgetRef ref, String campusId) async {
  final studentId = ref.read(authNotifierProvider).studentId;
  if (studentId == null) return;

  final repository = ref.read(studentProfileRepositoryProvider);
  final profile = await repository.getById(studentId);
  if (profile == null) return;

  await repository.update(profile.copyWith(campusId: campusId));

  ref.invalidate(studentProfileSummaryProvider);
  ref.invalidate(currentStudentCampusProvider);
  ref.invalidate(studentBrowsePropertiesProvider);
}
