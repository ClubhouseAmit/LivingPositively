import 'dart:async';
import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart'
    show TargetPlatform, debugPrint, defaultTargetPlatform, visibleForTesting;
import 'package:get_it/get_it.dart';
import 'package:http/http.dart' as http;
import 'package:mazilon/features/notifications/data/fcm_service.dart';
import 'package:mazilon/util/async/logger_service.dart';
import 'package:mazilon/features/notifications/data/notification_models.dart';
import 'package:mazilon/features/notifications/data/notification_preferences_repository.dart';
import 'package:mazilon/util/async/persistent_memory_service.dart';
import 'package:mazilon/util/userInformation.dart';
import 'package:mazilon/util/async/global_enums.dart';

/// Injectable authenticated HTTP boundary used by notification mutations.
part 'fcm_scheduler_transport.dart';
part 'fcm_scheduler_registration.dart';
part 'fcm_scheduler_cancellation.dart';

///
/// Production uses `http.post`; callers use this type only to provide an
/// equivalent transport in tests or a caller-approved boundary.
typedef NotificationHttpPost =
    Future<http.Response> Function(
      Uri url, {
      Map<String, String>? headers,
      Object? body,
      Encoding? encoding,
    });

/// Coordinates authenticated FCM reminder registration, cancellation, and
/// migration of the old Android device-local reminder.
class FcmScheduledNotificationService {
  static const String _functionsBaseUrl =
      'https://us-central1-mezilondb.cloudfunctions.net';
  static const String _legacyDefaultReminderMigrationKey =
      'fcmDefaultReminderMigrated';
  static const String _legacyDefaultReminderEnabledKey =
      'legacyDefaultReminderEnabled';
  static const String _legacyLocalNotificationsRetiredKey =
      'legacyLocalNotificationsRetired';
  static const Duration _networkTimeout = Duration(seconds: 15);
  static const Duration _legacyMigrationOperationTimeout = Duration(seconds: 5);
  static Future<void>? _operationQueue;
  static bool _legacyMigrationDisabled = false;
  static int _resetEpoch = 0;

  /// Test-only HTTP substitute for all scheduler requests.
  @visibleForTesting
  static NotificationHttpPost? debugPostOverride;

  /// Test-only substitute for legacy-reminder migration reporting.
  @visibleForTesting
  static Future<void> Function(UserInformation)?
  debugLegacyDefaultReminderMigrationOverride;

  /// Clears process-wide scheduler state between isolated tests.
  @visibleForTesting
  static void resetForTesting() {
    _operationQueue = null;
    _legacyMigrationDisabled = false;
    _resetEpoch = 0;
    debugPostOverride = null;
    debugLegacyDefaultReminderMigrationOverride = null;
  }

  /// Removes schedules left by the retired Android local-notification system.
  ///
  /// This cleanup is independent of authentication and intentionally does not
  /// infer reminder consent from legacy default hour/minute values. It runs
  /// once per installation and retries on a later launch if cancellation or
  /// marker persistence fails.
  static Future<void> retireLegacyLocalNotifications({
    PersistentMemoryService? persistentMemory,
    Future<void> Function()? legacyNotificationsCanceller,
  }) {
    if (defaultTargetPlatform != TargetPlatform.android) {
      return Future<void>.value();
    }
    return _enqueue(() async {
      final memory =
          persistentMemory ?? GetIt.instance<PersistentMemoryService>();
      final retired =
          await memory
              .getItem(
                _legacyLocalNotificationsRetiredKey,
                PersistentMemoryType.Bool,
              )
              .timeout(_legacyMigrationOperationTimeout) ??
          false;
      if (retired == true) return;

      await (legacyNotificationsCanceller ??
              FcmService.cancelAllLegacyLocalNotifications)()
          .timeout(_legacyMigrationOperationTimeout);
      await memory
          .setItem(
            _legacyLocalNotificationsRetiredKey,
            PersistentMemoryType.Bool,
            true,
          )
          .timeout(_legacyMigrationOperationTimeout);
    });
  }

  /// Retires legacy local schedules without allowing cleanup failure to block
  /// application startup.
  static Future<void> retireLegacyLocalNotificationsWithReporting({
    PersistentMemoryService? persistentMemory,
  }) async {
    try {
      await retireLegacyLocalNotifications(persistentMemory: persistentMemory);
    } catch (error, stackTrace) {
      _reportNotificationFailure(
        'Unable to retire legacy local notifications',
        error,
        stackTrace,
      );
    }
  }

  /// Migrates an Android legacy local default reminder to the FCM scheduler.
  ///
  /// Does nothing when migration is disabled, the platform is unsupported, no
  /// user state is available, no explicitly enabled legacy reminder exists, no
  /// valid legacy time exists, or migration already completed. The hour/minute
  /// values alone are not consent: old installs persist defaults even when the
  /// local alarm was cancelled.
  static Future<void> migrateLegacyDefaultReminder({
    UserInformation? userInformation,
    Future<String?> Function()? idTokenProvider,
    NotificationHttpPost? post,
    PersistentMemoryService? persistentMemory,
    Future<void> Function(int notificationId)? legacyNotificationCanceller,
  }) async {
    if (_legacyMigrationDisabled) return;
    // The removed local scheduler ran only on Android. Avoid turning values
    // persisted by the old shared user model into a new iOS reminder.
    if (defaultTargetPlatform != TargetPlatform.android) return;
    if (userInformation == null) {
      _log('Warning: no user state, cannot migrate a reminder.');
      return;
    }
    final resetEpoch = _resetEpoch;
    final userInfo = userInformation;

    await _enqueue(() async {
      if (_legacyMigrationDisabled || resetEpoch != _resetEpoch) return;
      final memory =
          persistentMemory ?? GetIt.instance<PersistentMemoryService>();
      final migrated =
          await memory
              .getItem(
                _legacyDefaultReminderMigrationKey,
                PersistentMemoryType.Bool,
              )
              .timeout(_legacyMigrationOperationTimeout) ??
          false;
      if (migrated == true ||
          _legacyMigrationDisabled ||
          resetEpoch != _resetEpoch) {
        return;
      }
      final preference = await _legacyDefaultReminderPreference(
        memory,
        requiresEnabledMarker: true,
      );
      if (preference == null) return;
      final legacyNotificationId = _legacyLocalNotificationId(preference);
      final registered = await _registerNotification(
        userInformation: userInfo,
        typeId: 'default',
        hour: preference.hour,
        minute: preference.minute,
        idTokenProvider: idTokenProvider,
        post: post,
        resetEpoch: resetEpoch,
      );
      if (registered) {
        await (legacyNotificationCanceller ??
                FcmService.cancelLegacyLocalNotification)(legacyNotificationId)
            .timeout(_legacyMigrationOperationTimeout);
        await memory
            .setItem(
              _legacyDefaultReminderMigrationKey,
              PersistentMemoryType.Bool,
              true,
            )
            .timeout(_legacyMigrationOperationTimeout);
      }
    });
  }

  /// any migration failure to the configured incident logger.
  static Future<void> migrateLegacyDefaultReminderWithReporting({
    required UserInformation userInformation,
  }) async {
    // Sign-out fences only the outgoing session. Authentication starts a new
    // session, so it may inspect the migration marker again.
    _legacyMigrationDisabled = false;
    final migrationOverride = debugLegacyDefaultReminderMigrationOverride;
    if (migrationOverride != null) {
      return migrationOverride(userInformation);
    }
    try {
      await migrateLegacyDefaultReminder(userInformation: userInformation);
    } catch (error, stackTrace) {
      if (GetIt.instance.isRegistered<IncidentLoggerService>()) {
        try {
          await GetIt.instance<IncidentLoggerService>().captureLog(
            error,
            stackTrace: stackTrace,
          );
        } catch (loggerError) {
          debugPrint(
            'Legacy reminder migration reporting failed: $loggerError',
          );
        }
      } else {
        debugPrint('Legacy reminder migration failed: $error');
      }
    }
  }

  /// Registers or updates a scheduled notification for [typeId].
  ///
  /// The [hour] and [minute] are Israel local time as selected by the user.
  /// Calls are serialized with cancellation and reset operations. Returns
  /// `false` for missing user state, unsupported platforms, authentication or
  /// transport failures, and compensates the remote mutation if local
  /// preference persistence fails.
  static Future<bool> registerNotification({
    UserInformation? userInformation,
    required String typeId,
    required int hour,
    required int minute,
    Future<String?> Function()? idTokenProvider,
    NotificationHttpPost? post,
  }) {
    if (userInformation == null) {
      _log('Warning: no user state, cannot register a reminder.');
      return Future.value(false);
    }
    final userInfo = userInformation;
    final resetEpoch = _resetEpoch;
    return _enqueue(
      () => _registerNotification(
        userInformation: userInfo,
        typeId: typeId,
        hour: hour,
        minute: minute,
        idTokenProvider: idTokenProvider,
        post: post,
        resetEpoch: resetEpoch,
      ),
    );
  }

  static Future<bool> cancelNotification({
    UserInformation? userInformation,
    required String typeId,
    bool requireNoActiveDeliveryPermit = false,
    Future<String?> Function()? idTokenProvider,
    NotificationHttpPost? post,
  }) {
    if (userInformation == null) {
      _log('Warning: no user state, cannot cancel a reminder.');
      return Future.value(false);
    }
    final userInfo = userInformation;
    final resetEpoch = _resetEpoch;
    return _enqueue(
      () => _cancelNotification(
        userInformation: userInfo,
        typeId: typeId,
        idTokenProvider: idTokenProvider,
        post: post,
        resetEpoch: resetEpoch,
        resetFence: requireNoActiveDeliveryPermit,
      ),
    );
  }

  /// Restores a default reminder after local reset fails following cancellation.
  ///
  /// Returns `true` when no prior preference exists or both the remote schedule
  /// and local preference have been restored. The reset epoch fences stale work.
  static Future<bool> restoreDefaultReminderAfterResetFailure({
    required UserInformation userInformation,
    NotificationPreference? previousPreference,
    Future<String?> Function()? idTokenProvider,
    NotificationHttpPost? post,
  }) {
    _resetEpoch++;
    _legacyMigrationDisabled = false;
    if (previousPreference == null) return Future.value(true);
    final resetEpoch = _resetEpoch;
    return _enqueue(
      () => _registerNotification(
        userInformation: userInformation,
        typeId: 'default',
        hour: previousPreference.hour,
        minute: previousPreference.minute,
        idTokenProvider: idTokenProvider,
        post: post,
        resetEpoch: resetEpoch,
        allowUnsupportedPlatform: true,
      ),
    );
  }

  /// Cancels the default reminder before a data reset.
  ///
  /// Fences queued migration and refuses cancellation after a claimed delivery.
  /// Returns `false` and re-enables migration if the cancellation cannot finish.
  /// When provided, [onRemoteScheduleCancelled] receives the server's schedule
  /// time after a successful remote cancellation.
  static Future<bool> cancelDefaultForReset({
    required UserInformation userInformation,
    Future<String?> Function()? idTokenProvider,
    NotificationHttpPost? post,
    void Function(NotificationPreference? remotePreference)?
    onRemoteScheduleCancelled,
  }) {
    _legacyMigrationDisabled = true;
    _resetEpoch++;
    final resetEpoch = _resetEpoch;
    return _enqueue(() async {
      try {
        final cancelled = await _cancelNotification(
          userInformation: userInformation,
          typeId: 'default',
          idTokenProvider: idTokenProvider,
          post: post,
          resetEpoch: resetEpoch,
          resetFence: true,
          onRemoteScheduleCancelled: onRemoteScheduleCancelled,
        );
        if (!cancelled) {
          _legacyMigrationDisabled = false;
        }
        return cancelled;
      } catch (_) {
        _legacyMigrationDisabled = false;
        rethrow;
      }
    });
  }

  /// Retires every form of the default reminder before the account signs out.
  ///
  /// Fences queued migration and cancellation after a claimed delivery. Returns
  /// `false` when remote retirement, legacy local retirement, or compensation
  /// fails, leaving migration eligible for a later retry.
  /// When provided, [onRemoteScheduleCancelled] receives the server's schedule
  /// time after a successful remote cancellation.
  static Future<bool> cancelDefaultForSignOut({
    required UserInformation userInformation,
    Future<String?> Function()? idTokenProvider,
    NotificationHttpPost? post,
    Future<void> Function(int notificationId)? legacyNotificationCanceller,
    void Function(NotificationPreference? remotePreference)?
    onRemoteScheduleCancelled,
  }) {
    _legacyMigrationDisabled = true;
    _resetEpoch++;
    final resetEpoch = _resetEpoch;
    return _enqueue(() async {
      try {
        final cancelled = await _cancelNotification(
          userInformation: userInformation,
          typeId: 'default',
          idTokenProvider: idTokenProvider,
          post: post,
          resetEpoch: resetEpoch,
          resetFence: true,
          legacyNotificationCanceller: legacyNotificationCanceller,
          onRemoteScheduleCancelled: onRemoteScheduleCancelled,
        );
        if (!cancelled) {
          _legacyMigrationDisabled = false;
        }
        return cancelled;
      } catch (error) {
        _legacyMigrationDisabled = false;
        _log('sign-out reminder cancellation error: $error');
        return false;
      }
    });
  }
}
