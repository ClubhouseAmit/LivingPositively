import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:http/http.dart' as http;
import 'package:mazilon/features/notifications/data/fcm_scheduled_notification_service.dart';
import 'package:mazilon/features/notifications/data/notification_models.dart';
import 'package:mazilon/features/notifications/data/notification_repository.dart';
import 'package:mazilon/features/notifications/ui/notification_locale_rescheduler.dart';
import 'package:mazilon/l10n/app_localizations_en.dart';
import 'package:mazilon/util/userInformation.dart';
import 'package:mockito/mockito.dart';

import '../Firebase/firebase_auth_service_test.mocks.dart';
import '../helpers/widget_test_scaffold.dart';

void main() {
  group('rescheduleNotificationsForLocale', () {
    testWidgets('should continue after one reminder reaches the server limit', (
      tester,
    ) async {
      final memory = FakePersistentMemoryService();
      final user = UserInformation(
        service: memory,
        loggedIn: true,
        userId: 'account-a',
        localeName: 'en',
      );
      final repository = NotificationRepository.forService(memory);
      for (final id in ['quick_exercise', 'quick_water']) {
        await repository.setPreference(
          id,
          const NotificationPreference.withContent(
            hour: 9,
            minute: 0,
            staticTitle: 'Living Positively',
            staticBody: 'Reminder',
          ),
        );
      }
      final auth = MockFirebaseAuth();
      final firebaseUser = MockUser();
      when(auth.currentUser).thenReturn(firebaseUser);
      when(firebaseUser.isAnonymous).thenReturn(false);
      when(firebaseUser.getIdToken()).thenAnswer((_) async => 'token-123');
      GetIt.instance.registerSingleton<FirebaseAuth>(auth);
      final registrations = <String>[];
      var rejectedOnce = false;
      FcmScheduledNotificationService.debugPostOverride =
          (url, {headers, body, encoding}) async {
            final request = jsonDecode(body! as String) as Map<String, dynamic>;
            if (url.path.endsWith('/getNotificationMutationVersion')) {
              return http.Response('{"mutationVersion":0}', 200);
            }
            final id = request['typeId'] as String;
            registrations.add(id);
            if (id == 'quick_exercise' && !rejectedOnce) {
              rejectedOnce = true;
              return http.Response('{}', 429);
            }
            return http.Response('{"success":true,"mutationVersion":1}', 200);
          };
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      try {
        final refresh = rescheduleNotificationsForLocale(
          user,
          AppLocalizationsEn(),
        );
        for (var i = 0; i < 10; i++) {
          await tester.pump();
        }
        expect(registrations.take(2), ['quick_exercise', 'quick_water']);
        await tester.pump(const Duration(seconds: 5));
        await refresh;
        expect(registrations, [
          'quick_exercise',
          'quick_water',
          'quick_exercise',
          'quick_water',
        ]);
      } finally {
        debugDefaultTargetPlatformOverride = null;
        FcmScheduledNotificationService.resetForTesting();
        await GetIt.instance.reset();
      }
    });
  });
}
