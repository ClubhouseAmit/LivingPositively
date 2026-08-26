import 'dart:async';
import 'dart:convert';

// Drives the previously-uncovered branches of UserSettings:
//   - resetData (lines 86-113) via the reset confirmation dialog's "confirm"
//     button — pushes a FirstPage route
//   - resizeText non-empty branch (lines 136-145) — the "(parenthetical)"
//     suffix render
//   - Confirm-button female / nonBinary / notWillingToSay gender branches
//     (lines 386-392)
//   - Age dropdown onSelected (lines 272-279)

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get_it/get_it.dart';
import 'package:http/http.dart' as http;
import 'package:mazilon/global_enums.dart';
import 'package:mazilon/pages/FeelGood/image_picker_service_impl.dart';
import 'package:mazilon/pages/SignIn_Pages/firstPage.dart';
import 'package:mazilon/pages/UserSettings.dart';
import 'package:mazilon/util/Form/formPagePhoneModel.dart';
import 'package:mazilon/util/Firebase/fcm_service.dart';
import 'package:mazilon/util/Firebase/fcm_scheduled_notification_service.dart';
import 'package:mazilon/util/logger_service.dart';
import 'package:mazilon/util/notification_preference.dart';
import 'package:mazilon/util/persistent_memory_service.dart';
import 'package:mazilon/util/userInformation.dart';
import 'package:mockito/mockito.dart';

import '../helpers/widget_test_scaffold.dart';
import '../Firebase/firebase_auth_service_test.mocks.dart';

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

class _FailingResetImagePickerService extends NoopImagePickerService {
  @override
  Future<void> deleteImages() async {
    throw StateError('image cleanup failed');
  }
}

class _PendingResetImagePickerService extends NoopImagePickerService {
  final Completer<void> completion = Completer<void>();
  bool deleteStarted = false;

  @override
  Future<void> deleteImages() {
    deleteStarted = true;
    return completion.future;
  }
}

class _TrackingResetImagePickerService extends NoopImagePickerService {
  bool deleteStarted = false;

  @override
  Future<void> deleteImages() async {
    deleteStarted = true;
  }
}

class _TrackingPhonePageData extends PhonePageData {
  _TrackingPhonePageData()
    : super(
        key: 'trackingPhonePageData',
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

  bool resetStarted = false;

  @override
  void reset() {
    resetStarted = true;
  }
}

class _FailingResetMemoryService extends FakePersistentMemoryService {
  @override
  Future<void> reset() {
    return Future<void>.error(StateError('persistent reset failed'));
  }
}

class _RejectedPhonePersistenceMemoryService
    extends FakePersistentMemoryService {
  bool resetCompleted = false;

  @override
  Future<void> reset() async {
    await super.reset();
    resetCompleted = true;
  }

  @override
  Future<void> setItem(String key, PersistentMemoryType type, dynamic value) {
    if (resetCompleted && key.endsWith('SavedPhoneNames')) {
      return Future<void>.error(StateError('phone persistence failed'));
    }
    return super.setItem(key, type, value);
  }
}

class _RejectedAuthPersistenceMemoryService
    extends FakePersistentMemoryService {
  bool resetCompleted = false;

  @override
  Future<void> reset() async {
    await super.reset();
    resetCompleted = true;
  }

  @override
  Future<void> setItem(String key, PersistentMemoryType type, dynamic value) {
    if (resetCompleted &&
        const {'loggedIn', 'authDecisionMade', 'userId'}.contains(key)) {
      return Future<void>.error(StateError('auth persistence failed'));
    }
    return super.setItem(key, type, value);
  }
}

class _PostResetReadFailingMemoryService extends FakePersistentMemoryService {
  bool resetCompleted = false;
  bool postResetReadAttempted = false;

  @override
  Future<void> reset() async {
    await super.reset();
    resetCompleted = true;
  }

  @override
  Future<dynamic> getItem(String key, PersistentMemoryType type) async {
    if (resetCompleted) {
      postResetReadAttempted = true;
      throw StateError('post-reset persistence read failed');
    }
    return super.getItem(key, type);
  }
}

class _PendingIncidentLoggerService extends NoopIncidentLoggerService {
  final Completer<void> completion = Completer<void>();
  bool captureStarted = false;

  @override
  Future<void> captureLog(
    dynamic exception, {
    StackTrace? stackTrace,
    dynamic exceptionData,
  }) async {
    captureStarted = true;
    await completion.future;
  }
}

class _SynchronouslyFailingIncidentLoggerService
    extends NoopIncidentLoggerService {
  @override
  Future<void> captureLog(
    dynamic exception, {
    StackTrace? stackTrace,
    dynamic exceptionData,
  }) {
    throw StateError('synchronous incident logger failure');
  }
}

class _AsynchronouslyFailingIncidentLoggerService
    extends NoopIncidentLoggerService {
  @override
  Future<void> captureLog(
    dynamic exception, {
    StackTrace? stackTrace,
    dynamic exceptionData,
  }) {
    return Future<void>.error(
      StateError('asynchronous incident logger failure'),
    );
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
    FcmService.debugCancelLegacyLocalNotificationOverride =
        (notificationId) async {};
  });

  tearDown(() {
    FcmScheduledNotificationService.resetForTesting();
    FcmService.resetForTesting();
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

      final resetButton = find.byKey(const Key('userSettingsResetButton'));
      await tester.ensureVisible(resetButton);
      await tester.tap(resetButton, warnIfMissed: false);
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

      // resetData pushes a FirstPage route via pushAndRemoveUntil.
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

      final resetButton = find.byKey(const Key('userSettingsResetButton'));
      await tester.ensureVisible(resetButton);
      await tester.tap(resetButton, warnIfMissed: false);
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
    'persistent reset failure should report the error and keep data',
    (tester) async {
      final logger = _PendingIncidentLoggerService();
      GetIt.instance.unregister<IncidentLoggerService>();
      GetIt.instance.registerSingleton<IncidentLoggerService>(logger);
      final memory = _FailingResetMemoryService();
      memory.store['name'] = 'Not reset';
      memory.store['age'] = '30-40';
      GetIt.instance.unregister<PersistentMemoryService>();
      GetIt.instance.registerSingleton<PersistentMemoryService>(memory);
      user.service = memory;
      user.name = 'Not reset';
      user.age = '30-40';
      final phonePageData = _TrackingPhonePageData();
      final picker = _TrackingResetImagePickerService();
      GetIt.instance.unregister<ImagePickerService>();
      GetIt.instance.registerSingleton<ImagePickerService>(picker);
      debugDefaultTargetPlatformOverride = TargetPlatform.windows;

      try {
        await pumpWithProviders(
          tester,
          UserSettings(
            username: user.name,
            age: user.age,
            gender: 'male',
            phonePageData: phonePageData,
            changeLocale: (_) {},
          ),
          userInformation: user,
          surfaceSize: const Size(1024, 2800),
        );

        final resetButton = find.byKey(const Key('userSettingsResetButton'));
        await tester.ensureVisible(resetButton);
        await tester.tap(resetButton, warnIfMissed: false);
        await tester.pumpAndSettle();

        var dialogButtons = find.descendant(
          of: find.byType(Dialog),
          matching: find.byType(TextButton),
        );
        await tester.tap(dialogButtons.last, warnIfMissed: false);
        await tester.pumpAndSettle();

        expect(find.byType(FirstPage), findsNothing);
        expect(find.byType(UserSettings), findsOneWidget);
        expect(find.byType(Dialog), findsNothing);
        expect(find.byType(CircularProgressIndicator), findsNothing);
        expect(
          find.text("Couldn't reset your data. Please try again."),
          findsOneWidget,
        );
        expect(logger.captureStarted, isTrue);
        expect(phonePageData.resetStarted, isFalse);
        expect(picker.deleteStarted, isFalse);
        expect(user.name, 'Not reset');
        expect(user.age, '30-40');
        expect(memory.store['name'], 'Not reset');
        expect(memory.store['age'], '30-40');
        expect(tester.takeException(), isNull);
      } finally {
        if (!logger.completion.isCompleted) {
          logger.completion.complete();
          await tester.pump();
        }
        debugDefaultTargetPlatformOverride = null;
      }
    },
  );

  testWidgets('discarded phone persistence failure remains terminal', (
    tester,
  ) async {
    final memory = _RejectedPhonePersistenceMemoryService();
    GetIt.instance.unregister<PersistentMemoryService>();
    GetIt.instance.registerSingleton<PersistentMemoryService>(memory);
    user.service = memory;
    final logger =
        GetIt.instance<IncidentLoggerService>() as NoopIncidentLoggerService;
    debugDefaultTargetPlatformOverride = TargetPlatform.windows;

    try {
      await pumpWithProviders(
        tester,
        UserSettings(
          username: 'Phone persistence',
          age: '18-30',
          gender: 'male',
          phonePageData: _phone(),
          changeLocale: (_) {},
        ),
        userInformation: user,
        surfaceSize: const Size(1024, 2800),
      );

      final resetButton = find.byKey(const Key('userSettingsResetButton'));
      await tester.ensureVisible(resetButton);
      await tester.tap(resetButton, warnIfMissed: false);
      await tester.pumpAndSettle();

      final dialogButtons = find.descendant(
        of: find.byType(Dialog),
        matching: find.byType(TextButton),
      );
      await tester.tap(dialogButtons.last, warnIfMissed: false);
      await tester.pumpAndSettle();

      expect(find.byType(FirstPage), findsOneWidget);
      expect(find.byType(UserSettings), findsNothing);
      expect(find.byType(Dialog), findsNothing);
      expect(
        logger.captured.whereType<StateError>().map((error) => error.message),
        contains('phone persistence failed'),
      );
      expect(tester.takeException(), isNull);
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });

  testWidgets('discarded auth persistence failures remain terminal', (
    tester,
  ) async {
    final memory = _RejectedAuthPersistenceMemoryService();
    GetIt.instance.unregister<PersistentMemoryService>();
    GetIt.instance.registerSingleton<PersistentMemoryService>(memory);
    user.service = memory;
    final logger =
        GetIt.instance<IncidentLoggerService>() as NoopIncidentLoggerService;
    final auth = MockFirebaseAuth();
    final firebaseUser = MockUser();
    when(auth.currentUser).thenReturn(firebaseUser);
    when(firebaseUser.isAnonymous).thenReturn(false);
    when(firebaseUser.uid).thenReturn('reset-user');
    when(firebaseUser.email).thenReturn('reset@example.com');
    when(firebaseUser.displayName).thenReturn('Reset User');
    when(firebaseUser.getIdToken()).thenAnswer((_) async => 'token-123');
    GetIt.instance.registerSingleton<FirebaseAuth>(auth);
    FcmScheduledNotificationService.debugPostOverride =
        (url, {headers, body, encoding}) async =>
            url.path.endsWith('/getNotificationMutationVersion')
            ? http.Response('{"mutationVersion":0}', 200)
            : http.Response('{"success":true}', 200);
    debugDefaultTargetPlatformOverride = TargetPlatform.windows;

    try {
      await pumpWithProviders(
        tester,
        UserSettings(
          username: 'Auth persistence',
          age: '18-30',
          gender: 'male',
          phonePageData: _phone(),
          changeLocale: (_) {},
        ),
        userInformation: user,
        surfaceSize: const Size(1024, 2800),
      );

      final resetButton = find.byKey(const Key('userSettingsResetButton'));
      await tester.ensureVisible(resetButton);
      await tester.tap(resetButton, warnIfMissed: false);
      await tester.pumpAndSettle();

      final dialogButtons = find.descendant(
        of: find.byType(Dialog),
        matching: find.byType(TextButton),
      );
      await tester.tap(dialogButtons.last, warnIfMissed: false);
      await tester.pumpAndSettle();

      expect(find.byType(FirstPage), findsOneWidget);
      expect(find.byType(UserSettings), findsNothing);
      expect(find.byType(Dialog), findsNothing);
      expect(user.loggedIn, isTrue);
      expect(user.userId, 'reset-user');
      expect(
        logger.captured.whereType<StateError>().map((error) => error.message),
        contains('auth persistence failed'),
      );
      expect(tester.takeException(), isNull);
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });

  testWidgets('reset stays terminal after persistence reset commits', (
    tester,
  ) async {
    final memory = _PostResetReadFailingMemoryService();
    memory.store['name'] = 'Committed reset';
    memory.store['age'] = '30-40';
    GetIt.instance.unregister<PersistentMemoryService>();
    GetIt.instance.registerSingleton<PersistentMemoryService>(memory);
    user.service = memory;
    user.name = 'Committed reset';
    user.age = '30-40';
    debugDefaultTargetPlatformOverride = TargetPlatform.windows;

    try {
      await pumpWithProviders(
        tester,
        UserSettings(
          username: user.name,
          age: user.age,
          gender: 'male',
          phonePageData: _phone(),
          changeLocale: (_) {},
        ),
        userInformation: user,
        surfaceSize: const Size(1024, 2800),
      );

      final resetButton = find.byKey(const Key('userSettingsResetButton'));
      await tester.ensureVisible(resetButton);
      await tester.tap(resetButton, warnIfMissed: false);
      await tester.pumpAndSettle();

      final dialogButtons = find.descendant(
        of: find.byType(Dialog),
        matching: find.byType(TextButton),
      );
      await tester.tap(dialogButtons.last, warnIfMissed: false);
      await tester.pumpAndSettle();

      expect(memory.resetCompleted, isTrue);
      expect(memory.postResetReadAttempted, isFalse);
      expect(find.byType(FirstPage), findsOneWidget);
      expect(find.byType(UserSettings), findsNothing);
      expect(find.byType(Dialog), findsNothing);
      expect(user.name, isEmpty);
      expect(user.age, isEmpty);
      expect(memory.store, isNot(contains('name')));
      expect(memory.store, isNot(contains('age')));
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });

  testWidgets('reset waits for successful image cleanup before navigation', (
    tester,
  ) async {
    final picker = _PendingResetImagePickerService();
    GetIt.instance.unregister<ImagePickerService>();
    GetIt.instance.registerSingleton<ImagePickerService>(picker);
    debugDefaultTargetPlatformOverride = TargetPlatform.windows;

    try {
      await pumpWithProviders(
        tester,
        UserSettings(
          username: 'Pending cleanup',
          age: '18-30',
          gender: 'male',
          phonePageData: _phone(),
          changeLocale: (_) {},
        ),
        userInformation: user,
        surfaceSize: const Size(1024, 2800),
      );

      final resetButton = find.byKey(const Key('userSettingsResetButton'));
      await tester.ensureVisible(resetButton);
      await tester.tap(resetButton, warnIfMissed: false);
      await tester.pumpAndSettle();

      final dialogButtons = find.descendant(
        of: find.byType(Dialog),
        matching: find.byType(TextButton),
      );
      await tester.tap(dialogButtons.last, warnIfMissed: false);
      await tester.pump();

      expect(picker.deleteStarted, isTrue);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.byType(UserSettings), findsOneWidget);
      expect(find.byType(Dialog), findsOneWidget);
      expect(find.byType(FirstPage), findsNothing);

      picker.completion.complete();
      await tester.pumpAndSettle();

      expect(find.byType(FirstPage), findsOneWidget);
      expect(find.byType(Dialog), findsNothing);
      expect(find.byType(UserSettings), findsNothing);
    } finally {
      if (!picker.completion.isCompleted) {
        picker.completion.complete();
        await tester.pump();
      }
      debugDefaultTargetPlatformOverride = null;
    }
  });

  testWidgets('reset remains terminal when best-effort image cleanup throws', (
    tester,
  ) async {
    final memory = user.service as FakePersistentMemoryService;
    user.name = 'Cleanup failure';
    user.age = '18-30';
    memory.store['name'] = user.name;
    memory.store['age'] = user.age;
    GetIt.instance.unregister<ImagePickerService>();
    GetIt.instance.registerSingleton<ImagePickerService>(
      _FailingResetImagePickerService(),
    );
    debugDefaultTargetPlatformOverride = TargetPlatform.windows;
    try {
      await pumpWithProviders(
        tester,
        UserSettings(
          username: 'Cleanup failure',
          age: '18-30',
          gender: 'male',
          phonePageData: _phone(),
          changeLocale: (_) {},
        ),
        userInformation: user,
        surfaceSize: const Size(1024, 2800),
      );

      final resetButton = find.byKey(const Key('userSettingsResetButton'));
      await tester.ensureVisible(resetButton);
      await tester.tap(resetButton, warnIfMissed: false);
      await tester.pumpAndSettle();

      var dialogButtons = find.descendant(
        of: find.byType(Dialog),
        matching: find.byType(TextButton),
      );
      await tester.tap(dialogButtons.last, warnIfMissed: false);
      await tester.pumpAndSettle();

      expect(find.byType(FirstPage), findsOneWidget);
      expect(find.byType(Dialog), findsNothing);
      expect(find.byType(UserSettings), findsNothing);
      expect(user.name, isEmpty);
      expect(user.age, isEmpty);
      expect(memory.store, isNot(contains('name')));
      expect(memory.store, isNot(contains('age')));
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });

  testWidgets('reset navigation does not wait for cleanup incident reporting', (
    tester,
  ) async {
    final logger = _PendingIncidentLoggerService();
    final memory = user.service as FakePersistentMemoryService;
    user.name = 'Pending failure report';
    user.age = '18-30';
    memory.store['name'] = user.name;
    memory.store['age'] = user.age;
    GetIt.instance.unregister<IncidentLoggerService>();
    GetIt.instance.registerSingleton<IncidentLoggerService>(logger);
    GetIt.instance.unregister<ImagePickerService>();
    GetIt.instance.registerSingleton<ImagePickerService>(
      _FailingResetImagePickerService(),
    );
    debugDefaultTargetPlatformOverride = TargetPlatform.windows;
    try {
      await pumpWithProviders(
        tester,
        UserSettings(
          username: 'Pending failure report',
          age: '18-30',
          gender: 'male',
          phonePageData: _phone(),
          changeLocale: (_) {},
        ),
        userInformation: user,
        surfaceSize: const Size(1024, 2800),
      );

      final resetButton = find.byKey(const Key('userSettingsResetButton'));
      await tester.ensureVisible(resetButton);
      await tester.tap(resetButton, warnIfMissed: false);
      await tester.pumpAndSettle();

      var dialogButtons = find.descendant(
        of: find.byType(Dialog),
        matching: find.byType(TextButton),
      );
      await tester.tap(dialogButtons.last, warnIfMissed: false);
      await tester.pumpAndSettle();

      expect(logger.captureStarted, isTrue);
      expect(find.byType(FirstPage), findsOneWidget);
      expect(find.byType(Dialog), findsNothing);
      expect(find.byType(UserSettings), findsNothing);
      expect(user.name, isEmpty);
      expect(user.age, isEmpty);
      expect(memory.store, isNot(contains('name')));
      expect(memory.store, isNot(contains('age')));
    } finally {
      if (!logger.completion.isCompleted) {
        logger.completion.complete();
        await tester.pump();
      }
      debugDefaultTargetPlatformOverride = null;
    }
  });

  final failingIncidentLoggers = <String, IncidentLoggerService Function()>{
    'throws synchronously': () => _SynchronouslyFailingIncidentLoggerService(),
    'returns a rejected Future': () =>
        _AsynchronouslyFailingIncidentLoggerService(),
  };

  failingIncidentLoggers.forEach((description, createLogger) {
    testWidgets(
      'cleanup failure stays terminal when incident logger $description',
      (tester) async {
        GetIt.instance.unregister<IncidentLoggerService>();
        GetIt.instance.registerSingleton<IncidentLoggerService>(createLogger());
        GetIt.instance.unregister<ImagePickerService>();
        GetIt.instance.registerSingleton<ImagePickerService>(
          _FailingResetImagePickerService(),
        );
        debugDefaultTargetPlatformOverride = TargetPlatform.windows;

        try {
          await pumpWithProviders(
            tester,
            UserSettings(
              username: 'Logger failure',
              age: '18-30',
              gender: 'male',
              phonePageData: _phone(),
              changeLocale: (_) {},
            ),
            userInformation: user,
            surfaceSize: const Size(1024, 2800),
          );

          final resetButton = find.byKey(const Key('userSettingsResetButton'));
          await tester.ensureVisible(resetButton);
          await tester.tap(resetButton, warnIfMissed: false);
          await tester.pumpAndSettle();

          final dialogButtons = find.descendant(
            of: find.byType(Dialog),
            matching: find.byType(TextButton),
          );
          await tester.tap(dialogButtons.last, warnIfMissed: false);
          await tester.pumpAndSettle();

          expect(find.byType(FirstPage), findsOneWidget);
          expect(find.byType(UserSettings), findsNothing);
          expect(find.byType(Dialog), findsNothing);
          expect(tester.takeException(), isNull);
        } finally {
          debugDefaultTargetPlatformOverride = null;
        }
      },
    );
  });

  testWidgets('signs out on desktop after cancelling the remote reminder', (
    tester,
  ) async {
    final auth = MockFirebaseAuth();
    final firebaseUser = MockUser();
    final events = <String>[];
    Map<String, dynamic>? cancellationPayload;
    when(auth.currentUser).thenReturn(firebaseUser);
    when(firebaseUser.isAnonymous).thenReturn(false);
    when(firebaseUser.getIdToken()).thenAnswer((_) async {
      events.add('getIdToken');
      return 'token-123';
    });
    when(auth.signOut()).thenAnswer((_) async {
      events.add('signOut');
    });
    GetIt.instance.registerSingleton<FirebaseAuth>(auth);
    user.loggedIn = true;
    user.authDecisionMade = true;
    user.userId = 'signed-in-user';
    user.email = 'user@example.com';
    user.displayName = 'Signed-in User';
    FcmScheduledNotificationService
        .debugPostOverride = (url, {headers, body, encoding}) async {
      if (url.path.endsWith('/getNotificationMutationVersion')) {
        events.add('getNotificationMutationVersion');
        return http.Response('{"mutationVersion":0}', 200);
      }
      events.add('cancelNotification');
      cancellationPayload = jsonDecode(body! as String) as Map<String, dynamic>;
      return http.Response('{"success":true}', 200);
    };
    debugDefaultTargetPlatformOverride = TargetPlatform.windows;

    try {
      await pumpWithProviders(
        tester,
        UserSettings(
          username: 'Keep identity',
          age: '18-30',
          gender: 'male',
          phonePageData: _phone(),
          changeLocale: (_) {},
        ),
        userInformation: user,
        surfaceSize: const Size(1024, 2800),
      );

      final signOutButton = find.byKey(const Key('userSettingsSignOutButton'));
      await tester.ensureVisible(signOutButton);
      await tester.tap(signOutButton, warnIfMissed: false);
      await tester.pumpAndSettle();

      expect(find.text('Sign Out?'), findsOneWidget);
      expect(
        find.text('You will need to sign in again to access all features.'),
        findsOneWidget,
      );

      final dialogButtons = find.descendant(
        of: find.byType(Dialog),
        matching: find.byType(TextButton),
      );
      await tester.tap(dialogButtons.last, warnIfMissed: false);
      await tester.pumpAndSettle();

      verify(auth.signOut()).called(1);
      expect(events, [
        'getIdToken',
        'getNotificationMutationVersion',
        'cancelNotification',
        'signOut',
      ]);
      expect(cancellationPayload, {
        'typeId': 'default',
        'expectedMutationVersion': 0,
        'resetFence': true,
      });
      expect(user.loggedIn, isFalse);
      expect(user.authDecisionMade, isFalse);
      expect(user.userId, isEmpty);
      expect(user.email, isEmpty);
      expect(user.displayName, isEmpty);
      expect(find.byType(FirstPage), findsOneWidget);
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });

  testWidgets('should restore the reminder when Firebase sign-out fails', (
    tester,
  ) async {
    final auth = MockFirebaseAuth();
    final firebaseUser = MockUser();
    final events = <String>[];
    final requestBodies = <Map<String, dynamic>>[];
    var mutationVersion = 0;
    when(auth.currentUser).thenReturn(firebaseUser);
    when(firebaseUser.isAnonymous).thenReturn(false);
    when(firebaseUser.getIdToken()).thenAnswer((_) async => 'token-123');
    when(auth.signOut()).thenAnswer((_) async {
      events.add('signOut');
      throw StateError('Firebase sign-out failed');
    });
    GetIt.instance.registerSingleton<FirebaseAuth>(auth);
    await user.setNotificationPreference(
      'default',
      const NotificationPreference(hour: 8, minute: 15),
    );
    user.loggedIn = true;
    user.authDecisionMade = true;
    user.userId = 'signed-in-user';
    FcmScheduledNotificationService.debugPostOverride =
        (url, {headers, body, encoding}) async {
          if (body is! String) {
            throw StateError('Expected an encoded notification mutation body.');
          }
          final requestBody = jsonDecode(body) as Map<String, dynamic>;
          requestBodies.add(requestBody);
          if (url.path.endsWith('/getNotificationMutationVersion')) {
            expect(requestBody, {'typeId': 'default'});
            events.add('version:$mutationVersion');
            return http.Response('{"mutationVersion":$mutationVersion}', 200);
          }
          if (url.path.endsWith('/cancelNotification')) {
            expect(requestBody, {
              'typeId': 'default',
              'expectedMutationVersion': 0,
              'resetFence': true,
            });
            events.add('cancel');
            mutationVersion++;
            return http.Response('{"mutationVersion":$mutationVersion}', 200);
          }
          if (url.path.endsWith('/registerNotification')) {
            expect(requestBody, {
              'typeId': 'default',
              'hour': 8,
              'minute': 15,
              'locale': 'en',
              'gender': 'male',
              'expectedMutationVersion': 1,
            });
            events.add('register');
            mutationVersion++;
            return http.Response('{"mutationVersion":$mutationVersion}', 200);
          }
          throw StateError('Unexpected notification mutation endpoint: $url');
        };
    debugDefaultTargetPlatformOverride = TargetPlatform.windows;

    try {
      await pumpWithProviders(
        tester,
        UserSettings(
          username: 'Keep reminder',
          age: '18-30',
          gender: 'male',
          phonePageData: _phone(),
          changeLocale: (_) {},
        ),
        userInformation: user,
        surfaceSize: const Size(1024, 2800),
      );

      final signOutButton = find.byKey(const Key('userSettingsSignOutButton'));
      await tester.ensureVisible(signOutButton);
      await tester.tap(signOutButton, warnIfMissed: false);
      await tester.pumpAndSettle();
      final dialogButtons = find.descendant(
        of: find.byType(Dialog),
        matching: find.byType(TextButton),
      );
      await tester.tap(dialogButtons.last, warnIfMissed: false);
      await tester.pumpAndSettle();

      verify(auth.signOut()).called(1);
      expect(events, [
        'version:0',
        'cancel',
        'signOut',
        'version:1',
        'register',
      ]);
      expect(requestBodies, [
        {'typeId': 'default'},
        {'typeId': 'default', 'expectedMutationVersion': 0, 'resetFence': true},
        {'typeId': 'default'},
        {
          'typeId': 'default',
          'hour': 8,
          'minute': 15,
          'locale': 'en',
          'gender': 'male',
          'expectedMutationVersion': 1,
        },
      ]);
      expect(
        user.getNotificationPreference('default')?.toJson(),
        const NotificationPreference(hour: 8, minute: 15).toJson(),
      );
      expect(user.loggedIn, isTrue);
      expect(user.authDecisionMade, isTrue);
      expect(user.userId, 'signed-in-user');
      expect(find.byType(UserSettings), findsOneWidget);
      expect(find.byType(FirstPage), findsNothing);
      expect(find.byType(SnackBar), findsOneWidget);
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });

  testWidgets(
    'sign-out keeps the session when the remote reminder cannot be cancelled',
    (tester) async {
      final auth = MockFirebaseAuth();
      final firebaseUser = MockUser();
      when(auth.currentUser).thenReturn(firebaseUser);
      when(firebaseUser.isAnonymous).thenReturn(false);
      when(firebaseUser.getIdToken()).thenAnswer((_) async => null);
      GetIt.instance.registerSingleton<FirebaseAuth>(auth);
      user.loggedIn = true;
      user.authDecisionMade = true;
      user.userId = 'signed-in-user';
      debugDefaultTargetPlatformOverride = TargetPlatform.windows;

      try {
        await pumpWithProviders(
          tester,
          UserSettings(
            username: 'Keep reminder private',
            age: '18-30',
            gender: 'male',
            phonePageData: _phone(),
            changeLocale: (_) {},
          ),
          userInformation: user,
          surfaceSize: const Size(1024, 2800),
        );

        final signOutButton = find.byKey(
          const Key('userSettingsSignOutButton'),
        );
        await tester.ensureVisible(signOutButton);
        await tester.tap(signOutButton, warnIfMissed: false);
        await tester.pumpAndSettle();

        final dialogButtons = find.descendant(
          of: find.byType(Dialog),
          matching: find.byType(TextButton),
        );
        await tester.tap(dialogButtons.last, warnIfMissed: false);
        await tester.pumpAndSettle();

        verify(firebaseUser.getIdToken()).called(1);
        verifyNever(auth.signOut());
        expect(user.loggedIn, isTrue);
        expect(find.byType(UserSettings), findsOneWidget);
        expect(find.byType(FirstPage), findsNothing);
        expect(find.byType(SnackBar), findsOneWidget);
      } finally {
        debugDefaultTargetPlatformOverride = null;
      }
    },
  );

  testWidgets(
    'reset keeps local data and navigation in place when remote cancellation fails',
    (tester) async {
      final auth = MockFirebaseAuth();
      final firebaseUser = MockUser();
      when(auth.currentUser).thenReturn(firebaseUser);
      when(firebaseUser.isAnonymous).thenReturn(false);
      when(firebaseUser.getIdToken()).thenAnswer((_) async => null);
      GetIt.instance.registerSingleton<FirebaseAuth>(auth);
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      try {
        user.setNotificationPreference(
          'default',
          const NotificationPreference(hour: 9, minute: 30),
        );
        await pumpWithProviders(
          tester,
          UserSettings(
            username: 'Keep reminder',
            age: '18-30',
            gender: 'male',
            phonePageData: _phone(),
            changeLocale: (_) {},
          ),
          userInformation: user,
          surfaceSize: const Size(1024, 2800),
        );

        final resetButton = find.byKey(const Key('userSettingsResetButton'));
        await tester.ensureVisible(resetButton);
        await tester.tap(resetButton, warnIfMissed: false);
        await tester.pumpAndSettle();

        final dialogButtons = find.descendant(
          of: find.byType(Dialog),
          matching: find.byType(TextButton),
        );
        await tester.tap(dialogButtons.last, warnIfMissed: false);
        await tester.pumpAndSettle();

        expect(find.byType(UserSettings), findsOneWidget);
        expect(find.byType(FirstPage), findsNothing);
        expect(user.getNotificationPreference('default'), isNotNull);
        expect(find.byType(Dialog), findsNothing);
        expect(find.byType(SnackBar).hitTestable(), findsOneWidget);
      } finally {
        debugDefaultTargetPlatformOverride = null;
      }
    },
  );

  testWidgets(
    'reset confirmation disables repeat taps while remote cancellation is pending',
    (tester) async {
      final auth = MockFirebaseAuth();
      final firebaseUser = MockUser();
      final idToken = Completer<String?>();
      when(auth.currentUser).thenReturn(firebaseUser);
      when(firebaseUser.isAnonymous).thenReturn(false);
      when(firebaseUser.getIdToken()).thenAnswer((_) => idToken.future);
      GetIt.instance.registerSingleton<FirebaseAuth>(auth);
      debugDefaultTargetPlatformOverride = TargetPlatform.android;

      try {
        await pumpWithProviders(
          tester,
          UserSettings(
            username: 'Pending reset',
            age: '18-30',
            gender: 'male',
            phonePageData: _phone(),
            changeLocale: (_) {},
          ),
          userInformation: user,
          surfaceSize: const Size(1024, 2800),
        );

        final resetButton = find.byKey(const Key('userSettingsResetButton'));
        await tester.ensureVisible(resetButton);
        await tester.tap(resetButton, warnIfMissed: false);
        await tester.pumpAndSettle();

        final dialogButtons = find.descendant(
          of: find.byType(Dialog),
          matching: find.byType(TextButton),
        );
        await tester.tap(dialogButtons.last, warnIfMissed: false);
        await tester.pump();

        expect(find.byType(CircularProgressIndicator), findsOneWidget);
        for (final button in tester.widgetList<TextButton>(dialogButtons)) {
          expect(button.onPressed, isNull);
        }
        verify(firebaseUser.getIdToken()).called(1);

        idToken.complete(null);
        await tester.pumpAndSettle();

        expect(find.byType(UserSettings), findsOneWidget);
        expect(find.byType(FirstPage), findsNothing);
        expect(find.byType(SnackBar), findsOneWidget);
      } finally {
        debugDefaultTargetPlatformOverride = null;
      }
    },
  );

  testWidgets(
    'reset confirmation cannot be dismissed while remote cancellation is pending',
    (tester) async {
      final auth = MockFirebaseAuth();
      final firebaseUser = MockUser();
      final idToken = Completer<String?>();
      when(auth.currentUser).thenReturn(firebaseUser);
      when(firebaseUser.isAnonymous).thenReturn(false);
      when(firebaseUser.getIdToken()).thenAnswer((_) => idToken.future);
      GetIt.instance.registerSingleton<FirebaseAuth>(auth);
      debugDefaultTargetPlatformOverride = TargetPlatform.android;

      try {
        await pumpWithProviders(
          tester,
          UserSettings(
            username: 'Pending reset dismissal',
            age: '18-30',
            gender: 'male',
            phonePageData: _phone(),
            changeLocale: (_) {},
          ),
          userInformation: user,
          surfaceSize: const Size(1024, 2800),
        );

        final resetButton = find.byKey(const Key('userSettingsResetButton'));
        await tester.ensureVisible(resetButton);
        await tester.tap(resetButton, warnIfMissed: false);
        await tester.pumpAndSettle();

        final dialogButtons = find.descendant(
          of: find.byType(Dialog),
          matching: find.byType(TextButton),
        );
        await tester.tap(dialogButtons.last, warnIfMissed: false);
        await tester.pump();

        expect(find.byType(CircularProgressIndicator), findsOneWidget);
        expect(
          tester
              .widgetList<ModalBarrier>(find.byType(ModalBarrier))
              .last
              .dismissible,
          isFalse,
        );

        await tester.binding.handlePopRoute();
        await tester.pump();

        expect(find.byType(Dialog), findsOneWidget);
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
        verify(firebaseUser.getIdToken()).called(1);

        idToken.complete(null);
        await tester.pumpAndSettle();

        expect(find.byType(UserSettings), findsOneWidget);
        expect(find.byType(FirstPage), findsNothing);
        expect(find.byType(SnackBar), findsOneWidget);
      } finally {
        debugDefaultTargetPlatformOverride = null;
      }
    },
  );

  testWidgets('reset confirmation ignores same-frame duplicate activation', (
    tester,
  ) async {
    final auth = MockFirebaseAuth();
    final firebaseUser = MockUser();
    final idToken = Completer<String?>();
    var tokenRequests = 0;
    when(auth.currentUser).thenReturn(firebaseUser);
    when(firebaseUser.isAnonymous).thenReturn(false);
    when(firebaseUser.getIdToken()).thenAnswer((_) {
      tokenRequests += 1;
      return idToken.future;
    });
    GetIt.instance.registerSingleton<FirebaseAuth>(auth);
    debugDefaultTargetPlatformOverride = TargetPlatform.android;

    try {
      await pumpWithProviders(
        tester,
        UserSettings(
          username: 'Duplicate reset confirmation',
          age: '18-30',
          gender: 'male',
          phonePageData: _phone(),
          changeLocale: (_) {},
        ),
        userInformation: user,
        surfaceSize: const Size(1024, 2800),
      );

      final resetButton = find.byKey(const Key('userSettingsResetButton'));
      await tester.ensureVisible(resetButton);
      await tester.tap(resetButton, warnIfMissed: false);
      await tester.pumpAndSettle();

      final dialogButtons = find.descendant(
        of: find.byType(Dialog),
        matching: find.byType(TextButton),
      );
      final confirm = tester.widget<TextButton>(dialogButtons.last).onPressed!;
      confirm();
      confirm();
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(tokenRequests, 1);

      idToken.complete(null);
      await tester.pumpAndSettle();

      expect(tokenRequests, 1);
      expect(find.byType(UserSettings), findsOneWidget);
      expect(find.byType(FirstPage), findsNothing);
      expect(find.byType(SnackBar), findsOneWidget);
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });

  testWidgets('reset cancels the remote reminder on an unsupported platform', (
    tester,
  ) async {
    final auth = MockFirebaseAuth();
    final firebaseUser = MockUser();
    when(auth.currentUser).thenReturn(firebaseUser);
    when(firebaseUser.isAnonymous).thenReturn(false);
    when(firebaseUser.getIdToken()).thenAnswer((_) async => 'token-123');
    GetIt.instance.registerSingleton<FirebaseAuth>(auth);
    user.setNotificationPreference(
      'default',
      const NotificationPreference(hour: 9, minute: 30),
    );
    final requests = <String>[];
    FcmScheduledNotificationService.debugPostOverride =
        (url, {headers, body, encoding}) async {
          requests.add(url.path);
          if (url.path.endsWith('/getNotificationMutationVersion')) {
            return http.Response('{"mutationVersion":0}', 200);
          }
          return http.Response('{"success":true}', 200);
        };
    debugDefaultTargetPlatformOverride = TargetPlatform.windows;
    try {
      await pumpWithProviders(
        tester,
        UserSettings(
          username: 'Web reset',
          age: '18-30',
          gender: 'male',
          phonePageData: _phone(),
          changeLocale: (_) {},
        ),
        userInformation: user,
        surfaceSize: const Size(1024, 2800),
      );

      final resetButton = find.byKey(const Key('userSettingsResetButton'));
      await tester.ensureVisible(resetButton);
      await tester.tap(resetButton, warnIfMissed: false);
      await tester.pumpAndSettle();
      final dialogButtons = find.descendant(
        of: find.byType(Dialog),
        matching: find.byType(TextButton),
      );
      await tester.tap(dialogButtons.last, warnIfMissed: false);
      await tester.pumpAndSettle();

      expect(find.byType(FirstPage), findsOneWidget);
      expect(requests, [
        '/getNotificationMutationVersion',
        '/cancelNotification',
      ]);
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });

  testWidgets(
    'reset keeps data when account cancellation fails without a local reminder',
    (tester) async {
      final auth = MockFirebaseAuth();
      final firebaseUser = MockUser();
      when(auth.currentUser).thenReturn(firebaseUser);
      when(firebaseUser.isAnonymous).thenReturn(false);
      when(firebaseUser.getIdToken()).thenAnswer((_) async => null);
      GetIt.instance.registerSingleton<FirebaseAuth>(auth);
      debugDefaultTargetPlatformOverride = TargetPlatform.android;

      try {
        await pumpWithProviders(
          tester,
          UserSettings(
            username: 'Account reset',
            age: '18-30',
            gender: 'male',
            phonePageData: _phone(),
            changeLocale: (_) {},
          ),
          userInformation: user,
          surfaceSize: const Size(1024, 2800),
        );

        final resetButton = find.byKey(const Key('userSettingsResetButton'));
        await tester.ensureVisible(resetButton);
        await tester.tap(resetButton, warnIfMissed: false);
        await tester.pumpAndSettle();
        final dialogButtons = find.descendant(
          of: find.byType(Dialog),
          matching: find.byType(TextButton),
        );
        await tester.tap(dialogButtons.last, warnIfMissed: false);
        await tester.pumpAndSettle();

        expect(find.byType(UserSettings), findsOneWidget);
        expect(find.byType(FirstPage), findsNothing);
        expect(find.byType(SnackBar), findsOneWidget);
      } finally {
        debugDefaultTargetPlatformOverride = null;
      }
    },
  );

  testWidgets(
    'reset on an unsupported platform restores authenticated identity',
    (tester) async {
      final auth = MockFirebaseAuth();
      final firebaseUser = MockUser();
      when(auth.currentUser).thenReturn(firebaseUser);
      when(firebaseUser.isAnonymous).thenReturn(false);
      when(firebaseUser.uid).thenReturn('uid-123');
      when(firebaseUser.email).thenReturn('user@example.com');
      when(firebaseUser.displayName).thenReturn('Remembered User');
      when(firebaseUser.getIdToken()).thenAnswer((_) async => 'token-123');
      GetIt.instance.registerSingleton<FirebaseAuth>(auth);
      FcmScheduledNotificationService.debugPostOverride =
          (url, {headers, body, encoding}) async =>
              url.path.endsWith('/getNotificationMutationVersion')
              ? http.Response('{"mutationVersion":0}', 200)
              : http.Response('{"success":true}', 200);
      debugDefaultTargetPlatformOverride = TargetPlatform.windows;

      try {
        await pumpWithProviders(
          tester,
          UserSettings(
            username: 'Reset identity',
            age: '18-30',
            gender: 'male',
            phonePageData: _phone(),
            changeLocale: (_) {},
          ),
          userInformation: user,
          surfaceSize: const Size(1024, 2800),
        );

        final resetButton = find.byKey(const Key('userSettingsResetButton'));
        await tester.ensureVisible(resetButton);
        await tester.tap(resetButton, warnIfMissed: false);
        await tester.pumpAndSettle();
        final dialogButtons = find.descendant(
          of: find.byType(Dialog),
          matching: find.byType(TextButton),
        );
        await tester.tap(dialogButtons.last, warnIfMissed: false);
        await tester.pumpAndSettle();

        expect(find.byType(FirstPage), findsOneWidget);
        expect(user.loggedIn, isTrue);
        expect(user.authDecisionMade, isTrue);
        expect(user.userId, 'uid-123');
        expect(user.email, 'user@example.com');
        expect(user.displayName, 'Remembered User');
      } finally {
        debugDefaultTargetPlatformOverride = null;
      }
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
