import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mazilon/l10n/app_localizations.dart';
import 'package:mazilon/pages/PersonalPlan/personal_plan_info_modal.dart';
import 'package:url_launcher_platform_interface/link.dart';
import 'package:url_launcher_platform_interface/url_launcher_platform_interface.dart';

import '../helpers/widget_test_scaffold.dart';

final class _RecordingUrlLauncherPlatform extends UrlLauncherPlatform {
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
    return true;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    registerTestServices(locale: 'en');
  });

  tearDown(() {
    resetTestServices();
  });

  testWidgets(
    'should expose a localized 48dp action and open readable text by default',
    (tester) async {
      final SemanticsHandle semanticsHandle = tester.ensureSemantics();
      try {
        await pumpWithProviders(
          tester,
          const Scaffold(
            body: Align(
              alignment: Alignment.topLeft,
              child: PersonalPlanInfoButton(
                actionKey: Key('standalonePersonalPlanInfoButton'),
              ),
            ),
          ),
          surfaceSize: const Size(360, 690),
          ignoreOverflow: false,
        );

        final Finder action = find.byKey(
          const Key('standalonePersonalPlanInfoButton'),
        );
        final Finder semanticAction = find.bySemanticsLabel(
          'About this Personal Plan',
        );
        expect(action, findsOneWidget);
        expect(tester.getSize(action), const Size(48, 48));
        expect(semanticAction, findsOneWidget);
        expect(
          tester
              .getSemantics(semanticAction)
              .getSemanticsData()
              .hasAction(SemanticsAction.tap),
          isTrue,
        );

        await tester.tap(action);
        await tester.pumpAndSettle();

        final Finder modal = find.byKey(const Key('personalPlanInfoModal'));
        final AppLocalizations l10n = AppLocalizations.of(
          tester.element(modal),
        )!;

        expect(modal, findsOneWidget);
        expect(find.text(l10n.personalPlanInfoTitle), findsOneWidget);
        expect(find.text(l10n.personalPlanInfoIntro), findsOneWidget);
        expect(find.text(l10n.personalPlanInfoExplanation), findsOneWidget);
        expect(find.text(l10n.personalPlanInfoBulletTriggers), findsOneWidget);
        expect(
          find.text(l10n.personalPlanInfoBulletSelfSoothing),
          findsOneWidget,
        );
        expect(
          find.text(l10n.personalPlanInfoBulletSupportCircle),
          findsOneWidget,
        );
        expect(find.text(l10n.personalPlanInfoRecommendation), findsOneWidget);
        expect(find.text(l10n.personalPlanInfoSpi), findsOneWidget);
        expect(find.text(l10n.personalPlanInfoRpp), findsOneWidget);
        expect(
          find.byKey(const Key('personalPlanInfoTextTab')),
          findsOneWidget,
        );
        expect(
          find.byKey(const Key('personalPlanInfoVideoPlayer')),
          findsNothing,
        );
        expect(
          tester
              .widget<ChoiceChip>(
                find.byKey(const Key('personalPlanInfoTextTab')),
              )
              .selected,
          isTrue,
        );
        expect(
          tester
              .widget<ChoiceChip>(
                find.byKey(const Key('personalPlanInfoVideoTab')),
              )
              .selected,
          isFalse,
        );
        expect(
          tester.getTopLeft(find.text('\u2022').first).dx,
          lessThan(
            tester
                .getTopLeft(find.text(l10n.personalPlanInfoBulletTriggers))
                .dx,
          ),
        );

        await tester.tap(find.byKey(const Key('personalPlanInfoCloseButton')));
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('personalPlanInfoModal')), findsNothing);
      } finally {
        semanticsHandle.dispose();
      }
    },
  );

  testWidgets('should launch the supplied SPI and RPP HTTPS resources', (
    tester,
  ) async {
    final UrlLauncherPlatform originalPlatform = UrlLauncherPlatform.instance;
    final _RecordingUrlLauncherPlatform fakePlatform =
        _RecordingUrlLauncherPlatform();
    UrlLauncherPlatform.instance = fakePlatform;
    addTearDown(() => UrlLauncherPlatform.instance = originalPlatform);

    await pumpWithProviders(
      tester,
      const Scaffold(
        body: PersonalPlanInfoButton(
          actionKey: Key('linkTestPersonalPlanInfoButton'),
        ),
      ),
      surfaceSize: const Size(360, 690),
    );

    await tester.tap(find.byKey(const Key('linkTestPersonalPlanInfoButton')));
    await tester.pumpAndSettle();

    final Finder spiLink = find.byKey(const Key('personalPlanInfoSpiLink'));
    final Finder rppLink = find.byKey(const Key('personalPlanInfoRppLink'));
    await tester.ensureVisible(spiLink);
    await tester.tap(spiLink);
    await tester.pump();
    expect(fakePlatform.lastLaunchedUrl, 'https://suicidesafetyplan.com/');

    await tester.ensureVisible(rppLink);
    await tester.tap(rppLink);
    await tester.pump();
    expect(
      fakePlatform.lastLaunchedUrl,
      'https://www.heretohelp.bc.ca/infosheet/'
      'preventing-relapse-of-a-mental-illness',
    );
  });

  testWidgets(
    'should preserve RTL direction and a scrollable dialog for Arabic on a small screen',
    (tester) async {
      await pumpWithProviders(
        tester,
        const Scaffold(
          body: PersonalPlanInfoButton(
            actionKey: Key('arabicPersonalPlanInfoButton'),
          ),
        ),
        locale: const Locale('ar'),
        surfaceSize: const Size(320, 480),
        ignoreOverflow: false,
      );

      await tester.tap(find.byKey(const Key('arabicPersonalPlanInfoButton')));
      await tester.pumpAndSettle();

      final Finder modal = find.byKey(const Key('personalPlanInfoModal'));
      final BuildContext modalContext = tester.element(modal);
      final AppLocalizations l10n = AppLocalizations.of(modalContext)!;
      final Finder modalScrollView = find.descendant(
        of: modal,
        matching: find.byType(SingleChildScrollView),
      );

      expect(Directionality.of(modalContext), TextDirection.rtl);
      expect(l10n.personalPlanInfoTitle, 'خطتي الشخصية');
      expect(find.text(l10n.personalPlanInfoTitle), findsOneWidget);
      expect(find.byTooltip(l10n.personalPlanInfoClose), findsOneWidget);
      expect(modalScrollView, findsOneWidget);
      expect(
        tester.getTopLeft(find.text('\u2022').first).dx,
        greaterThan(
          tester.getTopLeft(find.text(l10n.personalPlanInfoBulletTriggers)).dx,
        ),
      );

      await tester.drag(modalScrollView, const Offset(0, -250));
      await tester.pump();

      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('should retain the active dark theme in the info dialog', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        home: const Scaffold(
          body: PersonalPlanInfoButton(
            actionKey: Key('darkPersonalPlanInfoButton'),
          ),
        ),
      ),
    );
    await tester.pump();

    await tester.tap(find.byKey(const Key('darkPersonalPlanInfoButton')));
    await tester.pumpAndSettle();

    final Finder modal = find.byKey(const Key('personalPlanInfoModal'));
    expect(Theme.of(tester.element(modal)).brightness, Brightness.dark);
    expect(tester.takeException(), isNull);
  });
}
