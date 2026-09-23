import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../auth/providers/auth_notifier.dart';
import '../sos/sos_screen.dart';

/// Bottom-nav shell for a guest session: a Home tab (placeholder for the
/// real Browse Listings / Search / Map screens, still a later phase) and
/// an SOS tab -- Emergency SOS needs no login, so it's reachable here too,
/// not just from the authenticated roles' shells.
class GuestHomeScreen extends ConsumerStatefulWidget {
  const GuestHomeScreen({super.key});

  @override
  ConsumerState<GuestHomeScreen> createState() => _GuestHomeScreenState();
}

class _GuestHomeScreenState extends ConsumerState<GuestHomeScreen> {
  int _tabIndex = 0;

  static const _tabs = [
    _GuestHomeTab(),
    SosScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const Key('guest_home_shell'),
      appBar: AppBar(title: const Text('Boardie')),
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
            icon: Icon(Icons.sos_outlined),
            selectedIcon: Icon(Icons.sos),
            label: 'SOS',
          ),
        ],
      ),
    );
  }
}

class _GuestHomeTab extends ConsumerWidget {
  const _GuestHomeTab();

  Future<void> _goToLogin(BuildContext context, WidgetRef ref) async {
    // Dropping the guest session back to unauthenticated before navigating
    // keeps the router's redirect guard and this explicit navigation in
    // agreement -- see app_router.dart.
    await ref.read(authNotifierProvider.notifier).logout();
    if (context.mounted) context.go('/login');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Browsing as Guest'),
            const SizedBox(height: 16),
            FilledButton(
              key: const Key('guest_login_or_signup_button'),
              onPressed: () => _goToLogin(context, ref),
              child: const Text('Log In or Create an Account'),
            ),
          ],
        ),
      ),
    );
  }
}
