import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, visibleForTesting;
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:http/http.dart' as http;
import 'package:mazilon/util/Firebase/fcm_service.dart';
import 'package:mazilon/util/logger_service.dart';
import 'package:mazilon/util/notification_preference.dart';
import 'package:mazilon/util/persistent_memory_service.dart';
import 'package:mazilon/util/userInformation.dart';
import 'package:mazilon/global_enums.dart';
import 'package:provider/provider.dart';

typedef NotificationHttpPost =
    Future<http.Response> Function(
      Uri url, {
      Map<String, String>? headers,
      Object? body,
      Encoding? encoding,
    });

class FcmScheduledNotificationService {
  static const String _functionsBaseUrl =
      'https://us-central1-mezilondb.cloudfunctions.net';
  static const String _legacyDefaultReminderMigrationKey =
      'fcmDefaultReminderMigrated';
  static const String _legacyDefaultReminderEnabledKey =
      'legacyDefaultReminderEnabled';
  static const Duration _networkTimeout = Duration(seconds: 15);
  static const Duration _legacyMigrationOperationTimeout = Duration(seconds: 5);
  static Future<void>? _operationQueue;
  static bool _legacyMigrationDisabled = false;
  static int _resetEpoch = 0;

  @visibleForTesting
  static NotificationHttpPost? debugPostOverride;

  @visibleForTesting
  static Future<void> Function(UserInformation)?
  debugLegacyDefaultReminderMigrationOverride;

  @visibleForTesting
  static void resetForTesting() {
    _operationQueue = null;
    _legacyMigrationDisabled = false;
    _resetEpoch = 0;
    debugPostOverride = null;
    debugLegacyDefaultReminderMigrationOverride = null;
  }

  static void _log(String message) =>
      debugPrint('[FcmScheduledNotificationService] $message');

  static Future<T> _enqueue<T>(Future<T> Function() operation) {
    final previousOperation = _operationQueue;
    final operationResult = previousOperation == null
        ? Future<T>.sync(operation)
        : previousOperation.then((_) => operation());
    final queueRelease = operationResult.then<void>(
      (_) {},
      onError: (Object _, StackTrace _) {},
    );
    _operationQueue = queueRelease;
    return operationResult.whenComplete(() => queueRelease);
  }

  static UserInformation? _resolveUserInformation(
    BuildContext? context,
    UserInformation? userInformation,
  ) {
    if (userInformation != null) return userInformation;
    if (context == null) return null;
    try {
      return Provider.of<UserInformation>(context, listen: false);
    } catch (error) {
      _log('Warning: unable to read user state: $error');
      return null;
    }
  }

  static Future<String?> _getIdToken() async {
    if (!GetIt.instance.isRegistered<FirebaseAuth>()) {
      _log('Warning: FirebaseAuth is not initialized, cannot get ID token.');
      return null;
    }
    final user = GetIt.instance<FirebaseAuth>().currentUser;
    if (user == null || user.isAnonymous) {
      _log('Warning: no authenticated user, cannot get ID token.');
      return null;
    }
    final token = await user.getIdToken();
    if (token == null) {
      _log('Warning: no authenticated user, cannot get ID token.');
    }
    return token;
  }

  /// Migrates an Android legacy local default reminder to the FCM scheduler.
  ///
  /// Does nothing when migration is disabled, the platform is unsupported, no
  /// user state is available, no explicitly enabled legacy reminder exists, no
  /// valid legacy time exists, or migration already completed. The hour/minute
  /// values alone are not consent: old installs persist defaults even when the
  /// local alarm was cancelled.
  static Future<void> migrateLegacyDefaultReminder({
    BuildContext? context,
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
    if (context == null && userInformation == null) {
      _log('Warning: no user state, cannot migrate a reminder.');
      return;
    }
    final resetEpoch = _resetEpoch;
    final userInfo =
        userInformation ??
        Provider.of<UserInformation>(context!, listen: false);

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

  static Future<NotificationPreference?> _legacyDefaultReminderPreference(
    PersistentMemoryService memory, {
    bool requiresEnabledMarker = false,
  }) async {
    if (requiresEnabledMarker) {
      final legacyReminderEnabled = await memory
          .getItem(_legacyDefaultReminderEnabledKey, PersistentMemoryType.Bool)
          .timeout(_legacyMigrationOperationTimeout);
      if (legacyReminderEnabled != true) return null;
    }
    final legacyHour = await memory
        .getItem('notificationHour', PersistentMemoryType.Int)
        .timeout(_legacyMigrationOperationTimeout);
    final legacyMinute = await memory
        .getItem('notificationMinute', PersistentMemoryType.Int)
        .timeout(_legacyMigrationOperationTimeout);
    final hasValidLegacyTime =
        legacyHour is int &&
        legacyHour >= 0 &&
        legacyHour <= 23 &&
        legacyMinute is int &&
        legacyMinute >= 0 &&
        legacyMinute <= 59;
    if (!hasValidLegacyTime) return null;
    return NotificationPreference(hour: legacyHour, minute: legacyMinute);
  }

  static int _legacyLocalNotificationId(NotificationPreference preference) {
    return int.parse('${preference.hour}${preference.minute}');
  }

  /// Runs [migrateLegacyDefaultReminder] and reports, rather than propagates,
  /// any migration failure to the configured incident logger.
  static Future<void> migrateLegacyDefaultReminderWithReporting({
    required UserInformation userInformation,
  }) async {
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
    BuildContext? context,
    UserInformation? userInformation,
    required String typeId,
    required int hour,
    required int minute,
    Future<String?> Function()? idTokenProvider,
    NotificationHttpPost? post,
  }) {
    if (context == null && userInformation == null) {
      _log('Warning: no user state, cannot register a reminder.');
      return Future.value(false);
    }
    final userInfo = _resolveUserInformation(context, userInformation);
    if (userInfo == null) return Future.value(false);
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

  static Future<bool> _registerNotification({
    required UserInformation userInformation,
    required String typeId,
    required int hour,
    required int minute,
    Future<String?> Function()? idTokenProvider,
    NotificationHttpPost? post,
    required int resetEpoch,
    bool allowUnsupportedPlatform = false,
    bool persistLocalPreference = true,
    int? expectedMutationVersion,
  }) async {
    if (!allowUnsupportedPlatform && !FcmService.supportsReminderSettings()) {
      return false;
    }
    if (resetEpoch != _resetEpoch) return false;
    _log(
      'Registering notification: typeId=$typeId, hour=$hour, minute=$minute',
    );
    final userInfo = userInformation;
    final locale = _notificationLocale(userInfo.localeName);
    if (locale == null) {
      _log('Unsupported notification locale: ${userInfo.localeName}');
      return false;
    }
    final rawGender = userInfo.gender;
    final gender = (rawGender == 'male' || rawGender == 'female')
        ? rawGender
        : 'other';

    try {
      final idToken = await (idTokenProvider ?? _getIdToken)().timeout(
        _networkTimeout,
      );
      if (idToken == null) return false;
      if (resetEpoch != _resetEpoch) return false;
      final mutationVersion =
          expectedMutationVersion ??
          await _getNotificationMutationVersion(
            idToken: idToken,
            typeId: typeId,
            post: post,
          );
      if (mutationVersion == null || resetEpoch != _resetEpoch) {
        return false;
      }
      final response = await (post ?? debugPostOverride ?? http.post)(
        Uri.parse('$_functionsBaseUrl/registerNotification'),
        headers: {
          'Authorization': 'Bearer $idToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'typeId': typeId,
          'hour': hour,
          'minute': minute,
          'locale': locale,
          'gender': gender,
          'expectedMutationVersion': mutationVersion,
        }),
      ).timeout(_networkTimeout);

      if (response.statusCode == 200) {
        final nextMutationVersion = _successfulMutationVersion(
          response,
          mutationVersion,
        );
        if (nextMutationVersion == null) return false;
        _log('Notification registered successfully.');
        if (!persistLocalPreference) return true;
        final previousPreference = userInfo.getNotificationPreference(typeId);
        try {
          await userInfo
              .setNotificationPreference(
                typeId,
                NotificationPreference(hour: hour, minute: minute),
              )
              .timeout(_legacyMigrationOperationTimeout);
        } catch (error) {
          _log('Unable to persist registered notification: $error');
          await _restoreLocalNotificationPreference(
            userInfo,
            typeId,
            previousPreference,
          );
          final compensationVersion = previousPreference == null
              ? await _cancelRemoteNotification(
                  idToken: idToken,
                  typeId: typeId,
                  post: post,
                  expectedMutationVersion: nextMutationVersion,
                )
              : await _registerNotification(
                  userInformation: userInfo,
                  typeId: typeId,
                  hour: previousPreference.hour,
                  minute: previousPreference.minute,
                  idTokenProvider: () async => idToken,
                  post: post,
                  resetEpoch: resetEpoch,
                  allowUnsupportedPlatform: true,
                  persistLocalPreference: false,
                  expectedMutationVersion: nextMutationVersion,
                );
          final compensated = compensationVersion is bool
              ? compensationVersion
              : compensationVersion != null;
          if (!compensated) {
            _log('Unable to compensate a notification registration failure.');
          }
          return false;
        }
        return true;
      } else {
        _log(
          'registerNotification failed: ${response.statusCode} ${response.body}',
        );
        return false;
      }
    } catch (e) {
      _log('registerNotification error: $e');
      return false;
    }
  }

  static Future<int?> _cancelRemoteNotification({
    required String idToken,
    required String typeId,
    NotificationHttpPost? post,
    required int expectedMutationVersion,
  }) async {
    try {
      final response = await (post ?? debugPostOverride ?? http.post)(
        Uri.parse('$_functionsBaseUrl/cancelNotification'),
        headers: {
          'Authorization': 'Bearer $idToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'typeId': typeId,
          'expectedMutationVersion': expectedMutationVersion,
        }),
      ).timeout(_networkTimeout);
      return response.statusCode == 200
          ? _successfulMutationVersion(response, expectedMutationVersion)
          : null;
    } catch (error) {
      _log('Unable to compensate a notification registration failure: $error');
      return null;
    }
  }

  static Future<bool> _restoreLocalNotificationPreference(
    UserInformation userInformation,
    String typeId,
    NotificationPreference? preference,
  ) async {
    try {
      final write = preference == null
          ? userInformation.clearNotificationPreference(typeId)
          : userInformation.setNotificationPreference(typeId, preference);
      await write.timeout(_legacyMigrationOperationTimeout);
      return true;
    } catch (error) {
      _log('Unable to restore a local notification preference: $error');
      return false;
    }
  }

  /// Cancels the scheduled notification for [typeId].
  ///
  /// Set [requireNoActiveDeliveryPermit] for actions, such as sign-out, that
  /// must not complete after the scheduler has claimed a delivery. The call is
  /// serialized with registration and returns `false` if its remote mutation,
  /// local persistence, or required compensation cannot complete.
  static Future<bool> cancelNotification({
    BuildContext? context,
    UserInformation? userInformation,
    required String typeId,
    bool requireNoActiveDeliveryPermit = false,
    Future<String?> Function()? idTokenProvider,
    NotificationHttpPost? post,
  }) {
    if (context == null && userInformation == null) {
      _log('Warning: no user state, cannot cancel a reminder.');
      return Future.value(false);
    }
    final userInfo = _resolveUserInformation(context, userInformation);
    if (userInfo == null) return Future.value(false);
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

  static Future<bool> _cancelNotification({
    required UserInformation userInformation,
    required String typeId,
    Future<String?> Function()? idTokenProvider,
    NotificationHttpPost? post,
    required int resetEpoch,
    bool resetFence = false,
    Future<void> Function(int notificationId)? legacyNotificationCanceller,
    void Function(NotificationPreference? remotePreference)?
    onRemoteScheduleCancelled,
  }) async {
    if (resetEpoch != _resetEpoch) return false;
    _log('Cancelling notification: typeId=$typeId');
    final userInfo = userInformation;
    try {
      final idToken = await (idTokenProvider ?? _getIdToken)().timeout(
        _networkTimeout,
      );
      if (idToken == null) return false;
      if (resetEpoch != _resetEpoch) return false;
      final expectedMutationVersion = await _getNotificationMutationVersion(
        idToken: idToken,
        typeId: typeId,
        post: post,
      );
      if (expectedMutationVersion == null || resetEpoch != _resetEpoch) {
        return false;
      }
      final response = await (post ?? debugPostOverride ?? http.post)(
        Uri.parse('$_functionsBaseUrl/cancelNotification'),
        headers: {
          'Authorization': 'Bearer $idToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'typeId': typeId,
          'expectedMutationVersion': expectedMutationVersion,
          if (resetFence) 'resetFence': true,
        }),
      ).timeout(_networkTimeout);

      if (response.statusCode == 200) {
        final nextMutationVersion = _successfulMutationVersion(
          response,
          expectedMutationVersion,
        );
        if (nextMutationVersion == null) return false;
        final cancelledSchedule = _cancelledSchedulePreference(response);
        onRemoteScheduleCancelled?.call(cancelledSchedule);
        _log('Notification cancelled successfully.');
        if (typeId == 'default') {
          var legacyReminderHandled = false;
          try {
            await _cancelLegacyDefaultReminder(
              userInfo,
              legacyNotificationCanceller: legacyNotificationCanceller,
            );
            legacyReminderHandled = await _markLegacyDefaultReminderHandled(
              userInfo,
            );
          } catch (error) {
            _log('Unable to retire the legacy local reminder: $error');
          }
          if (!legacyReminderHandled) {
            if (cancelledSchedule != null) {
              final restoredRemotely = await _registerNotification(
                userInformation: userInfo,
                typeId: typeId,
                hour: cancelledSchedule.hour,
                minute: cancelledSchedule.minute,
                idTokenProvider: () async => idToken,
                post: post,
                resetEpoch: resetEpoch,
                allowUnsupportedPlatform: true,
                persistLocalPreference: false,
                expectedMutationVersion: nextMutationVersion,
              );
              if (!restoredRemotely) {
                _log(
                  'Unable to compensate a failed legacy reminder cancellation.',
                );
              }
            } else {
              _log(
                'Cannot compensate a cancellation without its remote schedule.',
              );
            }
            return false;
          }
        }
        try {
          await userInfo
              .clearNotificationPreference(typeId)
              .timeout(_legacyMigrationOperationTimeout);
        } catch (error) {
          _log('Unable to persist cancelled notification: $error');
          if (cancelledSchedule == null) {
            _log(
              'Cannot compensate a cancellation without its remote schedule.',
            );
            return false;
          }
          final restoredLocally = await _restoreLocalNotificationPreference(
            userInfo,
            typeId,
            cancelledSchedule,
          );
          final restoredRemotely = await _registerNotification(
            userInformation: userInfo,
            typeId: typeId,
            hour: cancelledSchedule.hour,
            minute: cancelledSchedule.minute,
            idTokenProvider: () async => idToken,
            post: post,
            resetEpoch: resetEpoch,
            allowUnsupportedPlatform: true,
            persistLocalPreference: false,
            expectedMutationVersion: nextMutationVersion,
          );
          if (!restoredRemotely) {
            _log('Unable to compensate a notification cancellation failure.');
          }
          if (!restoredLocally) {
            _log(
              'Unable to restore local notification state after cancellation.',
            );
          }
          return false;
        }
        return true;
      } else {
        _log(
          'cancelNotification failed: ${response.statusCode} ${response.body}',
        );
        return false;
      }
    } catch (e) {
      _log('cancelNotification error: $e');
      return false;
    }
  }

  static Future<bool> _markLegacyDefaultReminderHandled(
    UserInformation userInformation,
  ) async {
    try {
      await userInformation.service
          .setItem(
            _legacyDefaultReminderMigrationKey,
            PersistentMemoryType.Bool,
            true,
          )
          .timeout(_legacyMigrationOperationTimeout);
      return true;
    } catch (error) {
      _log('Unable to persist legacy reminder cancellation: $error');
      return false;
    }
  }

  static Future<void> _cancelLegacyDefaultReminder(
    UserInformation userInformation, {
    Future<void> Function(int notificationId)? legacyNotificationCanceller,
  }) async {
    final memory = userInformation.service;
    final migrated =
        await memory
            .getItem(
              _legacyDefaultReminderMigrationKey,
              PersistentMemoryType.Bool,
            )
            .timeout(_legacyMigrationOperationTimeout) ??
        false;
    if (migrated == true) return;

    final legacyPreference = await _legacyDefaultReminderPreference(memory);
    if (legacyPreference == null) return;
    await (legacyNotificationCanceller ??
            FcmService.cancelLegacyLocalNotification)(
          _legacyLocalNotificationId(legacyPreference),
        )
        .timeout(_legacyMigrationOperationTimeout);
  }

  static Future<int?> _getNotificationMutationVersion({
    required String idToken,
    required String typeId,
    NotificationHttpPost? post,
  }) async {
    try {
      final response = await (post ?? debugPostOverride ?? http.post)(
        Uri.parse('$_functionsBaseUrl/getNotificationMutationVersion'),
        headers: {
          'Authorization': 'Bearer $idToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'typeId': typeId}),
      ).timeout(_networkTimeout);
      if (response.statusCode != 200) {
        _log(
          'getNotificationMutationVersion failed: ${response.statusCode} ${response.body}',
        );
        return null;
      }
      final body = jsonDecode(response.body);
      final mutationVersion = body is Map<String, dynamic>
          ? body['mutationVersion']
          : null;
      if (mutationVersion is int && mutationVersion >= 0) {
        return mutationVersion;
      }
      _log('getNotificationMutationVersion returned an invalid body.');
      return null;
    } catch (e) {
      _log('getNotificationMutationVersion error: $e');
      return null;
    }
  }

  static int? _successfulMutationVersion(
    http.Response response,
    int expectedMutationVersion,
  ) {
    if (expectedMutationVersion == 9007199254740991) return null;
    try {
      final body = jsonDecode(response.body);
      final mutationVersion = body is Map<String, dynamic>
          ? body['mutationVersion']
          : null;
      if (mutationVersion is int &&
          mutationVersion == expectedMutationVersion + 1) {
        return mutationVersion;
      }
      if (body is Map<String, dynamic> &&
          body.length == 1 &&
          body['success'] == true) {
        // Older deployed Functions returned only this explicit success shape.
        return expectedMutationVersion + 1;
      }
      _log('Notification mutation returned an unexpected version.');
    } catch (_) {
      _log('Notification mutation returned an invalid body.');
    }
    return null;
  }

  static NotificationPreference? _cancelledSchedulePreference(
    http.Response response,
  ) {
    try {
      final body = jsonDecode(response.body);
      if (body is! Map<String, dynamic>) return null;
      final schedule = body['schedule'];
      if (schedule is! Map<String, dynamic>) return null;
      final hour = schedule['hour'];
      final minute = schedule['minute'];
      if (hour is! int ||
          minute is! int ||
          hour < 0 ||
          hour > 23 ||
          minute < 0 ||
          minute > 59) {
        return null;
      }
      return NotificationPreference(hour: hour, minute: minute);
    } catch (_) {
      return null;
    }
  }

  static String? _notificationLocale(String rawLocale) {
    final language = rawLocale.trim().split(RegExp('[-_]')).first.toLowerCase();
    return switch (language) {
      'he' || 'ar' || 'en' => language,
      '' => 'he',
      _ => null,
    };
  }
}
