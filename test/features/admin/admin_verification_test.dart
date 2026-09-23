import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:boardie/core/models/models.dart';
import 'package:boardie/core/providers/repository_providers.dart';
import 'package:boardie/main.dart';

const _seedPassword = 'password123';

Future<void> _loginAsAdmin(WidgetTester tester, ProviderContainer container) async {
  await tester.pumpWidget(UncontrolledProviderScope(
    container: container,
    child: const MyApp(),
  ));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const Key('onboarding_skip_button')));
  await tester.pumpAndSettle();

  await tester.enterText(
    find.byKey(const Key('login_email_field')),
    'grace.admin@boardie.io',
  );
  await tester.enterText(
    find.byKey(const Key('login_password_field')),
    _seedPassword,
  );
  await tester.tap(find.byKey(const Key('login_submit_button')));
  await tester.pumpAndSettle();
}

Future<void> _goToVerify(WidgetTester tester) async {
  await tester.tap(find.text('Verify'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
      'Verify Listings shows only pending properties, with landlord '
      'verification status and a pending-report warning', (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    await _loginAsAdmin(tester, container);
    await _goToVerify(tester);

    // property-003 (Daraga Hillside) is the only seeded pending property.
    expect(find.textContaining('Daraga Hillside Boarding House'), findsOneWidget);
    // Its landlord (landlord-002) is itself identity-verification pending --
    // shown for context, a separate field from the property's own status.
    expect(find.textContaining('Landlord identity verification'), findsOneWidget);
    // reportissue-005 (seeded) is a pending report against property-003.
    expect(find.textContaining('1 unreviewed report'), findsOneWidget);

    // Already-verified/rejected properties never appear here.
    expect(find.textContaining('Casa Bicolana Dormitory'), findsNothing);
    expect(find.textContaining('Mayon View Apartments'), findsNothing);
  });

  testWidgets(
      'verifying a property with a pending report surfaces a warning dialog, '
      'not a hard block', (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    await _loginAsAdmin(tester, container);
    await _goToVerify(tester);

    await tester.tap(find.byKey(const Key('verify_property_property-003')));
    await tester.pumpAndSettle();

    expect(find.text('Verify this listing?'), findsOneWidget);
    expect(find.textContaining('still await review'), findsOneWidget);
    expect(
      find.textContaining('Landlord could not be reached to confirm room availability.'),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const Key('confirm_verify_property_property-003')));
    await tester.pumpAndSettle();

    final property = await container.read(propertyRepositoryProvider).getById('property-003');
    expect(property!.verificationStatus, VerificationStatus.verified);
    expect(find.textContaining('Daraga Hillside Boarding House'), findsNothing);
  });

  testWidgets('rejecting a pending property sets verification_status to rejected',
      (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    await _loginAsAdmin(tester, container);
    await _goToVerify(tester);

    await tester.tap(find.byKey(const Key('reject_property_property-003')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('confirm_reject_property_property-003')));
    await tester.pumpAndSettle();

    final property = await container.read(propertyRepositoryProvider).getById('property-003');
    expect(property!.verificationStatus, VerificationStatus.rejected);
    expect(find.text('No listings awaiting verification.'), findsOneWidget);
  });
}
