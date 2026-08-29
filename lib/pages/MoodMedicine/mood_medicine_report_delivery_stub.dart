import 'dart:typed_data';

import 'mood_medicine_report_delivery_types.dart';

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
