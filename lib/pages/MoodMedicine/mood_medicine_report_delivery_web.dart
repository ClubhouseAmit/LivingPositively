import 'dart:typed_data';

import 'package:share_plus/share_plus.dart';

import 'mood_medicine_report_delivery_types.dart';

Future<MoodMedicineReportDelivery> deliverMoodMedicineReport({
  required Uint8List bytes,
  required String fileName,
  required String mimeType,
  String? shareText,
}) async {
  try {
    final result = await SharePlus.instance.share(
      ShareParams(
        files: <XFile>[
          XFile.fromData(bytes, name: fileName, mimeType: mimeType),
        ],
        fileNameOverrides: <String>[fileName],
        text: _nonEmpty(shareText),
        title: fileName,
        subject: fileName,
        downloadFallbackEnabled: true,
        mailToFallbackEnabled: false,
      ),
    );
    return switch (result.status) {
      ShareResultStatus.dismissed => const MoodMedicineReportDelivery(
        MoodMedicineReportDeliveryStatus.dismissed,
      ),
      // Browsers do not report the selected action. `share_plus` also returns
      // unavailable after its successful download fallback, so both outcomes
      // mean the report was handed to the browser.
      ShareResultStatus.success ||
      ShareResultStatus.unavailable => const MoodMedicineReportDelivery(
        MoodMedicineReportDeliveryStatus.delivered,
      ),
    };
  } catch (_) {
    return const MoodMedicineReportDelivery(
      MoodMedicineReportDeliveryStatus.failed,
    );
  }
}

String? _nonEmpty(String? value) {
  final trimmed = value?.trim();
  return trimmed == null || trimmed.isEmpty ? null : trimmed;
}
