import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../auth/providers/auth_notifier.dart';

/// Placeholder landing screen for a guest session. The real Browse
/// Listings / Search / Map / SOS screens (the Guest-tier capabilities)
/// arrive in a later phase.
class GuestHomeScreen extends ConsumerWidget {
  const GuestHomeScreen({super.key});

  Future<void> _goToLogin(BuildContext context, WidgetRef ref) async {
    // Dropping the guest session back to unauthenticated before navigating
    // keeps the router's redirect guard and this explicit navigation in
    // agreement -- see app_router.dart.
    await ref.read(authNotifierProvider.notifier).logout();
    if (context.mounted) context.go('/login');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Boardie')),
      body: Center(
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
      ),
    );
  }
}
