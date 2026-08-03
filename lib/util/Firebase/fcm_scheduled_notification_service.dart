import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:http/http.dart' as http;
import 'package:mazilon/util/Firebase/fcm_service.dart';
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
  static const Duration _networkTimeout = Duration(seconds: 15);
  static Future<void>? _operationQueue;
  static bool _legacyMigrationDisabled = false;
  static int _resetEpoch = 0;

  @visibleForTesting
  static void resetForTesting() {
    _operationQueue = null;
    _legacyMigrationDisabled = false;
    _resetEpoch = 0;
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

  static Future<void> migrateLegacyDefaultReminder({
    BuildContext? context,
    UserInformation? userInformation,
    Future<String?> Function()? idTokenProvider,
    NotificationHttpPost? post,
    PersistentMemoryService? persistentMemory,
  }) async {
    if (_legacyMigrationDisabled) return;
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
      final preference = userInfo.getNotificationPreference('default');
      if (preference == null) return;
      final memory =
          persistentMemory ?? GetIt.instance<PersistentMemoryService>();
      final migrated =
          await memory.getItem(
            _legacyDefaultReminderMigrationKey,
            PersistentMemoryType.Bool,
          ) ??
          false;
      if (
        migrated == true ||
        _legacyMigrationDisabled ||
        resetEpoch != _resetEpoch
      ) {
        return;
      }
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
        await memory.setItem(
          _legacyDefaultReminderMigrationKey,
          PersistentMemoryType.Bool,
          true,
        );
      }
    });
  }

  // Registers or updates a scheduled notification for the given type.
  // hour/minute are Israel local time, exactly as the user selected.
  // Returns true on success.
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
    final resetEpoch = _resetEpoch;
    return _enqueue(
      () => _registerNotification(
        context: context,
        userInformation: userInformation,
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
    BuildContext? context,
    UserInformation? userInformation,
    required String typeId,
    required int hour,
    required int minute,
    Future<String?> Function()? idTokenProvider,
    NotificationHttpPost? post,
    required int resetEpoch,
  }) async {
    if (!FcmService.supportsReminderSettings()) return false;
    if (resetEpoch != _resetEpoch) return false;
    _log(
      'Registering notification: typeId=$typeId, hour=$hour, minute=$minute',
    );
    final userInfo =
        userInformation ??
        Provider.of<UserInformation>(context!, listen: false);
    final locale = userInfo.localeName.isNotEmpty ? userInfo.localeName : 'he';
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
      final expectedMutationVersion = await _getNotificationMutationVersion(
        idToken: idToken,
        typeId: typeId,
        post: post,
      );
      if (expectedMutationVersion == null || resetEpoch != _resetEpoch) {
        return false;
      }
      final response = await (post ?? http.post)(
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
          'expectedMutationVersion': expectedMutationVersion,
        }),
      ).timeout(_networkTimeout);

      if (response.statusCode == 200) {
        _log('Notification registered successfully.');
        if (userInformation != null) {
          userInfo.setNotificationPreference(
            typeId,
            NotificationPreference(hour: hour, minute: minute),
          );
        } else if (context!.mounted) {
          Provider.of<UserInformation>(
            context,
            listen: false,
          ).setNotificationPreference(
            typeId,
            NotificationPreference(hour: hour, minute: minute),
          );
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

  // Cancels the scheduled notification for the given type (deletes Firestore doc).
  // Returns true on success.
  static Future<bool> cancelNotification({
    BuildContext? context,
    UserInformation? userInformation,
    required String typeId,
    Future<String?> Function()? idTokenProvider,
    NotificationHttpPost? post,
  }) {
    if (context == null && userInformation == null) {
      _log('Warning: no user state, cannot cancel a reminder.');
      return Future.value(false);
    }
    final resetEpoch = _resetEpoch;
    return _enqueue(
      () => _cancelNotification(
        context: context,
        userInformation: userInformation,
        typeId: typeId,
        idTokenProvider: idTokenProvider,
        post: post,
        resetEpoch: resetEpoch,
      ),
    );
  }

  static Future<bool> cancelDefaultForReset({
    required UserInformation userInformation,
    Future<String?> Function()? idTokenProvider,
    NotificationHttpPost? post,
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

  static Future<bool> _cancelNotification({
    BuildContext? context,
    UserInformation? userInformation,
    required String typeId,
    Future<String?> Function()? idTokenProvider,
    NotificationHttpPost? post,
    required int resetEpoch,
    bool resetFence = false,
  }) async {
    if (!FcmService.supportsReminderSettings()) return false;
    if (resetEpoch != _resetEpoch) return false;
    _log('Cancelling notification: typeId=$typeId');
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
      final response = await (post ?? http.post)(
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
        _log('Notification cancelled successfully.');
        if (userInformation != null) {
          userInformation.clearNotificationPreference(typeId);
        } else if (context!.mounted) {
          Provider.of<UserInformation>(
            context,
            listen: false,
          ).clearNotificationPreference(typeId);
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

  static Future<int?> _getNotificationMutationVersion({
    required String idToken,
    required String typeId,
    NotificationHttpPost? post,
  }) async {
    try {
      final response = await (post ?? http.post)(
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
}
