import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';

import 'mood_medicine_report_delivery_types.dart';
import 'mood_medicine_report_models.dart';

/// Displays a generated Mood Medicine report without invoking print or share.
///
/// Sharing deliberately remains an explicit action in the export sheet. PDF
/// preview uses a fixed A4 page with all `printing` actions disabled, while PNG
/// preview remains a zoomable image because it is a single report canvas.
class MoodMedicineReportPreviewPage extends StatelessWidget {
  const MoodMedicineReportPreviewPage({
    super.key,
    required this.report,
    required this.format,
    required this.title,
    this.pngPrintGuidance,
  });

  /// The immutable report selected for viewing.
  final MoodMedicineBuiltReport report;

  /// Determines whether to render a PDF page preview or a zoomable image.
  final MoodMedicineReportFormat format;

  /// Localized app-bar and semantics label supplied by the presentation layer.
  final String title;

  /// Optional localized guidance recommending PDF for reliable long printing.
  final String? pngPrintGuidance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: switch (format) {
        MoodMedicineReportFormat.pdf => _PdfReportPreview(
          key: const Key('moodMedicinePdfPreview'),
          report: report,
        ),
        MoodMedicineReportFormat.png => _PngReportPreview(
          key: const Key('moodMedicinePngPreview'),
          report: report,
          semanticLabel: title,
          printGuidance: pngPrintGuidance,
        ),
      },
    );
  }
}

class _PdfReportPreview extends StatelessWidget {
  const _PdfReportPreview({super.key, required this.report});

  final MoodMedicineBuiltReport report;

  @override
  Widget build(BuildContext context) {
    return PdfPreview(
      build: (_) async => report.bytes,
      initialPageFormat: PdfPageFormat.a4,
      allowPrinting: false,
      allowSharing: false,
      canChangePageFormat: false,
      canChangeOrientation: false,
      canDebug: false,
      useActions: false,
      dynamicLayout: false,
    );
  }
}

class _PngReportPreview extends StatelessWidget {
  const _PngReportPreview({
    super.key,
    required this.report,
    required this.semanticLabel,
    this.printGuidance,
  });

  final MoodMedicineBuiltReport report;
  final String semanticLabel;
  final String? printGuidance;

  @override
  Widget build(BuildContext context) {
    final String? guidance = printGuidance?.trim();
    return Column(
      children: <Widget>[
        Expanded(
          child: LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              return InteractiveViewer(
                minScale: 0.5,
                maxScale: 4,
                child: SizedBox(
                  width: constraints.maxWidth,
                  height: constraints.maxHeight,
                  child: Semantics(
                    image: true,
                    label: semanticLabel,
                    child: Image.memory(
                      report.bytes,
                      fit: BoxFit.contain,
                      filterQuality: FilterQuality.high,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        if (guidance != null && guidance.isNotEmpty)
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              child: Text(
                guidance,
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }
}
