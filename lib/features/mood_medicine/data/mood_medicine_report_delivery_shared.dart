import 'dart:typed_data';

import 'package:mazilon/util/logger_service.dart';
import 'package:share_plus/share_plus.dart';

import 'mood_medicine_report_delivery_types.dart';
import 'mood_medicine_report_failure_logging.dart';

/// Feature-internal implementation shared by the native and web adapters.
///
/// This remains unexported from the feature boundary. Adapters vary only in
/// their platform availability and fallback policy; byte ownership, plugin
/// parameters, status mapping, and privacy-safe error handling are identical.
Future<MoodMedicineReportDelivery> deliverMoodMedicineReportThroughShare({
  required IncidentLoggerService incidentLoggerService,
  required Uint8List bytes,
  required String fileName,
  required String mimeType,
  required Future<ShareResult> Function(ShareParams params) share,
  required bool downloadFallbackEnabled,
  required bool mailToFallbackEnabled,
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
        downloadFallbackEnabled: downloadFallbackEnabled,
        mailToFallbackEnabled: mailToFallbackEnabled,
      ),
    );
    return moodMedicineDeliveryForShareHandoffStatus(
      _handoffStatusForShareResult(result.status),
    );
  } catch (error, stackTrace) {
    await logMoodMedicineReportFailure(
      incidentLoggerService: incidentLoggerService,
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
