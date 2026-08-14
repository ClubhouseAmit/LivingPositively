import 'dart:async' show unawaited;

import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb, visibleForTesting;
import 'package:geolocator/geolocator.dart';
import 'package:mazilon/util/logger_service.dart';

/// Performs a single foreground SOS location lookup.
///
/// Implementations return typed success coordinates or a failure that tells the
/// caller whether location services are disabled. They never start background
/// tracking.
abstract interface class SosLocationService {
  /// Looks up one current foreground location for an SOS delivery action.
  Future<SosLocationLookupResult> lookupCurrentPosition();
}

/// The result of an SOS foreground location lookup.
sealed class SosLocationLookupResult {
  const SosLocationLookupResult();
}

/// A successful SOS location lookup.
final class SosLocationSuccess extends SosLocationLookupResult {
  const SosLocationSuccess(this.location);

  /// The coordinates captured for the current SOS action.
  final SosLocationSnapshot location;
}

/// An SOS location lookup that could not produce coordinates.
final class SosLocationFailureResult extends SosLocationLookupResult {
  const SosLocationFailureResult(this.kind);

  /// The classified reason the lookup could not produce a location.
  final SosLocationFailureKind kind;

  /// Whether the caller may offer the user another lookup attempt.
  bool get canRetry => kind == SosLocationFailureKind.servicesDisabled;
}

/// Classifies why an SOS location lookup could not produce coordinates.
enum SosLocationFailureKind {
  /// Device location services are disabled and can be enabled before retrying.
  servicesDisabled,

  /// The location is unavailable for any other reason.
  unavailable,
}

/// Immutable coordinates captured by an SOS location lookup.
final class SosLocationSnapshot {
  const SosLocationSnapshot({required this.latitude, required this.longitude});

  /// The captured latitude in decimal degrees.
  final double latitude;

  /// The captured longitude in decimal degrees.
  final double longitude;
}

/// A [SosLocationService] backed by [GeolocatorPlatform].
///
/// Production lookups are supported only on Android and iOS, never on the web.
/// The service performs one high-accuracy foreground lookup with a 15-second
/// limit. It requests only while-in-use permission while accepting an already
/// granted always permission, and never enables background tracking.
final class GeolocatorSosLocationService implements SosLocationService {
  /// Creates the production SOS location service for the current platform.
  GeolocatorSosLocationService({
    required IncidentLoggerService incidentLoggerService,
    GeolocatorPlatform? geolocatorPlatform,
  }) : this._(
         geolocatorPlatform: geolocatorPlatform ?? GeolocatorPlatform.instance,
         incidentLoggerService: incidentLoggerService,
         isWeb: kIsWeb,
         targetPlatform: defaultTargetPlatform,
       );

  /// Creates an SOS location service with an explicit runtime environment.
  ///
  /// This constructor exists only for tests that must exercise the same support
  /// predicate for web and platform combinations that cannot occur in one test
  /// runtime. Production code must use [GeolocatorSosLocationService].
  @visibleForTesting
  GeolocatorSosLocationService.forTesting({
    required IncidentLoggerService incidentLoggerService,
    required GeolocatorPlatform geolocatorPlatform,
    required bool isWeb,
    required TargetPlatform targetPlatform,
  }) : this._(
         geolocatorPlatform: geolocatorPlatform,
         incidentLoggerService: incidentLoggerService,
         isWeb: isWeb,
         targetPlatform: targetPlatform,
       );

  GeolocatorSosLocationService._({
    required this._geolocatorPlatform,
    required this._incidentLoggerService,
    required this._isWeb,
    required this._targetPlatform,
  });

  final GeolocatorPlatform _geolocatorPlatform;
  final IncidentLoggerService _incidentLoggerService;
  final bool _isWeb;
  final TargetPlatform _targetPlatform;

  bool get _isLocationSharingSupported =>
      _supportsLocationSharing(isWeb: _isWeb, targetPlatform: _targetPlatform);

  static bool _supportsLocationSharing({
    required bool isWeb,
    required TargetPlatform targetPlatform,
  }) {
    return !isWeb &&
        (targetPlatform == TargetPlatform.android ||
            targetPlatform == TargetPlatform.iOS);
  }

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
      _reportUnexpectedFailure(error, stackTrace);
      return const SosLocationFailureResult(SosLocationFailureKind.unavailable);
    }
  }

  void _reportUnexpectedFailure(Object error, StackTrace stackTrace) {
    unawaited(_captureUnexpectedFailure(error, stackTrace));
  }

  Future<void> _captureUnexpectedFailure(
    Object error,
    StackTrace stackTrace,
  ) async {
    try {
      await _incidentLoggerService.captureLog(error, stackTrace: stackTrace);
    } catch (_) {
      // SOS lookup remains fail-closed even when incident reporting fails.
    }
  }
}
