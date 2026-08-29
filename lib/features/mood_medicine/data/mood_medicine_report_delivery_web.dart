import 'package:flutter/foundation.dart';
import 'package:mazilon/util/logger_service.dart';
import 'package:share_plus/share_plus.dart';

import 'mood_medicine_report_delivery_shared.dart';
import 'mood_medicine_report_delivery_types.dart';

/// Opens the browser share handoff with its file-download fallback enabled.
///
/// Successful and unavailable `share_plus` results both mean the browser took
/// the report bytes. An explicit dismissal remains [dismissed], while adapter
/// errors become [failed] without throwing to the feature UI.
Future<MoodMedicineReportDelivery> deliverMoodMedicineReport({
  required IncidentLoggerService incidentLoggerService,
  required Uint8List bytes,
  required String fileName,
  required String mimeType,
  String? shareText,
}) {
  return _deliverMoodMedicineWebReport(
    incidentLoggerService: incidentLoggerService,
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
  required IncidentLoggerService incidentLoggerService,
  required Uint8List bytes,
  required String fileName,
  required String mimeType,
  required Future<ShareResult> Function(ShareParams params) share,
  String? shareText,
}) {
  return _deliverMoodMedicineWebReport(
    incidentLoggerService: incidentLoggerService,
    bytes: bytes,
    fileName: fileName,
    mimeType: mimeType,
    shareText: shareText,
    share: share,
  );
}

Future<MoodMedicineReportDelivery> _deliverMoodMedicineWebReport({
  required IncidentLoggerService incidentLoggerService,
  required Uint8List bytes,
  required String fileName,
  required String mimeType,
  required Future<ShareResult> Function(ShareParams params) share,
  String? shareText,
}) {
  return deliverMoodMedicineReportThroughShare(
    incidentLoggerService: incidentLoggerService,
    bytes: bytes,
    fileName: fileName,
    mimeType: mimeType,
    shareText: shareText,
    share: share,
    downloadFallbackEnabled: true,
    mailToFallbackEnabled: false,
  );
}
