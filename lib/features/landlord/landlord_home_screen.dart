import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../auth/providers/auth_notifier.dart';
import '../sos/sos_screen.dart';
import 'properties/landlord_properties_screen.dart';
import 'reports/landlord_reports_screen.dart';
import 'room_requests/landlord_room_requests_screen.dart';
import 'visit_requests/landlord_visit_requests_screen.dart';

Future<void> _logout(BuildContext context, WidgetRef ref) async {
  await ref.read(authNotifierProvider.notifier).logout();
  if (context.mounted) context.go('/login');
}

/// Bottom-nav shell for the landlord role: Properties, Visit Requests, Room
/// Requests, Reports, and SOS tabs. Rooms management nests under a property
/// (Property Details -> Manage Rooms), so it isn't a tab of its own.
class LandlordHomeScreen extends ConsumerStatefulWidget {
  const LandlordHomeScreen({super.key});

  @override
  ConsumerState<LandlordHomeScreen> createState() => _LandlordHomeScreenState();
}

class _LandlordHomeScreenState extends ConsumerState<LandlordHomeScreen> {
  int _tabIndex = 0;

  static const _tabs = [
    LandlordPropertiesScreen(),
    LandlordVisitRequestsScreen(),
    LandlordRoomRequestsScreen(),
    LandlordReportsScreen(),
    SosScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const Key('landlord_home_shell'),
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
            icon: Icon(Icons.home_work_outlined),
            selectedIcon: Icon(Icons.home_work),
            label: 'Properties',
          ),
          NavigationDestination(
            icon: Icon(Icons.event_available_outlined),
            selectedIcon: Icon(Icons.event_available),
            label: 'Visits',
          ),
          NavigationDestination(
            icon: Icon(Icons.meeting_room_outlined),
            selectedIcon: Icon(Icons.meeting_room),
            label: 'Room Requests',
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
