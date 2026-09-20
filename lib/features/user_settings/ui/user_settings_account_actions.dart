import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'package:mazilon/features/auth/data/auth_repository.dart';
import 'package:mazilon/features/feel_good/data/image_picker_repository.dart';
import 'package:mazilon/features/notifications/data/notification_models.dart';
import 'package:mazilon/features/notifications/data/notification_repository.dart';
import 'package:mazilon/util/async/global_enums.dart';
import 'package:mazilon/util/async/locale_service.dart';
import 'package:mazilon/util/async/logger_service.dart';
import 'package:mazilon/util/userInformation.dart';

/// Coordinates account cleanup while the settings page owns navigation.
class UserSettingsAccountActions {
  UserSettingsAccountActions({
    required this.imagePickerService,
    required this.invalidatePendingWrites,
    required this.resetPhoneData,
  });

  final ImagePickerService imagePickerService;
  final void Function() invalidatePendingWrites;
  final void Function() resetPhoneData;

  void _reportFailure(Object error, StackTrace stackTrace) {
    if (!GetIt.instance.isRegistered<IncidentLoggerService>()) {
      debugPrint('Account cleanup failed: $error');
      return;
    }
    unawaited(
      Future<void>.sync(
        () => GetIt.instance<IncidentLoggerService>().captureLog(
          error,
          stackTrace: stackTrace,
        ),
      ).catchError(
        (Object loggerError, StackTrace _) =>
            debugPrint('Cleanup failure reporting failed: $loggerError'),
      ),
    );
  }

  Future<void> _restoreReminder(
    UserInformation userInfo,
    NotificationPreference? preference,
  ) async {
    final restored = await NotificationRepository.forService(userInfo.service)
        .restoreDefaultReminderAfterResetFailure(
          userInformation: userInfo,
          previousPreference: preference,
        );
    if (!restored) {
      _reportFailure(
        StateError('Unable to restore the cancelled reminder.'),
        StackTrace.current,
      );
    }
  }

  Future<void> resetData(UserInformation userInfo) async {
    final localeService = GetIt.instance<LocaleService>();
    final notificationRepository = NotificationRepository.forService(
      userInfo.service,
    );
    final previousReminder = notificationRepository.getPreference('default');
    NotificationPreference? cancelledReminder;
    var remoteReminderCancelled = false;
    invalidatePendingWrites();
    try {
      final user = AuthService.registeredUser;
      if (user != null && !user.isAnonymous) {
        remoteReminderCancelled = await notificationRepository
            .cancelDefaultForReset(
              userInformation: userInfo,
              onRemoteScheduleCancelled: (value) => cancelledReminder = value,
            );
        if (!remoteReminderCancelled) {
          throw StateError('Unable to cancel the reminder before reset.');
        }
      }
      await userInfo.service.reset();
      await userInfo.reset(localeService.getLocale());
    } catch (error, stackTrace) {
      if (remoteReminderCancelled) {
        await _restoreReminder(userInfo, cancelledReminder ?? previousReminder);
      }
      _reportFailure(error, stackTrace);
      rethrow;
    }
    runZonedGuarded<void>(resetPhoneData, _reportFailure);
    final user = AuthService.registeredUser;
    if (user != null && !user.isAnonymous) {
      userInfo
        ..updateLoggedIn(true)
        ..updateAuthDecisionMade(true)
        ..updateUserId(user.uid)
        ..updateEmail(user.email ?? '')
        ..updateDisplayName(user.displayName ?? '');
    }
    try {
      await Future<void>.sync(imagePickerService.deleteImages);
    } catch (error, stackTrace) {
      _reportFailure(error, stackTrace);
    }
  }

  Future<(bool, bool)> _onboardingState(UserInformation userInfo) async {
    try {
      final entered = await userInfo.service.getItem(
        'enteredBefore',
        PersistentMemoryType.Bool,
      );
      final filled = await userInfo.service.getItem(
        'hasFilled',
        PersistentMemoryType.Bool,
      );
      return (entered as bool? ?? true, filled as bool? ?? false);
    } catch (error, stackTrace) {
      _reportFailure(error, stackTrace);
      return (true, false);
    }
  }

  /// Returns the onboarding route state only after a successful sign-out.
  Future<(bool, bool)?> signOut(UserInformation userInfo) async {
    final (entered, filled) = await _onboardingState(userInfo);
    final notificationRepository = NotificationRepository.forService(
      userInfo.service,
    );
    final previousReminder = notificationRepository.getPreference('default');
    NotificationPreference? cancelledReminder;
    var reminderCancelled = false;
    final user = AuthService.registeredUser;
    if (user != null && !user.isAnonymous) {
      reminderCancelled = await notificationRepository.cancelDefaultForSignOut(
        userInformation: userInfo,
        onRemoteScheduleCancelled: (value) => cancelledReminder = value,
      );
      if (!reminderCancelled) return null;
    }
    try {
      await AuthService.signOut();
    } catch (error, stackTrace) {
      if (reminderCancelled) {
        await _restoreReminder(userInfo, cancelledReminder ?? previousReminder);
      }
      _reportFailure(error, stackTrace);
      return null;
    }
    userInfo
      ..updateLoggedIn(false)
      ..updateAuthDecisionMade(false)
      ..updateUserId('')
      ..updateEmail('')
      ..updateDisplayName('');
    return (entered, filled);
  }
}
