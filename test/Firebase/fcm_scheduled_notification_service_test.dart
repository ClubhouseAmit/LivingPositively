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

  @override
  Future<dynamic> getItem(String key, PersistentMemoryType type) async =>
      stored[key];

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
    user = UserInformation(
      service: memory,
      localeName: 'en',
      gender: 'female',
      loggedIn: true,
    );
  });

  tearDown(() async {
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
    'cancel remains available on unsupported platforms for account reset',
    (tester) async {
      await pumpUser(tester);
      var postCalled = false;

      final result = await _onPlatform(
        TargetPlatform.windows,
        () => FcmScheduledNotificationService.cancelNotification(
          context: serviceContext,
          typeId: 'default',
          idTokenProvider: () async => 'token-123',
          post: (url, {headers, body, encoding}) async {
            postCalled = true;
            return http.Response('{}', 200);
          },
        ),
      );

      expect(result, isTrue);
      expect(postCalled, isTrue);
    },
  );
}
