import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:boardie/core/providers/repository_providers.dart';
import 'package:boardie/features/auth/providers/auth_notifier.dart';
import 'package:boardie/features/landlord/reports/landlord_reports_providers.dart';
import 'package:boardie/main.dart';

const _seedPassword = 'password123';

Future<void> _loginAsLandlord(WidgetTester tester, ProviderContainer container) async {
  await tester.pumpWidget(UncontrolledProviderScope(
    container: container,
    child: const MyApp(),
  ));
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

Future<void> _goToReports(WidgetTester tester) async {
  await tester.tap(find.text('Reports'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('generating a listings report records a Reports row scoped to this landlord',
      (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    await _loginAsLandlord(tester, container);
    await _goToReports(tester);

    await tester.tap(find.byKey(const Key('generate_report_listings')));
    await tester.pumpAndSettle();

    expect(find.text('Property Listings report generated.'), findsOneWidget);
    expect(find.text('Property Listings'), findsWidgets);

    final ramonUserId = container.read(authNotifierProvider).user!.userId;
    final reports = await container.read(reportRepositoryProvider).getByCreatedBy(ramonUserId);
    expect(reports, hasLength(1));
    expect(reports.first.reportType, 'listings');
    expect(reports.first.createdBy, ramonUserId);
    expect(reports.first.fileUrl, startsWith('local://reports/listings-'));
  });

  testWidgets('each of the four report types can be generated', (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    await _loginAsLandlord(tester, container);
    await _goToReports(tester);

    for (final type in ['listings', 'room_availability', 'occupancy', 'reservation']) {
      await tester.tap(find.byKey(Key('generate_report_$type')));
      await tester.pumpAndSettle();
    }

    final ramonUserId = container.read(authNotifierProvider).user!.userId;
    final reports = await container.read(reportRepositoryProvider).getByCreatedBy(ramonUserId);
    expect(reports.map((r) => r.reportType).toSet(), {
      'listings',
      'room_availability',
      'occupancy',
      'reservation',
    });
  });

  testWidgets('a landlord only ever sees their own generated reports',
      (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    await _loginAsLandlord(tester, container);
    await _goToReports(tester);

    await tester.tap(find.byKey(const Key('generate_report_listings')));
    await tester.pumpAndSettle();

    final ramonUserId = container.read(authNotifierProvider).user!.userId;
    final ramonReport =
        (await container.read(reportRepositoryProvider).getByCreatedBy(ramonUserId)).single;

    // Seed a report for a DIFFERENT landlord's user (Liza, landlord-002)
    // directly, then confirm it never shows up in ramon's own list.
    await container.read(reportRepositoryProvider).create(ramonReport.copyWith(
          reportId: '',
          createdBy: 'user-003',
        ));

    container.invalidate(landlordReportsProvider);
    final ramonReportsAfter = await container.read(landlordReportsProvider.future);

    expect(ramonReportsAfter, hasLength(1));
    expect(ramonReportsAfter.single.createdBy, ramonUserId);
  });
}
