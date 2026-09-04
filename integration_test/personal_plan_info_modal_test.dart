import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mazilon/l10n/app_localizations.dart';
import 'package:mazilon/pages/PersonalPlan/personal_plan_info_modal.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

Future<void> _waitForNativeWebView(
  WidgetTester tester,
  Finder nativeSurface,
) async {
  for (var attempt = 0; attempt < 50; attempt++) {
    if (nativeSurface.evaluate().isNotEmpty) {
      return;
    }

    await Future<void>.delayed(const Duration(milliseconds: 100));
    await tester.pump();
  }
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'should render the embedded Personal Plan video after Video is selected',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('en'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: const Scaffold(
            body: Align(
              alignment: Alignment.topLeft,
              child: PersonalPlanInfoButton(
                actionKey: Key('integrationPersonalPlanInfoButton'),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      await tester.tap(
        find.byKey(const Key('integrationPersonalPlanInfoButton')),
      );
      await tester.pumpAndSettle();
      expect(find.byType(YoutubePlayer), findsNothing);

      await tester.tap(find.byKey(const Key('personalPlanInfoVideoTab')));
      // In debug mode the package intentionally waits through two post-frame
      // callbacks before creating the Android WebView. Do not settle on its
      // external iframe work.
      await tester.pump();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));

      final Finder playerFinder = find.byType(YoutubePlayer);
      final Finder platformViewFinder = find.byType(PlatformViewLink);
      expect(playerFinder, findsOneWidget);
      expect(
        tester.widget<YoutubePlayer>(playerFinder).controller.key,
        'WCmX1xInZ-4',
      );
      expect(platformViewFinder, findsOneWidget);
      expect(
        tester.widget<PlatformViewLink>(platformViewFinder).viewType,
        'plugins.flutter.io/webview',
      );
      final Finder nativeSurfaceFinder = find.byType(AndroidViewSurface);
      await _waitForNativeWebView(tester, nativeSurfaceFinder);
      expect(nativeSurfaceFinder, findsOneWidget);
      final AndroidViewSurface nativeSurface = tester
          .widget<AndroidViewSurface>(nativeSurfaceFinder);
      expect(nativeSurface.controller.isCreated, isTrue);
      expect(nativeSurface.controller.viewId, greaterThanOrEqualTo(0));

      await tester.tap(find.byKey(const Key('personalPlanInfoTextTab')));
      await tester.pump(const Duration(milliseconds: 250));
      expect(find.byType(YoutubePlayer), findsNothing);

      await tester.tap(find.byKey(const Key('personalPlanInfoCloseButton')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('personalPlanInfoModal')), findsNothing);
    },
  );
}
