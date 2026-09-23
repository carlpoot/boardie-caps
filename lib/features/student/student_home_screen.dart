import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../auth/providers/auth_notifier.dart';
import 'home/home_tab_screen.dart';
import 'map/map_view.dart';

Future<void> _logout(BuildContext context, WidgetRef ref) async {
  await ref.read(authNotifierProvider.notifier).logout();
  if (context.mounted) context.go('/login');
}

/// Bottom-nav shell for the student role: Home (browse) and Map tabs.
///
/// Visit requests, room requests/holds, saved-properties list, compare, and
/// profile management are Phase 3b -- this phase is browsing and property
/// details only.
class StudentHomeScreen extends ConsumerStatefulWidget {
  const StudentHomeScreen({super.key});

  @override
  ConsumerState<StudentHomeScreen> createState() => _StudentHomeScreenState();
}

class _StudentHomeScreenState extends ConsumerState<StudentHomeScreen> {
  int _tabIndex = 0;

  static const _tabs = [HomeTabScreen(), MapView()];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const Key('student_home_shell'),
      appBar: AppBar(
        title: const Text('Boardie'),
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
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.map_outlined),
            selectedIcon: Icon(Icons.map),
            label: 'Map',
          ),
        ],
      ),
    );
  }
}
