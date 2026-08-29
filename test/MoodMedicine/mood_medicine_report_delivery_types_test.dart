import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:mazilon/pages/MoodMedicine/mood_medicine_report_delivery_types.dart';

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
  });
}
