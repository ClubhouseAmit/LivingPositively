import 'package:flutter/foundation.dart';
import 'package:share_plus/share_plus.dart';

import 'mood_medicine_report_failure_logging.dart';
import 'mood_medicine_report_delivery_types.dart';

/// Opens the browser share handoff with its file-download fallback enabled.
///
/// Successful and unavailable `share_plus` results both mean the browser took
/// the report bytes. An explicit dismissal remains [dismissed], while adapter
/// errors become [failed] without throwing to the feature UI.
Future<MoodMedicineReportDelivery> deliverMoodMedicineReport({
  required Uint8List bytes,
  required String fileName,
  required String mimeType,
  String? shareText,
}) {
  return _deliverMoodMedicineWebReport(
    bytes: bytes,
    fileName: fileName,
    mimeType: mimeType,
    shareText: shareText,
    share: SharePlus.instance.share,
  );
}

/// Exercises the browser adapter with an injected share boundary.
///
/// This is test-only; production enables the `share_plus` download fallback
/// and maps an unavailable result to a completed feature handoff.
@visibleForTesting
Future<MoodMedicineReportDelivery> deliverMoodMedicineWebReportForTesting({
  required Uint8List bytes,
  required String fileName,
  required String mimeType,
  required Future<ShareResult> Function(ShareParams params) share,
  String? shareText,
}) {
  return _deliverMoodMedicineWebReport(
    bytes: bytes,
    fileName: fileName,
    mimeType: mimeType,
    shareText: shareText,
    share: share,
  );
}

Future<MoodMedicineReportDelivery> _deliverMoodMedicineWebReport({
  required Uint8List bytes,
  required String fileName,
  required String mimeType,
  required Future<ShareResult> Function(ShareParams params) share,
  String? shareText,
}) async {
  try {
    final Uint8List deliveryBytes = Uint8List.fromList(bytes);
    final ShareResult result = await share(
      ShareParams(
        files: <XFile>[
          XFile.fromData(deliveryBytes, name: fileName, mimeType: mimeType),
        ],
        fileNameOverrides: <String>[fileName],
        text: normalizeMoodMedicineShareText(shareText),
        title: fileName,
        subject: fileName,
        downloadFallbackEnabled: true,
        mailToFallbackEnabled: false,
      ),
    );
    return moodMedicineDeliveryForShareHandoffStatus(
      _handoffStatusForShareResult(result.status),
    );
  } catch (error, stackTrace) {
    await logMoodMedicineReportFailure(
      stage: MoodMedicineReportFailureStage.delivery,
      error: error,
      stackTrace: stackTrace,
    );
    return const MoodMedicineReportDelivery(
      MoodMedicineReportDeliveryStatus.failed,
    );
  }
}

MoodMedicineShareHandoffStatus _handoffStatusForShareResult(
  ShareResultStatus status,
) {
  return switch (status) {
    ShareResultStatus.success => MoodMedicineShareHandoffStatus.success,
    ShareResultStatus.dismissed => MoodMedicineShareHandoffStatus.dismissed,
    ShareResultStatus.unavailable => MoodMedicineShareHandoffStatus.unavailable,
  };
}
