import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/models.dart';
import '../../../core/providers/repository_providers.dart';

/// A [User] composed with its linked [LandlordProfile] or [StudentProfile]
/// (never both -- an admin account has neither), and the [Campus] name for
/// a student profile. Not a Phase 1 ERD entity, just a UI view-model.
class AdminUserItem {
  const AdminUserItem({
    required this.user,
    this.landlordProfile,
    this.studentProfile,
    this.campusName,
  });

  final User user;
  final LandlordProfile? landlordProfile;
  final StudentProfile? studentProfile;
  final String? campusName;
}

/// Every `Users` row, system-wide, each composed with its linked profile.
final adminUsersProvider = FutureProvider<List<AdminUserItem>>((ref) async {
  final userRepository = ref.watch(userRepositoryProvider);
  final landlordProfileRepository = ref.watch(landlordProfileRepositoryProvider);
  final studentProfileRepository = ref.watch(studentProfileRepositoryProvider);
  final campusRepository = ref.watch(campusRepositoryProvider);

  final users = await userRepository.getAll();
  final items = <AdminUserItem>[];
  for (final user in users) {
    LandlordProfile? landlordProfile;
    StudentProfile? studentProfile;
    String? campusName;
    if (user.role == UserRole.landlord) {
      landlordProfile = await landlordProfileRepository.getByUserId(user.userId);
    } else if (user.role == UserRole.student) {
      studentProfile = await studentProfileRepository.getByUserId(user.userId);
      if (studentProfile != null) {
        final campus = await campusRepository.getById(studentProfile.campusId);
        campusName = campus?.name;
      }
    }
    items.add(AdminUserItem(
      user: user,
      landlordProfile: landlordProfile,
      studentProfile: studentProfile,
      campusName: campusName,
    ));
  }
  items.sort((a, b) => a.user.name.compareTo(b.user.name));
  return items;
});

/// Toggles `Users.status` between `active` and `suspended`.
Future<void> toggleUserStatus(WidgetRef ref, String userId) async {
  final userRepository = ref.read(userRepositoryProvider);
  final user = await userRepository.getById(userId);
  if (user == null) return;

  final nextStatus =
      user.status == UserStatus.active ? UserStatus.suspended : UserStatus.active;
  await userRepository.update(user.copyWith(status: nextStatus));
  ref.invalidate(adminUsersProvider);
}
