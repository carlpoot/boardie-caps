import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:boardie/main.dart';

const _seedPassword = 'password123';

Future<void> _loginAsStudent(WidgetTester tester) async {
  await tester.pumpWidget(const ProviderScope(child: MyApp()));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const Key('onboarding_skip_button')));
  await tester.pumpAndSettle();

  await tester.enterText(
    find.byKey(const Key('login_email_field')),
    'anna.student@boardie.io',
  );
  await tester.enterText(
    find.byKey(const Key('login_password_field')),
    _seedPassword,
  );
  await tester.tap(find.byKey(const Key('login_submit_button')));
  await tester.pumpAndSettle();
}

Future<void> _goToProfile(WidgetTester tester) async {
  await tester.tap(find.text('Profile'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('Profile shows personal info, campus anchor, and saved count',
      (tester) async {
    await _loginAsStudent(tester);
    await _goToProfile(tester);

    expect(find.text('Anna Marasigan'), findsOneWidget);
    expect(find.text('anna.student@boardie.io'), findsOneWidget);
    expect(find.text('09171234505'), findsOneWidget);
    expect(find.text('Bicol University'), findsOneWidget);

    // Seeded: anna has 2 saved properties (Embarcadero, Albay Park).
    expect(find.text('2 saved properties'), findsOneWidget);
    expect(find.text('Embarcadero Student Suites'), findsOneWidget);
    expect(find.text('Albay Park Residences'), findsOneWidget);
  });

  testWidgets('View All opens the full saved list, and unsaving updates the count',
      (tester) async {
    await _loginAsStudent(tester);
    await _goToProfile(tester);

    await tester.tap(find.byKey(const Key('view_all_saved_button')));
    await tester.pumpAndSettle();

    expect(find.text('Saved Properties'), findsOneWidget);
    expect(find.text('Embarcadero Student Suites'), findsOneWidget);
    expect(find.text('Albay Park Residences'), findsOneWidget);

    await tester.tap(find.byKey(const Key('unsave_property-002')));
    await tester.pumpAndSettle();

    expect(find.text('Embarcadero Student Suites'), findsNothing);
    expect(find.text('Albay Park Residences'), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('1 saved property'), findsOneWidget);
  });

  testWidgets('Set Campus Anchor updates the profile and the Home distance filter',
      (tester) async {
    await _loginAsStudent(tester);
    await _goToProfile(tester);

    await tester.tap(find.byKey(const Key('campus_anchor_tile')));
    await tester.pumpAndSettle();

    expect(find.text('Set Campus Anchor'), findsOneWidget);
    // Bicol University should start selected.
    final buRadio = tester.widget<RadioListTile<String>>(
      find.byKey(const Key('campus_option_campus-001')),
    );
    expect(buRadio.value, 'campus-001');

    await tester.tap(find.byKey(const Key('campus_option_campus-002')));
    await tester.pumpAndSettle();

    expect(find.text('Campus anchor set to Aquinas University of Legazpi.'), findsOneWidget);
    // Popped back to Profile, now showing the new campus.
    expect(find.text('Aquinas University of Legazpi'), findsOneWidget);
  });
}
