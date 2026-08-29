import 'dart:ui' as ui;

import 'package:flutter/foundation.dart' show immutable, visibleForTesting;
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
    final MoodMedicinePdfContentPlan contentPlan = _buildContentPlan(input);

    final document = pw.Document();
    document.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(36),
        build: (_) => <pw.Widget>[
          pw.Directionality(
            textDirection: textDirection,
            child: _buildPdfHeader(
              input: input,
              font: font,
              alignment: alignment,
              textAlign: textAlign,
            ),
          ),
          for (final MoodMedicinePdfContentCard card in contentPlan.cards)
            pw.Directionality(
              textDirection: textDirection,
              child: switch (card.kind) {
                MoodMedicinePdfContentCardKind.section => _buildPdfSection(
                  card: card,
                  font: font,
                  alignment: alignment,
                  textAlign: textAlign,
                ),
                MoodMedicinePdfContentCardKind.source => _buildPdfSourceCard(
                  card: card,
                  font: font,
                  alignment: alignment,
                  textAlign: textAlign,
                ),
              },
            ),
        ],
      ),
    );
    return document.save();
  }

  /// Exposes the same bounded cards consumed by [render] for renderer tests.
  @visibleForTesting
  MoodMedicinePdfContentPlan buildContentPlanForTesting(
    MoodMedicineReportInput input,
  ) {
    return _buildContentPlan(input);
  }

  MoodMedicinePdfContentPlan _buildContentPlan(MoodMedicineReportInput input) {
    final List<MoodMedicinePdfContentCard> cards =
        <MoodMedicinePdfContentCard>[];
    final Iterable<MoodMedicineReportSection> nonSourceSections = input
        .buildSections()
        .where((MoodMedicineReportSection section) {
          return section.heading != input.labels.sourcesLabel;
        });

    for (final MoodMedicineReportSection section in nonSourceSections) {
      final List<String> lines = <String>[
        for (final String line in section.lines) ..._splitPdfLine(line),
      ];
      for (
        var start = 0;
        start < lines.length;
        start += _maximumPdfSectionLinesPerCard
      ) {
        final int end = start + _maximumPdfSectionLinesPerCard > lines.length
            ? lines.length
            : start + _maximumPdfSectionLinesPerCard;
        cards.add(
          MoodMedicinePdfContentCard(
            kind: MoodMedicinePdfContentCardKind.section,
            heading: section.heading,
            fragments: <MoodMedicinePdfContentFragment>[
              for (final String line in lines.sublist(start, end))
                MoodMedicinePdfContentFragment(
                  kind: MoodMedicinePdfContentFragmentKind.line,
                  text: line,
                ),
            ],
          ),
        );
      }
    }

    var includeSourceHeading = true;
    for (final MoodMedicineReportSource source in input.sources) {
      final List<MoodMedicinePdfContentFragment> fragments =
          <MoodMedicinePdfContentFragment>[
            for (final String title in _splitPdfLine(source.title))
              MoodMedicinePdfContentFragment(
                kind: MoodMedicinePdfContentFragmentKind.title,
                text: title,
              ),
            if (source.description?.trim().isNotEmpty ?? false)
              for (final String description in _splitPdfLine(
                source.description!.trim(),
              ))
                MoodMedicinePdfContentFragment(
                  kind: MoodMedicinePdfContentFragmentKind.description,
                  text: description,
                ),
            for (final String url in _splitPdfLine(source.url.toString()))
              MoodMedicinePdfContentFragment(
                kind: MoodMedicinePdfContentFragmentKind.url,
                text: url,
                urlDestination: source.hasSafeHttpsUrl
                    ? source.url.toString()
                    : null,
              ),
          ];
      for (
        var start = 0;
        start < fragments.length;
        start += _maximumPdfSourceFragmentsPerCard
      ) {
        final int end =
            start + _maximumPdfSourceFragmentsPerCard > fragments.length
            ? fragments.length
            : start + _maximumPdfSourceFragmentsPerCard;
        cards.add(
          MoodMedicinePdfContentCard(
            kind: MoodMedicinePdfContentCardKind.source,
            heading: includeSourceHeading ? input.labels.sourcesLabel : null,
            fragments: fragments.sublist(start, end),
          ),
        );
        includeSourceHeading = false;
      }
    }

    return MoodMedicinePdfContentPlan(cards: cards);
  }

  pw.Widget _buildPdfHeader({
    required MoodMedicineReportInput input,
    required pw.Font font,
    required pw.Alignment alignment,
    required pw.TextAlign textAlign,
  }) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 20),
      child: pw.Column(
        mainAxisSize: pw.MainAxisSize.min,
        crossAxisAlignment: input.isRtl
            ? pw.CrossAxisAlignment.end
            : pw.CrossAxisAlignment.start,
        children: <pw.Widget>[
          pw.Align(
            alignment: alignment,
            child: pw.Text(
              _softWrapReportText(input.title),
              style: pw.TextStyle(font: font, fontSize: 24),
              textAlign: textAlign,
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Align(
            alignment: alignment,
            child: pw.Text(
              _softWrapReportText(input.dateRangeLabel),
              style: pw.TextStyle(font: font, fontSize: 12),
              textAlign: textAlign,
            ),
          ),
        ],
      ),
    );
  }

  /// Limits one unbroken report line to a card-friendly amount of text while
  /// preserving the visible content and preferring whitespace/soft-wrap marks.
  Iterable<String> _splitPdfLine(String line) sync* {
    const int maximumCharactersPerFragment = 240;
    for (final String paragraph in line.split(RegExp(r'\r\n|\r|\n'))) {
      var remaining = paragraph;
      while (remaining.length > maximumCharactersPerFragment) {
        final int limit = maximumCharactersPerFragment;
        final int breakIndex = remaining.lastIndexOf(
          RegExp(r'[\s\u200B]'),
          limit,
        );
        final int end = breakIndex > 0 ? breakIndex + 1 : limit;
        yield remaining.substring(0, end);
        remaining = remaining.substring(end);
      }
      yield remaining;
    }
  }

  pw.Widget _buildPdfSection({
    required MoodMedicinePdfContentCard card,
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
        mainAxisSize: pw.MainAxisSize.min,
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: <pw.Widget>[
          pw.Align(
            alignment: alignment,
            child: pw.Text(
              _softWrapReportText(card.heading!),
              style: pw.TextStyle(font: font, fontSize: 16),
              textAlign: textAlign,
            ),
          ),
          pw.SizedBox(height: 6),
          for (final MoodMedicinePdfContentFragment fragment in card.fragments)
            pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 4),
              child: pw.Text(
                _softWrapReportText(fragment.text),
                style: pw.TextStyle(font: font, fontSize: 11),
                textAlign: textAlign,
              ),
            ),
        ],
      ),
    );
  }

  pw.Widget _buildPdfSourceCard({
    required MoodMedicinePdfContentCard card,
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
        mainAxisSize: pw.MainAxisSize.min,
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: <pw.Widget>[
          if (card.heading != null) ...<pw.Widget>[
            pw.Align(
              alignment: alignment,
              child: pw.Text(
                _softWrapReportText(card.heading!),
                style: pw.TextStyle(font: font, fontSize: 16),
                textAlign: textAlign,
              ),
            ),
            pw.SizedBox(height: 6),
          ],
          for (final MoodMedicinePdfContentFragment fragment in card.fragments)
            pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 4),
              child: switch (fragment.kind) {
                MoodMedicinePdfContentFragmentKind.line ||
                MoodMedicinePdfContentFragmentKind.title => pw.Text(
                  _softWrapReportText(fragment.text),
                  style: pw.TextStyle(font: font, fontSize: 11),
                  textAlign: textAlign,
                ),
                MoodMedicinePdfContentFragmentKind.description => pw.Text(
                  _softWrapReportText(fragment.text),
                  style: pw.TextStyle(font: font, fontSize: 10),
                  textAlign: textAlign,
                ),
                MoodMedicinePdfContentFragmentKind.url => pw.Directionality(
                  textDirection: pw.TextDirection.ltr,
                  child: _buildSourceUrl(fragment, font),
                ),
              },
            ),
        ],
      ),
    );
  }

  pw.Widget _buildSourceUrl(
    MoodMedicinePdfContentFragment fragment,
    pw.Font font,
  ) {
    final url = pw.Text(
      _softWrapReportText(fragment.text),
      style: pw.TextStyle(font: font, fontSize: 9, color: PdfColors.blue),
      textAlign: pw.TextAlign.left,
    );
    if (fragment.urlDestination == null) {
      return url;
    }
    return pw.UrlLink(destination: fragment.urlDestination!, child: url);
  }
}

const int _maximumPdfSectionLinesPerCard = 8;
const int _maximumPdfSourceFragmentsPerCard = 4;

/// Immutable, bounded PDF content consumed by the production renderer.
@immutable
class MoodMedicinePdfContentPlan {
  MoodMedicinePdfContentPlan({required List<MoodMedicinePdfContentCard> cards})
    : cards = List<MoodMedicinePdfContentCard>.unmodifiable(cards);

  final List<MoodMedicinePdfContentCard> cards;
}

enum MoodMedicinePdfContentCardKind { section, source }

/// A page-safe PDF card. Section cards have at most eight line fragments;
/// source cards have at most four source fragments.
@immutable
class MoodMedicinePdfContentCard {
  MoodMedicinePdfContentCard({
    required this.kind,
    required List<MoodMedicinePdfContentFragment> fragments,
    this.heading,
  }) : assert(
         kind != MoodMedicinePdfContentCardKind.section || heading != null,
       ),
       assert(
         kind != MoodMedicinePdfContentCardKind.section ||
             fragments.length <= _maximumPdfSectionLinesPerCard,
       ),
       assert(
         kind != MoodMedicinePdfContentCardKind.source ||
             fragments.length <= _maximumPdfSourceFragmentsPerCard,
       ),
       fragments = List<MoodMedicinePdfContentFragment>.unmodifiable(fragments);

  final MoodMedicinePdfContentCardKind kind;

  /// The section heading, or the source heading on the first source card.
  final String? heading;
  final List<MoodMedicinePdfContentFragment> fragments;
}

enum MoodMedicinePdfContentFragmentKind { line, title, description, url }

/// A text fragment in a [MoodMedicinePdfContentCard].
@immutable
class MoodMedicinePdfContentFragment {
  const MoodMedicinePdfContentFragment({
    required this.kind,
    required this.text,
    this.urlDestination,
  });

  final MoodMedicinePdfContentFragmentKind kind;
  final String text;

  /// The full safe HTTPS destination, retained while visible URL text splits.
  final String? urlDestination;
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

  /// The height/width ratio of a portrait A4 page.
  static const double a4PortraitAspectRatio = 297 / 210;

  Future<Uint8List> render(MoodMedicineReportInput input) async {
    // This small raster buffer keeps antialiased glyphs inside the configured
    // safe margin when the logical canvas is encoded as a PNG.
    final contentInset = horizontalPadding + 2;
    final textWidth = width - (contentInset * 2);
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
    final contentHeight =
        paragraphs.fold<double>(
          contentInset,
          (height, paragraph) =>
              height + paragraph.paragraph.height + paragraph.bottomSpacing,
        ) +
        contentInset;
    final minimumA4PortraitHeight = width * a4PortraitAspectRatio;
    final logicalImageHeight = contentHeight < minimumA4PortraitHeight
        ? minimumA4PortraitHeight
        : contentHeight;
    if (logicalImageHeight > maxImageHeight) {
      throw MoodMedicinePngReportTooLargeException(maxImageHeight);
    }
    final imageHeight = logicalImageHeight.ceilToDouble();

    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);
    canvas.drawRect(
      ui.Rect.fromLTWH(0, 0, width, imageHeight),
      ui.Paint()..color = const ui.Color(0xfffdfbf7),
    );

    canvas.save();
    canvas.clipRect(
      ui.Rect.fromLTRB(
        contentInset,
        contentInset,
        width - contentInset,
        imageHeight - contentInset,
      ),
    );
    var y = contentInset;
    for (final paragraph in paragraphs) {
      canvas.drawParagraph(paragraph.paragraph, ui.Offset(contentInset, y));
      y += paragraph.paragraph.height + paragraph.bottomSpacing;
    }
    canvas.restore();

    final picture = recorder.endRecording();
    final image = await picture.toImage(width.ceil(), imageHeight.toInt());
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    picture.dispose();
    if (byteData == null) {
      throw StateError('Could not encode the mood medicine PNG report.');
    }
    return Uint8List.fromList(byteData.buffer.asUint8List());
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
          ..addText(_softWrapReportText(line.text));
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

const String _zeroWidthSpace = '\u200B';

/// Adds invisible opportunities around URL punctuation and inside unusually
/// long unbroken tokens. This preserves the visible report text while keeping
/// PDF and PNG content inside their safe horizontal margins in both directions.
String _softWrapReportText(String text) {
  const int maximumUnbrokenRun = 28;
  const Set<int> breakAfterRunes = <int>{
    0x0023, // #
    0x0025, // %
    0x0026, // &
    0x002d, // -
    0x002e, // .
    0x002f, // /
    0x003a, // :
    0x003d, // =
    0x003f, // ?
    0x005f, // _
    0x007e, // ~
  };
  final StringBuffer buffer = StringBuffer();
  var unbrokenRunLength = 0;

  for (final int rune in text.runes) {
    buffer.writeCharCode(rune);
    if (rune == 0x000a || rune == 0x000d || rune == 0x0020 || rune == 0x0009) {
      unbrokenRunLength = 0;
      continue;
    }
    if (rune == 0x200b || breakAfterRunes.contains(rune)) {
      buffer.write(_zeroWidthSpace);
      unbrokenRunLength = 0;
      continue;
    }
    unbrokenRunLength += 1;
    if (unbrokenRunLength >= maximumUnbrokenRun) {
      buffer.write(_zeroWidthSpace);
      unbrokenRunLength = 0;
    }
  }
  return buffer.toString();
}
