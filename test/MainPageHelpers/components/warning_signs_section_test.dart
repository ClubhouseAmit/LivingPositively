import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mazilon/MainPageHelpers/components/warning_signs_section.dart';
import 'package:mazilon/l10n/app_localizations.dart';
import 'package:mazilon/util/layout/directional_widgets.dart';
import 'package:mazilon/util/theme/app_theme.dart';
import 'package:mazilon/util/userInformation.dart';
import 'package:provider/provider.dart';

import '../../helpers/widget_test_scaffold.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('WarningSignsSectionWidget', () {
    setUp(() {
      registerTestServices(locale: 'en');
    });

    tearDown(resetTestServices);

    testWidgets(
      'should render a one-pixel green shared dashed border in both themes',
      (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = const Size(400, 500);
        addTearDown(tester.view.reset);

        for (final theme in [buildLightTheme(), buildDarkTheme()]) {
          var addCount = 0;
          await tester.pumpWidget(
            _warningSignsHarness(
              theme: theme,
              onAddItem: () {
                addCount++;
              },
            ),
          );
          await tester.pumpAndSettle();

          final customPaintFinder = find.descendant(
            of: find.byType(WarningSignsSectionWidget),
            matching: find.byWidgetPredicate(
              (widget) =>
                  widget is CustomPaint &&
                  widget.painter is DashedRoundedBorderPainter,
            ),
          );
          expect(customPaintFinder, findsOneWidget);

          final customPaint = tester.widget<CustomPaint>(customPaintFinder);
          final painter = customPaint.painter! as DashedRoundedBorderPainter;
          expect(painter.color, theme.colorScheme.tertiary);
          expect(painter.radius, 16);
          expect(painter.strokeWidth, 1);

          final raster = (await tester.runAsync(
            () => _rasterize(
              painter,
              tester.getSize(customPaintFinder),
              _warningBorderDashLength,
            ),
          ))!;
          expect(raster.effectiveStrokeWidth, closeTo(1, 0.2));
          expect(raster.contains(theme.colorScheme.tertiary), isTrue);

          await tester.tap(customPaintFinder);
          await tester.pump();
          expect(addCount, 1);
          expect(tester.takeException(), isNull);
        }
      },
    );
  });
}

Widget _warningSignsHarness({
  required ThemeData theme,
  required VoidCallback onAddItem,
}) {
  return ChangeNotifierProvider(
    create: (_) => UserInformation(gender: 'female'),
    child: MaterialApp(
      theme: theme,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      home: Scaffold(
        body: WarningSignsSectionWidget(
          signs: const [],
          onAddItem: onAddItem,
          onSeeAll: () {},
        ),
      ),
    ),
  );
}

Future<_RasterStats> _rasterize(
  CustomPainter painter,
  Size size,
  double Function(Size size) paintedDashLength,
) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  painter.paint(canvas, size);
  final picture = recorder.endRecording();
  final image = await picture.toImage(size.width.ceil(), size.height.ceil());
  final data = await image.toByteData(
    format: ui.ImageByteFormat.rawStraightRgba,
  );
  final bytes = data!.buffer.asUint8List();
  var alphaCoverage = 0.0;
  for (var offset = 3; offset < bytes.length; offset += 4) {
    alphaCoverage += bytes[offset] / 255;
  }
  image.dispose();
  picture.dispose();

  return _RasterStats(
    bytes: bytes,
    effectiveStrokeWidth: alphaCoverage / paintedDashLength(size),
  );
}

double _warningBorderDashLength(Size size) {
  final path = Path()
    ..addRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(1, 1, size.width - 2, size.height - 2),
        const Radius.circular(16),
      ),
    );
  var paintedLength = 0.0;
  for (final metric in path.computeMetrics()) {
    for (var distance = 0.0; distance < metric.length; distance += 12) {
      paintedLength += math.min(7, metric.length - distance);
    }
  }
  return paintedLength;
}

final class _RasterStats {
  final List<int> bytes;
  final double effectiveStrokeWidth;

  const _RasterStats({required this.bytes, required this.effectiveStrokeWidth});

  bool contains(Color color) {
    final argb = color.toARGB32();
    final red = (argb >> 16) & 0xFF;
    final green = (argb >> 8) & 0xFF;
    final blue = argb & 0xFF;
    for (var offset = 0; offset < bytes.length; offset += 4) {
      if (bytes[offset] == red &&
          bytes[offset + 1] == green &&
          bytes[offset + 2] == blue &&
          bytes[offset + 3] > 0) {
        return true;
      }
    }
    return false;
  }
}
