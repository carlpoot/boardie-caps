import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:boardie/main.dart';

const _seedPassword = 'password123';

Future<void> _login(WidgetTester tester, String email) async {
  await tester.pumpWidget(const ProviderScope(child: MyApp()));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const Key('onboarding_skip_button')));
  await tester.pumpAndSettle();

  await tester.enterText(find.byKey(const Key('login_email_field')), email);
  await tester.enterText(
    find.byKey(const Key('login_password_field')),
    _seedPassword,
  );
  await tester.tap(find.byKey(const Key('login_submit_button')));
  await tester.pumpAndSettle();
}

Future<void> _goToVisitRequests(WidgetTester tester) async {
  await tester.tap(find.text('Visits'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
      'landlord sees only their own visit requests, grouped by status, no '
      'actions on already-responded ones', (tester) async {
    await _login(tester, 'ramon.landlord@boardie.io');
    await _goToVisitRequests(tester);

    // Ramon (landlord-001): visit-001 completed, visit-002 accepted,
    // visit-004 declined -- none pending, so no action buttons anywhere.
    expect(find.text('Accepted'), findsOneWidget);
    expect(find.text('Declined'), findsOneWidget);
    expect(find.text('Completed'), findsOneWidget);
    expect(find.text('Embarcadero Student Suites'), findsOneWidget);
    expect(find.text('Albay Park Residences'), findsOneWidget);
    expect(find.text('Casa Bicolana Dormitory'), findsOneWidget);
    expect(find.text('Accept'), findsNothing);
    expect(find.text('Decline'), findsNothing);
    expect(find.text('Reschedule'), findsNothing);

    // visit-003 (pending) belongs to landlord-002, not ramon.
    expect(find.text('Pending'), findsNothing);
    expect(find.text('BU Gate Transient Rooms'), findsNothing);
  });

  testWidgets('accepting a pending visit request moves it to Accepted',
      (tester) async {
    await _login(tester, 'liza.landlord@boardie.io');
    await _goToVisitRequests(tester);

    expect(find.text('Pending'), findsOneWidget);
    expect(find.text('BU Gate Transient Rooms'), findsOneWidget);

    await tester.tap(find.byKey(const Key('accept_visit_visit-003')));
    await tester.pumpAndSettle();

    expect(find.text('Pending'), findsNothing);
    expect(find.text('Accepted'), findsOneWidget);
    expect(find.text('BU Gate Transient Rooms'), findsOneWidget);
  });

  testWidgets('declining a pending visit request moves it to Declined',
      (tester) async {
    await _login(tester, 'liza.landlord@boardie.io');
    await _goToVisitRequests(tester);

    await tester.tap(find.byKey(const Key('decline_visit_visit-003')));
    await tester.pumpAndSettle();

    expect(find.text('Pending'), findsNothing);
    expect(find.text('Declined'), findsOneWidget);
  });

  testWidgets('rescheduling a pending visit request moves it to Rescheduled '
      'with a new requested date/time', (tester) async {
    await _login(tester, 'liza.landlord@boardie.io');
    await _goToVisitRequests(tester);

    await tester.tap(find.byKey(const Key('reschedule_visit_visit-003')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK')); // accept the pre-selected date
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK')); // accept the pre-filled time
    await tester.pumpAndSettle();

    expect(find.text('Pending'), findsNothing);
    expect(find.text('Rescheduled'), findsOneWidget);
  });
}
