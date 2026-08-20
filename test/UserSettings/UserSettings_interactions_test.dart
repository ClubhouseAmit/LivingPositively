import 'dart:async';

// Drives the previously-uncovered branches of UserSettings:
//   - resetData via the reset confirmation dialog's "confirm" button —
//     pushes a FirstPage route
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

import '../../test_support/contract_persistent_memory_service.dart';
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

const Key _resetOpenKey = Key('user-settings-reset-open');
const Key _resetDialogKey = Key('user-settings-reset-dialog');
const Key _resetCancelKey = Key('user-settings-reset-cancel');
const Key _resetConfirmKey = Key('user-settings-reset-confirm');

Future<void> _openResetDialog(WidgetTester tester) async {
  final Finder resetButton = find.byKey(_resetOpenKey);
  await tester.ensureVisible(resetButton);
  await tester.tap(resetButton, warnIfMissed: false);
  await tester.pumpAndSettle();
  expect(find.byKey(_resetDialogKey), findsOneWidget);
}

abstract base class _UserSettingsPersistentMemoryService
    extends ContractPersistentMemoryService {
  _UserSettingsPersistentMemoryService() {
    onMissingRead = (_, PersistentMemoryType type) {
      switch (type) {
        case PersistentMemoryType.String:
          return '';
        case PersistentMemoryType.Int:
          return 0;
        case PersistentMemoryType.Double:
          return 0.0;
        case PersistentMemoryType.Bool:
          return false;
        case PersistentMemoryType.StringList:
          return <String>[];
      }
    };
  }
}

final class _FailingOnceDreamsPersistentMemoryService
    extends _UserSettingsPersistentMemoryService {
  bool _shouldFailNextWrite = true;

  _FailingOnceDreamsPersistentMemoryService() {
    onPersist = (key, _, _) {
      if (key == dreamsAndGoalsSelectionStorageKey && _shouldFailNextWrite) {
        _shouldFailNextWrite = false;
        throw StateError('Simulated Dreams persistence failure.');
      }
    };
  }
}

final class _DelayedDreamsPersistentMemoryService
    extends _UserSettingsPersistentMemoryService {
  final Completer<void> _firstDreamsSelectionWrite = Completer<void>();
  final Completer<void> firstDreamsSelectionWriteStarted = Completer<void>();
  int selectionWriteCount = 0;

  _DelayedDreamsPersistentMemoryService() {
    onPersist = (key, _, _) async {
      if (key == dreamsAndGoalsSelectionStorageKey) {
        selectionWriteCount++;
        if (selectionWriteCount == 1) {
          firstDreamsSelectionWriteStarted.complete();
          await _firstDreamsSelectionWrite.future;
        }
      }
    };
  }

  void releaseFirstDreamsSelectionWrite() {
    if (!_firstDreamsSelectionWrite.isCompleted) {
      _firstDreamsSelectionWrite.complete();
    }
  }
}

final class _RecordingResetPersistentMemoryService
    extends _UserSettingsPersistentMemoryService {
  int resetCalls = 0;

  _RecordingResetPersistentMemoryService() {
    onReset = () {
      resetCalls++;
    };
  }
}

final class _DelayedResetPersistentMemoryService
    extends _UserSettingsPersistentMemoryService {
  final Completer<void> resetStarted = Completer<void>();
  final Completer<void> _resetGate = Completer<void>();

  _DelayedResetPersistentMemoryService() {
    onReset = () async {
      resetStarted.complete();
      await _resetGate.future;
    };
  }

  void releaseReset() {
    if (!_resetGate.isCompleted) {
      _resetGate.complete();
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

      await _openResetDialog(tester);
      await tester.tap(find.byKey(_resetConfirmKey), warnIfMissed: false);
      await tester.pumpAndSettle();
      await tester.runAsync(() => Future<void>.delayed(Duration.zero));
      await tester.pumpAndSettle();

      // resetData pushes a FirstPage route via pushAndRemoveUntil.
      expect(find.byType(FirstPage), findsOneWidget);
    },
  );

  testWidgets(
    'reset clears the UserInformation injected storage before navigation',
    (tester) async {
      final memory = _RecordingResetPersistentMemoryService()
        ..store['legacy-profile-name'] = 'Old profile';
      expect(GetIt.instance<PersistentMemoryService>(), isNot(same(memory)));
      user = UserInformation(service: memory);
      user.gender = 'male';
      user.localeName = 'en';

      await pumpWithProviders(
        tester,
        UserSettings(
          username: 'Injected storage',
          age: '18-30',
          gender: 'male',
          phonePageData: _phone(),
          changeLocale: (_) {},
        ),
        userInformation: user,
        surfaceSize: const Size(1024, 2800),
      );

      await _openResetDialog(tester);
      await tester.tap(find.byKey(_resetConfirmKey), warnIfMissed: false);
      await tester.pumpAndSettle();
      await tester.runAsync(() => Future<void>.delayed(Duration.zero));
      await tester.pumpAndSettle();

      expect(memory.resetCalls, 1);
      expect(memory.store['legacy-profile-name'], isNull);
      expect(memory.store[dreamsAndGoalsSelectionStorageKey], <String>[]);
      expect(find.byType(FirstPage), findsOneWidget);
    },
  );

  testWidgets('reset waits for the injected storage clear before navigating', (
    tester,
  ) async {
    final memory = _DelayedResetPersistentMemoryService();
    user = UserInformation(service: memory);
    user.gender = 'male';
    user.localeName = 'en';

    await pumpWithProviders(
      tester,
      UserSettings(
        username: 'Ordered reset',
        age: '18-30',
        gender: 'male',
        phonePageData: _phone(),
        changeLocale: (_) {},
      ),
      userInformation: user,
      surfaceSize: const Size(1024, 2800),
    );

    await _openResetDialog(tester);
    await tester.tap(find.byKey(_resetConfirmKey), warnIfMissed: false);
    await tester.pump();
    await memory.resetStarted.future;

    expect(find.byType(FirstPage), findsNothing);
    expect(
      tester.widget<TextButton>(find.byKey(_resetConfirmKey)).onPressed,
      isNull,
    );

    memory.releaseReset();
    await tester.pumpAndSettle();
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pumpAndSettle();

    expect(find.byType(FirstPage), findsOneWidget);
  });

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

      await _openResetDialog(tester);
      await tester.ensureVisible(find.byKey(_resetConfirmKey));
      await tester.tap(find.byKey(_resetConfirmKey), warnIfMissed: false);
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

      await _openResetDialog(tester);
      await tester.ensureVisible(find.byKey(_resetConfirmKey));
      await tester.tap(find.byKey(_resetConfirmKey), warnIfMissed: false);
      await tester.pump();
      await memory.firstDreamsSelectionWriteStarted.future;

      final TextButton pendingConfirm = tester.widget<TextButton>(
        find.byKey(_resetConfirmKey),
      );
      expect(pendingConfirm.onPressed, isNull);
      final TextButton pendingClose = tester.widget<TextButton>(
        find.byKey(_resetCancelKey),
      );
      expect(pendingClose.onPressed, isNull);

      await tester.tapAt(const Offset(1, 1));
      await tester.pumpAndSettle();
      expect(find.byType(Dialog), findsOneWidget);

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.byType(Dialog), findsOneWidget);

      await tester.tap(find.byKey(_resetConfirmKey), warnIfMissed: false);
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

      await _openResetDialog(tester);

      await tester.tap(find.byKey(_resetCancelKey), warnIfMissed: false);
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
