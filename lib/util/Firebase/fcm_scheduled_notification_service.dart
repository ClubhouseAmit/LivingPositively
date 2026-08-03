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

  @visibleForTesting
  static void resetForTesting() {
    _operationQueue = null;
    _legacyMigrationDisabled = false;
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
    final userInfo =
        userInformation ??
        Provider.of<UserInformation>(context!, listen: false);

    await _enqueue(() async {
      if (_legacyMigrationDisabled) return;
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
      if (migrated == true || _legacyMigrationDisabled) return;
      final registered = await _registerNotification(
        userInformation: userInfo,
        typeId: 'default',
        hour: preference.hour,
        minute: preference.minute,
        idTokenProvider: idTokenProvider,
        post: post,
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
  }) => _enqueue(
    () => _registerNotification(
      context: context,
      userInformation: userInformation,
      typeId: typeId,
      hour: hour,
      minute: minute,
      idTokenProvider: idTokenProvider,
      post: post,
    ),
  );

  static Future<bool> _registerNotification({
    BuildContext? context,
    UserInformation? userInformation,
    required String typeId,
    required int hour,
    required int minute,
    Future<String?> Function()? idTokenProvider,
    NotificationHttpPost? post,
  }) async {
    if (!FcmService.supportsReminderSettings()) return false;
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
  }) => _enqueue(
    () => _cancelNotification(
      context: context,
      userInformation: userInformation,
      typeId: typeId,
      idTokenProvider: idTokenProvider,
      post: post,
    ),
  );

  static Future<bool> cancelDefaultForReset({
    required UserInformation userInformation,
    Future<String?> Function()? idTokenProvider,
    NotificationHttpPost? post,
  }) {
    _legacyMigrationDisabled = true;
    return _enqueue(() async {
      try {
        final cancelled = await _cancelNotification(
          userInformation: userInformation,
          typeId: 'default',
          idTokenProvider: idTokenProvider,
          post: post,
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
  }) async {
    if (!FcmService.supportsReminderSettings()) return false;
    _log('Cancelling notification: typeId=$typeId');
    try {
      final idToken = await (idTokenProvider ?? _getIdToken)().timeout(
        _networkTimeout,
      );
      if (idToken == null) return false;
      final response = await (post ?? http.post)(
        Uri.parse('$_functionsBaseUrl/cancelNotification'),
        headers: {
          'Authorization': 'Bearer $idToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'typeId': typeId}),
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
}
