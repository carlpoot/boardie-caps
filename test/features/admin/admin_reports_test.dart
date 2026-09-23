import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:boardie/core/providers/repository_providers.dart';
import 'package:boardie/features/auth/providers/auth_notifier.dart';
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

Future<void> _goToReports(WidgetTester tester) async {
  await tester.tap(find.text('Reports'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('generating a users report records a system-wide Reports row',
      (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    await _loginAsAdmin(tester, container);
    await _goToReports(tester);

    await tester.tap(find.byKey(const Key('generate_admin_report_users')));
    await tester.pumpAndSettle();

    expect(find.text('Users report generated.'), findsOneWidget);

    final graceUserId = container.read(authNotifierProvider).user!.userId;
    final reports =
        await container.read(reportRepositoryProvider).getByCreatedBy(graceUserId);
    final generated = reports.where((r) => r.reportType == 'users');
    expect(generated, hasLength(1));
    expect(generated.single.fileUrl, startsWith('local://reports/users-'));
  });

  testWidgets('each of the three admin report types can be generated', (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    await _loginAsAdmin(tester, container);
    await _goToReports(tester);

    for (final type in ['users', 'listing_verification', 'reported_listings']) {
      await tester.tap(find.byKey(Key('generate_admin_report_$type')));
      await tester.pumpAndSettle();
    }

    final graceUserId = container.read(authNotifierProvider).user!.userId;
    final reports =
        await container.read(reportRepositoryProvider).getByCreatedBy(graceUserId);
    expect(
      reports.map((r) => r.reportType).toSet(),
      containsAll(['users', 'listing_verification', 'reported_listings']),
    );
  });
}
