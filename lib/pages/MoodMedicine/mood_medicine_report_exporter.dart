import 'mood_medicine_report_delivery.dart';
import 'mood_medicine_report_failure_logging.dart';
import 'mood_medicine_report_models.dart';
import 'mood_medicine_report_renderer.dart';

export 'mood_medicine_report_delivery.dart'
    show
        MoodMedicineBuiltReport,
        MoodMedicineReportDelivery,
        MoodMedicineReportDeliveryStatus;
export 'mood_medicine_report_models.dart';

/// The report boundary used by the Mood Medicine view model.
///
/// It separates stable report input/state from renderer and platform-delivery
/// variations. [build] is suitable for an in-app preview, while [deliver]
/// keeps sharing on the existing centralized platform path.
abstract interface class MoodMedicineReportExportService {
  /// Builds an immutable PDF or PNG report without invoking platform UI.
  Future<MoodMedicineBuiltReport> build(
    MoodMedicineReportInput input,
    MoodMedicineReportFormat format,
  );

  /// Shares a previously built report through the platform delivery boundary.
  Future<MoodMedicineReportDelivery> deliver(
    MoodMedicineBuiltReport report, {
    String? shareText,
  });
}

/// Feature-local report boundary for Mood Tracker and Personal Medicine.
///
/// It accepts a deliberately simple DTO, so storage and dashboard state stay
/// separate from PDF/PNG rendering and platform sharing.
class MoodMedicineReportExporter implements MoodMedicineReportExportService {
  MoodMedicineReportExporter({
    MoodMedicinePdfReportRenderer? pdfRenderer,
    MoodMedicinePngReportRenderer? pngRenderer,
  }) : _pdfRenderer = pdfRenderer ?? const MoodMedicinePdfReportRenderer(),
       _pngRenderer = pngRenderer ?? const MoodMedicinePngReportRenderer();

  final MoodMedicinePdfReportRenderer _pdfRenderer;
  final MoodMedicinePngReportRenderer _pngRenderer;

  /// Produces report bytes without invoking a platform share or download UI.
  @override
  Future<MoodMedicineBuiltReport> build(
    MoodMedicineReportInput input,
    MoodMedicineReportFormat format,
  ) async {
    try {
      final bytes = switch (format) {
        MoodMedicineReportFormat.pdf => await _pdfRenderer.render(input),
        MoodMedicineReportFormat.png => await _pngRenderer.render(input),
      };
      return MoodMedicineBuiltReport(
        bytes: bytes,
        fileName: input.fileNameFor(format),
        mimeType: format.mimeType,
      );
    } on MoodMedicinePngReportTooLargeException {
      rethrow;
    } catch (error, stackTrace) {
      await logMoodMedicineReportFailure(
        stage: MoodMedicineReportFailureStage.render,
        error: error,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Hands an already-built report to the platform adapter.
  ///
  /// [MoodMedicineBuiltReport.bytes] supplies a defensive copy, and the
  /// delivery boundary makes another copy before passing it to native/web code.
  @override
  Future<MoodMedicineReportDelivery> deliver(
    MoodMedicineBuiltReport report, {
    String? shareText,
  }) async {
    try {
      return await deliverMoodMedicineReport(
        bytes: report.bytes,
        fileName: report.fileName,
        mimeType: report.mimeType,
        shareText: shareText,
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

  /// Builds and hands a report to the platform adapter. No [BuildContext] is
  /// required; the caller can decide how to surface the returned status.
  Future<MoodMedicineReportDelivery> export(
    MoodMedicineReportInput input,
    MoodMedicineReportFormat format, {
    String? shareText,
  }) async {
    try {
      final report = await build(input, format);
      return await deliver(report, shareText: shareText);
    } on MoodMedicinePngReportTooLargeException {
      return const MoodMedicineReportDelivery(
        MoodMedicineReportDeliveryStatus.tooLarge,
      );
    } catch (_) {
      return const MoodMedicineReportDelivery(
        MoodMedicineReportDeliveryStatus.failed,
      );
    }
  }
}
