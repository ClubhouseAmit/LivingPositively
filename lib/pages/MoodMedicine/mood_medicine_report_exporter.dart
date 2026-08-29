import 'mood_medicine_report_delivery.dart';
import 'mood_medicine_report_models.dart';
import 'mood_medicine_report_renderer.dart';

export 'mood_medicine_report_delivery.dart'
    show
        MoodMedicineBuiltReport,
        MoodMedicineReportDelivery,
        MoodMedicineReportDeliveryStatus;
export 'mood_medicine_report_models.dart';

/// Feature-local report boundary for Mood Tracker and Personal Medicine.
///
/// It accepts a deliberately simple DTO, so storage and dashboard state stay
/// separate from PDF/PNG rendering and platform sharing.
class MoodMedicineReportExporter {
  MoodMedicineReportExporter({
    MoodMedicinePdfReportRenderer? pdfRenderer,
    MoodMedicinePngReportRenderer? pngRenderer,
  }) : _pdfRenderer = pdfRenderer ?? const MoodMedicinePdfReportRenderer(),
       _pngRenderer = pngRenderer ?? const MoodMedicinePngReportRenderer();

  final MoodMedicinePdfReportRenderer _pdfRenderer;
  final MoodMedicinePngReportRenderer _pngRenderer;

  /// Produces report bytes without invoking a platform share or download UI.
  Future<MoodMedicineBuiltReport> build(
    MoodMedicineReportInput input,
    MoodMedicineReportFormat format,
  ) async {
    final bytes = switch (format) {
      MoodMedicineReportFormat.pdf => await _pdfRenderer.render(input),
      MoodMedicineReportFormat.png => await _pngRenderer.render(input),
    };
    return MoodMedicineBuiltReport(
      bytes: bytes,
      fileName: input.fileNameFor(format),
      mimeType: format.mimeType,
    );
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
      return await deliverMoodMedicineReport(
        bytes: report.bytes,
        fileName: report.fileName,
        mimeType: report.mimeType,
        shareText: shareText,
      );
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
