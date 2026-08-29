import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mazilon/features/mood_medicine/ui/mood_medicine_trend_chart.dart';

const Size _chartSize = Size(300, 190);

void main() {
  group('MoodMedicineTrendChart', () {
    testWidgets('should expose the empty label to assistive technology', (
      tester,
    ) async {
      await _pumpChart(tester, points: const <MoodMedicineTrendPoint>[]);
      final SemanticsHandle semantics = tester.ensureSemantics();
      try {
        expect(find.text('No check-ins yet'), findsOneWidget);
        expect(
          tester.getSemantics(find.byType(MoodMedicineTrendChart)),
          matchesSemantics(label: 'No check-ins yet'),
        );
        expect(_chartCustomPaint, findsNothing);
      } finally {
        semantics.dispose();
      }
    });

    testWidgets('should render a single point without a line', (tester) async {
      await _pumpChart(
        tester,
        points: const <MoodMedicineTrendPoint>[
          MoodMedicineTrendPoint(label: 'Mon', mood: 3),
        ],
      );

      expect(_chartCustomPaint, findsOneWidget);
      final _ChartRaster raster = (await tester.runAsync(
        () => _rasterize(_chartPainter(tester)),
      ))!;
      expect(raster.colorAt(150, 92), _lightTheme.colorScheme.surface);
    });

    testWidgets('should render multiple points and expose the trend summary', (
      tester,
    ) async {
      await _pumpChart(
        tester,
        points: const <MoodMedicineTrendPoint>[
          MoodMedicineTrendPoint(label: 'Mon', mood: 1),
          MoodMedicineTrendPoint(label: 'Tue', mood: 3),
          MoodMedicineTrendPoint(label: 'Wed', mood: 5),
        ],
      );
      final SemanticsHandle semantics = tester.ensureSemantics();
      try {
        expect(_chartCustomPaint, findsOneWidget);
        expect(
          tester.getSemantics(find.byType(MoodMedicineTrendChart)),
          matchesSemantics(label: 'Mood trend from Mon to Wed'),
        );
      } finally {
        semantics.dispose();
      }
    });

    testWidgets(
      'should paint highlighted activity points with the overlay color',
      (tester) async {
        await _pumpChart(
          tester,
          points: const <MoodMedicineTrendPoint>[
            MoodMedicineTrendPoint(label: 'Mon', mood: 1),
            MoodMedicineTrendPoint(
              label: 'Tue',
              mood: 3,
              activityIds: <String>{'walk'},
            ),
            MoodMedicineTrendPoint(label: 'Wed', mood: 5),
          ],
          highlightedActivityId: 'walk',
        );

        final _ChartRaster raster = (await tester.runAsync(
          () => _rasterize(_chartPainter(tester)),
        ))!;
        expect(raster.colorAt(155, 92), _lightTheme.colorScheme.tertiary);
        expect(raster.colorAt(150, 92), _lightTheme.colorScheme.surface);
      },
    );

    testWidgets('should use the dark theme surface for point centers', (
      tester,
    ) async {
      await _pumpChart(
        tester,
        theme: _darkTheme,
        points: const <MoodMedicineTrendPoint>[
          MoodMedicineTrendPoint(label: 'Mon', mood: 3),
        ],
      );

      final _ChartRaster raster = (await tester.runAsync(
        () => _rasterize(_chartPainter(tester)),
      ))!;
      expect(raster.colorAt(150, 92), _darkTheme.colorScheme.surface);
      expect(raster.colorAt(150, 92), isNot(Colors.white));
    });
  });
}

Finder get _chartCustomPaint => find.descendant(
  of: find.byType(MoodMedicineTrendChart),
  matching: find.byType(CustomPaint),
);

CustomPainter _chartPainter(WidgetTester tester) =>
    tester.widget<CustomPaint>(_chartCustomPaint).painter!;

final ThemeData _lightTheme = ThemeData(
  colorScheme: const ColorScheme.light(
    primary: Color(0xff1f6f8b),
    tertiary: Color(0xff965a38),
    surface: Color(0xfffefbf6),
    outline: Color(0xff65737e),
  ),
);

final ThemeData _darkTheme = ThemeData(
  colorScheme: const ColorScheme.dark(
    primary: Color(0xff79d0f5),
    tertiary: Color(0xffffb48f),
    surface: Color(0xff171717),
    outline: Color(0xffa7b1ba),
  ),
);

Future<void> _pumpChart(
  WidgetTester tester, {
  ThemeData? theme,
  required List<MoodMedicineTrendPoint> points,
  String? highlightedActivityId,
}) async {
  final ThemeData selectedTheme = theme ?? _lightTheme;
  await tester.pumpWidget(
    MaterialApp(
      theme: selectedTheme,
      home: Scaffold(
        body: Align(
          alignment: Alignment.topLeft,
          child: Material(
            color: selectedTheme.colorScheme.surface,
            child: SizedBox(
              width: _chartSize.width,
              height: _chartSize.height,
              child: MoodMedicineTrendChart(
                points: points,
                emptyLabel: 'No check-ins yet',
                semanticSummary: 'Mood trend from Mon to Wed',
                highlightedActivityId: highlightedActivityId,
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

Future<_ChartRaster> _rasterize(CustomPainter painter) async {
  final ui.PictureRecorder recorder = ui.PictureRecorder();
  final Canvas canvas = Canvas(recorder);
  painter.paint(canvas, _chartSize);
  final ui.Picture picture = recorder.endRecording();
  final ui.Image image = await picture.toImage(
    _chartSize.width.ceil(),
    _chartSize.height.ceil(),
  );
  try {
    final ByteData? data = await image.toByteData(
      format: ui.ImageByteFormat.rawStraightRgba,
    );
    final Uint8List bytes = data!.buffer.asUint8List(
      data.offsetInBytes,
      data.lengthInBytes,
    );
    return _ChartRaster(width: image.width, bytes: bytes);
  } finally {
    image.dispose();
    picture.dispose();
  }
}

final class _ChartRaster {
  const _ChartRaster({required this.width, required this.bytes});

  final int width;
  final Uint8List bytes;

  Color colorAt(int x, int y) {
    final int index = (y * width + x) * 4;
    return Color.fromARGB(
      bytes[index + 3],
      bytes[index],
      bytes[index + 1],
      bytes[index + 2],
    );
  }
}
