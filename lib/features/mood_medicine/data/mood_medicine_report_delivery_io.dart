import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:share_plus/share_plus.dart';

import 'mood_medicine_report_delivery_shared.dart';
import 'mood_medicine_report_delivery_types.dart';

/// Opens the native share handoff from an in-memory report.
///
/// Successful and unavailable `share_plus` results both mean bytes reached a
/// platform handoff; an explicit dismissal remains [dismissed], while file or
/// plugin errors become [failed] without throwing to the feature UI. The
/// plugin owns any platform cache file it needs to materialize from the bytes.
/// Linux has no `share_plus` file-report handoff, so it returns [unavailable]
/// without invoking the plugin.
Future<MoodMedicineReportDelivery> deliverMoodMedicineReport({
  required Uint8List bytes,
  required String fileName,
  required String mimeType,
  String? shareText,
}) {
  if (Platform.isLinux) {
    return Future<MoodMedicineReportDelivery>.value(
      const MoodMedicineReportDelivery(
        MoodMedicineReportDeliveryStatus.unavailable,
      ),
    );
  }
  return _deliverMoodMedicineIoReport(
    bytes: bytes,
    fileName: fileName,
    mimeType: mimeType,
    shareText: shareText,
    share: SharePlus.instance.share,
  );
}

/// Exercises the native adapter with an injected share boundary.
///
/// This is test-only; production provides byte-backed files to `share_plus`
/// and maps a successful or unavailable result to a completed feature handoff.
@visibleForTesting
Future<MoodMedicineReportDelivery> deliverMoodMedicineIoReportForTesting({
  required Uint8List bytes,
  required String fileName,
  required String mimeType,
  required Future<ShareResult> Function(ShareParams params) share,
  String? shareText,
}) {
  return _deliverMoodMedicineIoReport(
    bytes: bytes,
    fileName: fileName,
    mimeType: mimeType,
    shareText: shareText,
    share: share,
  );
}

Future<MoodMedicineReportDelivery> _deliverMoodMedicineIoReport({
  required Uint8List bytes,
  required String fileName,
  required String mimeType,
  required Future<ShareResult> Function(ShareParams params) share,
  String? shareText,
}) {
  return deliverMoodMedicineReportThroughShare(
    bytes: bytes,
    fileName: fileName,
    mimeType: mimeType,
    shareText: shareText,
    share: share,
    downloadFallbackEnabled: true,
    mailToFallbackEnabled: true,
  );
}
