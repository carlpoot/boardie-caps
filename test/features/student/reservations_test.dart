import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:boardie/core/models/models.dart';
import 'package:boardie/core/providers/repository_providers.dart';
import 'package:boardie/features/auth/providers/auth_notifier.dart';
import 'package:boardie/features/student/room_requests/room_request_providers.dart';
import 'package:boardie/main.dart';

const _seedPassword = 'password123';

Future<void> _loginAsStudent(WidgetTester tester) async {
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

Future<void> _goToReservations(WidgetTester tester) async {
  await tester.tap(find.text('Reservations'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('Room Holds tab defaults to Active and shows the seeded pending hold',
      (tester) async {
    await tester.pumpWidget(const ProviderScope(child: MyApp()));
    await tester.pumpAndSettle();
    await _loginAsStudent(tester);
    await _goToReservations(tester);

    // Seeded request-003: student-001 (anna), room-001 (Solo) at Casa
    // Bicolana Dormitory, status pending -- always live (held_until is
    // computed relative to whenever the app actually runs).
    expect(find.text('Casa Bicolana Dormitory'), findsOneWidget);
    expect(find.text('Solo'), findsOneWidget);
    expect(find.text('Pending'), findsOneWidget);

    await tester.tap(find.text('Confirmed'));
    await tester.pumpAndSettle();
    expect(find.text('No confirmed room holds.'), findsOneWidget);
  });

  testWidgets('Visit Requests tab shows the student\'s own visit requests',
      (tester) async {
    await tester.pumpWidget(const ProviderScope(child: MyApp()));
    await tester.pumpAndSettle();
    await _loginAsStudent(tester);
    await _goToReservations(tester);

    await tester.tap(find.text('Visit Requests'));
    await tester.pumpAndSettle();

    // Seeded visit-001 (completed, Casa Bicolana) and visit-005
    // (rescheduled, Daraga Hillside) both belong to anna.
    expect(find.text('Casa Bicolana Dormitory'), findsOneWidget);
    expect(find.text('Completed'), findsOneWidget);
    expect(find.text('Daraga Hillside Boarding House'), findsOneWidget);
    expect(find.text('Rescheduled'), findsOneWidget);
  });

  testWidgets('cancelling an active room hold moves it to the Cancelled filter',
      (tester) async {
    await tester.pumpWidget(const ProviderScope(child: MyApp()));
    await tester.pumpAndSettle();
    await _loginAsStudent(tester);
    await _goToReservations(tester);

    expect(find.text('Solo'), findsOneWidget); // request-003, Active by default

    await tester.tap(find.byKey(const Key('cancel_room_request_request-003')));
    await tester.pumpAndSettle();

    expect(find.text('No active room holds.'), findsOneWidget);

    await tester.tap(find.text('Cancelled'));
    await tester.pumpAndSettle();
    expect(find.text('Solo'), findsOneWidget);
  });

  testWidgets(
      'confirming an approved hold cancels all other active holds for that student',
      (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: const MyApp(),
    ));
    await tester.pumpAndSettle();
    await _loginAsStudent(tester);

    final studentId = container.read(authNotifierProvider).studentId!;
    final roomRequestRepository = container.read(roomRequestRepositoryProvider);
    final now = DateTime.now();

    // An approved hold, ready to confirm. anna already has request-003
    // (pending, room-001) as another active hold -- confirming this one
    // should auto-cancel that one too.
    await roomRequestRepository.create(RoomRequest(
      requestId: 'approved-test-request',
      studentId: studentId,
      roomId: 'room-002',
      propertyId: 'property-001',
      landlordId: 'landlord-001',
      status: RoomRequestStatus.approved,
      heldUntil: now.add(const Duration(hours: 24)),
      createdAt: now,
    ));
    // The Reservations tab is already mounted (IndexedStack keeps every
    // bottom-nav tab alive), so its provider may have already resolved
    // before this direct repository write -- force a refetch.
    container.invalidate(studentRoomRequestsProvider);

    await _goToReservations(tester);
    expect(find.text('Approved'), findsOneWidget);

    await tester.tap(find.byKey(const Key('confirm_room_request_approved-test-request')));
    await tester.pumpAndSettle();

    expect(
      find.text('Room request confirmed. Your other holds were cancelled.'),
      findsOneWidget,
    );

    // The confirmed one now shows under Confirmed...
    expect(find.text('Confirmed'), findsWidgets);
    await tester.tap(find.text('Active'));
    await tester.pumpAndSettle();
    expect(find.text('No active room holds.'), findsOneWidget);

    // ...and anna's other active hold (request-003, room-001/Solo) was
    // auto-cancelled.
    await tester.tap(find.text('Cancelled'));
    await tester.pumpAndSettle();
    expect(find.text('Solo'), findsOneWidget);
  });
}
