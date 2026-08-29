import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import 'mood_medicine_report_delivery_types.dart';

/// Writes a private temporary file and opens the native share handoff.
///
/// Successful and unavailable `share_plus` results both mean bytes reached a
/// platform handoff; an explicit dismissal remains [dismissed], while file or
/// plugin errors become [failed] without throwing to the feature UI.
Future<MoodMedicineReportDelivery> deliverMoodMedicineReport({
  required Uint8List bytes,
  required String fileName,
  required String mimeType,
  String? shareText,
}) {
  return _deliverMoodMedicineIoReport(
    bytes: bytes,
    fileName: fileName,
    mimeType: mimeType,
    shareText: shareText,
    temporaryDirectory: getTemporaryDirectory,
    share: SharePlus.instance.share,
  );
}

/// Exercises the native adapter with an injected directory and share boundary.
///
/// This is test-only; production always writes to the platform temporary
/// directory and maps a successful or unavailable `share_plus` result to a
/// completed feature handoff.
@visibleForTesting
Future<MoodMedicineReportDelivery> deliverMoodMedicineIoReportForTesting({
  required Uint8List bytes,
  required String fileName,
  required String mimeType,
  required Future<Directory> Function() temporaryDirectory,
  required Future<ShareResult> Function(ShareParams params) share,
  String? shareText,
}) {
  return _deliverMoodMedicineIoReport(
    bytes: bytes,
    fileName: fileName,
    mimeType: mimeType,
    shareText: shareText,
    temporaryDirectory: temporaryDirectory,
    share: share,
  );
}

Future<MoodMedicineReportDelivery> _deliverMoodMedicineIoReport({
  required Uint8List bytes,
  required String fileName,
  required String mimeType,
  required Future<Directory> Function() temporaryDirectory,
  required Future<ShareResult> Function(ShareParams params) share,
  String? shareText,
}) async {
  try {
    final Uint8List deliveryBytes = Uint8List.fromList(bytes);
    final Directory directory = await temporaryDirectory();
    final file = File('${directory.path}${Platform.pathSeparator}$fileName');
    await file.writeAsBytes(deliveryBytes, flush: true);

    final ShareResult result = await share(
      ShareParams(
        files: <XFile>[XFile(file.path, mimeType: mimeType)],
        fileNameOverrides: <String>[fileName],
        text: normalizeMoodMedicineShareText(shareText),
        title: fileName,
        subject: fileName,
      ),
    );
    return moodMedicineDeliveryForShareResult(result.status);
  } catch (_) {
    return const MoodMedicineReportDelivery(
      MoodMedicineReportDeliveryStatus.failed,
    );
  }
}
