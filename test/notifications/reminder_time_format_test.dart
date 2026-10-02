import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mazilon/features/notifications/data/fcm_scheduled_notification_service.dart';
import 'package:mazilon/features/notifications/data/fcm_service.dart';
import 'package:mazilon/features/notifications/data/notification_models.dart';
import 'package:mazilon/features/notifications/data/notification_repository.dart';
import 'package:mazilon/features/appearance/ui/appearance_settings.dart';
import 'package:mazilon/features/notifications/ui/custom_reminder_form.dart';
import 'package:mazilon/features/notifications/ui/notification_toggle_card.dart';
import 'package:mazilon/features/notifications/ui/reminder_item_card.dart';
import 'package:mazilon/pages/notification_page.dart';
import 'package:mazilon/features/shell/ui/app_time_format.dart';
import 'package:mazilon/l10n/app_localizations.dart';
import 'package:mazilon/l10n/app_localizations_he.dart';
import 'package:mazilon/util/userInformation.dart';
import 'package:provider/provider.dart';

import '../helpers/widget_test_scaffold.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    registerTestServices(locale: 'en');
    FcmService.resetForTesting();
    FcmService.debugGetNotificationSettingsOverride = () async => _authorized;
    FcmService.debugInitializeLocalNotificationsOverride = () async {};
    FcmService.debugGetCurrentUserIdOverride = () => null;
    FcmService.debugGetApnsTokenOverride = () async => 'apns-token';
    FcmService.debugGetTokenOverride = () async => 'fcm-token';
    FcmService.debugRegisterListenersOverride = () {};
  });

  tearDown(() {
    FcmService.resetForTesting();
    FcmScheduledNotificationService.resetForTesting();
    resetTestServices();
  });

  group('App time format first frame', () {
    testWidgets('should render Hebrew root and pushed reminders immediately', (
      tester,
    ) async {
      tester.platformDispatcher.alwaysUse24HourFormatTestValue = false;
      addTearDown(tester.platformDispatcher.clearAlwaysUse24HourTestValue);
      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: UserInformation(localeName: 'he'),
          child: MaterialApp(
            locale: const Locale('he'),
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: appLocalizationsDelegates,
            builder: appTimeFormatBuilder,
            home: Builder(
              builder: (context) => Scaffold(
                body: Column(
                  children: [
                    Text(const TimeOfDay(hour: 19, minute: 5).format(context)),
                    Text(MaterialLocalizations.of(context).cancelButtonLabel),
                    TextButton(
                      onPressed: () => Navigator.of(context).push<void>(
                        MaterialPageRoute(
                          builder: (_) => const NotificationPage(),
                        ),
                      ),
                      child: const Text('Open reminders'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      expect(find.text('7:05 PM'), findsOneWidget);
      expect(find.text('ביטול'), findsOneWidget);

      await tester.tap(find.text('Open reminders'));
      await tester.pump();
      expect(
        find.text(
          AppLocalizationsHe().reminderPageSubtitle,
          skipOffstage: false,
        ),
        findsOneWidget,
      );
      await tester.pumpAndSettle();
    });
  });

  group('AppearanceSettings OS time format', () {
    for (final localeName in ['en', 'he', 'ar']) {
      for (final use24Hour in [false, true]) {
        testWidgets(
          'should match reminder formats and update with the OS '
          '($localeName, 24h: $use24Hour)',
          (tester) async {
            tester.platformDispatcher.alwaysUse24HourFormatTestValue =
                use24Hour;
            tester.binding.handleMetricsChanged();
            addTearDown(
              tester.platformDispatcher.clearAlwaysUse24HourTestValue,
            );
            final user = UserInformation(
              localeName: localeName,
              darkModePreference: DarkModePreference.scheduled,
              darkModeStartHour: 19,
              darkModeStartMinute: 5,
              darkModeEndHour: 20,
              darkModeEndMinute: 15,
            );
            await pumpWithProviders(
              tester,
              Scaffold(body: AppearanceSettings(userInformation: user)),
              userInformation: user,
              locale: Locale(localeName),
              ignoreOverflow: false,
            );
            final locale = AppLocalizations.of(
              tester.element(find.byType(AppearanceSettings)),
            )!;
            final labels = _timeLabels(use24Hour, localeName);
            final startLabel = '${locale.darkModeStartTime}: ${labels[0]}';
            final endLabel = '${locale.darkModeEndTime}: ${labels[1]}';
            expect(find.text(startLabel), findsOneWidget);
            expect(find.text(endLabel), findsOneWidget);
            await _expectPicker(tester, startLabel, use24Hour, localeName);
            await _expectPicker(tester, endLabel, use24Hour, localeName);

            tester.platformDispatcher.alwaysUse24HourFormatTestValue =
                !use24Hour;
            tester.binding.handleMetricsChanged();
            await tester.pump();
            final updated = _timeLabels(!use24Hour, localeName);
            expect(
              find.text('${locale.darkModeStartTime}: ${updated[0]}'),
              findsOneWidget,
            );
            expect(
              find.text('${locale.darkModeEndTime}: ${updated[1]}'),
              findsOneWidget,
            );
            expect(user.darkModeStartHour, 19);
            expect(user.darkModeEndMinute, 15);
          },
          variant: TargetPlatformVariant({
            TargetPlatform.iOS,
            TargetPlatform.android,
          }),
        );
      }
    }
  });

  group('NotificationPage OS time format', () {
    for (final localeName in ['en', 'he', 'ar']) {
      for (final use24Hour in [false, true]) {
        testWidgets(
          'should use OS format for every time and live picker '
          '($localeName, 24h: $use24Hour)',
          (tester) async {
            final repository = await _pumpPage(tester, use24Hour, localeName);
            _expectTimes(use24Hour, localeName);
            expect(find.byType(Switch), findsNothing);
            expect(find.text('24h'), findsNothing);
            expect(find.text('AM/PM'), findsNothing);

            final timeLabels = _timeLabels(use24Hour, localeName);
            for (final label in timeLabels) {
              await _expectPicker(tester, label, use24Hour, localeName);
            }

            expect(repository.use24HourFormat, !use24Hour);
            expect(repository.getPreference('default')?.hour, 19);
            expect(repository.getPreference('quick_exercise')?.minute, 15);
            expect(repository.customReminders.single.hour, 21);
          },
          variant: TargetPlatformVariant({
            TargetPlatform.iOS,
            TargetPlatform.android,
          }),
        );
      }

      testWidgets(
        'should update visible times when OS format changes ($localeName)',
        (
          tester,
        ) async {
          final repository = await _pumpPage(tester, false, localeName);
          _expectTimes(false, localeName);

          tester.platformDispatcher.alwaysUse24HourFormatTestValue = true;
          tester.binding.handleMetricsChanged();
          await tester.pumpAndSettle();

          _expectTimes(true, localeName);
          expect(find.text('7:05 PM'), findsNothing);
          expect(repository.use24HourFormat, isTrue);
          expect(repository.getSavedTime('default')?.hour, 19);
        },
        variant: TargetPlatformVariant({
          TargetPlatform.iOS,
          TargetPlatform.android,
        }),
      );
    }
  });
}

Future<NotificationRepository> _pumpPage(
  WidgetTester tester,
  bool use24Hour, [
  String localeName = 'en',
]) async {
  tester.platformDispatcher.alwaysUse24HourFormatTestValue = use24Hour;
  tester.binding.handleMetricsChanged();
  addTearDown(tester.platformDispatcher.clearAlwaysUse24HourTestValue);
  final memory = FakePersistentMemoryService();
  final repository = NotificationRepository.forService(memory);
  repository.restoreJson('{"__use24HourFormat":${!use24Hour}}');
  await repository.setCustomReminderTime(
    const CustomReminder(
      id: 'custom_practice',
      emoji: 'x',
      label: 'Practice',
      hour: 21,
      minute: 25,
    ),
  );
  repository.restorePreferences({
    'default': const NotificationPreference(hour: 19, minute: 5),
    'quick_exercise': const NotificationPreference(hour: 20, minute: 15),
    'custom_practice': const NotificationPreference(hour: 21, minute: 25),
  });
  await pumpWithProviders(
    tester,
    const NotificationPage(),
    userInformation: UserInformation(
      service: memory,
      loggedIn: true,
      gender: 'other',
      localeName: localeName,
    ),
    locale: Locale(localeName),
    surfaceSize: const Size(400, 800),
    ignoreOverflow: false,
  );
  await tester.pumpAndSettle();
  return repository;
}

List<String> _timeLabels(bool use24Hour, String localeName) {
  final am = localeName == 'ar' ? 'ص' : 'AM';
  final pm = localeName == 'ar' ? 'م' : 'PM';
  return [
    use24Hour ? '19:05' : '7:05 $pm',
    use24Hour ? '20:15' : '8:15 $pm',
    use24Hour ? '21:25' : '9:25 $pm',
    use24Hour ? '08:00' : '8:00 $am',
  ];
}

void _expectTimes(bool use24Hour, String localeName) {
  final labels = _timeLabels(use24Hour, localeName);
  final defaultLabel = labels[0];
  final quickLabel = labels[1];
  final customLabel = labels[2];
  expect(
    find.descendant(
      of: find.byType(NotificationToggleCard),
      matching: find.text(defaultLabel),
    ),
    findsOneWidget,
  );
  expect(
    find.descendant(
      of: find.byKey(const ValueKey('quick_exercise')),
      matching: find.text(quickLabel),
    ),
    findsOneWidget,
  );
  expect(
    find.descendant(
      of: find.byKey(const ValueKey('custom_practice')),
      matching: find.text(customLabel),
    ),
    findsOneWidget,
  );
  expect(
    find.descendant(
      of: find.byType(CustomReminderForm),
      matching: find.text(labels[3]),
    ),
    findsOneWidget,
  );
  // Each enabled reminder repeats its formatted time in the active summary.
  expect(find.text(defaultLabel), findsNWidgets(2));
  expect(find.text(quickLabel), findsNWidgets(2));
  expect(find.text(customLabel), findsNWidgets(2));
  expect(find.byType(ReminderItemCard), findsNWidgets(12));
}

Future<void> _expectPicker(
  WidgetTester tester,
  String label,
  bool use24Hour,
  String localeName,
) async {
  final time = find.text(label).first;
  await tester.ensureVisible(time);
  await tester.tap(time);
  await tester.pump();
  expect(find.byType(TimePickerDialog), findsOneWidget);
  final am = localeName == 'ar' ? 'ص' : 'AM';
  final pm = localeName == 'ar' ? 'م' : 'PM';
  expect(find.text(am), use24Hour ? findsNothing : findsOneWidget);
  expect(find.text(pm), use24Hour ? findsNothing : findsOneWidget);
  final cancelLabel = switch (localeName) {
    'he' => 'ביטול',
    'ar' => 'الإلغاء',
    _ => 'Cancel',
  };
  expect(find.text(cancelLabel), findsOneWidget);
  if (localeName == 'he') expect(find.text('Cancel'), findsNothing);
  await tester.pumpAndSettle();
  if (localeName == 'he' && !use24Hour) {
    final selected = tester
        .widget<TimePickerDialog>(
          find.byType(TimePickerDialog),
        )
        .initialTime;
    for (final updatedFormat in [true, false]) {
      tester.platformDispatcher.alwaysUse24HourFormatTestValue = updatedFormat;
      tester.binding.handleMetricsChanged();
      await tester.pump();
      expect(find.text('AM'), updatedFormat ? findsNothing : findsOneWidget);
      expect(find.text('PM'), updatedFormat ? findsNothing : findsOneWidget);
      final hour = updatedFormat
          ? selected.hour.toString().padLeft(2, '0')
          : '${selected.hourOfPeriod == 0 ? 12 : selected.hourOfPeriod}';
      expect(find.text(hour), findsWidgets);
      expect(
        find.text(selected.minute.toString().padLeft(2, '0')),
        findsWidgets,
      );
      expect(find.text(cancelLabel), findsOneWidget);
      expect(
        tester
            .widget<TimePickerDialog>(find.byType(TimePickerDialog))
            .initialTime,
        selected,
      );
    }
  }
  await tester.tap(find.text(cancelLabel));
  await tester.pumpAndSettle();
}

const _authorized = NotificationSettings(
  alert: AppleNotificationSetting.enabled,
  announcement: AppleNotificationSetting.disabled,
  authorizationStatus: AuthorizationStatus.authorized,
  badge: AppleNotificationSetting.enabled,
  carPlay: AppleNotificationSetting.disabled,
  criticalAlert: AppleNotificationSetting.disabled,
  lockScreen: AppleNotificationSetting.enabled,
  notificationCenter: AppleNotificationSetting.enabled,
  showPreviews: AppleShowPreviewSetting.always,
  sound: AppleNotificationSetting.enabled,
  timeSensitive: AppleNotificationSetting.disabled,
  providesAppNotificationSettings: AppleNotificationSetting.disabled,
);
