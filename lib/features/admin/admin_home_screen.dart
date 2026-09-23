import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../auth/providers/auth_notifier.dart';
import '../sos/sos_screen.dart';
import 'reported_listings/admin_reported_listings_screen.dart';
import 'reports/admin_reports_screen.dart';
import 'users/admin_users_screen.dart';
import 'verification/admin_verification_screen.dart';

Future<void> _logout(BuildContext context, WidgetRef ref) async {
  await ref.read(authNotifierProvider.notifier).logout();
  if (context.mounted) context.go('/login');
}

/// Bottom-nav shell for the admin role: Users, Verify Listings, Reported
/// Listings, Reports, and SOS tabs -- matching the Administrator column of
/// the Use Case diagram (plus SOS, reachable by every role).
class AdminHomeScreen extends ConsumerStatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  ConsumerState<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends ConsumerState<AdminHomeScreen> {
  int _tabIndex = 0;

  static const _tabs = [
    AdminUsersScreen(),
    AdminVerificationScreen(),
    AdminReportedListingsScreen(),
    AdminReportsScreen(),
    SosScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const Key('admin_home_shell'),
      appBar: AppBar(
        title: const Text('Administrator'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Log out',
            onPressed: () => _logout(context, ref),
          ),
        ],
      ),
      body: IndexedStack(index: _tabIndex, children: _tabs),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tabIndex,
        onDestinationSelected: (index) => setState(() => _tabIndex = index),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.people_outline),
            selectedIcon: Icon(Icons.people),
            label: 'Users',
          ),
          NavigationDestination(
            icon: Icon(Icons.verified_outlined),
            selectedIcon: Icon(Icons.verified),
            label: 'Verify',
          ),
          NavigationDestination(
            icon: Icon(Icons.flag_outlined),
            selectedIcon: Icon(Icons.flag),
            label: 'Reported',
          ),
          NavigationDestination(
            icon: Icon(Icons.summarize_outlined),
            selectedIcon: Icon(Icons.summarize),
            label: 'Reports',
          ),
          NavigationDestination(
            icon: Icon(Icons.sos_outlined),
            selectedIcon: Icon(Icons.sos),
            label: 'SOS',
          ),
        ],
      ),
    );
  }
}
