import 'package:flutter/foundation.dart';

/// A completed in-memory report before it is passed to the platform adapter.
///
/// The constructor and [bytes] getter both make a copy. This keeps an export
/// preview, a delayed share handoff, and the renderer isolated from callers
/// that retain and mutate the same [Uint8List].
@immutable
class MoodMedicineBuiltReport {
  MoodMedicineBuiltReport({
    required Uint8List bytes,
    required this.fileName,
    required this.mimeType,
  }) : _bytes = Uint8List.fromList(bytes);

  final Uint8List _bytes;

  /// A defensive copy of the report document/image bytes.
  Uint8List get bytes => Uint8List.fromList(_bytes);

  final String fileName;
  final String mimeType;
}

/// The feature-level outcome of a report delivery attempt.
///
/// Native and web adapters map successful and unavailable handoffs to
/// [delivered]: in the latter case the platform completed the handoff but
/// cannot report the person's chosen action. [dismissed] maps only an explicit
/// cancellation. The unsupported-platform stub returns [unavailable] without
/// a handoff.
enum MoodMedicineReportDeliveryStatus {
  /// The report reached the native share sheet or browser share/download path.
  delivered,

  /// The platform explicitly reported that the person dismissed sharing.
  dismissed,

  /// The current platform has no report delivery adapter and did not hand off.
  unavailable,

  /// A PNG exceeded the feature's safe single-image canvas limit.
  tooLarge,

  /// Rendering, file preparation, or the delivery adapter failed.
  failed,
}

/// Result from a share/download handoff. This is deliberately independent of
/// `share_plus` so UI code does not need to know platform-plugin types.
@immutable
class MoodMedicineReportDelivery {
  const MoodMedicineReportDelivery(this.status, {this.errorMessage});

  final MoodMedicineReportDeliveryStatus status;
  final String? errorMessage;

  /// Whether report bytes were handed to a native or browser delivery path.
  bool get didDeliver => status == MoodMedicineReportDeliveryStatus.delivered;
}

/// Plugin-neutral statuses reported by native and browser share adapters.
enum MoodMedicineShareHandoffStatus {
  /// The platform accepted the handoff and reported success.
  success,

  /// The platform explicitly reported that the person dismissed sharing.
  dismissed,

  /// The platform completed a handoff without a final user-action result.
  unavailable,
}

/// Maps adapter handoff statuses to the feature's stable delivery semantics.
///
/// `unavailable` is intentionally [MoodMedicineReportDeliveryStatus.delivered]
/// here: a platform completed a handoff but cannot determine the final user
/// action, including a browser-download fallback.
MoodMedicineReportDelivery moodMedicineDeliveryForShareHandoffStatus(
  MoodMedicineShareHandoffStatus status,
) {
  return switch (status) {
    MoodMedicineShareHandoffStatus.dismissed =>
      const MoodMedicineReportDelivery(
        MoodMedicineReportDeliveryStatus.dismissed,
      ),
    MoodMedicineShareHandoffStatus.success ||
    MoodMedicineShareHandoffStatus.unavailable =>
      const MoodMedicineReportDelivery(
        MoodMedicineReportDeliveryStatus.delivered,
      ),
  };
}

/// Removes blank optional text before it reaches a platform share sheet.
String? normalizeMoodMedicineShareText(String? value) {
  final String? trimmed = value?.trim();
  return trimmed == null || trimmed.isEmpty ? null : trimmed;
}
