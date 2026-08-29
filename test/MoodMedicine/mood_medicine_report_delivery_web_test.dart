import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:mazilon/pages/MoodMedicine/mood_medicine_report_delivery_types.dart';
import 'package:mazilon/pages/MoodMedicine/mood_medicine_report_delivery_web.dart'
    as report_web;
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
