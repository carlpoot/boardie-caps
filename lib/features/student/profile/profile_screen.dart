import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../auth/providers/auth_notifier.dart';
import 'profile_providers.dart';

Future<void> _logout(BuildContext context, WidgetRef ref) async {
  await ref.read(authNotifierProvider.notifier).logout();
  if (context.mounted) context.go('/login');
}

void _showComingSoon(BuildContext context, String feature) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text('$feature is coming in a later phase.')));
}

/// Profile (Figure E5): personal info, saved properties, Set Campus Anchor,
/// account settings, and help center.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(studentProfileSummaryProvider);

    return summaryAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text('Could not load your profile: $error')),
      data: (summary) {
        if (summary == null) {
          return const Center(child: Text('Profile not found.'));
        }
        final user = summary.user;

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 32,
                  child: Text(
                    user.name.isEmpty ? '?' : user.name[0].toUpperCase(),
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(user.name, style: Theme.of(context).textTheme.titleLarge),
                      Text(user.email, style: Theme.of(context).textTheme.bodyMedium),
                      Text(user.contactNo, style: Theme.of(context).textTheme.bodyMedium),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Card(
              child: ListTile(
                key: const Key('campus_anchor_tile'),
                leading: const Icon(Icons.anchor_outlined),
                title: const Text('Set Campus Anchor'),
                subtitle: Text(summary.campus?.name ?? 'Not set'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push('/student/campus-anchor'),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ListTile(
                    leading: const Icon(Icons.favorite_outline),
                    title: Text('${summary.savedCount} saved '
                        'propert${summary.savedCount == 1 ? 'y' : 'ies'}'),
                    trailing: TextButton(
                      key: const Key('view_all_saved_button'),
                      onPressed: () => context.push('/student/saved'),
                      child: const Text('View All'),
                    ),
                  ),
                  if (summary.savedPreview.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(left: 16, right: 16, bottom: 12),
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: summary.savedPreview
                            .map((p) => Chip(label: Text(p.name)))
                            .toList(),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.settings_outlined),
                    title: const Text('Account Settings'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _showComingSoon(context, 'Account settings'),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.help_outline),
                    title: const Text('Help Center'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _showComingSoon(context, 'The help center'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: ListTile(
                leading: const Icon(Icons.logout),
                title: const Text('Log Out'),
                onTap: () => _logout(context, ref),
              ),
            ),
          ],
        );
      },
    );
  }
}
