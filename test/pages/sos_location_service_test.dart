import 'dart:async';

import 'package:flutter/foundation.dart'
    show TargetPlatform, debugDefaultTargetPlatformOverride;
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mazilon/pages/sos_location_service.dart';

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

void main() {
  group('GeolocatorSosLocationService', () {
    Future<SosLocationLookupResult> lookup(
      RecordingGeolocatorPlatform geolocator,
    ) {
      return GeolocatorSosLocationService(
        geolocatorPlatform: geolocator,
        supportsLocationSharing: true,
      ).lookupCurrentPosition();
    }

    test(
      'should return unavailable without platform calls when unsupported',
      () async {
        final geolocator = RecordingGeolocatorPlatform();
        final result = await GeolocatorSosLocationService(
          geolocatorPlatform: geolocator,
          supportsLocationSharing: false,
        ).lookupCurrentPosition();

        expect(result, isA<SosLocationFailureResult>());
        expect(
          (result as SosLocationFailureResult).kind,
          SosLocationFailureKind.unavailable,
        );
        expect(geolocator.calls, isEmpty);
      },
    );

    for (final platform in <TargetPlatform>[
      TargetPlatform.windows,
      TargetPlatform.macOS,
      TargetPlatform.linux,
    ]) {
      test('should avoid platform calls on $platform', () async {
        final originalPlatform = debugDefaultTargetPlatformOverride;
        debugDefaultTargetPlatformOverride = platform;
        try {
          final geolocator = RecordingGeolocatorPlatform();
          final result = await GeolocatorSosLocationService(
            geolocatorPlatform: geolocator,
          ).lookupCurrentPosition();

          expect(
            result,
            isA<SosLocationFailureResult>().having(
              (failure) => failure.kind,
              'kind',
              SosLocationFailureKind.unavailable,
            ),
          );
          expect(geolocator.calls, isEmpty);
        } finally {
          debugDefaultTargetPlatformOverride = originalPlatform;
        }
      });
    }

    test(
      'should classify disabled services before permission lookup',
      () async {
        final geolocator = RecordingGeolocatorPlatform(serviceEnabled: false);
        final result = await lookup(geolocator);

        expect(
          result,
          isA<SosLocationFailureResult>().having(
            (failure) => failure.kind,
            'kind',
            SosLocationFailureKind.servicesDisabled,
          ),
        );
        expect(geolocator.calls, ['isLocationServiceEnabled']);
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
            position: _position(latitude: 32.1, longitude: 34.8),
          );
          final result = await lookup(geolocator);

          expect(
            result,
            isA<SosLocationSuccess>()
                .having(
                  (success) => success.location.latitude,
                  'latitude',
                  32.1,
                )
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
        final result = await lookup(geolocator);

        expect(result, isA<SosLocationSuccess>());
        expect(geolocator.calls, [
          'isLocationServiceEnabled',
          'checkPermission',
          'requestPermission',
          'getCurrentPosition',
        ]);
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
        final result = await lookup(geolocator);

        expect(
          result,
          isA<SosLocationFailureResult>().having(
            (failure) => failure.kind,
            'kind',
            SosLocationFailureKind.unavailable,
          ),
        );
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
      });
    }

    for (final error in <Object>[
      TimeoutException('position timed out'),
      StateError('position failed'),
    ]) {
      test(
        'should return unavailable when the position lookup throws $error',
        () async {
          final geolocator = RecordingGeolocatorPlatform(positionError: error);
          final result = await lookup(geolocator);

          expect(
            result,
            isA<SosLocationFailureResult>().having(
              (failure) => failure.kind,
              'kind',
              SosLocationFailureKind.unavailable,
            ),
          );
          expect(geolocator.calls, [
            'isLocationServiceEnabled',
            'checkPermission',
            'getCurrentPosition',
          ]);
        },
      );
    }

    test(
      'should return unavailable when the permission platform call throws',
      () async {
        final geolocator = RecordingGeolocatorPlatform(
          permissionError: StateError('permission platform failed'),
        );
        final result = await lookup(geolocator);

        expect(
          result,
          isA<SosLocationFailureResult>()
              .having(
                (failure) => failure.kind,
                'kind',
                SosLocationFailureKind.unavailable,
              )
              .having((failure) => failure.canRetry, 'canRetry', isFalse),
        );
        expect(geolocator.calls, [
          'isLocationServiceEnabled',
          'checkPermission',
        ]);
      },
    );

    test(
      'should classify a disabled-services exception as retryable',
      () async {
        final geolocator = RecordingGeolocatorPlatform(
          serviceError: const LocationServiceDisabledException(),
        );
        final result = await lookup(geolocator);

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
      },
    );
  });
}
