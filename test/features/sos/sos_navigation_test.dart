import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:boardie/main.dart';

/// Confirms Emergency SOS (Figure E6) is reachable from the bottom nav for
/// every role -- Guest, Student, Landlord, and Administrator alike -- per
/// the task's explicit requirement that it needs no login and isn't gated
/// to any one role.
const _seedPassword = 'password123';

Future<void> _skipOnboarding(WidgetTester tester) async {
  await tester.pumpWidget(const ProviderScope(child: MyApp()));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const Key('onboarding_skip_button')));
  await tester.pumpAndSettle();
}

Future<void> _login(WidgetTester tester, String email) async {
  await tester.enterText(find.byKey(const Key('login_email_field')), email);
  await tester.enterText(find.byKey(const Key('login_password_field')), _seedPassword);
  await tester.tap(find.byKey(const Key('login_submit_button')));
  await tester.pumpAndSettle();
}

Future<void> _goToSos(WidgetTester tester) async {
  await tester.tap(find.text('SOS'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('a guest can reach Emergency SOS without logging in', (tester) async {
    await _skipOnboarding(tester);
    await tester.tap(find.byKey(const Key('continue_as_guest_button')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('guest_home_shell')), findsOneWidget);

    await _goToSos(tester);

    expect(find.text('Emergency SOS'), findsOneWidget);
    expect(find.text('National Emergency Hotline'), findsOneWidget);
  });

  testWidgets('a student can reach Emergency SOS from their bottom nav', (tester) async {
    await _skipOnboarding(tester);
    await _login(tester, 'anna.student@boardie.io');
    expect(find.byKey(const Key('student_home_shell')), findsOneWidget);

    await _goToSos(tester);

    expect(find.text('Emergency SOS'), findsOneWidget);
  });

  testWidgets('a landlord can reach Emergency SOS from their bottom nav', (tester) async {
    await _skipOnboarding(tester);
    await _login(tester, 'ramon.landlord@boardie.io');
    expect(find.byKey(const Key('landlord_home_shell')), findsOneWidget);

    await _goToSos(tester);

    expect(find.text('Emergency SOS'), findsOneWidget);
  });

  testWidgets('an admin can reach Emergency SOS from their bottom nav', (tester) async {
    await _skipOnboarding(tester);
    await _login(tester, 'grace.admin@boardie.io');
    expect(find.byKey(const Key('admin_home_shell')), findsOneWidget);

    await _goToSos(tester);

    expect(find.text('Emergency SOS'), findsOneWidget);
  });
}
