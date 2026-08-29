import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:mazilon/pages/MoodMedicine/mood_medicine_report_delivery_io.dart'
    as report_io;
import 'package:mazilon/pages/MoodMedicine/mood_medicine_report_delivery_stub.dart'
    as stub;
import 'package:mazilon/pages/MoodMedicine/mood_medicine_report_delivery_types.dart';
import 'package:mazilon/pages/MoodMedicine/mood_medicine_report_delivery_web.dart'
    as report_web;
import 'package:share_plus/share_plus.dart';

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
    test('should map a successful share handoff to delivered', () {
      expect(
        moodMedicineDeliveryForShareResult(ShareResultStatus.success).status,
        MoodMedicineReportDeliveryStatus.delivered,
      );
    });

    test('should map an unavailable share result to delivered', () {
      expect(
        moodMedicineDeliveryForShareResult(
          ShareResultStatus.unavailable,
        ).status,
        MoodMedicineReportDeliveryStatus.delivered,
      );
    });

    test('should map an explicit share dismissal to dismissed', () {
      expect(
        moodMedicineDeliveryForShareResult(ShareResultStatus.dismissed).status,
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
      'should exercise IO adapter result mappings and file handoff',
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
          final Directory directory = await Directory.systemTemp.createTemp(
            'mood_medicine_io_delivery_',
          );
          addTearDown(() => directory.delete(recursive: true));
          final _RecordingShare share = _RecordingShare(shareStatus);

          final MoodMedicineReportDelivery delivery = await report_io
              .deliverMoodMedicineIoReportForTesting(
                bytes: Uint8List.fromList(<int>[1, 2, 3]),
                fileName: 'report.pdf',
                mimeType: 'application/pdf',
                shareText: '  Mood report  ',
                temporaryDirectory: () async => directory,
                share: share.call,
              );

          expect(delivery.status, expectedStatus);
          final ShareParams params = share.params!;
          expect(params.text, 'Mood report');
          expect(params.fileNameOverrides, <String>['report.pdf']);
          expect(await params.files!.single.readAsBytes(), <int>[1, 2, 3]);
        }
      },
    );

    test('should map IO preparation and share errors to failed', () async {
      final _RecordingShare share = _RecordingShare(
        ShareResultStatus.success,
        error: StateError('share unavailable'),
      );
      final Directory directory = await Directory.systemTemp.createTemp(
        'mood_medicine_io_failure_',
      );
      addTearDown(() => directory.delete(recursive: true));

      final MoodMedicineReportDelivery shareFailure = await report_io
          .deliverMoodMedicineIoReportForTesting(
            bytes: Uint8List.fromList(<int>[1, 2, 3]),
            fileName: 'report.pdf',
            mimeType: 'application/pdf',
            temporaryDirectory: () async => directory,
            share: share.call,
          );
      final MoodMedicineReportDelivery preparationFailure = await report_io
          .deliverMoodMedicineIoReportForTesting(
            bytes: Uint8List.fromList(<int>[1, 2, 3]),
            fileName: 'report.pdf',
            mimeType: 'application/pdf',
            temporaryDirectory: () => throw StateError('no directory'),
            share: share.call,
          );

      expect(shareFailure.status, MoodMedicineReportDeliveryStatus.failed);
      expect(
        preparationFailure.status,
        MoodMedicineReportDeliveryStatus.failed,
      );
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
