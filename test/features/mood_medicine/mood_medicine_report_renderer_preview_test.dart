import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mazilon/features/mood_medicine/data/mood_medicine_report_delivery_types.dart';
import 'package:mazilon/features/mood_medicine/data/mood_medicine_report_models.dart';
import 'package:mazilon/features/mood_medicine/data/mood_medicine_report_renderer.dart';
import 'package:mazilon/features/mood_medicine/ui/mood_medicine_report_preview.dart';
import 'package:printing/printing.dart';

void main() {
  group('MoodMedicinePngReportRenderer', () {
    testWidgets('should create a portrait A4 canvas with safe margins', (
      WidgetTester tester,
    ) async {
      const MoodMedicinePngReportRenderer renderer =
          MoodMedicinePngReportRenderer();

      final _PngRaster raster = await _renderAndDecodePng(
        tester,
        renderer,
        _reportInput(),
      );

      expect(raster.width, renderer.width.ceil());
      expect(
        raster.height,
        greaterThanOrEqualTo(
          (renderer.width * MoodMedicinePngReportRenderer.a4PortraitAspectRatio)
              .ceil(),
        ),
      );
      final int safeMargin = renderer.horizontalPadding.floor();
      expect(_hasInkInRect(raster, 0, raster.width, 0, safeMargin), isFalse);
      expect(_hasInkInRect(raster, 0, safeMargin, 0, raster.height), isFalse);
      expect(
        _hasInkInRect(
          raster,
          raster.width - safeMargin,
          raster.width,
          0,
          raster.height,
        ),
        isFalse,
      );
      expect(
        _hasInkInRect(
          raster,
          0,
          raster.width,
          raster.height - safeMargin,
          raster.height,
        ),
        isFalse,
      );
    });

    testWidgets('should decode a long RTL URL without exceeding the canvas', (
      WidgetTester tester,
    ) async {
      const MoodMedicinePngReportRenderer renderer =
          MoodMedicinePngReportRenderer();
      final MoodMedicineReportInput report = _reportInput(
        rtl: true,
        sourceUrl:
            'https://example.org/a-very-long-source-path-that-needs-a-safe-break/'
            'with-a-long-token-and-query?source=mood-medicine&campaign=preview',
      );

      final _PngRaster raster = await _renderAndDecodePng(
        tester,
        renderer,
        report,
      );

      expect(raster.height, lessThanOrEqualTo(renderer.maxImageHeight));
      expect(raster.width, renderer.width.ceil());
    });

    testWidgets('should retain the too-large guard for oversized reports', (
      WidgetTester tester,
    ) async {
      const MoodMedicinePngReportRenderer renderer =
          MoodMedicinePngReportRenderer(maxImageHeight: 100);

      await tester.runAsync<void>(() async {
        await expectLater(
          renderer.render(_reportInput()),
          throwsA(isA<MoodMedicinePngReportTooLargeException>()),
        );
      });
    });
  });

  group('MoodMedicinePdfReportRenderer', () {
    testWidgets('should render normal and empty report documents', (
      WidgetTester tester,
    ) async {
      const MoodMedicinePdfReportRenderer renderer =
          MoodMedicinePdfReportRenderer();
      final Uint8List normalBytes = await _runOutsideFakeAsync(
        tester,
        () => renderer.render(_reportInput()),
      );
      final Uint8List emptyBytes = await _runOutsideFakeAsync(
        tester,
        () => renderer.render(
          MoodMedicineReportInput(
            title: 'Mood report',
            dateRangeLabel: 'This week',
            labels: _reportLabels,
            days: const <MoodMedicineReportDay>[],
          ),
        ),
      );

      expect(normalBytes.sublist(0, 4), <int>[0x25, 0x50, 0x44, 0x46]);
      expect(emptyBytes.sublist(0, 4), <int>[0x25, 0x50, 0x44, 0x46]);
    });

    testWidgets('should render a long RTL report across multiple PDF pages', (
      WidgetTester tester,
    ) async {
      final MoodMedicineReportInput report = _reportInput(
        rtl: true,
        extraDays: 90,
        sourceUrl:
            'https://example.org/a-very-long-source-path-that-needs-a-safe-break/'
            'with-a-long-token-and-query?source=mood-medicine&campaign=preview',
      );

      final Uint8List bytes = await _runOutsideFakeAsync(
        tester,
        () => const MoodMedicinePdfReportRenderer().render(report),
      );

      expect(bytes.length, greaterThan(100));
      expect(bytes.sublist(0, 4), <int>[0x25, 0x50, 0x44, 0x46]);
      expect(_pdfPageCount(bytes), greaterThan(1));
    });

    testWidgets(
      'should preserve a bounded RTL content plan when rendering across pages',
      (WidgetTester tester) async {
        const MoodMedicinePdfReportRenderer renderer =
            MoodMedicinePdfReportRenderer();
        final List<String> noteLines = List<String>.generate(
          24,
          (int index) => 'הערה ייחודית $index עם פרטי יומן לדוח',
        );
        final List<MoodMedicineReportSource> sources =
            List<MoodMedicineReportSource>.generate(
              12,
              (int index) => MoodMedicineReportSource(
                title:
                    'כותרת מקור ייחודית $index\nהמשך כותרת מקור ייחודית $index',
                description:
                    'תיאור מקור ייחודי $index\nפרט חינוכי ייחודי $index\n'
                    'הרחבה חינוכית ייחודית $index',
                url: Uri.parse(
                  'https://example.org/source-$index/'
                  '${List<String>.filled(42, 'segment').join('-')}'
                  '?marker=unique-url-$index',
                ),
              ),
            );
        final MoodMedicineReportInput report = _reportInput(
          rtl: true,
          note: noteLines.join('\n'),
          sources: sources,
        );
        final MoodMedicinePdfContentPlan contentPlan = renderer
            .buildContentPlanForTesting(report);

        final List<MoodMedicinePdfContentCard> noteCards = contentPlan.cards
            .where(
              (MoodMedicinePdfContentCard card) =>
                  card.kind == MoodMedicinePdfContentCardKind.section &&
                  card.heading == report.labels.notesLabel,
            )
            .toList(growable: false);
        final int firstSourceCardIndex = contentPlan.cards.indexWhere(
          (MoodMedicinePdfContentCard card) =>
              card.kind == MoodMedicinePdfContentCardKind.source,
        );

        expect(noteCards, isNotEmpty);
        expect(firstSourceCardIndex, greaterThan(0));
        expect(
          contentPlan.cards
              .sublist(0, firstSourceCardIndex)
              .any(
                (MoodMedicinePdfContentCard card) =>
                    card.kind == MoodMedicinePdfContentCardKind.section &&
                    card.heading == report.labels.notesLabel,
              ),
          isTrue,
        );
        expect(
          contentPlan.cards
              .sublist(firstSourceCardIndex)
              .any(
                (MoodMedicinePdfContentCard card) =>
                    card.kind == MoodMedicinePdfContentCardKind.section &&
                    card.heading == report.labels.notesLabel,
              ),
          isFalse,
        );
        expect(
          contentPlan.cards[firstSourceCardIndex].heading,
          report.labels.sourcesLabel,
        );

        for (final MoodMedicinePdfContentCard card in contentPlan.cards) {
          switch (card.kind) {
            case MoodMedicinePdfContentCardKind.section:
              expect(card.fragments.length, lessThanOrEqualTo(8));
              expect(
                card.fragments.every(
                  (MoodMedicinePdfContentFragment fragment) =>
                      fragment.kind == MoodMedicinePdfContentFragmentKind.line,
                ),
                isTrue,
              );
            case MoodMedicinePdfContentCardKind.source:
              expect(card.fragments.length, lessThanOrEqualTo(4));
              expect(
                card.fragments.every(
                  (MoodMedicinePdfContentFragment fragment) =>
                      fragment.kind != MoodMedicinePdfContentFragmentKind.line,
                ),
                isTrue,
              );
          }
        }

        final String noteText = _plannedText(
          noteCards,
          MoodMedicinePdfContentFragmentKind.line,
        );
        for (final String noteLine in noteLines) {
          expect(noteText, contains(noteLine));
        }
        final String titleText = _plannedText(
          contentPlan.cards,
          MoodMedicinePdfContentFragmentKind.title,
        );
        final String descriptionText = _plannedText(
          contentPlan.cards,
          MoodMedicinePdfContentFragmentKind.description,
        );
        final String urlText = _plannedText(
          contentPlan.cards,
          MoodMedicinePdfContentFragmentKind.url,
        );
        for (final MoodMedicineReportSource source in sources) {
          expect(titleText, contains(_withoutLineBreaks(source.title)));
          expect(
            descriptionText,
            contains(_withoutLineBreaks(source.description!.trim())),
          );
          expect(urlText, contains(source.url.toString()));
        }

        final Uint8List bytes = await _runOutsideFakeAsync(
          tester,
          () => renderer.render(report),
        );

        expect(bytes.sublist(0, 4), <int>[0x25, 0x50, 0x44, 0x46]);
        expect(_pdfPageCount(bytes), greaterThan(1));
      },
    );

    test(
      'should preserve an emoji across the 240-unit content-plan boundary',
      () {
        const MoodMedicinePdfReportRenderer renderer =
            MoodMedicinePdfReportRenderer();
        final String title = '${List<String>.filled(239, 'a').join()}😀tail';
        final MoodMedicinePdfContentPlan contentPlan = renderer
            .buildContentPlanForTesting(
              _reportInput(
                sources: <MoodMedicineReportSource>[
                  MoodMedicineReportSource(
                    title: title,
                    url: Uri.parse('https://example.org/source'),
                  ),
                ],
              ),
            );
        final List<String> fragments = contentPlan.cards
            .expand((MoodMedicinePdfContentCard card) => card.fragments)
            .where(
              (MoodMedicinePdfContentFragment fragment) =>
                  fragment.kind == MoodMedicinePdfContentFragmentKind.title,
            )
            .map((MoodMedicinePdfContentFragment fragment) => fragment.text)
            .toList(growable: false);

        expect(fragments, hasLength(2));
        expect(fragments.first.length, 239);
        expect(fragments.last, startsWith('😀'));
        expect(fragments.join(), title);
        expect(
          fragments.every((String fragment) => fragment.length <= 240),
          isTrue,
        );
        expect(fragments.every(_hasValidUtf16SurrogatePairs), isTrue);
      },
    );
  });

  group('MoodMedicineReportPreviewPage', () {
    testWidgets('should show a zoomable PNG preview and its print guidance', (
      WidgetTester tester,
    ) async {
      final Uint8List png = await _runOutsideFakeAsync(
        tester,
        () => const MoodMedicinePngReportRenderer().render(_reportInput()),
      );
      final MoodMedicineBuiltReport report = MoodMedicineBuiltReport(
        bytes: png,
        fileName: 'report.png',
        mimeType: 'image/png',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: MoodMedicineReportPreviewPage(
            report: report,
            format: MoodMedicineReportFormat.png,
            title: 'Image preview',
            pngPrintGuidance: 'Choose PDF for long reports.',
          ),
        ),
      );

      expect(find.byKey(const Key('moodMedicinePngPreview')), findsOneWidget);
      expect(find.byType(InteractiveViewer), findsOneWidget);
      expect(find.text('Choose PDF for long reports.'), findsOneWidget);
    });

    testWidgets('should configure a display-only fixed-A4 PDF preview', (
      WidgetTester tester,
    ) async {
      final MoodMedicineBuiltReport report = MoodMedicineBuiltReport(
        bytes: await _runOutsideFakeAsync(
          tester,
          () => const MoodMedicinePdfReportRenderer().render(_reportInput()),
        ),
        fileName: 'report.pdf',
        mimeType: 'application/pdf',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: MoodMedicineReportPreviewPage(
            report: report,
            format: MoodMedicineReportFormat.pdf,
            title: 'PDF preview',
          ),
        ),
      );

      final PdfPreview preview = tester.widget<PdfPreview>(
        find.byType(PdfPreview),
      );
      expect(find.byKey(const Key('moodMedicinePdfPreview')), findsOneWidget);
      expect(preview.allowPrinting, isFalse);
      expect(preview.allowSharing, isFalse);
      expect(preview.useActions, isFalse);
      expect(preview.canChangePageFormat, isFalse);
      expect(preview.canChangeOrientation, isFalse);
      expect(preview.dynamicLayout, isFalse);
    });
  });
}

Future<T> _runOutsideFakeAsync<T>(
  WidgetTester tester,
  Future<T> Function() callback,
) async {
  final T? value = await tester.runAsync<T>(callback);
  if (value == null) {
    throw StateError('The report renderer did not return a value.');
  }
  return value;
}

Future<_PngRaster> _renderAndDecodePng(
  WidgetTester tester,
  MoodMedicinePngReportRenderer renderer,
  MoodMedicineReportInput input,
) {
  return _runOutsideFakeAsync<_PngRaster>(tester, () async {
    final Uint8List bytes = await renderer.render(input);
    final ui.Codec codec = await ui.instantiateImageCodec(bytes);
    final ui.FrameInfo frame = await codec.getNextFrame();
    final ByteData? rawPixels = await frame.image.toByteData(
      format: ui.ImageByteFormat.rawRgba,
    );
    if (rawPixels == null) {
      throw StateError('The PNG image could not be decoded as RGBA pixels.');
    }
    final _PngRaster raster = _PngRaster(
      width: frame.image.width,
      height: frame.image.height,
      pixels: Uint8List.fromList(
        rawPixels.buffer.asUint8List(
          rawPixels.offsetInBytes,
          rawPixels.lengthInBytes,
        ),
      ),
    );
    frame.image.dispose();
    codec.dispose();
    return raster;
  });
}

class _PngRaster {
  const _PngRaster({
    required this.width,
    required this.height,
    required this.pixels,
  });

  final int width;
  final int height;
  final Uint8List pixels;
}

bool _hasInkInRect(
  _PngRaster raster,
  int left,
  int right,
  int top,
  int bottom,
) {
  for (int y = top; y < bottom; y += 1) {
    for (int x = left; x < right; x += 1) {
      final int offset = ((y * raster.width) + x) * 4;
      if (raster.pixels[offset] != 0xfd ||
          raster.pixels[offset + 1] != 0xfb ||
          raster.pixels[offset + 2] != 0xf7 ||
          raster.pixels[offset + 3] != 0xff) {
        return true;
      }
    }
  }
  return false;
}

int _pdfPageCount(Uint8List bytes) {
  final String document = latin1.decode(bytes, allowInvalid: true);
  return RegExp(r'/Type/Page\b').allMatches(document).length;
}

String _plannedText(
  Iterable<MoodMedicinePdfContentCard> cards,
  MoodMedicinePdfContentFragmentKind kind,
) {
  return cards
      .expand(
        (MoodMedicinePdfContentCard card) => card.fragments.where(
          (MoodMedicinePdfContentFragment fragment) => fragment.kind == kind,
        ),
      )
      .map((MoodMedicinePdfContentFragment fragment) => fragment.text)
      .join();
}

String _withoutLineBreaks(String text) {
  return text.replaceAll(RegExp(r'\r\n|\r|\n'), '');
}

bool _hasValidUtf16SurrogatePairs(String text) {
  for (var index = 0; index < text.length; index += 1) {
    final int codeUnit = text.codeUnitAt(index);
    if (codeUnit >= 0xd800 && codeUnit <= 0xdbff) {
      if (index + 1 >= text.length) {
        return false;
      }
      final int followingCodeUnit = text.codeUnitAt(index + 1);
      if (followingCodeUnit < 0xdc00 || followingCodeUnit > 0xdfff) {
        return false;
      }
      index += 1;
    } else if (codeUnit >= 0xdc00 && codeUnit <= 0xdfff) {
      return false;
    }
  }
  return true;
}

const MoodMedicineReportLabels _reportLabels = MoodMedicineReportLabels(
  moodLabel: 'Mood',
  activitiesLabel: 'Activities',
  associationsLabel: 'Associations',
  notesLabel: 'Notes',
  sourcesLabel: 'Sources',
  noDataLabel: 'No data',
  withActivityLabel: 'With activity',
  withoutActivityLabel: 'Without activity',
  associationDisclaimer: 'Association does not mean causation.',
);

MoodMedicineReportInput _reportInput({
  bool rtl = false,
  String? sourceUrl,
  String? sourceDescription,
  String? note,
  int sourceCount = 1,
  int extraDays = 0,
  List<MoodMedicineReportSource>? sources,
}) {
  final List<MoodMedicineReportDay> days = <MoodMedicineReportDay>[
    MoodMedicineReportDay(
      dayLabel: '2026-08-29',
      moodAverage: 4,
      activities: <String>['Walk'],
      note: note,
    ),
    for (int index = 0; index < extraDays; index += 1)
      MoodMedicineReportDay(
        dayLabel: '2026-07-${(index % 28) + 1}',
        moodAverage: 3.5,
        activities: const <String>['Walk', 'Sleep'],
      ),
  ];
  return MoodMedicineReportInput(
    title: rtl ? 'דוח מצב רוח' : 'Mood report',
    dateRangeLabel: rtl ? 'שבוע זה' : 'This week',
    labels: _reportLabels,
    days: days,
    textDirection: rtl ? ui.TextDirection.rtl : ui.TextDirection.ltr,
    includeNotes: note != null,
    sources:
        sources ??
        List<MoodMedicineReportSource>.generate(
          sourceCount,
          (int index) => MoodMedicineReportSource(
            title: rtl ? 'מקור ${index + 1}' : 'Source ${index + 1}',
            description: sourceDescription,
            url: Uri.parse(
              sourceUrl ?? 'https://example.org/source/${index + 1}',
            ),
          ),
        ),
  );
}
