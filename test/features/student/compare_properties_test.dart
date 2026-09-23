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

Future<void> _tapPropertyCard(WidgetTester tester, String name) async {
  final finder = find.text(name);
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
}

void main() {
  testWidgets(
      'selecting 2 properties from Browse and comparing shows both side by side',
      (tester) async {
    await _loginAsStudent(tester);

    await tester.tap(find.byKey(const Key('toggle_compare_mode_button')));
    await tester.pumpAndSettle();

    // The Compare button starts disabled with 0 selected.
    expect(
      tester.widget<FilledButton>(find.byKey(const Key('compare_selected_button'))).onPressed,
      isNull,
    );

    await _tapPropertyCard(tester, 'Casa Bicolana Dormitory');
    await _tapPropertyCard(tester, 'BU Gate Transient Rooms');
    await tester.pumpAndSettle();

    expect(find.text('Compare (2)'), findsOneWidget);
    await tester.tap(find.byKey(const Key('compare_selected_button')));
    await tester.pumpAndSettle();

    expect(find.text('Compare Properties'), findsOneWidget);
    expect(find.text('Casa Bicolana Dormitory'), findsOneWidget);
    expect(find.text('BU Gate Transient Rooms'), findsOneWidget);
    // Rooms from each property should be listed in its own column.
    expect(find.text('Solo'), findsWidgets);
  });

  testWidgets('a 4th selection is rejected with a clear message', (tester) async {
    await _loginAsStudent(tester);

    await tester.tap(find.byKey(const Key('toggle_compare_mode_button')));
    await tester.pumpAndSettle();

    await _tapPropertyCard(tester, 'Casa Bicolana Dormitory');
    await _tapPropertyCard(tester, 'Embarcadero Student Suites');
    await _tapPropertyCard(tester, 'BU Gate Transient Rooms');
    await tester.pumpAndSettle();
    expect(find.text('Compare (3)'), findsOneWidget);

    await _tapPropertyCard(tester, 'Albay Park Residences');
    await tester.pump();

    expect(find.text('You can compare up to 3 properties.'), findsOneWidget);
    expect(find.text('Compare (3)'), findsOneWidget);
  });

  testWidgets('Cancel exits compare mode and clears the selection', (tester) async {
    await _loginAsStudent(tester);

    await tester.tap(find.byKey(const Key('toggle_compare_mode_button')));
    await tester.pumpAndSettle();
    await _tapPropertyCard(tester, 'Casa Bicolana Dormitory');
    await tester.pumpAndSettle();
    expect(find.text('Compare (1)'), findsOneWidget);

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    // Back to normal browsing -- tapping a card now opens details again.
    await _tapPropertyCard(tester, 'Casa Bicolana Dormitory');
    await tester.pumpAndSettle();
    expect(find.text('Rizal St, Legazpi City, Albay'), findsOneWidget);
  });

  testWidgets('comparing from the Saved Properties list works too', (tester) async {
    await _loginAsStudent(tester);
    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('view_all_saved_button')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('toggle_saved_compare_mode_button')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('compare_checkbox_property-002')));
    await tester.tap(find.byKey(const Key('compare_checkbox_property-006')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('compare_selected_from_saved_button')));
    await tester.pumpAndSettle();

    expect(find.text('Embarcadero Student Suites'), findsOneWidget);
    expect(find.text('Albay Park Residences'), findsOneWidget);
  });
}
