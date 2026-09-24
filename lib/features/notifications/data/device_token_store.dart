import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';

/// Writes the current FCM token under the authenticated device document.
final class DeviceTokenStore {
  const DeviceTokenStore._();

  static Future<void> save(String deviceId, String token) =>
      FirebaseFirestore.instance.collection('devices').doc(deviceId).set({
        'fcmToken': token,
        'platform': Platform.isAndroid ? 'android' : 'ios',
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
}
