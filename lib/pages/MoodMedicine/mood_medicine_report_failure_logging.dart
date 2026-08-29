import 'package:get_it/get_it.dart';
import 'package:mazilon/util/logger_service.dart';

/// The bounded report stage that failed without exposing report contents.
enum MoodMedicineReportFailureStage { render, delivery, deliveryCleanup }

/// Records a privacy-safe report failure through the existing incident logger.
///
/// Report contents can include notes and source URLs, so this deliberately
/// sends only the feature stage, the original error's runtime type, and the
/// stack trace. Logging is best effort and never changes a report outcome.
Future<void> logMoodMedicineReportFailure({
  required MoodMedicineReportFailureStage stage,
  required Object error,
  required StackTrace stackTrace,
}) async {
  final GetIt locator = GetIt.instance;
  if (!locator.isRegistered<IncidentLoggerService>()) {
    return;
  }
  try {
    await locator<IncidentLoggerService>().captureLog(
      _MoodMedicineReportFailureLog(stage, error.runtimeType),
      stackTrace: stackTrace,
    );
  } catch (_) {
    // Incident telemetry must not hide the feature's local recovery UI.
  }
}

/// Sanitized incident payload that intentionally has no report data.
final class _MoodMedicineReportFailureLog implements Exception {
  const _MoodMedicineReportFailureLog(this.stage, this.errorType);

  final MoodMedicineReportFailureStage stage;
  final Type errorType;

  @override
  String toString() =>
      'MoodMedicineReportFailure(stage: ${stage.name}, errorType: $errorType)';
}
