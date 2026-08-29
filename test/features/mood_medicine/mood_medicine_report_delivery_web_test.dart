import 'dart:typed_data';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mazilon/features/mood_medicine/data/mood_medicine_report_delivery_types.dart';
import 'package:mazilon/features/mood_medicine/data/mood_medicine_report_delivery_web.dart'
    as report_web;
import 'package:mazilon/util/logger_service.dart';
import 'package:share_plus/share_plus.dart';

void main() {
  group('deliverMoodMedicineWebReportForTesting', () {
    test('should map web handoffs and configure download fallback', () async {
      final List<
        (ShareResultStatus shareStatus, MoodMedicineReportDeliveryStatus status)
      >
      cases =
          <
            (
              ShareResultStatus shareStatus,
              MoodMedicineReportDeliveryStatus status,
            )
          >[
            (
              ShareResultStatus.success,
              MoodMedicineReportDeliveryStatus.delivered,
            ),
            (
              ShareResultStatus.unavailable,
              MoodMedicineReportDeliveryStatus.delivered,
            ),
            (
              ShareResultStatus.dismissed,
              MoodMedicineReportDeliveryStatus.dismissed,
            ),
          ];

      for (final (
            ShareResultStatus shareStatus,
            MoodMedicineReportDeliveryStatus expectedStatus,
          )
          in cases) {
        final _RecordingShare share = _RecordingShare(shareStatus);
        final MoodMedicineReportDelivery delivery = await report_web
            .deliverMoodMedicineWebReportForTesting(
              incidentLoggerService: const _NoopIncidentLoggerService(),
              bytes: Uint8List.fromList(<int>[4, 5, 6]),
              fileName: 'report.png',
              mimeType: 'image/png',
              shareText: '  Mood report  ',
              share: share.call,
            );

        expect(delivery.status, expectedStatus);
        final ShareParams params = share.params!;
        expect(params.text, 'Mood report');
        expect(params.title, 'report.png');
        expect(params.subject, 'report.png');
        expect(params.fileNameOverrides, <String>['report.png']);
        expect(params.downloadFallbackEnabled, isTrue);
        expect(params.mailToFallbackEnabled, isFalse);
        expect(await params.files!.single.readAsBytes(), <int>[4, 5, 6]);
      }
    });

    test('should map web share errors to failed', () async {
      final _RecordingShare share = _RecordingShare(
        ShareResultStatus.success,
        error: StateError('browser unavailable'),
      );

      final MoodMedicineReportDelivery delivery = await report_web
          .deliverMoodMedicineWebReportForTesting(
            incidentLoggerService: const _NoopIncidentLoggerService(),
            bytes: Uint8List.fromList(<int>[4, 5, 6]),
            fileName: 'report.png',
            mimeType: 'image/png',
            share: share.call,
          );

      expect(delivery.status, MoodMedicineReportDeliveryStatus.failed);
    });

    test('should log a sanitized web delivery failure', () async {
      final _CapturingLogger logger = _CapturingLogger();

      final MoodMedicineReportDelivery delivery = await report_web
          .deliverMoodMedicineWebReportForTesting(
            incidentLoggerService: logger,
            bytes: Uint8List.fromList(<int>[4, 5, 6]),
            fileName: 'report.png',
            mimeType: 'image/png',
            share: _RecordingShare(
              ShareResultStatus.success,
              error: StateError('private note https://example.test/source'),
            ).call,
          );

      expect(delivery.status, MoodMedicineReportDeliveryStatus.failed);
      expect(logger.logs, hasLength(1));
      final String payload = logger.logs.single.toString();
      expect(payload, contains('delivery'));
      expect(payload, contains('StateError'));
      expect(payload, isNot(contains('private note')));
      expect(payload, isNot(contains('https://example.test/source')));
      expect(logger.stackTraces.single, isNotNull);
    });

    test('should retain failed status when incident logging throws', () async {
      final MoodMedicineReportDelivery delivery = await report_web
          .deliverMoodMedicineWebReportForTesting(
            incidentLoggerService: const _ThrowingLogger(),
            bytes: Uint8List.fromList(<int>[4, 5, 6]),
            fileName: 'report.png',
            mimeType: 'image/png',
            share: _RecordingShare(
              ShareResultStatus.success,
              error: StateError('browser unavailable'),
            ).call,
          );

      expect(delivery.status, MoodMedicineReportDeliveryStatus.failed);
    });
  });
}

final class _RecordingShare {
  _RecordingShare(this._status, {this.error});

  final ShareResultStatus _status;
  final Object? error;
  ShareParams? params;

  Future<ShareResult> call(ShareParams value) async {
    params = value;
    if (error != null) {
      throw error!;
    }
    return ShareResult('test', _status);
  }
}

final class _CapturingLogger implements IncidentLoggerService {
  final List<Object> logs = <Object>[];
  final List<StackTrace?> stackTraces = <StackTrace?>[];

  @override
  Future<void> captureLog(
    dynamic exception, {
    StackTrace? stackTrace,
    dynamic exceptionData,
  }) async {
    logs.add(exception as Object);
    stackTraces.add(stackTrace);
  }

  @override
  Future<void> initializeSentry(Widget myApp) async {}
}

final class _NoopIncidentLoggerService implements IncidentLoggerService {
  const _NoopIncidentLoggerService();

  @override
  Future<void> captureLog(
    dynamic exception, {
    StackTrace? stackTrace,
    dynamic exceptionData,
  }) async {}

  @override
  Future<void> initializeSentry(Widget myApp) async {}
}

final class _ThrowingLogger implements IncidentLoggerService {
  const _ThrowingLogger();

  @override
  Future<void> captureLog(
    dynamic exception, {
    StackTrace? stackTrace,
    dynamic exceptionData,
  }) async {
    throw StateError('telemetry unavailable');
  }

  @override
  Future<void> initializeSentry(Widget myApp) async {}
}
