import 'dart:typed_data';

import 'mood_medicine_report_delivery_stub.dart'
    if (dart.library.io) 'mood_medicine_report_delivery_io.dart'
    if (dart.library.js_interop) 'mood_medicine_report_delivery_web.dart'
    as platform;
import 'mood_medicine_report_delivery_types.dart';

export 'mood_medicine_report_delivery_types.dart';

/// Hands a generated report to the appropriate platform mechanism.
///
/// Native platforms share a temporary file. On web, `share_plus` invokes the
/// browser Web Share API when available and performs its file-download fallback
/// when it is not. The adapter receives its own byte copy so a caller cannot
/// mutate a report while a platform handoff is being prepared.
Future<MoodMedicineReportDelivery> deliverMoodMedicineReport({
  required Uint8List bytes,
  required String fileName,
  required String mimeType,
  String? shareText,
}) {
  return platform.deliverMoodMedicineReport(
    bytes: Uint8List.fromList(bytes),
    fileName: fileName,
    mimeType: mimeType,
    shareText: shareText,
  );
}
