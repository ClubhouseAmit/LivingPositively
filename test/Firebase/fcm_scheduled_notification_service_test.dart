import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:http/http.dart' as http;
import 'package:mazilon/global_enums.dart';
import 'package:mazilon/util/Firebase/fcm_service.dart';
import 'package:mazilon/util/Firebase/fcm_scheduled_notification_service.dart';
import 'package:mazilon/util/logger_service.dart';
import 'package:mazilon/util/notification_preference.dart';
import 'package:mazilon/util/persistent_memory_service.dart';
import 'package:mazilon/util/userInformation.dart';
import 'package:provider/provider.dart';

class _FakePersistentMemoryService implements PersistentMemoryService {
  static const _migrationKey = 'fcmDefaultReminderMigrated';
  static const _notificationPreferencesKey = 'notificationPreferences';
  static const _legacyReminderKeys = {'notificationHour', 'notificationMinute'};
  final Map<String, dynamic> stored = {};
  Completer<dynamic>? migrationMarkerRead;
  Completer<void>? migrationMarkerReadStarted;
  Object? migrationMarkerReadError;
  StackTrace? migrationMarkerReadStackTrace;
  Object? migrationMarkerWriteError;
  Completer<void>? migrationMarkerWrite;
  int notificationPreferenceWritesToFail = 0;

  @override
  Future<dynamic> getItem(String key, PersistentMemoryType type) async {
    if (_legacyReminderKeys.contains(key)) {
      if (type != PersistentMemoryType.Int) {
        throw StateError('Unexpected persistent-memory type for $key: $type');
      }
      return stored[key];
    }
    if (key != _migrationKey) {
      throw StateError('Unexpected persistent-memory read: $key');
    }
    if (migrationMarkerRead != null) {
      migrationMarkerReadStarted?.complete();
      return migrationMarkerRead!.future;
    }
    if (migrationMarkerReadError != null) {
      Error.throwWithStackTrace(
        migrationMarkerReadError!,
        migrationMarkerReadStackTrace!,
      );
    }
    return stored[key];
  }

  @override
  Future<void> reset() async => stored.clear();

  @override
  Future<void> setItem(
    String key,
    PersistentMemoryType type,
    dynamic value,
  ) async {
    if (key != _migrationKey && key != _notificationPreferencesKey) {
      throw StateError('Unexpected persistent-memory write: $key');
    }
    if (key == _notificationPreferencesKey) {
      if (notificationPreferenceWritesToFail > 0) {
        notificationPreferenceWritesToFail--;
        throw StateError('notification preferences disk unavailable');
      }
      stored[key] = value;
      return;
    }
    if (migrationMarkerWrite != null) {
      await migrationMarkerWrite!.future;
    }
    if (migrationMarkerWriteError != null) {
      throw migrationMarkerWriteError!;
    }
    stored[key] = value;
  }
}

class _RecordingIncidentLogger implements IncidentLoggerService {
  dynamic capturedError;
  StackTrace? capturedStackTrace;

  @override
  Future<void> captureLog(
    dynamic exception, {
    StackTrace? stackTrace,
    dynamic exceptionData,
  }) async {
    capturedError = exception;
    capturedStackTrace = stackTrace;
  }

  @override
  Future<void> initializeSentry(Widget myApp) async {}
}

class _ThrowingIncidentLogger implements IncidentLoggerService {
  bool captureAttempted = false;

  @override
  Future<void> captureLog(
    dynamic exception, {
    StackTrace? stackTrace,
    dynamic exceptionData,
  }) async {
    captureAttempted = true;
    throw StateError('incident logger unavailable');
  }

  @override
  Future<void> initializeSentry(Widget myApp) async {}
}

Future<T> _onPlatform<T>(
  TargetPlatform platform,
  Future<T> Function() body,
) async {
  debugDefaultTargetPlatformOverride = platform;
  try {
    return await body();
  } finally {
    debugDefaultTargetPlatformOverride = null;
  }
}

Future<void> _ignoreLegacyNotification(int notificationId) async {}

void main() {
  late _FakePersistentMemoryService memory;
  late UserInformation user;
  late BuildContext serviceContext;

  setUp(() {
    memory = _FakePersistentMemoryService();
    memory.stored.addAll({'notificationHour': 8, 'notificationMinute': 15});
    GetIt.instance.registerSingleton<PersistentMemoryService>(memory);
    user = UserInformation(
      service: memory,
      localeName: 'en',
      gender: 'female',
      loggedIn: true,
    );
    FcmService.debugCancelLegacyLocalNotificationOverride =
        _ignoreLegacyNotification;
  });

  tearDown(() async {
    FcmScheduledNotificationService.resetForTesting();
    FcmService.resetForTesting();
    await GetIt.instance.reset();
  });

  Future<void> pumpUser(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ChangeNotifierProvider<UserInformation>.value(
          value: user,
          child: Builder(
            builder: (context) {
              serviceContext = context;
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );
  }

  testWidgets('notification operations reject missing user state safely', (
    tester,
  ) async {
    await _onPlatform(TargetPlatform.android, () async {
      expect(
        await FcmScheduledNotificationService.registerNotification(
          typeId: 'default',
          hour: 9,
          minute: 30,
        ),
        isFalse,
      );
      expect(
        await FcmScheduledNotificationService.cancelNotification(
          typeId: 'default',
        ),
        isFalse,
      );
      await expectLater(
        FcmScheduledNotificationService.migrateLegacyDefaultReminder(),
        completes,
      );
    });
  });

  testWidgets('register sends an authenticated FCM schedule and saves it', (
    tester,
  ) async {
    await pumpUser(tester);
    late Uri requestedUrl;
    late Map<String, String> requestedHeaders;
    late String requestedBody;
    late String versionReadBody;

    final result = await _onPlatform(
      TargetPlatform.android,
      () => FcmScheduledNotificationService.registerNotification(
        context: serviceContext,
        typeId: 'default',
        hour: 9,
        minute: 30,
        idTokenProvider: () async => 'token-123',
        post: (url, {headers, body, encoding}) async {
          if (url.path.endsWith('/getNotificationMutationVersion')) {
            versionReadBody = body! as String;
            return http.Response('{"mutationVersion":0}', 200);
          }
          requestedUrl = url;
          requestedHeaders = headers!;
          requestedBody = body! as String;
          return http.Response('{"success":true}', 200);
        },
      ),
    );

    expect(result, isTrue);
    expect(
      requestedUrl.toString(),
      'https://us-central1-mezilondb.cloudfunctions.net/registerNotification',
    );
    expect(requestedHeaders['Authorization'], 'Bearer token-123');
    expect(jsonDecode(versionReadBody), {'typeId': 'default'});
    expect(jsonDecode(requestedBody), {
      'typeId': 'default',
      'hour': 9,
      'minute': 30,
      'locale': 'en',
      'gender': 'female',
      'expectedMutationVersion': 0,
    });
    expect(
      user.getNotificationPreference('default')?.toJson(),
      const NotificationPreference(hour: 9, minute: 30).toJson(),
    );
  });

  testWidgets('cancel removes the saved schedule only after server success', (
    tester,
  ) async {
    user.setNotificationPreference(
      'default',
      const NotificationPreference(hour: 8, minute: 15),
    );
    await pumpUser(tester);

    final result = await _onPlatform(
      TargetPlatform.iOS,
      () => FcmScheduledNotificationService.cancelNotification(
        context: serviceContext,
        typeId: 'default',
        idTokenProvider: () async => 'token-123',
        post: (url, {headers, body, encoding}) async =>
            url.path.endsWith('/getNotificationMutationVersion')
            ? http.Response('{"mutationVersion":0}', 200)
            : http.Response('{"success":true}', 200),
      ),
    );

    expect(result, isTrue);
    expect(user.getNotificationPreference('default'), isNull);
  });

  test('register rejects a malformed successful mutation response', () async {
    final registered = await _onPlatform(
      TargetPlatform.android,
      () => FcmScheduledNotificationService.registerNotification(
        userInformation: user,
        typeId: 'default',
        hour: 9,
        minute: 30,
        idTokenProvider: () async => 'token-123',
        post: (url, {headers, body, encoding}) async =>
            url.path.endsWith('/getNotificationMutationVersion')
            ? http.Response('{"mutationVersion":0}', 200)
            : http.Response('{}', 200),
      ),
    );

    expect(registered, isFalse);
    expect(user.getNotificationPreference('default'), isNull);
  });

  test(
    'register compensates the remote schedule when local preference persistence fails',
    () async {
      memory.notificationPreferenceWritesToFail = 1;
      final operations = <String>[];
      var mutationVersion = 0;

      final registered = await _onPlatform(
        TargetPlatform.android,
        () => FcmScheduledNotificationService.registerNotification(
          userInformation: user,
          typeId: 'default',
          hour: 9,
          minute: 30,
          idTokenProvider: () async => 'token-123',
          post: (url, {headers, body, encoding}) async {
            if (url.path.endsWith('/getNotificationMutationVersion')) {
              operations.add('version:$mutationVersion');
              return http.Response('{"mutationVersion":$mutationVersion}', 200);
            }
            if (url.path.endsWith('/registerNotification')) {
              operations.add('register');
            } else {
              operations.add('cancel');
            }
            mutationVersion++;
            return http.Response('{"success":true}', 200);
          },
        ),
      );

      expect(registered, isFalse);
      expect(operations, ['version:0', 'register', 'cancel']);
      expect(user.getNotificationPreference('default'), isNull);
    },
  );

  test(
    'register restores an existing remote schedule when its edited preference cannot persist',
    () async {
      const existing = NotificationPreference(hour: 8, minute: 15);
      await user.setNotificationPreference('default', existing);
      memory.notificationPreferenceWritesToFail = 1;
      final operations = <String>[];
      var mutationVersion = 0;

      final registered = await _onPlatform(
        TargetPlatform.android,
        () => FcmScheduledNotificationService.registerNotification(
          userInformation: user,
          typeId: 'default',
          hour: 9,
          minute: 30,
          idTokenProvider: () async => 'token-123',
          post: (url, {headers, body, encoding}) async {
            if (url.path.endsWith('/getNotificationMutationVersion')) {
              operations.add('version:$mutationVersion');
              return http.Response('{"mutationVersion":$mutationVersion}', 200);
            }
            if (url.path.endsWith('/registerNotification')) {
              final request =
                  jsonDecode(body! as String) as Map<String, dynamic>;
              operations.add(
                'register:${request['hour']}:${request['minute']}',
              );
            } else {
              operations.add('cancel');
            }
            mutationVersion++;
            return http.Response('{"success":true}', 200);
          },
        ),
      );

      expect(registered, isFalse);
      expect(operations, ['version:0', 'register:9:30', 'register:8:15']);
      expect(
        user.getNotificationPreference('default')?.toJson(),
        existing.toJson(),
      );
    },
  );

  test(
    'cancel restores the remote schedule when clearing its local preference fails',
    () async {
      const existing = NotificationPreference(hour: 8, minute: 15);
      await user.setNotificationPreference('default', existing);
      memory.notificationPreferenceWritesToFail = 1;
      final operations = <String>[];
      var mutationVersion = 0;

      final cancelled = await _onPlatform(
        TargetPlatform.iOS,
        () => FcmScheduledNotificationService.cancelNotification(
          userInformation: user,
          typeId: 'default',
          idTokenProvider: () async => 'token-123',
          post: (url, {headers, body, encoding}) async {
            if (url.path.endsWith('/getNotificationMutationVersion')) {
              operations.add('version:$mutationVersion');
              return http.Response('{"mutationVersion":$mutationVersion}', 200);
            }
            if (url.path.endsWith('/cancelNotification')) {
              operations.add('cancel');
            } else {
              operations.add('register');
            }
            mutationVersion++;
            return http.Response('{"success":true}', 200);
          },
        ),
      );

      expect(cancelled, isFalse);
      expect(operations, ['version:0', 'cancel', 'register']);
      expect(
        user.getNotificationPreference('default')?.toJson(),
        existing.toJson(),
      );
    },
  );

  testWidgets('cancel keeps the saved schedule when the server rejects it', (
    tester,
  ) async {
    const existing = NotificationPreference(hour: 8, minute: 15);
    user.setNotificationPreference('default', existing);
    await pumpUser(tester);

    final result = await _onPlatform(
      TargetPlatform.android,
      () => FcmScheduledNotificationService.cancelNotification(
        context: serviceContext,
        typeId: 'default',
        idTokenProvider: () async => 'token-123',
        post: (url, {headers, body, encoding}) async =>
            url.path.endsWith('/getNotificationMutationVersion')
            ? http.Response('{"mutationVersion":0}', 200)
            : http.Response('server error', 500),
      ),
    );

    expect(result, isFalse);
    expect(
      user.getNotificationPreference('default')?.toJson(),
      existing.toJson(),
    );
  });

  testWidgets(
    'fenced cancellation keeps the schedule when delivery is already claimed',
    (tester) async {
      const existing = NotificationPreference(hour: 8, minute: 15);
      user.setNotificationPreference('default', existing);
      await pumpUser(tester);
      Map<String, dynamic>? cancellationPayload;

      final result = await _onPlatform(
        TargetPlatform.android,
        () => FcmScheduledNotificationService.cancelNotification(
          context: serviceContext,
          typeId: 'default',
          requireNoActiveDeliveryPermit: true,
          idTokenProvider: () async => 'token-123',
          post: (url, {headers, body, encoding}) async {
            if (url.path.endsWith('/getNotificationMutationVersion')) {
              return http.Response('{"mutationVersion":0}', 200);
            }
            cancellationPayload =
                jsonDecode(body! as String) as Map<String, dynamic>;
            return http.Response(
              'Scheduled delivery is already authorized',
              409,
            );
          },
        ),
      );

      expect(result, isFalse);
      expect(cancellationPayload, {
        'typeId': 'default',
        'expectedMutationVersion': 0,
        'resetFence': true,
      });
      expect(
        user.getNotificationPreference('default')?.toJson(),
        existing.toJson(),
      );
    },
  );

  testWidgets('queue registration completes its serialized turn', (
    tester,
  ) async {
    await pumpUser(tester);

    final registered = await _onPlatform(
      TargetPlatform.android,
      () => FcmScheduledNotificationService.registerNotification(
        context: serviceContext,
        typeId: 'default',
        hour: 9,
        minute: 30,
        idTokenProvider: () async => 'token-123',
        post: (url, {headers, body, encoding}) async =>
            url.path.endsWith('/getNotificationMutationVersion')
            ? http.Response('{"mutationVersion":0}', 200)
            : http.Response('{"success":true}', 200),
      ),
    );

    expect(registered, isTrue);
  });

  testWidgets('queue cancellation runs after a completed serialized turn', (
    tester,
  ) async {
    user.setNotificationPreference(
      'default',
      const NotificationPreference(hour: 8, minute: 15),
    );
    await pumpUser(tester);

    final cancelled = await _onPlatform(
      TargetPlatform.android,
      () => FcmScheduledNotificationService.cancelNotification(
        context: serviceContext,
        typeId: 'default',
        idTokenProvider: () async => 'token-123',
        post: (url, {headers, body, encoding}) async =>
            url.path.endsWith('/getNotificationMutationVersion')
            ? http.Response('{"mutationVersion":0}', 200)
            : http.Response('{"success":true}', 200),
      ),
    );

    expect(cancelled, isTrue);
  });

  testWidgets(
    'a timed out operation releases the serialized notification queue',
    (tester) async {
      user.setNotificationPreference(
        'default',
        const NotificationPreference(hour: 8, minute: 15),
      );
      await pumpUser(tester);
      final stalledPost = Completer<http.Response>();

      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      try {
        final registering =
            FcmScheduledNotificationService.registerNotification(
              userInformation: user,
              typeId: 'default',
              hour: 9,
              minute: 30,
              idTokenProvider: () async => 'token-123',
              post: (url, {headers, body, encoding}) =>
                  url.path.endsWith('/getNotificationMutationVersion')
                  ? Future.value(http.Response('{"mutationVersion":0}', 200))
                  : stalledPost.future,
            );
        final cancelling = FcmScheduledNotificationService.cancelNotification(
          userInformation: user,
          typeId: 'default',
          idTokenProvider: () async => 'token-123',
          post: (url, {headers, body, encoding}) async =>
              url.path.endsWith('/getNotificationMutationVersion')
              ? http.Response('{"mutationVersion":0}', 200)
              : http.Response('{"success":true}', 200),
        );

        bool? registrationResult;
        bool? cancellationResult;
        registering.then((result) => registrationResult = result);
        cancelling.then((result) => cancellationResult = result);
        await tester.pump();
        await tester.pump(const Duration(seconds: 15));

        expect(registrationResult, isFalse);
        expect(cancellationResult, isTrue);
        expect(user.getNotificationPreference('default'), isNull);
      } finally {
        debugDefaultTargetPlatformOverride = null;
      }
    },
  );

  testWidgets(
    'timed-out legacy migration releases the queue for fenced cancellation',
    (tester) async {
      user.setNotificationPreference(
        'default',
        const NotificationPreference(hour: 8, minute: 15),
      );
      memory.migrationMarkerRead = Completer<dynamic>();
      memory.migrationMarkerReadStarted = Completer<void>();
      await pumpUser(tester);
      debugDefaultTargetPlatformOverride = TargetPlatform.android;

      try {
        final migration =
            FcmScheduledNotificationService.migrateLegacyDefaultReminder(
              userInformation: user,
              persistentMemory: memory,
            );
        final migrationFailure = expectLater(
          migration,
          throwsA(isA<TimeoutException>()),
        );
        await tester.pump();
        await memory.migrationMarkerReadStarted!.future;

        final cancellation = FcmScheduledNotificationService.cancelNotification(
          userInformation: user,
          typeId: 'default',
          requireNoActiveDeliveryPermit: true,
          idTokenProvider: () async => 'token-123',
          post: (url, {headers, body, encoding}) async =>
              url.path.endsWith('/getNotificationMutationVersion')
              ? http.Response('{"mutationVersion":0}', 200)
              : http.Response('{"success":true}', 200),
        );
        memory.migrationMarkerRead = null;
        await tester.pump(const Duration(seconds: 5));

        await migrationFailure;
        expect(await cancellation, isTrue);
      } finally {
        debugDefaultTargetPlatformOverride = null;
      }
    },
  );

  testWidgets(
    'a late registration cannot recreate a reminder after reset cancellation',
    (tester) async {
      user.setNotificationPreference(
        'default',
        const NotificationPreference(hour: 8, minute: 15),
      );
      await pumpUser(tester);
      var remoteMutationVersion = 0;
      var remoteSchedulePresent = true;
      Object? registrationExpectedMutationVersion;
      Map<String, dynamic>? resetCancellationPayload;
      final registrationStarted = Completer<void>();
      final completeLateRegistration = Completer<void>();

      Future<http.Response> post(
        Uri url, {
        Map<String, String>? headers,
        Object? body,
        Encoding? encoding,
      }) async {
        if (url.path.endsWith('/getNotificationMutationVersion')) {
          return http.Response(
            jsonEncode({'mutationVersion': remoteMutationVersion}),
            200,
          );
        }

        final payload = jsonDecode(body! as String) as Map<String, dynamic>;
        final expectedMutationVersion = payload['expectedMutationVersion'];
        if (url.path.endsWith('/registerNotification')) {
          registrationExpectedMutationVersion = expectedMutationVersion;
          registrationStarted.complete();
          await completeLateRegistration.future;
        } else if (url.path.endsWith('/cancelNotification')) {
          resetCancellationPayload = payload;
        }

        if (expectedMutationVersion is int &&
            expectedMutationVersion != remoteMutationVersion) {
          return http.Response('Stale notification mutation', 409);
        }

        if (url.path.endsWith('/registerNotification')) {
          remoteSchedulePresent = true;
        } else if (url.path.endsWith('/cancelNotification')) {
          remoteSchedulePresent = false;
        } else {
          fail('Unexpected endpoint: $url');
        }
        if (expectedMutationVersion is int) {
          remoteMutationVersion++;
        }
        return http.Response('{"success":true}', 200);
      }

      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      try {
        final registering =
            FcmScheduledNotificationService.registerNotification(
              userInformation: user,
              typeId: 'default',
              hour: 9,
              minute: 30,
              idTokenProvider: () async => 'token-123',
              post: post,
            );
        await tester.pump();
        await registrationStarted.future;

        final resetCancellation =
            FcmScheduledNotificationService.cancelDefaultForReset(
              userInformation: user,
              idTokenProvider: () async => 'token-123',
              post: post,
            );
        await tester.pump(const Duration(seconds: 15));

        expect(await registering, isFalse);
        expect(await resetCancellation, isTrue);
        expect(registrationExpectedMutationVersion, 0);
        expect(resetCancellationPayload, {
          'typeId': 'default',
          'expectedMutationVersion': 0,
          'resetFence': true,
        });
        expect(remoteMutationVersion, 1);
        expect(remoteSchedulePresent, isFalse);

        completeLateRegistration.complete();
        await tester.pump();
        expect(remoteSchedulePresent, isFalse);
      } finally {
        debugDefaultTargetPlatformOverride = null;
      }
    },
  );

  testWidgets(
    'register returns false when FirebaseAuth has not been initialized',
    (tester) async {
      await GetIt.instance.reset();
      await pumpUser(tester);
      var postCalled = false;

      final result = await _onPlatform(
        TargetPlatform.android,
        () => FcmScheduledNotificationService.registerNotification(
          context: serviceContext,
          typeId: 'default',
          hour: 9,
          minute: 30,
          post: (url, {headers, body, encoding}) async {
            postCalled = true;
            return http.Response('{"success":true}', 200);
          },
        ),
      );

      expect(result, isFalse);
      expect(postCalled, isFalse);
    },
  );

  testWidgets(
    'unsupported platforms skip reminder registration before authentication and network calls',
    (tester) async {
      await pumpUser(tester);
      var tokenRequested = false;
      var postCalled = false;

      final result = await _onPlatform(
        TargetPlatform.windows,
        () => FcmScheduledNotificationService.registerNotification(
          context: serviceContext,
          typeId: 'default',
          hour: 9,
          minute: 30,
          idTokenProvider: () async {
            tokenRequested = true;
            return 'token-123';
          },
          post: (url, {headers, body, encoding}) async {
            postCalled = true;
            return http.Response('{"success":true}', 200);
          },
        ),
      );

      expect(result, isFalse);
      expect(tokenRequested, isFalse);
      expect(postCalled, isFalse);
    },
  );

  testWidgets('remote cancellation runs on an unsupported platform', (
    tester,
  ) async {
    user.setNotificationPreference(
      'default',
      const NotificationPreference(hour: 8, minute: 15),
    );
    await pumpUser(tester);
    var tokenRequested = false;
    final requestPaths = <String>[];

    final result = await _onPlatform(
      TargetPlatform.windows,
      () => FcmScheduledNotificationService.cancelNotification(
        context: serviceContext,
        typeId: 'default',
        requireNoActiveDeliveryPermit: true,
        idTokenProvider: () async {
          tokenRequested = true;
          return 'token-123';
        },
        post: (url, {headers, body, encoding}) async {
          requestPaths.add(url.path);
          return url.path.endsWith('/getNotificationMutationVersion')
              ? http.Response('{"mutationVersion":0}', 200)
              : http.Response('{"success":true}', 200);
        },
      ),
    );

    expect(result, isTrue);
    expect(tokenRequested, isTrue);
    expect(requestPaths, [
      '/getNotificationMutationVersion',
      '/cancelNotification',
    ]);
    expect(user.getNotificationPreference('default'), isNull);
  });

  testWidgets(
    'migrates a persisted legacy reminder, retires it, then marks it once',
    (tester) async {
      expect(user.getNotificationPreference('default'), isNull);
      await pumpUser(tester);
      var postCalls = 0;
      final operations = <String>[];

      await _onPlatform(
        TargetPlatform.android,
        () => FcmScheduledNotificationService.migrateLegacyDefaultReminder(
          context: serviceContext,
          idTokenProvider: () async => 'token-123',
          post: (url, {headers, body, encoding}) async {
            if (url.path.endsWith('/getNotificationMutationVersion')) {
              return http.Response('{"mutationVersion":0}', 200);
            }
            postCalls++;
            operations.add('register');
            return http.Response('{"success":true}', 200);
          },
          legacyNotificationCanceller: (notificationId) async {
            expect(
              memory.stored.containsKey('fcmDefaultReminderMigrated'),
              isFalse,
            );
            operations.add('cancel:$notificationId');
          },
        ),
      );
      await _onPlatform(
        TargetPlatform.android,
        () => FcmScheduledNotificationService.migrateLegacyDefaultReminder(
          context: serviceContext,
          idTokenProvider: () async => 'token-123',
          post: (url, {headers, body, encoding}) async {
            if (url.path.endsWith('/getNotificationMutationVersion')) {
              return http.Response('{"mutationVersion":0}', 200);
            }
            postCalls++;
            return http.Response('{"success":true}', 200);
          },
          legacyNotificationCanceller: (notificationId) async {
            operations.add('cancel:$notificationId');
          },
        ),
      );

      expect(postCalls, 1);
      expect(operations, ['register', 'cancel:815']);
      expect(memory.stored['fcmDefaultReminderMigrated'], isTrue);
    },
  );

  testWidgets('does not migrate a reminder without a persisted legacy time', (
    tester,
  ) async {
    memory.stored.remove('notificationHour');
    memory.stored.remove('notificationMinute');
    user.setNotificationPreference(
      'default',
      const NotificationPreference(hour: 8, minute: 15),
    );
    await pumpUser(tester);
    var postCalls = 0;
    final cancelledIds = <int>[];

    await _onPlatform(
      TargetPlatform.android,
      () => FcmScheduledNotificationService.migrateLegacyDefaultReminder(
        userInformation: user,
        idTokenProvider: () async => 'token-123',
        post: (url, {headers, body, encoding}) async {
          postCalls++;
          return http.Response('{"success":true}', 200);
        },
        legacyNotificationCanceller: (notificationId) async {
          cancelledIds.add(notificationId);
        },
      ),
    );

    expect(postCalls, 0);
    expect(cancelledIds, isEmpty);
    expect(memory.stored.containsKey('fcmDefaultReminderMigrated'), isFalse);
  });

  testWidgets('reports a migration-marker read failure without propagating it', (
    tester,
  ) async {
    final logger = _RecordingIncidentLogger();
    final exception = StateError('migration marker unavailable');
    final stackTrace = StackTrace.current;
    memory.migrationMarkerReadError = exception;
    memory.migrationMarkerReadStackTrace = stackTrace;
    GetIt.instance.registerSingleton<IncidentLoggerService>(logger);
    user.setNotificationPreference(
      'default',
      const NotificationPreference(hour: 8, minute: 15),
    );

    await _onPlatform(
      TargetPlatform.android,
      () =>
          FcmScheduledNotificationService.migrateLegacyDefaultReminderWithReporting(
            userInformation: user,
          ),
    );

    expect(logger.capturedError, same(exception));
    expect(logger.capturedStackTrace, same(stackTrace));
  });

  testWidgets('contains logger failures while reporting a migration failure', (
    tester,
  ) async {
    final logger = _ThrowingIncidentLogger();
    memory.migrationMarkerReadError = StateError(
      'migration marker unavailable',
    );
    memory.migrationMarkerReadStackTrace = StackTrace.current;
    GetIt.instance.registerSingleton<IncidentLoggerService>(logger);
    user.setNotificationPreference(
      'default',
      const NotificationPreference(hour: 8, minute: 15),
    );

    await expectLater(
      _onPlatform(
        TargetPlatform.android,
        () =>
            FcmScheduledNotificationService.migrateLegacyDefaultReminderWithReporting(
              userInformation: user,
            ),
      ),
      completes,
    );

    expect(logger.captureAttempted, isTrue);
  });

  testWidgets(
    'leaves migration unmarked when authentication or registration fails',
    (tester) async {
      user.setNotificationPreference(
        'default',
        const NotificationPreference(hour: 8, minute: 15),
      );
      await pumpUser(tester);
      var postCalls = 0;
      final cancelledIds = <int>[];

      await _onPlatform(
        TargetPlatform.android,
        () => FcmScheduledNotificationService.migrateLegacyDefaultReminder(
          context: serviceContext,
          idTokenProvider: () async => null,
          post: (url, {headers, body, encoding}) async {
            if (url.path.endsWith('/getNotificationMutationVersion')) {
              return http.Response('{"mutationVersion":0}', 200);
            }
            postCalls++;
            return http.Response('{"success":true}', 200);
          },
          legacyNotificationCanceller: (notificationId) async {
            cancelledIds.add(notificationId);
          },
        ),
      );
      await _onPlatform(
        TargetPlatform.android,
        () => FcmScheduledNotificationService.migrateLegacyDefaultReminder(
          context: serviceContext,
          idTokenProvider: () async => 'token-123',
          post: (url, {headers, body, encoding}) async {
            if (url.path.endsWith('/getNotificationMutationVersion')) {
              return http.Response('{"mutationVersion":0}', 200);
            }
            postCalls++;
            return http.Response('failed', 500);
          },
          legacyNotificationCanceller: (notificationId) async {
            cancelledIds.add(notificationId);
          },
        ),
      );

      expect(postCalls, 1);
      expect(cancelledIds, isEmpty);
      expect(memory.stored.containsKey('fcmDefaultReminderMigrated'), isFalse);
    },
  );

  testWidgets(
    'leaves migration retryable when legacy local reminder cancellation fails',
    (tester) async {
      memory.stored['notificationHour'] = 8;
      memory.stored['notificationMinute'] = 15;
      user.setNotificationPreference(
        'default',
        const NotificationPreference(hour: 8, minute: 15),
      );
      await pumpUser(tester);
      final registrations = <({int hour, int minute})>[];
      var cancellationCalls = 0;
      final cancelledIds = <int>[];

      Future<http.Response> post(
        Uri url, {
        Map<String, String>? headers,
        Object? body,
        Encoding? encoding,
      }) async {
        if (url.path.endsWith('/getNotificationMutationVersion')) {
          return http.Response('{"mutationVersion":0}', 200);
        }
        final payload = jsonDecode(body! as String) as Map<String, dynamic>;
        registrations.add((
          hour: payload['hour'] as int,
          minute: payload['minute'] as int,
        ));
        return http.Response('{"success":true}', 200);
      }

      Future<void> cancelLegacyNotification(int notificationId) async {
        cancellationCalls++;
        cancelledIds.add(notificationId);
        if (cancellationCalls == 1) {
          throw StateError('local notification database unavailable');
        }
      }

      await expectLater(
        _onPlatform(
          TargetPlatform.android,
          () => FcmScheduledNotificationService.migrateLegacyDefaultReminder(
            context: serviceContext,
            idTokenProvider: () async => 'token-123',
            post: post,
            legacyNotificationCanceller: cancelLegacyNotification,
          ),
        ),
        throwsA(isA<StateError>()),
      );
      expect(memory.stored.containsKey('fcmDefaultReminderMigrated'), isFalse);
      await _onPlatform(
        TargetPlatform.android,
        () => FcmScheduledNotificationService.migrateLegacyDefaultReminder(
          context: serviceContext,
          idTokenProvider: () async => 'token-123',
          post: post,
          legacyNotificationCanceller: cancelLegacyNotification,
        ),
      );

      expect(registrations, [(hour: 8, minute: 15), (hour: 8, minute: 15)]);
      expect(cancelledIds, [815, 815]);
      expect(memory.stored['fcmDefaultReminderMigrated'], isTrue);
    },
  );

  testWidgets(
    'serializes concurrent legacy migrations before reading the marker',
    (tester) async {
      user.setNotificationPreference(
        'default',
        const NotificationPreference(hour: 8, minute: 15),
      );
      memory.migrationMarkerRead = Completer<dynamic>();
      memory.migrationMarkerReadStarted = Completer<void>();
      await pumpUser(tester);
      var postCalls = 0;

      final first = _onPlatform(
        TargetPlatform.android,
        () => FcmScheduledNotificationService.migrateLegacyDefaultReminder(
          userInformation: user,
          idTokenProvider: () async => 'token-123',
          legacyNotificationCanceller: _ignoreLegacyNotification,
          post: (url, {headers, body, encoding}) async {
            if (url.path.endsWith('/getNotificationMutationVersion')) {
              return http.Response('{"mutationVersion":0}', 200);
            }
            postCalls++;
            return http.Response('{"success":true}', 200);
          },
        ),
      );
      await memory.migrationMarkerReadStarted!.future;
      final second = _onPlatform(
        TargetPlatform.android,
        () => FcmScheduledNotificationService.migrateLegacyDefaultReminder(
          userInformation: user,
          idTokenProvider: () async => 'token-123',
          legacyNotificationCanceller: _ignoreLegacyNotification,
          post: (url, {headers, body, encoding}) async {
            if (url.path.endsWith('/getNotificationMutationVersion')) {
              return http.Response('{"mutationVersion":0}', 200);
            }
            postCalls++;
            return http.Response('{"success":true}', 200);
          },
        ),
      );
      final markerRead = memory.migrationMarkerRead!;
      memory.migrationMarkerRead = null;
      markerRead.complete(false);

      await Future.wait([first, second]);

      expect(postCalls, 1);
      expect(memory.stored['fcmDefaultReminderMigrated'], isTrue);
    },
  );

  testWidgets(
    'failed reset cancellation permits a subsequent legacy migration',
    (tester) async {
      user.setNotificationPreference(
        'default',
        const NotificationPreference(hour: 8, minute: 15),
      );
      await pumpUser(tester);
      var cancelRequests = 0;
      var registerRequests = 0;

      final cancelled = await _onPlatform(
        TargetPlatform.windows,
        () => FcmScheduledNotificationService.cancelDefaultForReset(
          userInformation: user,
          idTokenProvider: () async => 'token-123',
          post: (url, {headers, body, encoding}) async {
            if (url.path.endsWith('/getNotificationMutationVersion')) {
              return http.Response('{"mutationVersion":0}', 200);
            }
            cancelRequests++;
            return http.Response('failed', 500);
          },
        ),
      );

      expect(cancelled, isFalse);
      expect(cancelRequests, 1);
      expect(memory.stored.containsKey('fcmDefaultReminderMigrated'), isFalse);

      await _onPlatform(
        TargetPlatform.android,
        () => FcmScheduledNotificationService.migrateLegacyDefaultReminder(
          userInformation: user,
          idTokenProvider: () async => 'token-123',
          legacyNotificationCanceller: _ignoreLegacyNotification,
          post: (url, {headers, body, encoding}) async {
            if (url.path.endsWith('/getNotificationMutationVersion')) {
              return http.Response('{"mutationVersion":0}', 200);
            }
            registerRequests++;
            return http.Response('{"success":true}', 200);
          },
        ),
      );

      expect(registerRequests, 1);
      expect(memory.stored['fcmDefaultReminderMigrated'], isTrue);
    },
  );

  testWidgets(
    'local reset failure restores the remote reminder after cancellation off platform',
    (tester) async {
      const previousPreference = NotificationPreference(hour: 8, minute: 15);
      user.setNotificationPreference('default', previousPreference);
      await pumpUser(tester);
      var cancelRequests = 0;
      var registerRequests = 0;

      final cancelled = await _onPlatform(
        TargetPlatform.windows,
        () => FcmScheduledNotificationService.cancelDefaultForReset(
          userInformation: user,
          idTokenProvider: () async => 'token-123',
          post: (url, {headers, body, encoding}) async {
            if (url.path.endsWith('/getNotificationMutationVersion')) {
              return http.Response('{"mutationVersion":0}', 200);
            }
            cancelRequests++;
            return http.Response('{"success":true}', 200);
          },
        ),
      );

      expect(cancelled, isTrue);
      expect(cancelRequests, 1);
      expect(user.getNotificationPreference('default'), isNull);

      memory.stored['fcmDefaultReminderMigrated'] = true;
      final restored = await _onPlatform(
        TargetPlatform.windows,
        () =>
            FcmScheduledNotificationService.restoreDefaultReminderAfterResetFailure(
              userInformation: user,
              previousPreference: previousPreference,
              idTokenProvider: () async => 'token-123',
              post: (url, {headers, body, encoding}) async {
                if (url.path.endsWith('/getNotificationMutationVersion')) {
                  return http.Response('{"mutationVersion":1}', 200);
                }
                registerRequests++;
                return http.Response('{"success":true}', 200);
              },
            ),
      );

      expect(restored, isTrue);
      expect(user.getNotificationPreference('default')?.hour, 8);
      expect(user.getNotificationPreference('default')?.minute, 15);
      expect(registerRequests, 1);
      expect(memory.stored['fcmDefaultReminderMigrated'], isTrue);
    },
  );

  testWidgets(
    'reset cancellation prevents an in-flight migration from registering',
    (tester) async {
      user.setNotificationPreference(
        'default',
        const NotificationPreference(hour: 8, minute: 15),
      );
      memory.migrationMarkerRead = Completer<dynamic>();
      memory.migrationMarkerReadStarted = Completer<void>();
      await pumpUser(tester);
      final requests = <String>[];

      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      try {
        final migration =
            FcmScheduledNotificationService.migrateLegacyDefaultReminder(
              userInformation: user,
              idTokenProvider: () async => 'token-123',
              post: (url, {headers, body, encoding}) async {
                if (url.path.endsWith('/getNotificationMutationVersion')) {
                  return http.Response('{"mutationVersion":0}', 200);
                }
                requests.add(url.path);
                return http.Response('{"success":true}', 200);
              },
            );
        await tester.pump();
        await memory.migrationMarkerReadStarted!.future;

        final resetCancellation =
            FcmScheduledNotificationService.cancelDefaultForReset(
              userInformation: user,
              idTokenProvider: () async => 'token-123',
              post: (url, {headers, body, encoding}) async {
                if (url.path.endsWith('/getNotificationMutationVersion')) {
                  return http.Response('{"mutationVersion":0}', 200);
                }
                requests.add(url.path);
                return http.Response('{"success":true}', 200);
              },
            );
        final migrationMarkerRead = memory.migrationMarkerRead!;
        memory.migrationMarkerRead = null;
        migrationMarkerRead.complete(false);

        expect(await resetCancellation, isTrue);
        await migration;
        expect(requests, ['/cancelNotification']);
      } finally {
        debugDefaultTargetPlatformOverride = null;
      }
    },
  );

  testWidgets(
    'manual cancellation retires the legacy local reminder after remote success',
    (tester) async {
      user.setNotificationPreference(
        'default',
        const NotificationPreference(hour: 8, minute: 15),
      );
      await pumpUser(tester);
      final operations = <String>[];
      FcmService.debugCancelLegacyLocalNotificationOverride =
          (notificationId) async => operations.add('local:$notificationId');

      final cancelled = await _onPlatform(
        TargetPlatform.windows,
        () => FcmScheduledNotificationService.cancelNotification(
          userInformation: user,
          typeId: 'default',
          idTokenProvider: () async => 'token-123',
          post: (url, {headers, body, encoding}) async {
            if (url.path.endsWith('/getNotificationMutationVersion')) {
              return http.Response('{"mutationVersion":0}', 200);
            }
            operations.add('remote');
            return http.Response('{"success":true}', 200);
          },
        ),
      );

      expect(cancelled, isTrue);
      expect(operations, ['remote', 'local:815']);
      expect(memory.stored['fcmDefaultReminderMigrated'], isTrue);
      expect(user.getNotificationPreference('default'), isNull);
    },
  );

  testWidgets(
    'reset cancellation retires the legacy local reminder after remote success',
    (tester) async {
      user.setNotificationPreference(
        'default',
        const NotificationPreference(hour: 8, minute: 15),
      );
      await pumpUser(tester);
      final operations = <String>[];
      FcmService.debugCancelLegacyLocalNotificationOverride =
          (notificationId) async => operations.add('local:$notificationId');

      final cancelled = await _onPlatform(
        TargetPlatform.windows,
        () => FcmScheduledNotificationService.cancelDefaultForReset(
          userInformation: user,
          idTokenProvider: () async => 'token-123',
          post: (url, {headers, body, encoding}) async {
            if (url.path.endsWith('/getNotificationMutationVersion')) {
              return http.Response('{"mutationVersion":0}', 200);
            }
            operations.add('remote');
            return http.Response('{"success":true}', 200);
          },
        ),
      );

      expect(cancelled, isTrue);
      expect(operations, ['remote', 'local:815']);
      expect(memory.stored['fcmDefaultReminderMigrated'], isTrue);
      expect(user.getNotificationPreference('default'), isNull);
    },
  );

  testWidgets(
    'default cancellation keeps its marker unset when legacy retirement fails',
    (tester) async {
      user.setNotificationPreference(
        'default',
        const NotificationPreference(hour: 8, minute: 15),
      );
      await pumpUser(tester);
      FcmService.debugCancelLegacyLocalNotificationOverride =
          (notificationId) async => throw StateError('local cancel failed');
      final operations = <String>[];
      var mutationVersion = 0;

      final cancelled = await _onPlatform(
        TargetPlatform.android,
        () => FcmScheduledNotificationService.cancelNotification(
          userInformation: user,
          typeId: 'default',
          idTokenProvider: () async => 'token-123',
          post: (url, {headers, body, encoding}) async {
            if (url.path.endsWith('/getNotificationMutationVersion')) {
              operations.add('version:$mutationVersion');
              return http.Response('{"mutationVersion":$mutationVersion}', 200);
            }
            operations.add(
              url.path.endsWith('/cancelNotification') ? 'cancel' : 'register',
            );
            mutationVersion++;
            return http.Response('{"success":true}', 200);
          },
        ),
      );

      expect(cancelled, isFalse);
      expect(operations, ['version:0', 'cancel', 'register']);
      expect(memory.stored.containsKey('fcmDefaultReminderMigrated'), isFalse);
      expect(user.getNotificationPreference('default'), isNotNull);
    },
  );

  testWidgets(
    'sign-out retires the legacy local reminder and prevents queued migration',
    (tester) async {
      user.setNotificationPreference(
        'default',
        const NotificationPreference(hour: 8, minute: 15),
      );
      memory.migrationMarkerRead = Completer<dynamic>();
      memory.migrationMarkerReadStarted = Completer<void>();
      await pumpUser(tester);
      final operations = <String>[];

      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      try {
        final migration =
            FcmScheduledNotificationService.migrateLegacyDefaultReminder(
              userInformation: user,
              idTokenProvider: () async => 'token-123',
              post: (url, {headers, body, encoding}) async {
                if (url.path.endsWith('/getNotificationMutationVersion')) {
                  return http.Response('{"mutationVersion":0}', 200);
                }
                operations.add('register');
                return http.Response('{"success":true}', 200);
              },
            );
        await tester.pump();
        await memory.migrationMarkerReadStarted!.future;

        final signOutCancellation =
            FcmScheduledNotificationService.cancelDefaultForSignOut(
              userInformation: user,
              idTokenProvider: () async => 'token-123',
              post: (url, {headers, body, encoding}) async {
                if (url.path.endsWith('/getNotificationMutationVersion')) {
                  return http.Response('{"mutationVersion":0}', 200);
                }
                operations.add('remote');
                return http.Response('{"success":true}', 200);
              },
              legacyNotificationCanceller: (notificationId) async {
                operations.add('local:$notificationId');
              },
            );
        final migrationMarkerRead = memory.migrationMarkerRead!;
        memory.migrationMarkerRead = null;
        migrationMarkerRead.complete(false);

        expect(await signOutCancellation, isTrue);
        await migration;
      expect(operations, ['remote', 'local:815']);
        expect(memory.stored['fcmDefaultReminderMigrated'], isTrue);
        expect(user.getNotificationPreference('default'), isNull);
      } finally {
        debugDefaultTargetPlatformOverride = null;
      }
    },
  );

  testWidgets(
    'sign-out remains blocked when its legacy migration marker cannot persist',
    (tester) async {
      user.setNotificationPreference(
        'default',
        const NotificationPreference(hour: 8, minute: 15),
      );
      memory.migrationMarkerWriteError = StateError('disk unavailable');
      await pumpUser(tester);
      final operations = <String>[];
      var mutationVersion = 0;

      final cancelled = await _onPlatform(
        TargetPlatform.android,
        () => FcmScheduledNotificationService.cancelDefaultForSignOut(
          userInformation: user,
          idTokenProvider: () async => 'token-123',
          post: (url, {headers, body, encoding}) async {
            if (url.path.endsWith('/getNotificationMutationVersion')) {
              operations.add('version:$mutationVersion');
              return http.Response('{"mutationVersion":$mutationVersion}', 200);
            }
            operations.add(
              url.path.endsWith('/cancelNotification') ? 'cancel' : 'register',
            );
            mutationVersion++;
            return http.Response('{"success":true}', 200);
          },
          legacyNotificationCanceller: _ignoreLegacyNotification,
        ),
      );

      expect(cancelled, isFalse);
      expect(operations, ['version:0', 'cancel', 'register']);
      expect(memory.stored.containsKey('fcmDefaultReminderMigrated'), isFalse);
      expect(user.getNotificationPreference('default'), isNotNull);
    },
  );

  testWidgets('sign-out bounds a pending legacy migration marker write', (
    tester,
  ) async {
    user.setNotificationPreference(
      'default',
      const NotificationPreference(hour: 8, minute: 15),
    );
    memory.migrationMarkerWrite = Completer<void>();
    await pumpUser(tester);

    final cancelled = _onPlatform(
      TargetPlatform.android,
      () => FcmScheduledNotificationService.cancelDefaultForSignOut(
        userInformation: user,
        idTokenProvider: () async => 'token-123',
        post: (url, {headers, body, encoding}) async {
          if (url.path.endsWith('/getNotificationMutationVersion')) {
            return http.Response('{"mutationVersion":0}', 200);
          }
          return http.Response('{"success":true}', 200);
        },
        legacyNotificationCanceller: _ignoreLegacyNotification,
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 5));

    expect(await cancelled, isFalse);
    expect(memory.stored.containsKey('fcmDefaultReminderMigrated'), isFalse);
    expect(user.getNotificationPreference('default'), isNotNull);
  });

  testWidgets(
    'migration does not restore a reminder cancelled before its queued turn',
    (tester) async {
      user.setNotificationPreference(
        'default',
        const NotificationPreference(hour: 8, minute: 15),
      );
      await pumpUser(tester);
      final cancelResponse = Completer<http.Response>();
      final requests = <String>[];

      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      try {
        final cancellation = FcmScheduledNotificationService.cancelNotification(
          userInformation: user,
          typeId: 'default',
          idTokenProvider: () async => 'token-123',
          post: (url, {headers, body, encoding}) async {
            if (url.path.endsWith('/getNotificationMutationVersion')) {
              return http.Response('{"mutationVersion":0}', 200);
            }
            requests.add(url.path);
            return cancelResponse.future;
          },
        );
        await tester.pump();

        final migration =
            FcmScheduledNotificationService.migrateLegacyDefaultReminder(
              userInformation: user,
              idTokenProvider: () async => 'token-123',
              post: (url, {headers, body, encoding}) async {
                if (url.path.endsWith('/getNotificationMutationVersion')) {
                  return http.Response('{"mutationVersion":0}', 200);
                }
                requests.add(url.path);
                return http.Response('{"success":true}', 200);
              },
            );
        cancelResponse.complete(http.Response('{"success":true}', 200));

        expect(await cancellation, isTrue);
        await migration;
        expect(requests, ['/cancelNotification']);
        expect(memory.stored['fcmDefaultReminderMigrated'], isTrue);
      } finally {
        debugDefaultTargetPlatformOverride = null;
      }
    },
  );
}
