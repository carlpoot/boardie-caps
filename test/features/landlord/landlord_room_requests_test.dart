import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:boardie/main.dart';

const _seedPassword = 'password123';

Future<void> _loginAsLandlord(WidgetTester tester) async {
  await tester.pumpWidget(const ProviderScope(child: MyApp()));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const Key('onboarding_skip_button')));
  await tester.pumpAndSettle();

  await tester.enterText(
    find.byKey(const Key('login_email_field')),
    'ramon.landlord@boardie.io',
  );
  await tester.enterText(
    find.byKey(const Key('login_password_field')),
    _seedPassword,
  );
  await tester.tap(find.byKey(const Key('login_submit_button')));
  await tester.pumpAndSettle();
}

Future<void> _goToRoomRequests(WidgetTester tester) async {
  await tester.tap(find.text('Room Requests'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
      'landlord sees only their own room requests, grouped by live status, '
      'actions only on Pending', (tester) async {
    await _loginAsLandlord(tester);
    await _goToRoomRequests(tester);

    // Ramon (landlord-001): request-003 pending (live), request-002
    // approved, request-001 confirmed -- all visible without scrolling.
    expect(find.text('Pending'), findsOneWidget);
    expect(find.text('Approved'), findsOneWidget);
    expect(find.text('Confirmed'), findsOneWidget);
    expect(find.text('Approve'), findsOneWidget);
    expect(find.text('Decline'), findsOneWidget);
    // No "Confirm" action anywhere -- that's the student's action only.
    expect(find.text('Confirm'), findsNothing);

    // request-004 (declined) and request-006 (cancelled) belong to
    // landlord-002, not ramon.
    expect(find.text('Declined'), findsNothing);
    expect(find.text('Cancelled'), findsNothing);

    // request-005 (expired) is further down the list -- scroll to it.
    await tester.drag(find.byType(ListView), const Offset(0, -400));
    await tester.pumpAndSettle();
    expect(find.text('Expired'), findsOneWidget);
  });

  testWidgets('approving a pending room request moves it to Approved, no '
      'confirm option for the landlord', (tester) async {
    await _loginAsLandlord(tester);
    await _goToRoomRequests(tester);

    await tester.tap(find.byKey(const Key('approve_room_request_request-003')));
    await tester.pumpAndSettle();

    // Two Approved cards now (request-002 pre-existing + request-003).
    final approvedHeaders = find.text('Approved');
    expect(approvedHeaders, findsOneWidget);
    expect(find.text('Pending'), findsNothing);
    expect(find.text('Confirm'), findsNothing);
  });

  testWidgets('declining a pending room request moves it to Declined',
      (tester) async {
    await _loginAsLandlord(tester);
    await _goToRoomRequests(tester);

    await tester.tap(find.byKey(const Key('decline_room_request_request-003')));
    await tester.pumpAndSettle();

    expect(find.text('Pending'), findsNothing);
    expect(find.text('Declined'), findsOneWidget);
  });
}
