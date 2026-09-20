import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;

/// Determines whether this device can own mobile reminder settings.
final class NotificationPlatformPolicy {
  const NotificationPlatformPolicy._();

  static bool supportsReminders({
    bool? isWebOverride,
    TargetPlatform? platformOverride,
  }) {
    if (isWebOverride ?? kIsWeb) return false;
    final platform = platformOverride ?? defaultTargetPlatform;
    return platform == TargetPlatform.android || platform == TargetPlatform.iOS;
  }
}
