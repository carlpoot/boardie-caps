import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:boardie/main.dart';

/// Every seeded Users row can be logged into with this password in the mock
/// auth repository -- see MockAuthRepository.seedPassword.
const _seedPassword = 'password123';

Future<void> _skipOnboarding(WidgetTester tester) async {
  await tester.pumpWidget(const ProviderScope(child: MyApp()));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const Key('onboarding_skip_button')));
  await tester.pumpAndSettle();
}

Future<void> _login(WidgetTester tester, String email) async {
  await tester.enterText(find.byKey(const Key('login_email_field')), email);
  await tester.enterText(
    find.byKey(const Key('login_password_field')),
    _seedPassword,
  );
  await tester.tap(find.byKey(const Key('login_submit_button')));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('first launch shows onboarding, then login, then guest home',
      (WidgetTester tester) async {
    await _skipOnboarding(tester);
    expect(find.byKey(const Key('login_email_field')), findsOneWidget);

    await tester.tap(find.byKey(const Key('continue_as_guest_button')));
    await tester.pumpAndSettle();

    expect(find.text('Browsing as Guest'), findsOneWidget);
  });

  testWidgets('logging in with seeded admin credentials reaches admin home',
      (WidgetTester tester) async {
    await _skipOnboarding(tester);
    await _login(tester, 'grace.admin@boardie.io');
    expect(find.text('Logged in as admin'), findsOneWidget);
  });

  testWidgets('logging in with seeded student credentials reaches student home',
      (WidgetTester tester) async {
    await _skipOnboarding(tester);
    await _login(tester, 'anna.student@boardie.io');
    expect(find.byKey(const Key('student_home_shell')), findsOneWidget);
  });

  testWidgets('logging in with seeded landlord credentials reaches landlord home',
      (WidgetTester tester) async {
    await _skipOnboarding(tester);
    await _login(tester, 'ramon.landlord@boardie.io');
    expect(find.text('Logged in as landlord'), findsOneWidget);
  });

  testWidgets('an incorrect password stays on the login screen with an error',
      (WidgetTester tester) async {
    await _skipOnboarding(tester);
    await tester.enterText(
      find.byKey(const Key('login_email_field')),
      'grace.admin@boardie.io',
    );
    await tester.enterText(
      find.byKey(const Key('login_password_field')),
      'wrong-password',
    );
    await tester.tap(find.byKey(const Key('login_submit_button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('login_email_field')), findsOneWidget);
    expect(find.text('Incorrect email or password.'), findsOneWidget);
  });

  testWidgets(
    "role guard redirects a student's attempt to reach the admin home back to their own home",
    (WidgetTester tester) async {
      await _skipOnboarding(tester);
      await _login(tester, 'anna.student@boardie.io');
      expect(find.byKey(const Key('student_home_shell')), findsOneWidget);

      final context = tester.element(find.byType(Scaffold).first);
      GoRouter.of(context).go('/admin/home');
      await tester.pumpAndSettle();

      expect(find.text('Logged in as admin'), findsNothing);
      expect(find.byKey(const Key('student_home_shell')), findsOneWidget);
    },
  );

  testWidgets('a guest attempting a student-only route is redirected to guest home',
      (WidgetTester tester) async {
    await _skipOnboarding(tester);
    await tester.tap(find.byKey(const Key('continue_as_guest_button')));
    await tester.pumpAndSettle();
    expect(find.text('Browsing as Guest'), findsOneWidget);

    final context = tester.element(find.byType(Scaffold).first);
    GoRouter.of(context).go('/student/home');
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('student_home_shell')), findsNothing);
    expect(find.text('Browsing as Guest'), findsOneWidget);
  });

  testWidgets('guest home "Log In or Create an Account" returns to the login screen',
      (WidgetTester tester) async {
    await _skipOnboarding(tester);
    await tester.tap(find.byKey(const Key('continue_as_guest_button')));
    await tester.pumpAndSettle();
    expect(find.text('Browsing as Guest'), findsOneWidget);

    await tester.tap(find.byKey(const Key('guest_login_or_signup_button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('login_email_field')), findsOneWidget);
  });

  testWidgets('signing up as a student then logging out returns to the login screen',
      (WidgetTester tester) async {
    await _skipOnboarding(tester);
    await tester.tap(find.byKey(const Key('create_account_link')));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('signup_name_field')), 'New Student');
    await tester.enterText(
      find.byKey(const Key('signup_email_field')),
      'newstudent@example.com',
    );
    await tester.enterText(
      find.byKey(const Key('signup_contact_no_field')),
      '09170000009',
    );
    await tester.enterText(
      find.byKey(const Key('signup_password_field')),
      'brandnew1',
    );
    await tester.tap(find.byKey(const Key('signup_submit_button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('student_home_shell')), findsOneWidget);

    await tester.tap(find.widgetWithIcon(IconButton, Icons.logout));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('login_email_field')), findsOneWidget);
  });
}
