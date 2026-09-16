import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mazilon/features/remember_to_breathe/data/breathing_photo_importer.dart';
import 'package:mazilon/features/remember_to_breathe/data/breathing_store.dart';
import 'package:mazilon/features/remember_to_breathe/ui/breathing_page.dart';
import 'package:mazilon/features/remember_to_breathe/ui/breathing_view_model.dart';
import 'package:mazilon/features/remember_to_breathe/ui/breathing_view_state.dart';
import 'package:mazilon/menu.dart';
import 'package:mazilon/pages/home.dart';
import 'package:mazilon/pages/phone.dart';
import 'package:mazilon/util/Form/formPagePhoneModel.dart';
import 'package:mazilon/util/appInformation.dart';
import 'package:mazilon/util/userInformation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';

import '../../../MenuTest/test_data.dart';
import '../../../helpers/widget_test_scaffold.dart';

void main() {
  group('BreathingMenu', () {
    late TestServiceLocators services;
    late BreathingStore store;
    late UserInformation user;
    late AppInformation app;
    late PhonePageData phoneData;
    late List<BreathingViewModel> visits;
    Duration elapsed = Duration.zero;
    int ids = 0;

    setUp(() async {
      await GetIt.instance.reset();
      services = registerTestServices();
      user = UserInformation()
        ..gender = 'male'
        ..localeName = 'en';
      app = AppInformation();
      getData(app);
      phoneData = PhonePageData(
        key: 'phonePageData',
        header: 'Emergency contacts',
        subTitle: '',
        midTitle: '',
        phoneNameTitle: 'Name',
        phoneNumberTitle: 'Phone',
        phoneNames: [],
        phoneNumbers: [],
        savedPhoneNames: [],
        savedPhoneNumbers: [],
        phoneDescription: [],
      );
      visits = [];
      elapsed = Duration.zero;
      ids = 0;
      PackageInfo.setMockInitialValues(
        appName: 'Mazilon',
        packageName: 'mazilon',
        version: '1.0.0',
        buildNumber: '1',
        buildSignature: '',
      );
    });

    tearDown(() async => GetIt.instance.reset());

    BreathingViewModel createVisit() {
      final model = BreathingViewModel(
        store,
        photoImporter: BreathingPhotoImporter(services.picker),
        monotonicElapsed: () => elapsed,
        now: () => DateTime.utc(2026, 9, 13).add(elapsed),
        sessionId: () => 'visit-${++ids}',
      );
      visits.add(model);
      return model;
    }

    Future<void> pumpMenu(WidgetTester tester, {bool composed = true}) async {
      store = BreathingStore(services.memory);
      await pumpWithProviders(
        tester,
        ChangeNotifierProvider<PhonePageData>.value(
          value: phoneData,
          child: Menu(
            phonePageData: phoneData,
            hasFilled: false,
            changeLocale: (String _) {},
            breathingViewModelFactory: composed ? createVisit : null,
          ),
        ),
        userInformation: user,
        appInformation: app,
        surfaceSize: const Size(420, 900),
        ignoreOverflow: false,
      );
      await tester.pumpAndSettle();
    }

    Future<void> tap(WidgetTester tester, String key) async {
      final target = find.byKey(Key(key));
      await tester.ensureVisible(target);
      await tester.tap(target);
      await tester.pump();
      await tester.pump();
    }

    Future<void> openBreathing(WidgetTester tester) async {
      await tap(tester, 'mainMenuButton');
      await tester.pumpAndSettle();
      await tap(tester, 'mainMenuBreathing');
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump();
      expect(find.byType(BreathingPage), findsOneWidget);
      expect(visits.last.isReady, isTrue, reason: '${visits.last.error}');
    }

    testWidgets('should expose composed breathing from the actual main menu', (
      tester,
    ) async {
      await pumpMenu(tester);
      expect(find.byType(Home), findsOneWidget);
      await openBreathing(tester);
      expect(visits, hasLength(1));
      expect(find.byKey(const Key('bottomNavHome')), findsOneWidget);
      await tap(tester, 'breathingQuickStart');
      await tap(tester, 'breathingSkipRating');
      expect(find.byKey(const Key('bottomNavHome')), findsNothing);
      expect(find.byType(FloatingActionButton), findsOneWidget);
      await tester.binding.handlePopRoute();
      await tester.pump();
      expect(find.byKey(const Key('breathingContinue')), findsOneWidget);
      expect(find.byType(BreathingPage), findsOneWidget);
      await tap(tester, 'breathingEnd');
      expect(visits.single.screen, BreathingScreen.result);
      expect(find.byKey(const Key('bottomNavHome')), findsNothing);
      await tap(tester, 'breathingDone');
      expect(find.byKey(const Key('bottomNavHome')), findsOneWidget);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.byType(Home), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
      'should navigate SOS immediately while a paused partial save is pending',
      (tester) async {
        await pumpMenu(tester);
        await openBreathing(tester);
        await tap(tester, 'breathingQuickStart');
        await tap(tester, 'breathingSkipRating');
        elapsed += const Duration(seconds: 6);
        visits.single.refresh();
        await tester.pump();
        await tap(tester, 'breathingPause');
        final saving = Completer<void>();
        final release = Completer<void>();
        services.memory.onPersist = (key, _, _) async {
          if (key == BreathingStore.snapshotKey) {
            saving.complete();
            await release.future;
          }
        };
        await tester.tap(find.byType(FloatingActionButton));
        await tester.pump();
        await tester.pump();
        expect(find.byType(PhonePage), findsOneWidget);
        expect(find.byType(BreathingPage), findsNothing);
        expect(find.byKey(const Key('bottomNavHome')), findsOneWidget);
        await saving.future;
        // The old page must not resume when an app lifecycle callback arrives.
        tester.binding.handleAppLifecycleStateChanged(
          AppLifecycleState.inactive,
        );
        tester.binding.handleAppLifecycleStateChanged(
          AppLifecycleState.resumed,
        );
        elapsed += const Duration(minutes: 1);
        visits.single.refresh();
        await tester.pump();
        expect(find.byType(PhonePage), findsOneWidget);
        release.complete();
        await tester.pumpAndSettle();
        services.memory.onPersist = null;
        expect((await store.load()).sessions.single.completedCycles, 1);
        await tap(tester, 'bottomNavHome');
        await openBreathing(tester);
        expect(visits, hasLength(2));
        expect(visits.last.completedCycles, 0);
        expect(visits.last.screen, BreathingScreen.landing);
        expect(visits.last.history, hasLength(1));
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'should ignore a queued fullscreen callback after emergency departure',
      (tester) async {
        await pumpMenu(tester);
        await openBreathing(tester);
        await tap(tester, 'breathingQuickStart');
        // Queue fullscreen synchronization, then leave before the next frame.
        await tester.tap(find.byKey(const Key('breathingSkipRating')));
        await tester.tap(find.byType(FloatingActionButton));
        await tester.pumpAndSettle();
        expect(find.byType(PhonePage), findsOneWidget);
        expect(find.byKey(const Key('bottomNavHome')), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets('should keep lightweight uncomposed Menu hosts working', (
      tester,
    ) async {
      await pumpMenu(tester, composed: false);
      await tap(tester, 'mainMenuButton');
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('mainMenuBreathing')), findsNothing);
      expect(find.byType(Home), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
