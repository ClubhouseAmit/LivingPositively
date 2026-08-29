import 'dart:ui' as ui;

import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'mood_medicine_report_models.dart';

/// Builds an accessible, multi-page PDF from a renderer-agnostic report DTO.
class MoodMedicinePdfReportRenderer {
  const MoodMedicinePdfReportRenderer({
    this.fontAsset = 'assets/fonts/CALIBRI.TTF',
  });

  final String fontAsset;

  Future<Uint8List> render(MoodMedicineReportInput input) async {
    final fontData = await rootBundle.load(fontAsset);
    final font = pw.Font.ttf(fontData.buffer.asByteData());
    final textDirection = input.isRtl
        ? pw.TextDirection.rtl
        : pw.TextDirection.ltr;
    final alignment = input.isRtl
        ? pw.Alignment.centerRight
        : pw.Alignment.centerLeft;
    final textAlign = input.isRtl ? pw.TextAlign.right : pw.TextAlign.left;
    final sections = input.buildSections();
    final nonSourceSections = sections
        .where((section) => section.heading != input.labels.sourcesLabel)
        .toList(growable: false);

    final document = pw.Document();
    document.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(36),
        build: (_) => <pw.Widget>[
          pw.Directionality(
            textDirection: textDirection,
            child: pw.Column(
              crossAxisAlignment: input.isRtl
                  ? pw.CrossAxisAlignment.end
                  : pw.CrossAxisAlignment.start,
              children: <pw.Widget>[
                pw.Align(
                  alignment: alignment,
                  child: pw.Text(
                    input.title,
                    style: pw.TextStyle(font: font, fontSize: 24),
                    textAlign: textAlign,
                  ),
                ),
                pw.SizedBox(height: 8),
                pw.Align(
                  alignment: alignment,
                  child: pw.Text(
                    input.dateRangeLabel,
                    style: pw.TextStyle(font: font, fontSize: 12),
                    textAlign: textAlign,
                  ),
                ),
                pw.SizedBox(height: 20),
                for (final section in nonSourceSections)
                  _buildPdfSection(
                    section: section,
                    font: font,
                    alignment: alignment,
                    textAlign: textAlign,
                  ),
                if (input.sources.isNotEmpty)
                  _buildPdfSources(
                    input: input,
                    font: font,
                    alignment: alignment,
                    textAlign: textAlign,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
    return document.save();
  }

  pw.Widget _buildPdfSection({
    required MoodMedicineReportSection section,
    required pw.Font font,
    required pw.Alignment alignment,
    required pw.TextAlign textAlign,
  }) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 16),
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: PdfColor.fromInt(0xfff7f4ee),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: <pw.Widget>[
          pw.Align(
            alignment: alignment,
            child: pw.Text(
              section.heading,
              style: pw.TextStyle(font: font, fontSize: 16),
              textAlign: textAlign,
            ),
          ),
          pw.SizedBox(height: 6),
          for (final line in section.lines)
            pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 4),
              child: pw.Text(
                line,
                style: pw.TextStyle(font: font, fontSize: 11),
                textAlign: textAlign,
              ),
            ),
        ],
      ),
    );
  }

  pw.Widget _buildPdfSources({
    required MoodMedicineReportInput input,
    required pw.Font font,
    required pw.Alignment alignment,
    required pw.TextAlign textAlign,
  }) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 16),
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: PdfColor.fromInt(0xfff7f4ee),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: <pw.Widget>[
          pw.Align(
            alignment: alignment,
            child: pw.Text(
              input.labels.sourcesLabel,
              style: pw.TextStyle(font: font, fontSize: 16),
              textAlign: textAlign,
            ),
          ),
          pw.SizedBox(height: 6),
          for (final source in input.sources)
            pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 8),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                children: <pw.Widget>[
                  pw.Text(
                    source.title,
                    style: pw.TextStyle(font: font, fontSize: 11),
                    textAlign: textAlign,
                  ),
                  if (source.description?.trim().isNotEmpty ?? false)
                    pw.Text(
                      source.description!.trim(),
                      style: pw.TextStyle(font: font, fontSize: 10),
                      textAlign: textAlign,
                    ),
                  pw.Directionality(
                    textDirection: pw.TextDirection.ltr,
                    child: _buildSourceUrl(source, font),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  pw.Widget _buildSourceUrl(MoodMedicineReportSource source, pw.Font font) {
    final urlText = source.url.toString();
    final url = pw.Text(
      urlText,
      style: pw.TextStyle(font: font, fontSize: 9, color: PdfColors.blue),
      textAlign: pw.TextAlign.left,
    );
    if (!source.hasSafeHttpsUrl) {
      return url;
    }
    return pw.UrlLink(destination: urlText, child: url);
  }
}

/// Renders the same report content as a portable PNG without relying on a
/// screenshot of the dashboard widget tree.
class MoodMedicinePngReportRenderer {
  const MoodMedicinePngReportRenderer({
    this.width = 1200,
    this.horizontalPadding = 60,
    this.maxImageHeight = 16000,
  }) : assert(width > 0),
       assert(horizontalPadding >= 0),
       assert(width > horizontalPadding * 2),
       assert(maxImageHeight > 0);

  final double width;
  final double horizontalPadding;
  final int maxImageHeight;

  Future<Uint8List> render(MoodMedicineReportInput input) async {
    final textWidth = width - (horizontalPadding * 2);
    final lines = _buildLines(input);
    final paragraphs = <_PngParagraph>[
      for (final line in lines)
        _PngParagraph(
          _paragraphFor(
            line: line,
            textWidth: textWidth,
            textDirection: input.textDirection,
          ),
          line.bottomSpacing,
        ),
    ];
    final contentHeight = paragraphs.fold<double>(
      horizontalPadding,
      (height, paragraph) =>
          height + paragraph.paragraph.height + paragraph.bottomSpacing,
    );
    final logicalImageHeight = contentHeight < 420 ? 420.0 : contentHeight;
    if (logicalImageHeight > maxImageHeight) {
      throw MoodMedicinePngReportTooLargeException(maxImageHeight);
    }

    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);
    canvas.drawRect(
      ui.Rect.fromLTWH(0, 0, width, logicalImageHeight),
      ui.Paint()..color = const ui.Color(0xfffdfbf7),
    );

    var y = horizontalPadding;
    for (final paragraph in paragraphs) {
      canvas.drawParagraph(
        paragraph.paragraph,
        ui.Offset(horizontalPadding, y),
      );
      y += paragraph.paragraph.height + paragraph.bottomSpacing;
    }

    final picture = recorder.endRecording();
    final image = await picture.toImage(
      width.ceil(),
      logicalImageHeight.ceil(),
    );
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    picture.dispose();
    if (byteData == null) {
      throw StateError('Could not encode the mood medicine PNG report.');
    }
    return byteData.buffer.asUint8List();
  }

  List<_PngLine> _buildLines(MoodMedicineReportInput input) {
    return <_PngLine>[
      _PngLine(
        input.title,
        fontSize: 32,
        color: const ui.Color(0xff352c22),
        bottomSpacing: 8,
        isHeading: true,
      ),
      _PngLine(
        input.dateRangeLabel,
        fontSize: 17,
        color: const ui.Color(0xff625a50),
        bottomSpacing: 28,
      ),
      for (final section in input.buildSections()) ...<_PngLine>[
        _PngLine(
          section.heading,
          fontSize: 22,
          color: const ui.Color(0xff5d4531),
          bottomSpacing: 8,
          isHeading: true,
        ),
        for (final line in section.lines)
          _PngLine(
            line,
            fontSize: 16,
            color: const ui.Color(0xff352c22),
            bottomSpacing: 8,
          ),
        _PngLine('', fontSize: 1, bottomSpacing: 12),
      ],
    ];
  }

  ui.Paragraph _paragraphFor({
    required _PngLine line,
    required double textWidth,
    required ui.TextDirection textDirection,
  }) {
    final textAlign = textDirection == ui.TextDirection.rtl
        ? ui.TextAlign.right
        : ui.TextAlign.left;
    final builder =
        ui.ParagraphBuilder(
            ui.ParagraphStyle(
              textAlign: textAlign,
              textDirection: textDirection,
            ),
          )
          ..pushStyle(
            ui.TextStyle(
              color: line.color,
              fontSize: line.fontSize,
              fontWeight: line.isHeading
                  ? ui.FontWeight.w600
                  : ui.FontWeight.w400,
            ),
          )
          ..addText(line.text);
    return builder.build()..layout(ui.ParagraphConstraints(width: textWidth));
  }
}

/// A single PNG cannot safely remain both legible and within common canvas
/// limits for arbitrarily long notes. Callers can offer the PDF alternative.
class MoodMedicinePngReportTooLargeException implements Exception {
  const MoodMedicinePngReportTooLargeException(this.maxImageHeight);

  final int maxImageHeight;
}

class _PngParagraph {
  const _PngParagraph(this.paragraph, this.bottomSpacing);

  final ui.Paragraph paragraph;
  final double bottomSpacing;
}

class _PngLine {
  const _PngLine(
    this.text, {
    required this.fontSize,
    required this.bottomSpacing,
    this.color = const ui.Color(0xff352c22),
    this.isHeading = false,
  });

  final String text;
  final double fontSize;
  final double bottomSpacing;
  final ui.Color color;
  final bool isHeading;
}
