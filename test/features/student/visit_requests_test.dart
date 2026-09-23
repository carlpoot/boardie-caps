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

void main() {
  testWidgets(
      'Request Visit opens a sheet, and sending a request with the default '
      'date/time succeeds', (tester) async {
    await _loginAsStudent(tester);
    await tester.tap(find.text('Casa Bicolana Dormitory'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('request_visit_button')));
    await tester.pumpAndSettle();

    expect(find.text('Request a Visit'), findsOneWidget);
    expect(find.text('Casa Bicolana Dormitory'), findsWidgets);

    // Submit is disabled until a date/time is chosen.
    expect(tester.widget<FilledButton>(find.byKey(const Key('submit_visit_request_button'))).onPressed, isNull);

    await tester.tap(find.byKey(const Key('pick_visit_datetime_button')));
    await tester.pumpAndSettle();
    // Accept the calendar's pre-selected initial date.
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    // Accept the clock's pre-filled initial time.
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    expect(tester.widget<FilledButton>(find.byKey(const Key('submit_visit_request_button'))).onPressed, isNotNull);

    await tester.tap(find.byKey(const Key('submit_visit_request_button')));
    await tester.pumpAndSettle();

    expect(find.text('Visit request sent.'), findsOneWidget);
    // The sheet should have closed.
    expect(find.text('Request a Visit'), findsNothing);
  });
}
