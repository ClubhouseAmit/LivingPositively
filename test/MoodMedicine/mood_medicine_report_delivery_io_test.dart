import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mazilon/pages/MoodMedicine/mood_medicine_report_delivery_io.dart'
    as report_io;
import 'package:mazilon/pages/MoodMedicine/mood_medicine_report_delivery_types.dart';
import 'package:mazilon/util/logger_service.dart';
import 'package:share_plus/share_plus.dart';

void main() {
  group('deliverMoodMedicineIoReportForTesting', () {
    test('should map IO handoff statuses and use byte-backed files', () async {
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

        final MoodMedicineReportDelivery delivery = await report_io
            .deliverMoodMedicineIoReportForTesting(
              bytes: Uint8List.fromList(<int>[1, 2, 3]),
              fileName: 'report.pdf',
              mimeType: 'application/pdf',
              shareText: '  Mood report  ',
              share: share.call,
            );

        expect(delivery.status, expectedStatus);
        final ShareParams params = share.params!;
        expect(params.text, 'Mood report');
        expect(params.title, 'report.pdf');
        expect(params.subject, 'report.pdf');
        expect(params.fileNameOverrides, <String>['report.pdf']);
        final XFile file = params.files!.single;
        expect(file.mimeType, 'application/pdf');
        expect(share.fileBytes, <int>[1, 2, 3]);
      }
    });

    test('should isolate IO handoff bytes from a caller mutation', () async {
      final Completer<void> shareStarted = Completer<void>();
      final Completer<void> allowRead = Completer<void>();
      final _RecordingShare share = _RecordingShare(
        ShareResultStatus.success,
        beforeRead: () async {
          shareStarted.complete();
          await allowRead.future;
        },
      );
      final Uint8List source = Uint8List.fromList(<int>[1, 2, 3]);

      final Future<MoodMedicineReportDelivery> deliveryFuture = report_io
          .deliverMoodMedicineIoReportForTesting(
            bytes: source,
            fileName: 'report.pdf',
            mimeType: 'application/pdf',
            share: share.call,
          );
      await shareStarted.future;
      source[0] = 9;
      allowRead.complete();

      final MoodMedicineReportDelivery delivery = await deliveryFuture;

      expect(delivery.status, MoodMedicineReportDeliveryStatus.delivered);
      expect(share.fileBytes, <int>[1, 2, 3]);
    });

    test('should map IO share errors to failed', () async {
      final _RecordingShare share = _RecordingShare(
        ShareResultStatus.success,
        error: StateError('share unavailable'),
      );

      final MoodMedicineReportDelivery delivery = await report_io
          .deliverMoodMedicineIoReportForTesting(
            bytes: Uint8List.fromList(<int>[1, 2, 3]),
            fileName: 'report.pdf',
            mimeType: 'application/pdf',
            share: share.call,
          );

      expect(delivery.status, MoodMedicineReportDeliveryStatus.failed);
    });

    test('should log a sanitized native delivery failure', () async {
      final _CapturingLogger logger = _CapturingLogger();
      await GetIt.instance.reset();
      addTearDown(GetIt.instance.reset);
      GetIt.instance.registerSingleton<IncidentLoggerService>(logger);

      final MoodMedicineReportDelivery delivery = await report_io
          .deliverMoodMedicineIoReportForTesting(
            bytes: Uint8List.fromList(<int>[1, 2, 3]),
            fileName: 'report.pdf',
            mimeType: 'application/pdf',
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
  });
}

final class _RecordingShare {
  _RecordingShare(this._status, {this.error, this.beforeRead});

  final ShareResultStatus _status;
  final Object? error;
  final Future<void> Function()? beforeRead;
  ShareParams? params;
  Uint8List? fileBytes;

  Future<ShareResult> call(ShareParams value) async {
    params = value;
    await beforeRead?.call();
    if (value.files?.isNotEmpty ?? false) {
      final XFile file = value.files!.single;
      fileBytes = Uint8List.fromList(await file.readAsBytes());
    }
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
