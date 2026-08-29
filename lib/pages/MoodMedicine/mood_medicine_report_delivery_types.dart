import 'package:flutter/foundation.dart';

/// A completed in-memory report before it is passed to the platform adapter.
@immutable
class MoodMedicineBuiltReport {
  const MoodMedicineBuiltReport({
    required this.bytes,
    required this.fileName,
    required this.mimeType,
  });

  final Uint8List bytes;
  final String fileName;
  final String mimeType;
}

enum MoodMedicineReportDeliveryStatus {
  delivered,
  dismissed,
  unavailable,
  tooLarge,
  failed,
}

/// Result from a share/download handoff. This is deliberately independent of
/// `share_plus` so UI code does not need to know platform-plugin types.
@immutable
class MoodMedicineReportDelivery {
  const MoodMedicineReportDelivery(this.status, {this.errorMessage});

  final MoodMedicineReportDeliveryStatus status;
  final String? errorMessage;

  bool get didDeliver => status == MoodMedicineReportDeliveryStatus.delivered;
}
