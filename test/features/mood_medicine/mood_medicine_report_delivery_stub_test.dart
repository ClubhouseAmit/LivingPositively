import 'dart:typed_data';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mazilon/features/mood_medicine/data/mood_medicine_report_delivery_stub.dart'
    as stub;
import 'package:mazilon/features/mood_medicine/data/mood_medicine_report_delivery_types.dart';
import 'package:mazilon/util/logger_service.dart';

void main() {
  group('deliverMoodMedicineReport', () {
    test('should leave unsupported platform delivery unavailable', () async {
      final MoodMedicineReportDelivery delivery = await stub
          .deliverMoodMedicineReport(
            incidentLoggerService: const _ThrowingLogger(),
            bytes: Uint8List.fromList(<int>[1, 2, 3]),
            fileName: 'report.pdf',
            mimeType: 'application/pdf',
          );

      expect(delivery.status, MoodMedicineReportDeliveryStatus.unavailable);
      expect(delivery.didDeliver, isFalse);
    });
  });
}

final class _ThrowingLogger implements IncidentLoggerService {
  const _ThrowingLogger();

  @override
  Future<void> captureLog(
    dynamic exception, {
    StackTrace? stackTrace,
    dynamic exceptionData,
  }) async {
    throw StateError('known unsupported delivery must not be logged');
  }

  @override
  Future<void> initializeSentry(Widget myApp) async {}
}
