import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mazilon/util/Phone/phoneTextAndIcon.dart';
import 'package:url_launcher_platform_interface/link.dart';
import 'package:url_launcher_platform_interface/url_launcher_platform_interface.dart';

class _FakeUrlLauncherPlatform extends UrlLauncherPlatform {
  String? lastLaunchedUrl;
  bool shouldSucceed = true;

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
    return shouldSucceed;
  }
}

Widget _wrap(Widget Function(BuildContext) builder,
    {Locale locale = const Locale('en')}) {
  return MaterialApp(
    locale: locale,
    home: ScreenUtilInit(
      designSize: const Size(360, 690),
      builder: (context, _) => Scaffold(
        body: Builder(builder: builder),
      ),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('phoneContact widget', () {
    testWidgets('renders contact text and dials when icon tapped',
        (tester) async {
      final originalPlatform = UrlLauncherPlatform.instance;
      final fake = _FakeUrlLauncherPlatform();
      UrlLauncherPlatform.instance = fake;
      addTearDown(() => UrlLauncherPlatform.instance = originalPlatform);

      await tester.pumpWidget(_wrap((_) => phoneContact('555-1234', 'Mom')));
      await tester.pumpAndSettle();

      expect(find.text('Mom'), findsOneWidget);
      expect(find.byIcon(Icons.phone), findsOneWidget);

      await tester.tap(find.byIcon(Icons.phone));
      await tester.pumpAndSettle();

      expect(fake.lastLaunchedUrl, 'tel:555-1234');
    });
  });

  group('getTextIconWidget', () {
    testWidgets('renders text + icon and triggers callback on tap',
        (tester) async {
      var taps = 0;
      await tester.pumpWidget(_wrap((_) => getTextIconWidget(
            'Send',
            () => taps++,
            Icons.send,
          )));
      await tester.pumpAndSettle();

      expect(find.text('Send'), findsOneWidget);
      expect(find.byIcon(Icons.send), findsOneWidget);

      await tester.tap(find.byIcon(Icons.send));
      await tester.pumpAndSettle();
      expect(taps, 1);
    });
  });

  group('dialPhone url construction', () {
    test('non-Android platform uses raw tel scheme', () async {
      final originalPlatform = UrlLauncherPlatform.instance;
      final fake = _FakeUrlLauncherPlatform();
      UrlLauncherPlatform.instance = fake;
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      addTearDown(() {
        debugDefaultTargetPlatformOverride = null;
        UrlLauncherPlatform.instance = originalPlatform;
      });

      await dialPhone('1201');
      expect(fake.lastLaunchedUrl, 'tel:1201');
    });

    test('failed launch is handled silently (no throw)', () async {
      final originalPlatform = UrlLauncherPlatform.instance;
      final fake = _FakeUrlLauncherPlatform()..shouldSucceed = false;
      UrlLauncherPlatform.instance = fake;
      addTearDown(() => UrlLauncherPlatform.instance = originalPlatform);

      await expectLater(dialPhone('555'), completes);
    });
  });

  group('openWhatsApp', () {
    test('uses wa.me URL', () async {
      final originalPlatform = UrlLauncherPlatform.instance;
      final fake = _FakeUrlLauncherPlatform();
      UrlLauncherPlatform.instance = fake;
      addTearDown(() => UrlLauncherPlatform.instance = originalPlatform);

      await openWhatsApp('972501234567');
      expect(fake.lastLaunchedUrl, 'https://wa.me/972501234567');
    });

    test('failure does not throw', () async {
      final originalPlatform = UrlLauncherPlatform.instance;
      final fake = _FakeUrlLauncherPlatform()..shouldSucceed = false;
      UrlLauncherPlatform.instance = fake;
      addTearDown(() => UrlLauncherPlatform.instance = originalPlatform);

      await expectLater(openWhatsApp('1'), completes);
    });
  });

  group('openSite', () {
    test('launches the provided URL string', () async {
      final originalPlatform = UrlLauncherPlatform.instance;
      final fake = _FakeUrlLauncherPlatform();
      UrlLauncherPlatform.instance = fake;
      addTearDown(() => UrlLauncherPlatform.instance = originalPlatform);

      await openSite('https://example.com/help');
      expect(fake.lastLaunchedUrl, 'https://example.com/help');
    });

    test('failure does not throw', () async {
      final originalPlatform = UrlLauncherPlatform.instance;
      final fake = _FakeUrlLauncherPlatform()..shouldSucceed = false;
      UrlLauncherPlatform.instance = fake;
      addTearDown(() => UrlLauncherPlatform.instance = originalPlatform);

      await expectLater(openSite('https://example.com'), completes);
    });
  });

  group('openTextMessage', () {
    test('without body uses sms scheme without query', () async {
      final originalPlatform = UrlLauncherPlatform.instance;
      final fake = _FakeUrlLauncherPlatform();
      UrlLauncherPlatform.instance = fake;
      addTearDown(() => UrlLauncherPlatform.instance = originalPlatform);

      await openTextMessage('555');
      expect(fake.lastLaunchedUrl, 'sms:555');
    });

    test('with body adds body query parameter', () async {
      final originalPlatform = UrlLauncherPlatform.instance;
      final fake = _FakeUrlLauncherPlatform();
      UrlLauncherPlatform.instance = fake;
      addTearDown(() => UrlLauncherPlatform.instance = originalPlatform);

      await openTextMessage('741741', body: 'HOME');
      expect(fake.lastLaunchedUrl, 'sms:741741?body=HOME');
    });

    test('whitespace-only body is treated as empty', () async {
      final originalPlatform = UrlLauncherPlatform.instance;
      final fake = _FakeUrlLauncherPlatform();
      UrlLauncherPlatform.instance = fake;
      addTearDown(() => UrlLauncherPlatform.instance = originalPlatform);

      await openTextMessage('555', body: '   ');
      expect(fake.lastLaunchedUrl, 'sms:555');
    });

    test('failure does not throw', () async {
      final originalPlatform = UrlLauncherPlatform.instance;
      final fake = _FakeUrlLauncherPlatform()..shouldSucceed = false;
      UrlLauncherPlatform.instance = fake;
      addTearDown(() => UrlLauncherPlatform.instance = originalPlatform);

      await expectLater(openTextMessage('1', body: 'x'), completes);
    });
  });
}
