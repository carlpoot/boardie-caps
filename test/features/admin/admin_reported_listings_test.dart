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

Future<void> _goToReported(WidgetTester tester) async {
  await tester.tap(find.text('Reported'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
      'Review Reported Listings shows only pending reports, and hides '
      'Reject Property for an already-rejected property', (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    await _loginAsAdmin(tester, container);
    await _goToReported(tester);

    // reportissue-001 and reportissue-004, both against property-005
    // (already rejected) -- pending review, no Reject Property action.
    expect(find.textContaining('Mayon View Apartments'), findsNWidgets(2));
    expect(find.byKey(const Key('reject_property_from_report_reportissue-001')), findsNothing);
    expect(find.byKey(const Key('reject_property_from_report_reportissue-004')), findsNothing);

    // reportissue-005, against property-003 (still pending) -- has the
    // Reject Property action available.
    expect(find.textContaining('Daraga Hillside Boarding House'), findsOneWidget);
    expect(find.byKey(const Key('reject_property_from_report_reportissue-005')), findsOneWidget);

    // reportissue-002 (reviewed) and reportissue-003 (dismissed) never show.
    expect(find.textContaining('BU Gate Transient Rooms'), findsNothing);
  });

  testWidgets('marking a report reviewed or dismissed removes it from the '
      'queue without touching the property\'s verification_status', (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    await _loginAsAdmin(tester, container);
    await _goToReported(tester);

    await tester.tap(find.byKey(const Key('review_report_reportissue-001')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('dismiss_report_reportissue-004')));
    await tester.pumpAndSettle();

    final reportedListingRepository = container.read(reportedListingRepositoryProvider);
    final r1 = await reportedListingRepository.getById('reportissue-001');
    final r4 = await reportedListingRepository.getById('reportissue-004');
    expect(r1!.reviewStatus, ReportedListingReviewStatus.reviewed);
    expect(r4!.reviewStatus, ReportedListingReviewStatus.dismissed);

    // property-005's verification_status is untouched by either action.
    final property = await container.read(propertyRepositoryProvider).getById('property-005');
    expect(property!.verificationStatus, VerificationStatus.rejected);
  });

  testWidgets(
      'Reject Property is a separate action from reviewing the report -- '
      'it does not itself change the report\'s review_status', (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    await _loginAsAdmin(tester, container);
    await _goToReported(tester);

    await tester.tap(find.byKey(const Key('reject_property_from_report_reportissue-005')));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const Key('confirm_reject_property_from_report_reportissue-005')),
    );
    await tester.pumpAndSettle();

    final property = await container.read(propertyRepositoryProvider).getById('property-003');
    expect(property!.verificationStatus, VerificationStatus.rejected);

    final report = await container
        .read(reportedListingRepositoryProvider)
        .getById('reportissue-005');
    expect(report!.reviewStatus, ReportedListingReviewStatus.pending);

    // The report card is still in the queue (still pending review) but no
    // longer offers Reject Property, since the property is rejected now.
    expect(find.byKey(const Key('reject_property_from_report_reportissue-005')), findsNothing);
  });
}
