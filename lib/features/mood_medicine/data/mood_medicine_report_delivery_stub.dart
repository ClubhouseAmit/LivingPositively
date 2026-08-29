import 'dart:typed_data';

import 'mood_medicine_report_delivery_types.dart';

/// Completes without a handoff when no platform adapter is available.
///
/// The feature-level [MoodMedicineReportDeliveryStatus.unavailable] result is
/// intentional and non-throwing, so callers can distinguish it from a failed
/// native or web delivery attempt.
Future<MoodMedicineReportDelivery> deliverMoodMedicineReport({
  required Uint8List bytes,
  required String fileName,
  required String mimeType,
  String? shareText,
}) async {
  return const MoodMedicineReportDelivery(
    MoodMedicineReportDeliveryStatus.unavailable,
  );
}
