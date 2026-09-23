import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:url_launcher_platform_interface/link.dart';
import 'package:url_launcher_platform_interface/url_launcher_platform_interface.dart';

import 'package:boardie/features/sos/sos_screen.dart';

/// A fake [UrlLauncherPlatform] that records the last `tel:`/etc. URL it was
/// asked to launch and returns a controllable result, instead of reaching a
/// real platform channel.
///
/// **Why this exists at all:** a genuine (unmocked) `launchUrl()` call was
/// found, while building this screen, to hang indefinitely under
/// `flutter_test` on Windows rather than failing fast (see the README) --
/// so every test below must guarantee no real platform call is ever
/// attempted, not just that one "happens" not to hang today.
class _FakeUrlLauncherPlatform extends UrlLauncherPlatform {
  String? lastLaunchedUrl;
  bool launchResult = true;

  @override
  LinkDelegate? get linkDelegate => null;

  @override
  Future<bool> canLaunch(String url) async => true;

  @override
  Future<bool> launch(
    String url, {
    required bool useSafariVC,
    required bool useWebView,
    required bool enableJavaScript,
    required bool enableDomStorage,
    required bool universalLinksOnly,
    required Map<String, String> headers,
    String? webOnlyWindowName,
  }) async {
    lastLaunchedUrl = url;
    return launchResult;
  }
}

void main() {
  late _FakeUrlLauncherPlatform fakePlatform;
  final originalPlatform = UrlLauncherPlatform.instance;

  setUp(() {
    fakePlatform = _FakeUrlLauncherPlatform();
    UrlLauncherPlatform.instance = fakePlatform;
  });

  tearDown(() {
    UrlLauncherPlatform.instance = originalPlatform;
  });

  Future<void> pumpSosScreen(WidgetTester tester) => tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: SosScreen())),
      );

  testWidgets('shows the red header and all four hotlines from Figure E6',
      (tester) async {
    await pumpSosScreen(tester);

    expect(find.text('Emergency SOS'), findsOneWidget);
    expect(
      find.text('Quick access to emergency services and hotlines'),
      findsOneWidget,
    );

    expect(find.text('National Emergency Hotline'), findsOneWidget);
    expect(find.text('For all emergencies'), findsOneWidget);
    expect(find.text('911'), findsOneWidget);

    expect(find.text('Police Station'), findsOneWidget);
    expect(find.text('Legazpi City Police'), findsOneWidget);

    expect(find.text('Hospital / Clinic'), findsOneWidget);
    expect(find.text('Aquinas University Hospital'), findsOneWidget);

    expect(find.text('Fire Station'), findsOneWidget);
    expect(find.text('Legazpi Fire Department'), findsOneWidget);
  });

  testWidgets('tapping a hotline\'s call icon launches a tel: URI for its number',
      (tester) async {
    await pumpSosScreen(tester);

    await tester.tap(find.byKey(const Key('call_hotline_national_emergency')));
    await tester.pumpAndSettle();

    expect(fakePlatform.lastLaunchedUrl, 'tel:911');
  });

  testWidgets('each hotline calls its own number, not a shared/wrong one',
      (tester) async {
    await pumpSosScreen(tester);

    await tester.tap(find.byKey(const Key('call_hotline_police')));
    await tester.pumpAndSettle();
    expect(fakePlatform.lastLaunchedUrl, 'tel:(052)480-5000');

    await tester.tap(find.byKey(const Key('call_hotline_hospital')));
    await tester.pumpAndSettle();
    expect(fakePlatform.lastLaunchedUrl, 'tel:(052)480-0888');

    await tester.tap(find.byKey(const Key('call_hotline_fire')));
    await tester.pumpAndSettle();
    expect(fakePlatform.lastLaunchedUrl, 'tel:(052)480-1116');
  });

  testWidgets(
      'the tel: URI never contains a raw or percent-encoded space, per RFC '
      "3966's grammar (a real regression this screen's phone numbers hit)",
      (tester) async {
    await pumpSosScreen(tester);

    await tester.tap(find.byKey(const Key('call_hotline_police')));
    await tester.pumpAndSettle();

    expect(fakePlatform.lastLaunchedUrl, isNot(contains(' ')));
    expect(fakePlatform.lastLaunchedUrl, isNot(contains('%20')));
  });

  testWidgets('shows a snackbar if the platform reports it could not launch',
      (tester) async {
    fakePlatform.launchResult = false;
    await pumpSosScreen(tester);

    await tester.tap(find.byKey(const Key('call_hotline_national_emergency')));
    await tester.pumpAndSettle();

    expect(find.text('Could not open the dialer for 911.'), findsOneWidget);
  });
}
