import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter/services.dart';
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

const _smsComposeChannel = MethodChannel('com.matzilon.mezilon/sms_compose');

Widget _wrap(
  Widget Function(BuildContext) builder, {
  Locale locale = const Locale('en'),
}) {
  return MaterialApp(
    locale: locale,
    home: ScreenUtilInit(
      designSize: const Size(360, 690),
      builder: (context, _) => Scaffold(body: Builder(builder: builder)),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('circularActionButton', () {
    testWidgets('honors supplied visual dimensions and callback', (
      tester,
    ) async {
      var taps = 0;
      await tester.pumpWidget(
        _wrap(
          (context) => circularActionButton(
            context,
            tooltip: 'Call contact',
            icon: Icons.phone,
            diameter: 32,
            iconSize: 16,
            onTap: () => taps++,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byTooltip('Call contact'), findsOneWidget);
      expect(tester.widget<CircleAvatar>(find.byType(CircleAvatar)).radius, 16);
      expect(tester.widget<Icon>(find.byIcon(Icons.phone)).size, 16);

      await tester.tap(find.byIcon(Icons.phone));
      await tester.pumpAndSettle();
      expect(taps, 1);
    });

    testWidgets('expands the tap target for a large visual diameter', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          (context) => circularActionButton(
            context,
            tooltip: 'Call contact',
            icon: Icons.phone,
            diameter: 80,
            onTap: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      final tapTarget = find.byWidgetPredicate(
        (widget) =>
            widget is SizedBox && widget.width == 80 && widget.height == 80,
      );
      expect(tapTarget, findsOneWidget);
      expect(tester.getSize(tapTarget), const Size(80, 80));
      expect(tester.getSize(find.byType(CircleAvatar)), const Size(80, 80));
    });
  });

  group('phoneContact widget', () {
    testWidgets('renders contact text and dials when icon tapped', (
      tester,
    ) async {
      final originalPlatform = UrlLauncherPlatform.instance;
      final fake = _FakeUrlLauncherPlatform();
      UrlLauncherPlatform.instance = fake;
      addTearDown(() => UrlLauncherPlatform.instance = originalPlatform);

      await tester.pumpWidget(_wrap((_) => phoneContact('555-1234', 'Mom')));
      await tester.pumpAndSettle();

      expect(find.text('Mom'), findsOneWidget);
      expect(find.byIcon(Icons.phone), findsOneWidget);
      expect(find.byType(InkWell), findsOneWidget);

      await tester.tap(find.byIcon(Icons.phone));
      await tester.pumpAndSettle();

      expect(fake.lastLaunchedUrl, 'tel:555-1234');
    });
  });

  group('getTextIconWidget', () {
    testWidgets('renders text + icon and triggers callback on tap', (
      tester,
    ) async {
      var taps = 0;
      await tester.pumpWidget(
        _wrap((_) => getTextIconWidget('Send', () => taps++, Icons.send)),
      );
      await tester.pumpAndSettle();

      expect(find.text('Send'), findsOneWidget);
      expect(find.byIcon(Icons.send), findsOneWidget);
      expect(find.byType(InkWell), findsOneWidget);

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

    test('failed launch returns false', () async {
      final originalPlatform = UrlLauncherPlatform.instance;
      final fake = _FakeUrlLauncherPlatform()..shouldSucceed = false;
      UrlLauncherPlatform.instance = fake;
      addTearDown(() => UrlLauncherPlatform.instance = originalPlatform);

      expect(await dialPhone('555'), isFalse);
    });

    test('successful launch returns true', () async {
      final originalPlatform = UrlLauncherPlatform.instance;
      final fake = _FakeUrlLauncherPlatform();
      UrlLauncherPlatform.instance = fake;
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      addTearDown(() {
        debugDefaultTargetPlatformOverride = null;
        UrlLauncherPlatform.instance = originalPlatform;
      });

      expect(await dialPhone('1201'), isTrue);
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

    test('normalizes an international recipient to canonical digits', () async {
      final originalPlatform = UrlLauncherPlatform.instance;
      final fake = _FakeUrlLauncherPlatform();
      UrlLauncherPlatform.instance = fake;
      addTearDown(() => UrlLauncherPlatform.instance = originalPlatform);

      await openWhatsApp('+972 (50) 123-4567');

      expect(fake.lastLaunchedUrl, 'https://wa.me/972501234567');
    });

    test('adds a URL-encoded message body when provided', () async {
      final originalPlatform = UrlLauncherPlatform.instance;
      final fake = _FakeUrlLauncherPlatform();
      UrlLauncherPlatform.instance = fake;
      addTearDown(() => UrlLauncherPlatform.instance = originalPlatform);

      await openWhatsApp(
        '+972 50 123 4567',
        body: 'I am here.\nhttps://example.com/location',
      );
      final uri = Uri.parse(fake.lastLaunchedUrl!);
      expect(uri.host, 'wa.me');
      expect(uri.path, '/972501234567');
      expect(
        uri.queryParameters['text'],
        'I am here.\nhttps://example.com/location',
      );
    });

    test('failed launch returns false', () async {
      final originalPlatform = UrlLauncherPlatform.instance;
      final fake = _FakeUrlLauncherPlatform()..shouldSucceed = false;
      UrlLauncherPlatform.instance = fake;
      addTearDown(() => UrlLauncherPlatform.instance = originalPlatform);

      expect(await openWhatsApp('972501234567'), isFalse);
      expect(fake.lastLaunchedUrl, 'https://wa.me/972501234567');
    });

    test(
      'rejects domestic and malformed recipients without launching',
      () async {
        final originalPlatform = UrlLauncherPlatform.instance;
        final fake = _FakeUrlLauncherPlatform();
        UrlLauncherPlatform.instance = fake;
        addTearDown(() => UrlLauncherPlatform.instance = originalPlatform);

        expect(await openWhatsApp('0521210105'), isFalse);
        expect(fake.lastLaunchedUrl, isNull);

        expect(await openWhatsApp('+97250invalid'), isFalse);
        expect(fake.lastLaunchedUrl, isNull);
      },
    );

    test('successful launch returns true', () async {
      final originalPlatform = UrlLauncherPlatform.instance;
      final fake = _FakeUrlLauncherPlatform();
      UrlLauncherPlatform.instance = fake;
      addTearDown(() => UrlLauncherPlatform.instance = originalPlatform);

      expect(await openWhatsApp('972501234567'), isTrue);
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

    test('failed launch returns false', () async {
      final originalPlatform = UrlLauncherPlatform.instance;
      final fake = _FakeUrlLauncherPlatform()..shouldSucceed = false;
      UrlLauncherPlatform.instance = fake;
      addTearDown(() => UrlLauncherPlatform.instance = originalPlatform);

      expect(await openSite('https://example.com'), isFalse);
    });

    test('successful launch returns true', () async {
      final originalPlatform = UrlLauncherPlatform.instance;
      final fake = _FakeUrlLauncherPlatform();
      UrlLauncherPlatform.instance = fake;
      addTearDown(() => UrlLauncherPlatform.instance = originalPlatform);

      expect(await openSite('https://example.com/help'), isTrue);
    });
  });

  group('openTextMessage', () {
    setUp(() {
      debugDefaultTargetPlatformOverride = TargetPlatform.windows;
    });

    tearDown(() {
      debugDefaultTargetPlatformOverride = null;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(_smsComposeChannel, null);
    });

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

    test('with spaces and newlines percent-encodes the body query', () async {
      final originalPlatform = UrlLauncherPlatform.instance;
      final fake = _FakeUrlLauncherPlatform();
      UrlLauncherPlatform.instance = fake;
      addTearDown(() => UrlLauncherPlatform.instance = originalPlatform);

      await openTextMessage('741741', body: 'I need help\nPlease call');
      expect(
        fake.lastLaunchedUrl,
        'sms:741741?body=I%20need%20help%0APlease%20call',
      );
    });

    test('whitespace-only body is treated as empty', () async {
      final originalPlatform = UrlLauncherPlatform.instance;
      final fake = _FakeUrlLauncherPlatform();
      UrlLauncherPlatform.instance = fake;
      addTearDown(() => UrlLauncherPlatform.instance = originalPlatform);

      await openTextMessage('555', body: '   ');
      expect(fake.lastLaunchedUrl, 'sms:555');
    });

    test('failed launch returns false', () async {
      final originalPlatform = UrlLauncherPlatform.instance;
      final fake = _FakeUrlLauncherPlatform()..shouldSucceed = false;
      UrlLauncherPlatform.instance = fake;
      addTearDown(() => UrlLauncherPlatform.instance = originalPlatform);

      expect(await openTextMessage('1', body: 'x'), isFalse);
    });

    test('successful launch returns true', () async {
      final originalPlatform = UrlLauncherPlatform.instance;
      final fake = _FakeUrlLauncherPlatform();
      UrlLauncherPlatform.instance = fake;
      addTearDown(() => UrlLauncherPlatform.instance = originalPlatform);

      expect(await openTextMessage('741741', body: 'HOME'), isTrue);
    });

    test(
      'Android invokes the native composer with trimmed arguments',
      () async {
        debugDefaultTargetPlatformOverride = TargetPlatform.android;
        MethodCall? call;
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(_smsComposeChannel, (receivedCall) async {
              call = receivedCall;
              return true;
            });

        expect(
          await openTextMessage(
            '972501234567',
            body: '  I need help\nCall me  ',
          ),
          isTrue,
        );
        expect(call?.method, 'composeSms');
        expect(call?.arguments, <String, String>{
          'number': '972501234567',
          'body': 'I need help\nCall me',
        });
      },
    );

    test(
      'Android returns false when the native composer is unavailable',
      () async {
        debugDefaultTargetPlatformOverride = TargetPlatform.android;
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(
              _smsComposeChannel,
              (call) async => false,
            );

        expect(await openTextMessage('972501234567', body: 'HELP'), isFalse);
      },
    );

    test('Android native composer errors propagate', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
            _smsComposeChannel,
            (call) async => throw PlatformException(code: 'unavailable'),
          );

      await expectLater(
        openTextMessage('972501234567', body: 'HELP'),
        throwsA(isA<PlatformException>()),
      );
    });

    test(
      'iOS invokes the native composer with an empty trimmed body',
      () async {
        debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
        MethodCall? call;
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(_smsComposeChannel, (receivedCall) async {
              call = receivedCall;
              return true;
            });

        expect(await openTextMessage('555', body: '   '), isTrue);
        expect(call?.method, 'composeSms');
        expect(call?.arguments, <String, String>{'number': '555', 'body': ''});
      },
    );

    test('iOS returns false when the native composer is unavailable', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(_smsComposeChannel, (call) async => false);

      expect(await openTextMessage('555', body: 'HELP'), isFalse);
    });

    test('iOS native composer errors propagate', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
            _smsComposeChannel,
            (call) async => throw PlatformException(code: 'unavailable'),
          );

      await expectLater(
        openTextMessage('555', body: 'HELP'),
        throwsA(isA<PlatformException>()),
      );
    });
  });
}
