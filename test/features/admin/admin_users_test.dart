import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:boardie/main.dart';

const _seedPassword = 'password123';

Future<void> _loginAsAdmin(WidgetTester tester) async {
  await tester.pumpWidget(const ProviderScope(child: MyApp()));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const Key('onboarding_skip_button')));
  await tester.pumpAndSettle();

  await tester.enterText(
    find.byKey(const Key('login_email_field')),
    'grace.admin@boardie.io',
  );
  await tester.enterText(
    find.byKey(const Key('login_password_field')),
    _seedPassword,
  );
  await tester.tap(find.byKey(const Key('login_submit_button')));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
      'Manage Users lists every user with their linked profile shown inline',
      (tester) async {
    await _loginAsAdmin(tester);
    // Only the 3 seeded landlords, sorted by name: Dante, Liza, Ramon --
    // all fit on screen without scrolling.
    await tester.tap(find.byKey(const Key('role_filter_Landlord')));
    await tester.pumpAndSettle();

    expect(find.textContaining('Ramon Bicol'), findsOneWidget);
    expect(find.textContaining('Landlord profile: landlord-001'), findsOneWidget);
    expect(find.text('Verified'), findsOneWidget);
  });

  testWidgets('filtering by role narrows the list to just that role',
      (tester) async {
    await _loginAsAdmin(tester);

    // Anna (a student) is visible under the default "All" filter --
    // sorted first alphabetically.
    expect(find.textContaining('Anna Marasigan'), findsOneWidget);

    await tester.tap(find.byKey(const Key('role_filter_Landlord')));
    await tester.pumpAndSettle();

    expect(find.textContaining('Ramon Bicol'), findsOneWidget);
    expect(find.textContaining('Anna Marasigan'), findsNothing);
  });

  testWidgets('a student user shows their linked StudentProfile and campus',
      (tester) async {
    await _loginAsAdmin(tester);

    await tester.tap(find.byKey(const Key('role_filter_Student')));
    await tester.pumpAndSettle();

    expect(find.textContaining('Student profile: student-001'), findsOneWidget);
    expect(find.textContaining('Bicol University'), findsWidgets);
  });

  testWidgets('toggling status suspends an active user, and reactivates a suspended one',
      (tester) async {
    await _loginAsAdmin(tester);
    await tester.tap(find.byKey(const Key('role_filter_Landlord')));
    await tester.pumpAndSettle();

    // Ramon (user-002) starts active.
    final ramonToggle = find.byKey(const Key('toggle_user_status_user-002'));
    await tester.ensureVisible(ramonToggle);
    await tester.pumpAndSettle();
    await tester.tap(ramonToggle);
    await tester.pumpAndSettle();

    expect(
      find.descendant(
        of: find.ancestor(of: ramonToggle, matching: find.byType(Card)),
        matching: find.text('Suspended'),
      ),
      findsOneWidget,
    );

    // Dante (user-004) starts suspended -- reactivate him.
    final danteToggle = find.byKey(const Key('toggle_user_status_user-004'));
    await tester.ensureVisible(danteToggle);
    await tester.pumpAndSettle();
    await tester.tap(danteToggle);
    await tester.pumpAndSettle();

    expect(
      find.descendant(
        of: find.ancestor(of: danteToggle, matching: find.byType(Card)),
        matching: find.text('Active'),
      ),
      findsOneWidget,
    );
  });
}
