import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:http/http.dart' as http;
import 'package:mazilon/global_enums.dart';
import 'package:mazilon/util/Firebase/fcm_scheduled_notification_service.dart';
import 'package:mazilon/util/notification_preference.dart';
import 'package:mazilon/util/persistent_memory_service.dart';
import 'package:mazilon/util/userInformation.dart';
import 'package:provider/provider.dart';

class _FakePersistentMemoryService implements PersistentMemoryService {
  final Map<String, dynamic> stored = {};
  Completer<dynamic>? migrationMarkerRead;
  Completer<void>? migrationMarkerReadStarted;

  @override
  Future<dynamic> getItem(String key, PersistentMemoryType type) async {
    if (key == 'fcmDefaultReminderMigrated' && migrationMarkerRead != null) {
      migrationMarkerReadStarted?.complete();
      return migrationMarkerRead!.future;
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
    stored[key] = value;
  }
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

void main() {
  late _FakePersistentMemoryService memory;
  late UserInformation user;
  late BuildContext serviceContext;

  setUp(() {
    memory = _FakePersistentMemoryService();
    GetIt.instance.registerSingleton<PersistentMemoryService>(memory);
    user = UserInformation(
      service: memory,
      localeName: 'en',
      gender: 'female',
      loggedIn: true,
    );
  });

  tearDown(() async {
    FcmScheduledNotificationService.resetForTesting();
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

  testWidgets('register sends an authenticated FCM schedule and saves it', (
    tester,
  ) async {
    await pumpUser(tester);
    late Uri requestedUrl;
    late Map<String, String> requestedHeaders;
    late String requestedBody;

    final result = await _onPlatform(
      TargetPlatform.android,
      () => FcmScheduledNotificationService.registerNotification(
        context: serviceContext,
        typeId: 'default',
        hour: 9,
        minute: 30,
        idTokenProvider: () async => 'token-123',
        post: (url, {headers, body, encoding}) async {
          requestedUrl = url;
          requestedHeaders = headers!;
          requestedBody = body! as String;
          return http.Response('{}', 200);
        },
      ),
    );

    expect(result, isTrue);
    expect(
      requestedUrl.toString(),
      'https://us-central1-mezilondb.cloudfunctions.net/registerNotification',
    );
    expect(requestedHeaders['Authorization'], 'Bearer token-123');
    expect(jsonDecode(requestedBody), {
      'typeId': 'default',
      'hour': 9,
      'minute': 30,
      'locale': 'en',
      'gender': 'female',
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
            http.Response('{}', 200),
      ),
    );

    expect(result, isTrue);
    expect(user.getNotificationPreference('default'), isNull);
  });

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
            http.Response('server error', 500),
      ),
    );

    expect(result, isFalse);
    expect(
      user.getNotificationPreference('default')?.toJson(),
      existing.toJson(),
    );
  });

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
            http.Response('{}', 200),
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
            http.Response('{}', 200),
      ),
    );

    expect(cancelled, isTrue);
  });

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
            return http.Response('{}', 200);
          },
        ),
      );

      expect(result, isFalse);
      expect(postCalled, isFalse);
    },
  );

  testWidgets(
    'unsupported platforms stop before authentication and network calls',
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
            return http.Response('{}', 200);
          },
        ),
      );

      expect(result, isFalse);
      expect(tokenRequested, isFalse);
      expect(postCalled, isFalse);
    },
  );

  testWidgets(
    'migrates an unmarked default preference once after remote registration succeeds',
    (tester) async {
      user.setNotificationPreference(
        'default',
        const NotificationPreference(hour: 8, minute: 15),
      );
      await pumpUser(tester);
      var postCalls = 0;

      await _onPlatform(
        TargetPlatform.android,
        () => FcmScheduledNotificationService.migrateLegacyDefaultReminder(
          context: serviceContext,
          idTokenProvider: () async => 'token-123',
          post: (url, {headers, body, encoding}) async {
            postCalls++;
            return http.Response('{}', 200);
          },
        ),
      );
      await _onPlatform(
        TargetPlatform.android,
        () => FcmScheduledNotificationService.migrateLegacyDefaultReminder(
          context: serviceContext,
          idTokenProvider: () async => 'token-123',
          post: (url, {headers, body, encoding}) async {
            postCalls++;
            return http.Response('{}', 200);
          },
        ),
      );

      expect(postCalls, 1);
      expect(memory.stored['fcmDefaultReminderMigrated'], isTrue);
    },
  );

  testWidgets(
    'leaves migration unmarked when authentication or registration fails',
    (tester) async {
      user.setNotificationPreference(
        'default',
        const NotificationPreference(hour: 8, minute: 15),
      );
      await pumpUser(tester);
      var postCalls = 0;

      await _onPlatform(
        TargetPlatform.android,
        () => FcmScheduledNotificationService.migrateLegacyDefaultReminder(
          context: serviceContext,
          idTokenProvider: () async => null,
          post: (url, {headers, body, encoding}) async {
            postCalls++;
            return http.Response('{}', 200);
          },
        ),
      );
      await _onPlatform(
        TargetPlatform.android,
        () => FcmScheduledNotificationService.migrateLegacyDefaultReminder(
          context: serviceContext,
          idTokenProvider: () async => 'token-123',
          post: (url, {headers, body, encoding}) async {
            postCalls++;
            return http.Response('failed', 500);
          },
        ),
      );

      expect(postCalls, 1);
      expect(memory.stored.containsKey('fcmDefaultReminderMigrated'), isFalse);
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
          post: (url, {headers, body, encoding}) async {
            postCalls++;
            return http.Response('{}', 200);
          },
        ),
      );
      await memory.migrationMarkerReadStarted!.future;
      final second = _onPlatform(
        TargetPlatform.android,
        () => FcmScheduledNotificationService.migrateLegacyDefaultReminder(
          userInformation: user,
          idTokenProvider: () async => 'token-123',
          post: (url, {headers, body, encoding}) async {
            postCalls++;
            return http.Response('{}', 200);
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
        TargetPlatform.android,
        () => FcmScheduledNotificationService.cancelDefaultForReset(
          userInformation: user,
          idTokenProvider: () async => 'token-123',
          post: (url, {headers, body, encoding}) async {
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
          post: (url, {headers, body, encoding}) async {
            registerRequests++;
            return http.Response('{}', 200);
          },
        ),
      );

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
                requests.add(url.path);
                return http.Response('{}', 200);
              },
            );
        await tester.pump();
        await memory.migrationMarkerReadStarted!.future;

        final resetCancellation =
            FcmScheduledNotificationService.cancelDefaultForReset(
              userInformation: user,
              idTokenProvider: () async => 'token-123',
              post: (url, {headers, body, encoding}) async {
                requests.add(url.path);
                return http.Response('{}', 200);
              },
            );
        memory.migrationMarkerRead!.complete(false);

        expect(await resetCancellation, isTrue);
        await migration;
        expect(requests, ['/cancelNotification']);
      } finally {
        debugDefaultTargetPlatformOverride = null;
      }
    },
  );
}
