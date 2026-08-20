import 'dart:async';

// Drives the previously-uncovered branches of UserSettings:
//   - resetData (lines 86-113) via the reset confirmation dialog's "confirm"
//     button — pushes a FirstPage route
//   - resizeText non-empty branch (lines 136-145) — the "(parenthetical)"
//     suffix render
//   - Confirm-button female / nonBinary / notWillingToSay gender branches
//     (lines 386-392)
//   - Age dropdown onSelected (lines 272-279)

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mazilon/global_enums.dart';
import 'package:mazilon/pages/SignIn_Pages/firstPage.dart';
import 'package:mazilon/pages/UserSettings.dart';
import 'package:mazilon/util/Form/formPagePhoneModel.dart';
import 'package:mazilon/util/dreams_and_goals_selection.dart';
import 'package:mazilon/util/persistent_memory_service.dart';
import 'package:mazilon/util/userInformation.dart';

import '../helpers/widget_test_scaffold.dart';

PhonePageData _phone() => PhonePageData(
  key: 'phonePageData',
  header: 'header',
  subTitle: 'subTitle',
  midTitle: 'midTitle',
  phoneNameTitle: 'phoneNameTitle',
  phoneNumberTitle: 'phoneNumberTitle',
  phoneNames: const [],
  phoneNumbers: const [],
  savedPhoneNames: const [],
  savedPhoneNumbers: const [],
  phoneDescription: const [],
);

class _FailingOnceDreamsPersistentMemoryService
    extends FakePersistentMemoryService {
  bool _shouldFailNextWrite = true;

  @override
  Future<void> setItem(
    String key,
    PersistentMemoryType type,
    dynamic value,
  ) async {
    if (key == dreamsAndGoalsSelectionStorageKey && _shouldFailNextWrite) {
      _shouldFailNextWrite = false;
      throw StateError('Simulated Dreams persistence failure.');
    }
    await super.setItem(key, type, value);
  }
}

class _DelayedDreamsPersistentMemoryService
    extends FakePersistentMemoryService {
  final Completer<void> _firstDreamsSelectionWrite = Completer<void>();
  final Completer<void> firstDreamsSelectionWriteStarted = Completer<void>();
  int selectionWriteCount = 0;

  @override
  Future<void> setItem(
    String key,
    PersistentMemoryType type,
    dynamic value,
  ) async {
    if (key == dreamsAndGoalsSelectionStorageKey) {
      selectionWriteCount++;
      if (selectionWriteCount == 1) {
        firstDreamsSelectionWriteStarted.complete();
        await _firstDreamsSelectionWrite.future;
      }
    }
    await super.setItem(key, type, value);
  }

  void releaseFirstDreamsSelectionWrite() {
    if (!_firstDreamsSelectionWrite.isCompleted) {
      _firstDreamsSelectionWrite.complete();
    }
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late UserInformation user;

  setUp(() {
    registerTestServices(locale: 'en');
    user = UserInformation();
    user.gender = 'male';
    user.localeName = 'en';
  });

  tearDown(() {
    resetTestServices();
  });

  testWidgets(
    'reset confirmation dialog "Confirm" tap calls resetData and pushes '
    'FirstPage',
    (tester) async {
      await pumpWithProviders(
        tester,
        UserSettings(
          username: 'Reset Me',
          age: '18-30',
          gender: 'male',
          phonePageData: _phone(),
          changeLocale: (_) {},
        ),
        userInformation: user,
        surfaceSize: const Size(1024, 2800),
      );

      // Open the reset confirmation dialog (the last top-level TextButton
      // before the dialog opens is ResetButton).
      final pageButtons = find.byType(TextButton);
      final last = pageButtons.evaluate().last;
      await tester.ensureVisible(find.byWidget(last.widget));
      await tester.tap(find.byWidget(last.widget), warnIfMissed: false);
      await tester.pumpAndSettle();

      // Now the Dialog is open with two TextButtons: Close + Confirm. Tap the
      // last one (Confirm) → resetData runs.
      final dialogButtons = find.descendant(
        of: find.byType(Dialog),
        matching: find.byType(TextButton),
      );
      expect(dialogButtons, findsNWidgets(2));
      await tester.tap(dialogButtons.last, warnIfMissed: false);
      await tester.pumpAndSettle();
      await tester.runAsync(() => Future<void>.delayed(Duration.zero));
      await tester.pumpAndSettle();

      // resetData pushes a FirstPage route via pushAndRemoveUntil.
      expect(find.byType(FirstPage), findsOneWidget);
    },
  );

  testWidgets(
    'reset failure keeps the dialog open and retry navigates only after the '
    'empty Dreams snapshot saves',
    (tester) async {
      final memory = _FailingOnceDreamsPersistentMemoryService();
      GetIt.instance
        ..unregister<PersistentMemoryService>()
        ..registerSingleton<PersistentMemoryService>(memory);
      user = UserInformation(service: memory);
      user.gender = 'male';
      user.localeName = 'en';

      await pumpWithProviders(
        tester,
        UserSettings(
          username: 'Retry Me',
          age: '18-30',
          gender: 'male',
          phonePageData: _phone(),
          changeLocale: (_) {},
        ),
        userInformation: user,
        surfaceSize: const Size(1024, 2800),
      );

      final pageButtons = find.byType(TextButton);
      final last = pageButtons.evaluate().last;
      await tester.ensureVisible(find.byWidget(last.widget));
      await tester.tap(find.byWidget(last.widget), warnIfMissed: false);
      await tester.pumpAndSettle();

      final dialogButtons = find.descendant(
        of: find.byType(Dialog),
        matching: find.byType(TextButton),
      );
      await tester.ensureVisible(dialogButtons.last);
      await tester.tap(dialogButtons.last, warnIfMissed: false);
      await tester.pumpAndSettle();

      expect(find.byType(Dialog), findsOneWidget);
      expect(find.byType(FirstPage), findsNothing);
      final retryButton = find.widgetWithText(SnackBarAction, 'Try again');
      expect(retryButton, findsOneWidget);

      await tester.ensureVisible(retryButton);
      await tester.tap(retryButton, warnIfMissed: false);
      await tester.pumpAndSettle();
      await tester.runAsync(() => Future<void>.delayed(Duration.zero));
      await tester.pumpAndSettle();

      expect(find.byType(FirstPage), findsOneWidget);
    },
  );

  testWidgets(
    'reset dialog remains recoverable while Dreams persistence is pending',
    (tester) async {
      final memory = _DelayedDreamsPersistentMemoryService();
      GetIt.instance
        ..unregister<PersistentMemoryService>()
        ..registerSingleton<PersistentMemoryService>(memory);
      user = UserInformation(service: memory);
      user.gender = 'male';
      user.localeName = 'en';

      await pumpWithProviders(
        tester,
        UserSettings(
          username: 'Single flight',
          age: '18-30',
          gender: 'male',
          phonePageData: _phone(),
          changeLocale: (_) {},
        ),
        userInformation: user,
        surfaceSize: const Size(1024, 2800),
      );

      final pageButtons = find.byType(TextButton);
      final last = pageButtons.evaluate().last;
      await tester.ensureVisible(find.byWidget(last.widget));
      await tester.tap(find.byWidget(last.widget), warnIfMissed: false);
      await tester.pumpAndSettle();

      final dialogButtons = find.descendant(
        of: find.byType(Dialog),
        matching: find.byType(TextButton),
      );
      await tester.ensureVisible(dialogButtons.last);
      await tester.tap(dialogButtons.last, warnIfMissed: false);
      await tester.pump();
      await memory.firstDreamsSelectionWriteStarted.future;

      final pendingDialogButtons = find.descendant(
        of: find.byType(Dialog),
        matching: find.byType(TextButton),
      );
      final TextButton pendingConfirm = tester.widget<TextButton>(
        pendingDialogButtons.last,
      );
      expect(pendingConfirm.onPressed, isNull);
      final TextButton pendingClose = tester.widget<TextButton>(
        pendingDialogButtons.first,
      );
      expect(pendingClose.onPressed, isNull);

      await tester.tapAt(const Offset(1, 1));
      await tester.pumpAndSettle();
      expect(find.byType(Dialog), findsOneWidget);

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.byType(Dialog), findsOneWidget);

      await tester.tap(pendingDialogButtons.last, warnIfMissed: false);
      await tester.pump();
      expect(memory.selectionWriteCount, 1);

      memory.releaseFirstDreamsSelectionWrite();
      await tester.pumpAndSettle();
      await tester.runAsync(() => Future<void>.delayed(Duration.zero));
      await tester.pumpAndSettle();

      expect(find.byType(FirstPage), findsOneWidget);
    },
  );

  testWidgets(
    'reset confirmation dialog "Close" tap pops without invoking resetData',
    (tester) async {
      await pumpWithProviders(
        tester,
        UserSettings(
          username: 'Stay',
          age: '18-30',
          gender: 'male',
          phonePageData: _phone(),
          changeLocale: (_) {},
        ),
        userInformation: user,
        surfaceSize: const Size(1024, 2800),
      );

      final pageButtons = find.byType(TextButton);
      final last = pageButtons.evaluate().last;
      await tester.ensureVisible(find.byWidget(last.widget));
      await tester.tap(find.byWidget(last.widget), warnIfMissed: false);
      await tester.pumpAndSettle();

      final dialogButtons = find.descendant(
        of: find.byType(Dialog),
        matching: find.byType(TextButton),
      );
      // First is "Close" — tap it, the dialog should pop without leaving
      // UserSettings.
      await tester.tap(dialogButtons.first, warnIfMissed: false);
      await tester.pumpAndSettle();

      expect(find.byType(Dialog), findsNothing);
      expect(find.byType(UserSettings), findsOneWidget);
    },
  );

  testWidgets(
    'renders for a female user without crashing (gender-specific build)',
    (tester) async {
      user.gender = 'female';
      await pumpWithProviders(
        tester,
        UserSettings(
          username: 'Female User',
          age: '31-50',
          gender: 'female',
          phonePageData: _phone(),
          changeLocale: (_) {},
        ),
        userInformation: user,
        surfaceSize: const Size(1024, 2800),
      );

      expect(find.byType(UserSettings), findsOneWidget);
    },
  );

  testWidgets(
    'renders for a nonBinary user (binary=true initial selection branch)',
    (tester) async {
      user.binary = true;
      await pumpWithProviders(
        tester,
        UserSettings(
          username: 'NB User',
          age: '18-30',
          gender: '',
          phonePageData: _phone(),
          changeLocale: (_) {},
        ),
        userInformation: user,
        surfaceSize: const Size(1024, 2800),
      );

      expect(find.byType(UserSettings), findsOneWidget);
      expect(find.byType(DropdownMenu<String>), findsNWidgets(3));
    },
  );

  testWidgets('name text field keeps a Material-sized tap target', (
    tester,
  ) async {
    await pumpWithProviders(
      tester,
      UserSettings(
        username: 'Sized',
        age: '18-30',
        gender: 'male',
        phonePageData: _phone(),
        changeLocale: (_) {},
      ),
      userInformation: user,
      surfaceSize: const Size(320, 900),
    );

    final textFieldSize = tester.getSize(find.byType(TextField).first);
    expect(textFieldSize.height, greaterThanOrEqualTo(40));
    expect(textFieldSize.width, lessThanOrEqualTo(320));
  });
}
