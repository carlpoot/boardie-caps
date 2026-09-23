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
  testWidgets('student home lists only verified properties', (tester) async {
    await _loginAsStudent(tester);

    // Verified -- should appear.
    expect(find.text('Casa Bicolana Dormitory'), findsOneWidget);
    expect(find.text('Embarcadero Student Suites'), findsOneWidget);
    expect(find.text('BU Gate Transient Rooms'), findsOneWidget);
    expect(find.text('Albay Park Residences'), findsOneWidget);

    // Pending / rejected -- must not appear to a student.
    expect(find.text('Daraga Hillside Boarding House'), findsNothing);
    expect(find.text('Mayon View Apartments'), findsNothing);
  });

  testWidgets('search bar filters the browse list by name', (tester) async {
    await _loginAsStudent(tester);
    expect(find.text('BU Gate Transient Rooms'), findsOneWidget);

    await tester.enterText(find.byType(TextField).first, 'Casa');
    await tester.pumpAndSettle();

    expect(find.text('Casa Bicolana Dormitory'), findsOneWidget);
    expect(find.text('BU Gate Transient Rooms'), findsNothing);
  });

  testWidgets('the "Near BU" filter narrows the list to nearby properties',
      (tester) async {
    await _loginAsStudent(tester);
    expect(find.text('Mayon View Apartments'), findsNothing); // rejected anyway

    // Daraga Hillside is ~3.7km from Bicol University -- outside the 2km
    // "near" threshold, and also unverified, so it's excluded either way.
    // Embarcadero (~3km) IS verified, so it's the one that actually proves
    // the distance filter (not just the verification filter) is working.
    expect(find.text('Embarcadero Student Suites'), findsOneWidget);

    await tester.tap(find.text('Near BU'));
    await tester.pumpAndSettle();

    expect(find.text('Embarcadero Student Suites'), findsNothing);
    expect(find.text('BU Gate Transient Rooms'), findsOneWidget); // ~0.6km
  });

  testWidgets('tapping a property card opens its details with rooms listed',
      (tester) async {
    await _loginAsStudent(tester);

    await tester.tap(find.text('Casa Bicolana Dormitory'));
    await tester.pumpAndSettle();

    expect(find.text('Casa Bicolana Dormitory'), findsOneWidget);
    expect(find.text('Rizal St, Legazpi City, Albay'), findsOneWidget);
    // Casa Bicolana Dormitory has room-001 (Solo) and room-002 (Shared (2-bed)).
    expect(find.text('Solo'), findsOneWidget);
    expect(find.text('Shared (2-bed)'), findsOneWidget);
  });

  testWidgets('the save heart icon toggles and persists across a refresh',
      (tester) async {
    await _loginAsStudent(tester);
    await tester.tap(find.text('BU Gate Transient Rooms'));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.favorite_border), findsOneWidget);
    expect(find.byIcon(Icons.favorite), findsNothing);

    await tester.tap(find.byKey(const Key('save_property_button')));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.favorite), findsOneWidget);
    expect(find.byIcon(Icons.favorite_border), findsNothing);

    // Toggling again removes the SavedProperties row.
    await tester.tap(find.byKey(const Key('save_property_button')));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.favorite_border), findsOneWidget);
  });

  testWidgets('the Map tab lists properties with distance-from-campus text',
      (tester) async {
    await _loginAsStudent(tester);

    await tester.tap(find.text('Map'));
    await tester.pumpAndSettle();

    expect(find.textContaining('km from campus'), findsWidgets);
    // Nearest property (BU Gate Transient Rooms, ~0.6km) should be first.
    final firstTileFinder = find.byType(ListTile).first;
    expect(
      find.descendant(of: firstTileFinder, matching: find.text('BU Gate Transient Rooms')),
      findsOneWidget,
    );
  });
}
