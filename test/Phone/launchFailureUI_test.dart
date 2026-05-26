// Widget tests for the launch-failure UI introduced in ADR-005 §A.1.
// Covers the path where `launchUrl` returns false from inside both
// `phoneContact` (personal contacts) and `EmergencyDialogBox` (system
// emergency numbers): a SnackBar with localized failure copy must render,
// and a "Copy number" SnackBarAction must be present when there is a
// number to copy.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mazilon/global_enums.dart';
import 'package:mazilon/l10n/app_localizations.dart';
import 'package:mazilon/util/Phone/emergencyDialogBox.dart';
import 'package:mazilon/util/Phone/phoneTextAndIcon.dart';
import 'package:mazilon/util/appInformation.dart';
import 'package:mazilon/util/persistent_memory_service.dart';
import 'package:mazilon/util/userInformation.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher_platform_interface/link.dart';
import 'package:url_launcher_platform_interface/url_launcher_platform_interface.dart';

class _FailingUrlLauncherPlatform extends UrlLauncherPlatform {
  String? lastLaunchedUrl;

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
    return false;
  }
}

class _FakePersistentMemoryService implements PersistentMemoryService {
  @override
  Future<dynamic> getItem(String key, PersistentMemoryType type) async => null;

  @override
  Future<void> reset() async {}

  @override
  Future<void> setItem(
      String key, PersistentMemoryType type, dynamic value) async {}
}

Widget _wrapForPhoneContact(Widget Function(BuildContext) build) {
  return MaterialApp(
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    locale: const Locale('en'),
    home: ScreenUtilInit(
      designSize: const Size(360, 690),
      // Build inside ScreenUtilInit's builder so `.sp` works.
      builder: (context, _) => Scaffold(body: Builder(builder: build)),
    ),
  );
}

Widget _wrapForEmergencyDialog(EmergencyDialogBox dialog) {
  final userInfo = UserInformation(
    gender: 'male',
    service: _FakePersistentMemoryService(),
  );
  final appInfo = AppInformation();
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<UserInformation>.value(value: userInfo),
      ChangeNotifierProvider<AppInformation>.value(value: appInfo),
    ],
    child: MaterialApp(
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      locale: const Locale('en'),
      // Scaffold ancestor so the dialog's snackbar has a ScaffoldMessenger.
      home: ScreenUtilInit(
        designSize: const Size(360, 690),
        builder: (_, __) => Scaffold(body: dialog),
      ),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('phoneContact failure UI', () {
    testWidgets(
        'on dial failure shows snackbar with localized message + Copy number action',
        (tester) async {
      final originalPlatform = UrlLauncherPlatform.instance;
      final fake = _FailingUrlLauncherPlatform();
      UrlLauncherPlatform.instance = fake;
      addTearDown(() => UrlLauncherPlatform.instance = originalPlatform);

      await tester.pumpWidget(
        _wrapForPhoneContact((_) => phoneContact('555-1234', 'Mom')),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.phone));
      // The async dial completes on the next microtask; pump once for the
      // SnackBar transition, then settle.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(fake.lastLaunchedUrl, 'tel:555-1234');
      expect(find.byType(SnackBar), findsOneWidget);
      expect(
          find.text("Couldn't open the dialer for 555-1234"), findsOneWidget);
      expect(
          find.widgetWithText(SnackBarAction, 'Copy number'), findsOneWidget);
    });

    testWidgets(
        'tapping Copy number writes to clipboard and shows confirmation toast',
        (tester) async {
      final originalPlatform = UrlLauncherPlatform.instance;
      final fake = _FailingUrlLauncherPlatform();
      UrlLauncherPlatform.instance = fake;
      addTearDown(() => UrlLauncherPlatform.instance = originalPlatform);

      // Intercept Clipboard.setData so we don't need a platform channel.
      String? clipboardWrite;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, (call) async {
        if (call.method == 'Clipboard.setData') {
          clipboardWrite = (call.arguments as Map)['text'] as String?;
        }
        return null;
      });
      addTearDown(() {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(SystemChannels.platform, null);
      });

      await tester.pumpWidget(
        _wrapForPhoneContact((_) => phoneContact('555-7890', 'Crisis line')),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.phone));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      // SnackBar floats below the visible viewport in test mode; tap by
      // finder fails hit-testing. Invoke the action's onPressed callback
      // directly — same code path, no gesture machinery.
      final actionFinder = find.widgetWithText(SnackBarAction, 'Copy number');
      expect(actionFinder, findsOneWidget);
      final action = tester.widget<SnackBarAction>(actionFinder);
      action.onPressed();
      // Flush the async chain inside onPressed (Clipboard write + second
      // showSnackBar) before asserting the follow-up toast renders.
      await tester.pumpAndSettle();

      expect(clipboardWrite, '555-7890');
      expect(find.text('Number copied'), findsOneWidget);
    });
  });

  group('EmergencyDialogBox failure UI', () {
    testWidgets('dial failure surfaces the same snackbar as phoneContact',
        (tester) async {
      final originalPlatform = UrlLauncherPlatform.instance;
      final fake = _FailingUrlLauncherPlatform();
      UrlLauncherPlatform.instance = fake;
      addTearDown(() => UrlLauncherPlatform.instance = originalPlatform);

      await tester.pumpWidget(
        _wrapForEmergencyDialog(
          const EmergencyDialogBox(
            number: '988',
            whatsappNumber: '',
            link: '',
            hasWhatsApp: false,
            hasLink: false,
            canCall: true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.phone));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(fake.lastLaunchedUrl, 'tel:988');
      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.text("Couldn't open the dialer for 988"), findsOneWidget);
      expect(
          find.widgetWithText(SnackBarAction, 'Copy number'), findsOneWidget);
    });

    testWidgets(
        'WhatsApp failure shows non-call message and still offers Copy number for the WhatsApp number',
        (tester) async {
      final originalPlatform = UrlLauncherPlatform.instance;
      final fake = _FailingUrlLauncherPlatform();
      UrlLauncherPlatform.instance = fake;
      addTearDown(() => UrlLauncherPlatform.instance = originalPlatform);

      await tester.pumpWidget(
        _wrapForEmergencyDialog(
          const EmergencyDialogBox(
            number: '',
            whatsappNumber: '972501234567',
            link: '',
            hasWhatsApp: true,
            hasLink: false,
            canCall: false,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.chat));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(fake.lastLaunchedUrl, 'https://wa.me/972501234567');
      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.text("Couldn't open the app"), findsOneWidget);
      // WhatsApp uses the non-call message; Copy number IS still offered
      // because the whatsappNumber is non-empty.
      expect(
          find.widgetWithText(SnackBarAction, 'Copy number'), findsOneWidget);
    });

    testWidgets('link failure has no Copy number action (no number to copy)',
        (tester) async {
      final originalPlatform = UrlLauncherPlatform.instance;
      final fake = _FailingUrlLauncherPlatform();
      UrlLauncherPlatform.instance = fake;
      addTearDown(() => UrlLauncherPlatform.instance = originalPlatform);

      await tester.pumpWidget(
        _wrapForEmergencyDialog(
          const EmergencyDialogBox(
            number: '',
            whatsappNumber: '',
            link: 'https://example.com/help',
            hasWhatsApp: false,
            hasLink: true,
            canCall: false,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.language));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(fake.lastLaunchedUrl, 'https://example.com/help');
      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.text("Couldn't open the app"), findsOneWidget);
      expect(find.byType(SnackBarAction), findsNothing);
    });
  });
}
