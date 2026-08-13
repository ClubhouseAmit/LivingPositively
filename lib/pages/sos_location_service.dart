import 'package:flutter/foundation.dart'
    show TargetPlatform, debugPrint, defaultTargetPlatform, kIsWeb;
import 'package:geolocator/geolocator.dart';

abstract interface class SosLocationService {
  Future<SosLocationLookupResult> lookupCurrentPosition();
}

sealed class SosLocationLookupResult {
  const SosLocationLookupResult();
}

final class SosLocationSuccess extends SosLocationLookupResult {
  const SosLocationSuccess(this.location);

  final SosLocationSnapshot location;
}

final class SosLocationFailureResult extends SosLocationLookupResult {
  const SosLocationFailureResult(this.kind);

  final SosLocationFailureKind kind;

  bool get canRetry => kind == SosLocationFailureKind.servicesDisabled;
}

enum SosLocationFailureKind { servicesDisabled, unavailable }

class SosLocationSnapshot {
  const SosLocationSnapshot({required this.latitude, required this.longitude});

  final double latitude;
  final double longitude;
}

class GeolocatorSosLocationService implements SosLocationService {
  GeolocatorSosLocationService({
    GeolocatorPlatform? geolocatorPlatform,
    bool? supportsLocationSharing,
  }) : _geolocatorPlatform = geolocatorPlatform ?? GeolocatorPlatform.instance,
       _supportsLocationSharingOverride = supportsLocationSharing;

  final GeolocatorPlatform _geolocatorPlatform;
  final bool? _supportsLocationSharingOverride;

  bool get _isLocationSharingSupported =>
      _supportsLocationSharingOverride ??
      (!kIsWeb &&
          (defaultTargetPlatform == TargetPlatform.android ||
              defaultTargetPlatform == TargetPlatform.iOS));

  @override
  Future<SosLocationLookupResult> lookupCurrentPosition() async {
    if (!_isLocationSharingSupported) {
      return const SosLocationFailureResult(SosLocationFailureKind.unavailable);
    }

    try {
      final serviceEnabled = await _geolocatorPlatform
          .isLocationServiceEnabled();
      if (!serviceEnabled) {
        return const SosLocationFailureResult(
          SosLocationFailureKind.servicesDisabled,
        );
      }

      var permission = await _geolocatorPlatform.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await _geolocatorPlatform.requestPermission();
      }
      if (permission != LocationPermission.whileInUse &&
          permission != LocationPermission.always) {
        return const SosLocationFailureResult(
          SosLocationFailureKind.unavailable,
        );
      }

      final position = await _geolocatorPlatform.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );
      return SosLocationSuccess(
        SosLocationSnapshot(
          latitude: position.latitude,
          longitude: position.longitude,
        ),
      );
    } on LocationServiceDisabledException {
      return const SosLocationFailureResult(
        SosLocationFailureKind.servicesDisabled,
      );
    } catch (error, stackTrace) {
      debugPrint('Could not get SOS location: $error\n$stackTrace');
      return const SosLocationFailureResult(SosLocationFailureKind.unavailable);
    }
  }
}
