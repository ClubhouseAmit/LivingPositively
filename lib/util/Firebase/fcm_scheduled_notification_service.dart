import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:http/http.dart' as http;
import 'package:mazilon/util/notification_preference.dart';
import 'package:mazilon/util/userInformation.dart';
import 'package:provider/provider.dart';

class FcmScheduledNotificationService {
  static const String _functionsBaseUrl =
      'https://us-central1-mezilondb.cloudfunctions.net';

  static void _log(String message) =>
      debugPrint('[FcmScheduledNotificationService] $message');

  static Future<String?> _getIdToken() async {
    final token =
        await GetIt.instance<FirebaseAuth>().currentUser?.getIdToken();
    if (token == null) _log('Warning: no authenticated user, cannot get ID token.');
    return token;
  }

  // Registers or updates a scheduled notification for the given type.
  // hour/minute are Israel local time, exactly as the user selected.
  // Returns true on success.
  static Future<bool> registerNotification({
    required BuildContext context,
    required String typeId,
    required int hour,
    required int minute,
  }) async {
    _log('Registering notification: typeId=$typeId, hour=$hour, minute=$minute');
    final userInfo = Provider.of<UserInformation>(context, listen: false);
    final locale = userInfo.localeName.isNotEmpty ? userInfo.localeName : 'he';
    final rawGender = userInfo.gender;
    final gender = (rawGender == 'male' || rawGender == 'female') ? rawGender : 'other';

    final idToken = await _getIdToken();
    if (idToken == null) return false;

    try {
      final response = await http.post(
        Uri.parse('$_functionsBaseUrl/registerNotification'),
        headers: {
          'Authorization': 'Bearer $idToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'typeId': typeId, 'hour': hour, 'minute': minute, 'locale': locale, 'gender': gender}),
      );

      if (response.statusCode == 200) {
        _log('Notification registered successfully.');
        if (context.mounted) {
          Provider.of<UserInformation>(context, listen: false)
              .setNotificationPreference(
                  typeId, NotificationPreference(hour: hour, minute: minute));
        }
        return true;
      } else {
        _log('registerNotification failed: ${response.statusCode} ${response.body}');
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
    required BuildContext context,
    required String typeId,
  }) async {
    _log('Cancelling notification: typeId=$typeId');
    final idToken = await _getIdToken();
    if (idToken == null) return false;

    try {
      final response = await http.post(
        Uri.parse('$_functionsBaseUrl/cancelNotification'),
        headers: {
          'Authorization': 'Bearer $idToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'typeId': typeId}),
      );

      if (response.statusCode == 200) {
        _log('Notification cancelled successfully.');
        if (context.mounted) {
          Provider.of<UserInformation>(context, listen: false)
              .clearNotificationPreference(typeId);
        }
        return true;
      } else {
        _log('cancelNotification failed: ${response.statusCode} ${response.body}');
        return false;
      }
    } catch (e) {
      _log('cancelNotification error: $e');
      return false;
    }
  }
}
