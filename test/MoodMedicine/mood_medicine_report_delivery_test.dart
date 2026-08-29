import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mazilon/pages/MoodMedicine/mood_medicine_report_delivery_io.dart'
    as report_io;
import 'package:mazilon/pages/MoodMedicine/mood_medicine_report_delivery_stub.dart'
    as stub;
import 'package:mazilon/pages/MoodMedicine/mood_medicine_report_delivery_types.dart';
import 'package:mazilon/pages/MoodMedicine/mood_medicine_report_delivery_web.dart'
    as report_web;
import 'package:share_plus/share_plus.dart';
import 'package:mazilon/util/logger_service.dart';

void main() {
  group('MoodMedicineBuiltReport', () {
    test('should retain immutable bytes across report boundaries', () {
      final Uint8List source = Uint8List.fromList(<int>[1, 2, 3]);
      final MoodMedicineBuiltReport report = MoodMedicineBuiltReport(
        bytes: source,
        fileName: 'report.pdf',
        mimeType: 'application/pdf',
      );

      source[0] = 9;
      final Uint8List firstRead = report.bytes..[1] = 8;

      expect(firstRead, <int>[1, 8, 3]);
      expect(report.bytes, <int>[1, 2, 3]);
    });
  });

  group('MoodMedicineReportDelivery', () {
    test('should map a successful neutral handoff to delivered', () {
      expect(
        moodMedicineDeliveryForShareHandoffStatus(
          MoodMedicineShareHandoffStatus.success,
        ).status,
        MoodMedicineReportDeliveryStatus.delivered,
      );
    });

    test('should map an unavailable neutral handoff to delivered', () {
      expect(
        moodMedicineDeliveryForShareHandoffStatus(
          MoodMedicineShareHandoffStatus.unavailable,
        ).status,
        MoodMedicineReportDeliveryStatus.delivered,
      );
    });

    test('should map an explicit neutral dismissal to dismissed', () {
      expect(
        moodMedicineDeliveryForShareHandoffStatus(
          MoodMedicineShareHandoffStatus.dismissed,
        ).status,
        MoodMedicineReportDeliveryStatus.dismissed,
      );
    });

    test('should discard blank optional share text', () {
      expect(normalizeMoodMedicineShareText('  '), isNull);
      expect(normalizeMoodMedicineShareText(' Report '), 'Report');
    });

    test('should leave unsupported platform delivery unavailable', () async {
      final MoodMedicineReportDelivery delivery = await stub
          .deliverMoodMedicineReport(
            bytes: Uint8List.fromList(<int>[1, 2, 3]),
            fileName: 'report.pdf',
            mimeType: 'application/pdf',
          );

      expect(delivery.status, MoodMedicineReportDeliveryStatus.unavailable);
      expect(delivery.didDeliver, isFalse);
    });

    test(
      'should exercise IO adapter result mappings and byte-backed handoff',
      () async {
        final List<
          (
            ShareResultStatus shareStatus,
            MoodMedicineReportDeliveryStatus expectedStatus,
          )
        >
        cases = <(ShareResultStatus, MoodMedicineReportDeliveryStatus)>[
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
          expect(params.fileNameOverrides, <String>['report.pdf']);
          final XFile file = params.files!.single;
          expect(file.mimeType, 'application/pdf');
          expect(share.fileBytes, <int>[1, 2, 3]);
        }
      },
    );

    test(
      'should keep IO handoff bytes isolated from a caller mutation',
      () async {
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
      },
    );

    test('should map IO share errors to failed', () async {
      final _RecordingShare share = _RecordingShare(
        ShareResultStatus.success,
        error: StateError('share unavailable'),
      );

      final MoodMedicineReportDelivery shareFailure = await report_io
          .deliverMoodMedicineIoReportForTesting(
            bytes: Uint8List.fromList(<int>[1, 2, 3]),
            fileName: 'report.pdf',
            mimeType: 'application/pdf',
            share: share.call,
          );

      expect(shareFailure.status, MoodMedicineReportDeliveryStatus.failed);
    });

    test(
      'should exercise web adapter result mappings and fallback options',
      () async {
        final List<
          (
            ShareResultStatus shareStatus,
            MoodMedicineReportDeliveryStatus expectedStatus,
          )
        >
        cases = <(ShareResultStatus, MoodMedicineReportDeliveryStatus)>[
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
                bytes: Uint8List.fromList(<int>[4, 5, 6]),
                fileName: 'report.png',
                mimeType: 'image/png',
                shareText: '  Mood report  ',
                share: share.call,
              );

          expect(delivery.status, expectedStatus);
          final ShareParams params = share.params!;
          expect(params.text, 'Mood report');
          expect(params.fileNameOverrides, <String>['report.png']);
          expect(params.downloadFallbackEnabled, isTrue);
          expect(params.mailToFallbackEnabled, isFalse);
          expect(await params.files!.single.readAsBytes(), <int>[4, 5, 6]);
        }
      },
    );

    test('should map web share errors to failed', () async {
      final _RecordingShare share = _RecordingShare(
        ShareResultStatus.success,
        error: StateError('browser unavailable'),
      );

      final MoodMedicineReportDelivery delivery = await report_web
          .deliverMoodMedicineWebReportForTesting(
            bytes: Uint8List.fromList(<int>[4, 5, 6]),
            fileName: 'report.png',
            mimeType: 'image/png',
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
