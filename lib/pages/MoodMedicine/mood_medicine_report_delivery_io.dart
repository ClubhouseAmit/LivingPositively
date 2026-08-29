import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import 'mood_medicine_report_delivery_types.dart';

Future<MoodMedicineReportDelivery> deliverMoodMedicineReport({
  required Uint8List bytes,
  required String fileName,
  required String mimeType,
  String? shareText,
}) async {
  try {
    final directory = await getTemporaryDirectory();
    final file = File('${directory.path}${Platform.pathSeparator}$fileName');
    await file.writeAsBytes(bytes, flush: true);

    final result = await SharePlus.instance.share(
      ShareParams(
        files: <XFile>[XFile(file.path, mimeType: mimeType)],
        fileNameOverrides: <String>[fileName],
        text: _nonEmpty(shareText),
        title: fileName,
        subject: fileName,
      ),
    );
    return switch (result.status) {
      ShareResultStatus.dismissed => const MoodMedicineReportDelivery(
        MoodMedicineReportDeliveryStatus.dismissed,
      ),
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
