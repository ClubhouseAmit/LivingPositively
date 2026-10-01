import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:http/http.dart' as http;
import 'package:mazilon/features/notifications/data/fcm_scheduled_notification_service.dart';
import 'package:mazilon/features/notifications/data/notification_models.dart';
import 'package:mazilon/util/userInformation.dart';
import 'package:mockito/mockito.dart';

import '../Firebase/firebase_auth_service_test.mocks.dart';
import '../helpers/widget_test_scaffold.dart';

void main() {
  group('Reminder limit response', () {
    late UserInformation user;
    late String responseBody;

    setUp(() {
      final auth = MockFirebaseAuth();
      final firebaseUser = MockUser();
      when(auth.currentUser).thenReturn(firebaseUser);
      when(firebaseUser.isAnonymous).thenReturn(false);
      when(firebaseUser.getIdToken()).thenAnswer((_) async => 'token');
      GetIt.instance.registerSingleton<FirebaseAuth>(auth);
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      user = UserInformation(
        service: FakePersistentMemoryService(),
        loggedIn: true,
        userId: 'account-a',
      );
      FcmScheduledNotificationService.debugPostOverride =
          (url, {headers, body, encoding}) async =>
              url.path.endsWith('/getNotificationMutationVersion')
              ? http.Response('{"mutationVersion":0}', 200)
              : http.Response(responseBody, 429);
    });

    tearDown(() async {
      FcmScheduledNotificationService.debugPostOverride = null;
      debugDefaultTargetPlatformOverride = null;
      await GetIt.instance.reset();
    });

    Future<bool> register() => registerTextReminder(
      userInformation: user,
      typeId: 'custom_limit_test',
      hour: 8,
      minute: 0,
      title: 'Living Positively',
      body: 'Practice',
    );

    test('should report the explicit server reminder limit', () async {
      responseBody = '{"error":"REMINDER_LIMIT_REACHED"}';
      await expectLater(
        register(),
        throwsA(isA<NotificationReminderLimitException>()),
      );
    });

    for (final body in [
      'No instance available',
      '{"error":"RESOURCE_EXHAUSTED"}',
      '{"message":"Reminder limit reached"}',
      '',
    ]) {
      test(
        'should treat infrastructure 429 as retryable failure: $body',
        () async {
          responseBody = body;
          expect(await register(), isFalse);
        },
      );
    }
  });
}
