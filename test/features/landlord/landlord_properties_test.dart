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

void main() {
  testWidgets('landlord sees only their own properties', (tester) async {
    await _loginAsLandlord(tester);

    // Ramon (landlord-001) owns Casa Bicolana, Embarcadero, Albay Park.
    expect(find.text('Casa Bicolana Dormitory'), findsOneWidget);
    expect(find.text('Embarcadero Student Suites'), findsOneWidget);
    expect(find.text('Albay Park Residences'), findsOneWidget);
    // Daraga Hillside and BU Gate belong to landlord-002.
    expect(find.text('Daraga Hillside Boarding House'), findsNothing);
    expect(find.text('BU Gate Transient Rooms'), findsNothing);
  });

  testWidgets('creating a property adds it to the list with pending verification',
      (tester) async {
    await _loginAsLandlord(tester);

    await tester.tap(find.byKey(const Key('add_property_fab')));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('property_name_field')), 'Test Boarding House');
    await tester.enterText(
      find.byKey(const Key('property_address_field')),
      '123 Test St, Legazpi City',
    );
    await tester.enterText(find.byKey(const Key('property_latitude_field')), '13.14');
    await tester.enterText(find.byKey(const Key('property_longitude_field')), '123.74');
    await tester.enterText(find.byKey(const Key('property_storeys_field')), '2');
    await tester.enterText(find.byKey(const Key('property_min_price_field')), '3000');
    await tester.tap(find.byKey(const Key('property_form_submit_button')));
    await tester.pumpAndSettle();

    expect(find.text('Test Boarding House'), findsOneWidget);
    expect(find.textContaining('Pending'), findsOneWidget);
  });

  testWidgets('editing a property updates its details', (tester) async {
    await _loginAsLandlord(tester);

    await tester.tap(find.text('Casa Bicolana Dormitory'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('edit_property_button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('property_name_field')), findsOneWidget);
    await tester.enterText(
      find.byKey(const Key('property_name_field')),
      'Casa Bicolana Dormitory (Renovated)',
    );
    await tester.tap(find.byKey(const Key('property_form_submit_button')));
    await tester.pumpAndSettle();

    expect(find.text('Casa Bicolana Dormitory (Renovated)'), findsOneWidget);
  });

  testWidgets('adding and removing an amenity updates the property',
      (tester) async {
    await _loginAsLandlord(tester);
    await tester.tap(find.text('Casa Bicolana Dormitory'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('add_amenity_button')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('amenity_name_field')), 'Rooftop Deck');
    await tester.tap(find.byKey(const Key('confirm_add_amenity_button')));
    await tester.pumpAndSettle();

    expect(find.text('Rooftop Deck'), findsOneWidget);

    final chip = tester.widget<Chip>(find.ancestor(
      of: find.text('Rooftop Deck'),
      matching: find.byType(Chip),
    ));
    chip.onDeleted!();
    await tester.pumpAndSettle();

    expect(find.text('Rooftop Deck'), findsNothing);
  });

  testWidgets('adding and removing a photo updates the property', (tester) async {
    await _loginAsLandlord(tester);
    await tester.tap(find.text('Casa Bicolana Dormitory'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('add_image_button')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('image_url_field')),
      'https://picsum.photos/seed/test-image/400/300',
    );
    await tester.tap(find.byKey(const Key('confirm_add_image_button')));
    await tester.pumpAndSettle();

    // image-001 and image-002 are already seeded for Casa Bicolana; the new
    // one should bring the total to 3 Image widgets in the photo strip.
    expect(find.byType(Image), findsNWidgets(3));

    await tester.tap(find.byKey(const Key('add_image_button')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('image_url_field')),
      'https://picsum.photos/seed/test-image-2/400/300',
    );
    await tester.tap(find.byKey(const Key('confirm_add_image_button')));
    await tester.pumpAndSettle();
    expect(find.byType(Image), findsNWidgets(4));
  });

  testWidgets('deleting a property removes it from the list', (tester) async {
    await _loginAsLandlord(tester);
    await tester.tap(find.text('Albay Park Residences'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('delete_property_button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('confirm_delete_property_button')));
    await tester.pumpAndSettle();

    expect(find.text('Albay Park Residences'), findsNothing);
  });
}
