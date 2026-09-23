import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/models.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/status_display.dart';
import 'admin_users_providers.dart';

const _roleLabels = {
  UserRole.guest: 'Guest',
  UserRole.student: 'Student',
  UserRole.landlord: 'Landlord',
  UserRole.admin: 'Admin',
};

/// Manage Users: every `Users` row, filterable by role, with each user's
/// linked `LandlordProfiles`/`StudentProfiles` record shown inline. The
/// only action is toggling `Users.status` between `active` and `suspended`.
class AdminUsersScreen extends ConsumerStatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  ConsumerState<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends ConsumerState<AdminUsersScreen> {
  UserRole? _roleFilter;

  @override
  Widget build(BuildContext context) {
    final itemsAsync = ref.watch(adminUsersProvider);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: SizedBox(
            height: 36,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _RoleFilterChip(
                  label: 'All',
                  selected: _roleFilter == null,
                  onSelected: () => setState(() => _roleFilter = null),
                ),
                const SizedBox(width: 8),
                for (final role in UserRole.values) ...[
                  _RoleFilterChip(
                    label: _roleLabels[role]!,
                    selected: _roleFilter == role,
                    onSelected: () => setState(() => _roleFilter = role),
                  ),
                  const SizedBox(width: 8),
                ],
              ],
            ),
          ),
        ),
        Expanded(
          child: itemsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => Center(child: Text('Could not load users: $error')),
            data: (items) {
              final filtered = _roleFilter == null
                  ? items
                  : items.where((i) => i.user.role == _roleFilter).toList();
              if (filtered.isEmpty) {
                return const Center(child: Text('No users match this filter.'));
              }
              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                itemCount: filtered.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (context, index) => _UserCard(item: filtered[index]),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _RoleFilterChip extends StatelessWidget {
  const _RoleFilterChip({
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  final String label;
  final bool selected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      key: Key('role_filter_$label'),
      label: Text(label),
      selected: selected,
      onSelected: (_) => onSelected(),
    );
  }
}

class _UserCard extends ConsumerWidget {
  const _UserCard({required this.item});

  final AdminUserItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = item.user;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(user.name, style: Theme.of(context).textTheme.titleSmall),
                ),
                _StatusBadge(status: user.status),
              ],
            ),
            const SizedBox(height: 4),
            Text(user.email, style: Theme.of(context).textTheme.bodySmall),
            Text(
              '${_roleLabels[user.role]} · ${user.contactNo}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            if (item.landlordProfile != null) ...[
              const SizedBox(height: 8),
              _ProfileChip(
                icon: Icons.home_work_outlined,
                label: 'Landlord profile: ${item.landlordProfile!.landlordId}',
                status: item.landlordProfile!.verificationStatus,
              ),
            ],
            if (item.studentProfile != null) ...[
              const SizedBox(height: 8),
              Text(
                'Student profile: ${item.studentProfile!.studentId} · '
                '${item.campusName ?? item.studentProfile!.campusId}',
                style: AppTypography.bodySmall.copyWith(color: AppColors.onSurfaceMuted),
              ),
            ],
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: OutlinedButton(
                key: Key('toggle_user_status_${user.userId}'),
                onPressed: () => toggleUserStatus(ref, user.userId),
                child: Text(
                  user.status == UserStatus.active ? 'Suspend' : 'Reactivate',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final UserStatus status;

  @override
  Widget build(BuildContext context) {
    final color = status.color;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(status.label, style: AppTypography.labelLarge.copyWith(color: color)),
    );
  }
}

class _ProfileChip extends StatelessWidget {
  const _ProfileChip({required this.icon, required this.label, required this.status});

  final IconData icon;
  final String label;
  final VerificationStatus status;

  @override
  Widget build(BuildContext context) {
    final color = status.color;
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.onSurfaceMuted),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            label,
            style: AppTypography.bodySmall.copyWith(color: AppColors.onSurfaceMuted),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(status.label, style: AppTypography.caption.copyWith(color: color)),
        ),
      ],
    );
  }
}
