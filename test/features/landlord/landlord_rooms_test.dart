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

Future<void> _openCasaBicolanaRooms(WidgetTester tester) async {
  await tester.tap(find.text('Casa Bicolana Dormitory'));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const Key('manage_rooms_button')));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('Manage Rooms lists the property\'s rooms with an availability badge',
      (tester) async {
    await _loginAsLandlord(tester);
    await _openCasaBicolanaRooms(tester);

    // room-001 (Solo) has a live pending hold occupying its only slot ->
    // Full. room-002 (Shared (2-bed)) has 1 open slot -> Available.
    expect(find.text('Solo'), findsOneWidget);
    expect(find.text('Shared (2-bed)'), findsOneWidget);
    expect(find.text('Full'), findsOneWidget);
    expect(find.text('Available'), findsOneWidget);
  });

  testWidgets('creating a room adds it to the list', (tester) async {
    await _loginAsLandlord(tester);
    await _openCasaBicolanaRooms(tester);

    await tester.tap(find.byKey(const Key('add_room_fab')));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('room_type_field')), 'Shared (3-bed)');
    await tester.enterText(find.byKey(const Key('room_capacity_field')), '3');
    await tester.enterText(find.byKey(const Key('room_occupancy_field')), '1');
    await tester.enterText(find.byKey(const Key('room_rent_price_field')), '2200');
    await tester.tap(find.byKey(const Key('room_form_submit_button')));
    await tester.pumpAndSettle();

    expect(find.text('Shared (3-bed)'), findsOneWidget);
    expect(find.textContaining('Capacity 3'), findsOneWidget);
  });

  testWidgets('occupancy cannot exceed capacity', (tester) async {
    await _loginAsLandlord(tester);
    await _openCasaBicolanaRooms(tester);

    await tester.tap(find.byKey(const Key('add_room_fab')));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('room_type_field')), 'Bad Room');
    await tester.enterText(find.byKey(const Key('room_capacity_field')), '2');
    await tester.enterText(find.byKey(const Key('room_occupancy_field')), '5');
    await tester.enterText(find.byKey(const Key('room_rent_price_field')), '1000');
    await tester.tap(find.byKey(const Key('room_form_submit_button')));
    await tester.pumpAndSettle();

    expect(find.text('Cannot exceed capacity'), findsOneWidget);
    // Still on the form -- nothing was created.
    expect(find.byKey(const Key('room_form_submit_button')), findsOneWidget);
  });

  testWidgets('editing a room updates its details and recalculates availability',
      (tester) async {
    await _loginAsLandlord(tester);
    await _openCasaBicolanaRooms(tester);

    await tester.tap(find.text('Shared (2-bed)'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('room_type_field')), findsOneWidget);
    await tester.enterText(find.byKey(const Key('room_occupancy_field')), '2');
    await tester.tap(find.byKey(const Key('room_form_submit_button')));
    await tester.pumpAndSettle();

    // Now full (2/2), instead of the original 1/2 Available.
    expect(find.textContaining('Occupancy 2'), findsOneWidget);
  });

  testWidgets('deleting a room removes it from the list', (tester) async {
    await _loginAsLandlord(tester);
    await _openCasaBicolanaRooms(tester);

    expect(find.text('Solo'), findsOneWidget);
    await tester.tap(find.byKey(const Key('delete_room_room-001')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('confirm_delete_room_button')));
    await tester.pumpAndSettle();

    expect(find.text('Solo'), findsNothing);
  });
}
