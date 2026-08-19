import 'dart:async';

import 'package:flutter/foundation.dart'
    show TargetPlatform, debugDefaultTargetPlatformOverride;
import 'package:flutter/widgets.dart' show Widget;
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mazilon/pages/sos_location_service.dart';
import 'package:mazilon/util/logger_service.dart';

class RecordingGeolocatorPlatform extends GeolocatorPlatform {
  RecordingGeolocatorPlatform({
    this.serviceEnabled = true,
    this.permission = LocationPermission.whileInUse,
    this.requestedPermission,
    this.position,
    this.positionError,
    this.permissionError,
    this.serviceError,
  });

  final bool serviceEnabled;
  final LocationPermission permission;
  final LocationPermission? requestedPermission;
  final Position? position;
  final Object? positionError;
  final Object? permissionError;
  final Object? serviceError;
  final List<String> calls = [];
  LocationSettings? locationSettings;

  @override
  Future<bool> isLocationServiceEnabled() async {
    calls.add('isLocationServiceEnabled');
    if (serviceError != null) {
      throw serviceError!;
    }
    return serviceEnabled;
  }

  @override
  Future<LocationPermission> checkPermission() async {
    calls.add('checkPermission');
    if (permissionError != null) {
      throw permissionError!;
    }
    return permission;
  }

  @override
  Future<LocationPermission> requestPermission() async {
    calls.add('requestPermission');
    if (permissionError != null) {
      throw permissionError!;
    }
    return requestedPermission ?? permission;
  }

  @override
  Future<Position> getCurrentPosition({LocationSettings? locationSettings}) {
    calls.add('getCurrentPosition');
    this.locationSettings = locationSettings;
    if (positionError != null) {
      return Future<Position>.error(positionError!);
    }
    return Future<Position>.value(position ?? _position());
  }
}

class RecordingIncidentLoggerService implements IncidentLoggerService {
  RecordingIncidentLoggerService({
    this.throwOnCapture = false,
    this.captureCompleter,
  });

  final bool throwOnCapture;
  final Completer<void>? captureCompleter;
  final List<({Object exception, StackTrace? stackTrace})> captured = [];
  int captureCalls = 0;

  @override
  Future<void> initializeSentry(Widget myApp) async {}

  @override
  Future<void> captureLog(
    dynamic exception, {
    StackTrace? stackTrace,
    dynamic exceptionData,
  }) async {
    captureCalls++;
    if (throwOnCapture) {
      throw StateError('incident logging failed');
    }
    captured.add((exception: exception as Object, stackTrace: stackTrace));
    final completer = captureCompleter;
    if (completer != null) {
      await completer.future;
    }
  }
}

Position _position({double latitude = 31.7683, double longitude = 35.2137}) {
  return Position(
    latitude: latitude,
    longitude: longitude,
    timestamp: DateTime.utc(2026),
    accuracy: 1,
    altitude: 0,
    altitudeAccuracy: 0,
    heading: 0,
    headingAccuracy: 0,
    speed: 0,
    speedAccuracy: 0,
  );
}

Future<SosLocationLookupResult> _lookupOnNativeTarget(
  RecordingGeolocatorPlatform geolocator,
  RecordingIncidentLoggerService logger, {
  TargetPlatform targetPlatform = TargetPlatform.android,
}) async {
  final originalPlatform = debugDefaultTargetPlatformOverride;
  debugDefaultTargetPlatformOverride = targetPlatform;
  try {
    return await GeolocatorSosLocationService(
      incidentLoggerService: logger,
      geolocatorPlatform: geolocator,
    ).lookupCurrentPosition();
  } finally {
    debugDefaultTargetPlatformOverride = originalPlatform;
  }
}

void _expectUnavailable(SosLocationLookupResult result) {
  expect(
    result,
    isA<SosLocationFailureResult>().having(
      (failure) => failure.kind,
      'kind',
      SosLocationFailureKind.unavailable,
    ),
  );
}

void main() {
  group('GeolocatorSosLocationService', () {
    for (final targetPlatform in <TargetPlatform>[
      TargetPlatform.android,
      TargetPlatform.iOS,
    ]) {
      test('should allow one lookup on native $targetPlatform', () async {
        final geolocator = RecordingGeolocatorPlatform(
          position: _position(latitude: 32.1, longitude: 34.8),
        );
        final logger = RecordingIncidentLoggerService();

        final result = await _lookupOnNativeTarget(
          geolocator,
          logger,
          targetPlatform: targetPlatform,
        );

        expect(
          result,
          isA<SosLocationSuccess>()
              .having((success) => success.location.latitude, 'latitude', 32.1)
              .having(
                (success) => success.location.longitude,
                'longitude',
                34.8,
              ),
        );
        expect(geolocator.calls, [
          'isLocationServiceEnabled',
          'checkPermission',
          'getCurrentPosition',
        ]);
        expect(geolocator.locationSettings?.accuracy, LocationAccuracy.high);
        expect(
          geolocator.locationSettings?.timeLimit,
          const Duration(seconds: 15),
        );
        expect(logger.captureCalls, 0);
      });
    }

    for (final targetPlatform in <TargetPlatform>[
      TargetPlatform.windows,
      TargetPlatform.macOS,
      TargetPlatform.linux,
    ]) {
      test(
        'should fail closed without platform calls on $targetPlatform',
        () async {
          final geolocator = RecordingGeolocatorPlatform();
          final logger = RecordingIncidentLoggerService();

          final result = await _lookupOnNativeTarget(
            geolocator,
            logger,
            targetPlatform: targetPlatform,
          );

          _expectUnavailable(result);
          expect(geolocator.calls, isEmpty);
          expect(logger.captureCalls, 0);
        },
      );
    }

    test('should fail closed without platform calls on web', () async {
      final geolocator = RecordingGeolocatorPlatform();
      final logger = RecordingIncidentLoggerService();

      final result = await GeolocatorSosLocationService.forTesting(
        incidentLoggerService: logger,
        geolocatorPlatform: geolocator,
        isWeb: true,
        targetPlatform: TargetPlatform.android,
      ).lookupCurrentPosition();

      _expectUnavailable(result);
      expect(geolocator.calls, isEmpty);
      expect(logger.captureCalls, 0);
    });

    test(
      'should classify disabled services before permission lookup',
      () async {
        final geolocator = RecordingGeolocatorPlatform(serviceEnabled: false);
        final logger = RecordingIncidentLoggerService();

        final result = await _lookupOnNativeTarget(geolocator, logger);

        expect(
          result,
          isA<SosLocationFailureResult>().having(
            (failure) => failure.kind,
            'kind',
            SosLocationFailureKind.servicesDisabled,
          ),
        );
        expect(geolocator.calls, ['isLocationServiceEnabled']);
        expect(logger.captureCalls, 0);
      },
    );

    for (final permission in <LocationPermission>[
      LocationPermission.whileInUse,
      LocationPermission.always,
    ]) {
      test(
        'should return a snapshot for existing $permission permission',
        () async {
          final geolocator = RecordingGeolocatorPlatform(
            permission: permission,
          );
          final logger = RecordingIncidentLoggerService();

          final result = await _lookupOnNativeTarget(geolocator, logger);

          expect(result, isA<SosLocationSuccess>());
          expect(geolocator.calls, [
            'isLocationServiceEnabled',
            'checkPermission',
            'getCurrentPosition',
          ]);
          expect(logger.captureCalls, 0);
        },
      );
    }

    test(
      'should request denied permission once before a successful lookup',
      () async {
        final geolocator = RecordingGeolocatorPlatform(
          permission: LocationPermission.denied,
          requestedPermission: LocationPermission.whileInUse,
        );
        final logger = RecordingIncidentLoggerService();

        final result = await _lookupOnNativeTarget(geolocator, logger);

        expect(result, isA<SosLocationSuccess>());
        expect(geolocator.calls, [
          'isLocationServiceEnabled',
          'checkPermission',
          'requestPermission',
          'getCurrentPosition',
        ]);
        expect(logger.captureCalls, 0);
      },
    );

    for (final permissionCase
        in <({LocationPermission initial, LocationPermission? requested})>[
          (
            initial: LocationPermission.denied,
            requested: LocationPermission.denied,
          ),
          (initial: LocationPermission.deniedForever, requested: null),
          (initial: LocationPermission.unableToDetermine, requested: null),
        ]) {
      test('should return unavailable for $permissionCase', () async {
        final geolocator = RecordingGeolocatorPlatform(
          permission: permissionCase.initial,
          requestedPermission: permissionCase.requested,
        );
        final logger = RecordingIncidentLoggerService();

        final result = await _lookupOnNativeTarget(geolocator, logger);

        _expectUnavailable(result);
        expect(
          geolocator.calls,
          permissionCase.initial == LocationPermission.denied
              ? [
                  'isLocationServiceEnabled',
                  'checkPermission',
                  'requestPermission',
                ]
              : ['isLocationServiceEnabled', 'checkPermission'],
        );
        expect(logger.captureCalls, 0);
      });
    }

    for (final error in <Object>[
      TimeoutException('position timed out'),
      StateError('position failed'),
    ]) {
      test(
        'should log structured diagnostics when the position lookup throws $error',
        () async {
          final geolocator = RecordingGeolocatorPlatform(positionError: error);
          final logger = RecordingIncidentLoggerService();

          final result = await _lookupOnNativeTarget(geolocator, logger);

          _expectUnavailable(result);
          expect(geolocator.calls, [
            'isLocationServiceEnabled',
            'checkPermission',
            'getCurrentPosition',
          ]);
          expect(logger.captureCalls, 1);
          expect(logger.captured, hasLength(1));
          expect(logger.captured.single.exception, same(error));
          expect(logger.captured.single.stackTrace, isNotNull);
        },
      );
    }

    test(
      'should log a permission platform failure with its stack trace',
      () async {
        final error = StateError('permission platform failed');
        final geolocator = RecordingGeolocatorPlatform(permissionError: error);
        final logger = RecordingIncidentLoggerService();

        final result = await _lookupOnNativeTarget(geolocator, logger);

        _expectUnavailable(result);
        expect(geolocator.calls, [
          'isLocationServiceEnabled',
          'checkPermission',
        ]);
        expect(logger.captureCalls, 1);
        expect(logger.captured.single.exception, same(error));
        expect(logger.captured.single.stackTrace, isNotNull);
      },
    );

    test(
      'should log a location-service platform failure with its stack trace',
      () async {
        final error = StateError('location service platform failed');
        final geolocator = RecordingGeolocatorPlatform(serviceError: error);
        final logger = RecordingIncidentLoggerService();

        final result = await _lookupOnNativeTarget(geolocator, logger);

        _expectUnavailable(result);
        expect(geolocator.calls, ['isLocationServiceEnabled']);
        expect(logger.captureCalls, 1);
        expect(logger.captured.single.exception, same(error));
        expect(logger.captured.single.stackTrace, isNotNull);
      },
    );

    test(
      'should return unavailable before a stalled incident capture completes',
      () async {
        final captureCompleter = Completer<void>();
        addTearDown(() {
          if (!captureCompleter.isCompleted) {
            captureCompleter.complete();
          }
        });
        final error = StateError('position failed');
        final geolocator = RecordingGeolocatorPlatform(positionError: error);
        final logger = RecordingIncidentLoggerService(
          captureCompleter: captureCompleter,
        );

        final result = await _lookupOnNativeTarget(
          geolocator,
          logger,
        ).timeout(const Duration(seconds: 1));

        _expectUnavailable(result);
        expect(logger.captureCalls, 1);
        expect(logger.captured.single.exception, same(error));
        expect(logger.captured.single.stackTrace, isNotNull);
        expect(captureCompleter.isCompleted, isFalse);
      },
    );

    test('should remain unavailable when incident logging fails', () async {
      final geolocator = RecordingGeolocatorPlatform(
        positionError: StateError('position failed'),
      );
      final logger = RecordingIncidentLoggerService(throwOnCapture: true);

      final result = await _lookupOnNativeTarget(geolocator, logger);

      _expectUnavailable(result);
      expect(logger.captureCalls, 1);
      expect(logger.captured, isEmpty);
    });

    test(
      'should classify a disabled-services exception without logging',
      () async {
        final geolocator = RecordingGeolocatorPlatform(
          serviceError: const LocationServiceDisabledException(),
        );
        final logger = RecordingIncidentLoggerService();

        final result = await _lookupOnNativeTarget(geolocator, logger);

        expect(
          result,
          isA<SosLocationFailureResult>()
              .having(
                (failure) => failure.kind,
                'kind',
                SosLocationFailureKind.servicesDisabled,
              )
              .having((failure) => failure.canRetry, 'canRetry', isTrue),
        );
        expect(geolocator.calls, ['isLocationServiceEnabled']);
        expect(logger.captureCalls, 0);
      },
    );
  });
}
