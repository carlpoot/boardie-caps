import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:boardie/core/models/models.dart';
import 'package:boardie/core/providers/repository_providers.dart';
import 'package:boardie/features/auth/providers/auth_notifier.dart';
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

Future<void> _openCasaBicolanaRoom002(WidgetTester tester) async {
  await tester.tap(find.text('Casa Bicolana Dormitory'));
  await tester.pumpAndSettle();
}

Finder _requestButtonFor(String roomTypeText) {
  final roomCard = find.ancestor(of: find.text(roomTypeText), matching: find.byType(Card));
  return find.descendant(of: roomCard, matching: find.text('Request Room'));
}

void main() {
  testWidgets(
      'Request Room on an available room succeeds and updates its availability badge',
      (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: const MyApp(),
    ));
    await tester.pumpAndSettle();
    await _loginAsStudent(tester);
    await _openCasaBicolanaRoom002(tester);

    // room-002 (Shared (2-bed)): capacity 2, occupancy 1, no active holds
    // yet -- 1 slot open.
    expect(find.textContaining('Available · 1 slot'), findsOneWidget);

    final requestButton = _requestButtonFor('Shared (2-bed)');
    await tester.ensureVisible(requestButton);
    await tester.pumpAndSettle();
    await tester.tap(requestButton);
    await tester.pumpAndSettle();

    expect(find.text('Room request sent -- held for 24 hours.'), findsOneWidget);
    // The new hold occupies room-002's only remaining slot. (room-001, next
    // to it, was already "Full" beforehand from its own pre-existing hold.)
    final room002Card = find.ancestor(
      of: find.text('Shared (2-bed)'),
      matching: find.byType(Card),
    );
    expect(
      find.descendant(of: room002Card, matching: find.textContaining('Full · 0 slots')),
      findsOneWidget,
    );
  });

  testWidgets('a 5th active hold is rejected with a clear error message',
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

    // Seed 3 more active holds on top of anna's existing 1 (request-003, on
    // room-001) so she's sitting at exactly the 4-hold cap.
    final now = DateTime.now();
    for (var i = 0; i < 3; i++) {
      await roomRequestRepository.create(RoomRequest(
        requestId: '',
        studentId: studentId,
        roomId: 'synthetic-room-$i',
        propertyId: 'property-001',
        landlordId: 'landlord-001',
        status: RoomRequestStatus.pending,
        heldUntil: now.add(const Duration(hours: 24)),
        createdAt: now,
      ));
    }

    await _openCasaBicolanaRoom002(tester);
    final requestButton = _requestButtonFor('Shared (2-bed)');
    await tester.ensureVisible(requestButton);
    await tester.pumpAndSettle();
    await tester.tap(requestButton);
    await tester.pumpAndSettle();

    expect(
      find.text(
        'You already have 4 active room holds. Cancel or confirm one before requesting another.',
      ),
      findsOneWidget,
    );
  });
}
