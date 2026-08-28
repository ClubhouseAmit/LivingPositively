import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mazilon/util/layout/directional_widgets.dart';
import 'package:mazilon/util/theme/app_theme.dart';

import '../../helpers/widget_test_scaffold.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SectionHeaderWidget onTitleTap', () {
    setUp(() {
      registerTestServices(locale: 'en');
    });

    tearDown(() {
      resetTestServices();
    });

    testWidgets('should trigger onTitleTap and expose default key fallback when titleKey is omitted', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      try {
        var tapped = false;
        await pumpWithProviders(
          tester,
          Scaffold(
            body: SectionHeaderWidget(
              title: 'Default Key Section',
              leadingIcon: Icons.star,
              onTitleTap: () {
                tapped = true;
              },
            ),
          ),
        );

        final defaultKeyFinder = find.byKey(const Key('sectionHeaderTitleTapTarget'));
        expect(defaultKeyFinder, findsOneWidget);

        await tester.tap(defaultKeyFinder);
        await tester.pump();

        expect(tapped, isTrue);

        final semantics = tester.getSemantics(find.text('Default Key Section'));
        expect(semantics.getSemanticsData().hasAction(SemanticsAction.tap), isTrue);
      } finally {
        handle.dispose();
      }
    });

    testWidgets('should trigger onTitleTap when custom titleKey is provided', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      try {
        var tapped = false;
        await pumpWithProviders(
          tester,
          Scaffold(
            body: SectionHeaderWidget(
              title: 'My Section',
              titleKey: const Key('customTitleKey'),
              leadingIcon: Icons.star,
              onTitleTap: () {
                tapped = true;
              },
            ),
          ),
        );

        final titleFinder = find.byKey(const Key('customTitleKey'));
        expect(titleFinder, findsOneWidget);

        await tester.tap(titleFinder);
        await tester.pump();

        expect(tapped, isTrue);

        final semantics = tester.getSemantics(find.text('My Section'));
        expect(semantics.getSemanticsData().hasAction(SemanticsAction.tap), isTrue);
      } finally {
        handle.dispose();
      }
    });

    testWidgets('should trigger onTitleTap callback when leading icon is tapped', (
      tester,
    ) async {
      var tapped = false;
      await pumpWithProviders(
        tester,
        Scaffold(
          body: SectionHeaderWidget(
            title: 'My Section',
            leadingIcon: Icons.star,
            onTitleTap: () {
              tapped = true;
            },
          ),
        ),
      );

      final iconFinder = find.byIcon(Icons.star);
      expect(iconFinder, findsOneWidget);

      await tester.tap(iconFinder);
      await tester.pump();

      expect(tapped, isTrue);
    });

    testWidgets('should occupy full width of Expanded and be tappable in whitespace', (
      tester,
    ) async {
      var tapCount = 0;
      await pumpWithProviders(
        tester,
        Scaffold(
          body: SizedBox(
            width: 400,
            child: SectionHeaderWidget(
              title: 'Title',
              leadingIcon: Icons.star,
              onTitleTap: () {
                tapCount++;
              },
            ),
          ),
        ),
        surfaceSize: const Size(600, 800),
      );

      final targetFinder = find.byKey(const Key('sectionHeaderTitleTapTarget'));
      expect(targetFinder, findsOneWidget);

      final rect = tester.getRect(targetFinder);
      await tester.tapAt(Offset(rect.right - 1, rect.center.dy));
      await tester.pump();

      expect(tapCount, equals(1));
    });

    testWidgets('should not wrap with button semantics or interactive key when onTitleTap is null', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      try {
        await pumpWithProviders(
          tester,
          const Scaffold(
            body: SectionHeaderWidget(
              title: 'Static Section',
              leadingIcon: Icons.star,
            ),
          ),
        );

        final titleFinder = find.text('Static Section');
        expect(titleFinder, findsOneWidget);

        expect(find.byKey(const Key('sectionHeaderTitleTapTarget')), findsNothing);

        final semantics = tester.getSemantics(titleFinder);
        expect(semantics.getSemanticsData().hasAction(SemanticsAction.tap), isFalse);
      } finally {
        handle.dispose();
      }
    });
  });

  group('DashedPillAddSlot', () {
    testWidgets(
      'should render one-pixel green strokes and repaint when the theme changes',
      (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = const Size(400, 120);
        addTearDown(tester.view.reset);

        var isDark = true;
        late StateSetter setTheme;

        await tester.pumpWidget(
          StatefulBuilder(
            builder: (context, setState) {
              setTheme = setState;
              return _slotHarness(
                theme: isDark ? buildDarkTheme() : buildLightTheme(),
              );
            },
          ),
        );

        final darkPaints = _slotCustomPaints(tester);
        expect(darkPaints, hasLength(2));
        final darkPillPainter =
            darkPaints[1].painter! as DashedRoundedBorderPainter;
        expect(darkPillPainter.radius, 24);
        expect(darkPillPainter.strokeWidth, 1);
        final darkCircle = (await tester.runAsync(
          () => _rasterize(
            darkPaints[0].painter!,
            tester.getSize(_slotCustomPaintFinder().at(0)),
            _circleDashLength,
          ),
        ))!;
        final darkPill = (await tester.runAsync(
          () => _rasterize(
            darkPaints[1].painter!,
            tester.getSize(_slotCustomPaintFinder().at(1)),
            _pillDashLength,
          ),
        ))!;

        expect(darkCircle.effectiveStrokeWidth, closeTo(1, 0.2));
        expect(darkPill.effectiveStrokeWidth, closeTo(1, 0.2));
        expect(darkCircle.contains(AppColors.darkSuccess), isTrue);
        expect(darkPill.contains(AppColors.darkSuccess), isTrue);

        setTheme(() => isDark = false);
        await tester.pump();

        final lightPaints = _slotCustomPaints(tester);
        expect(lightPaints, hasLength(2));
        final lightPillPainter =
            lightPaints[1].painter! as DashedRoundedBorderPainter;
        expect(lightPillPainter.radius, 24);
        expect(lightPillPainter.strokeWidth, 1);
        final lightCircle = (await tester.runAsync(
          () => _rasterize(
            lightPaints[0].painter!,
            tester.getSize(_slotCustomPaintFinder().at(0)),
            _circleDashLength,
          ),
        ))!;
        final lightPill = (await tester.runAsync(
          () => _rasterize(
            lightPaints[1].painter!,
            tester.getSize(_slotCustomPaintFinder().at(1)),
            _pillDashLength,
          ),
        ))!;

        expect(
          lightPaints[0].painter!.shouldRepaint(darkPaints[0].painter!),
          isTrue,
        );
        expect(
          lightPaints[1].painter!.shouldRepaint(darkPaints[1].painter!),
          isTrue,
        );
        expect(lightCircle.effectiveStrokeWidth, closeTo(1, 0.2));
        expect(lightPill.effectiveStrokeWidth, closeTo(1, 0.2));
        expect(lightCircle.contains(AppColors.success), isTrue);
        expect(lightPill.contains(AppColors.success), isTrue);
      },
    );

    testWidgets('should preserve callbacks and directional order in RTL', (
      tester,
    ) async {
      var addCount = 0;
      var refreshCount = 0;

      await tester.pumpWidget(
        _slotHarness(
          theme: buildDarkTheme(),
          textDirection: TextDirection.rtl,
          onTap: () => addCount++,
          onRefresh: () => refreshCount++,
        ),
      );

      expect(
        tester.getCenter(find.byIcon(Icons.add)).dx,
        greaterThan(tester.getCenter(find.text('Add another')).dx),
      );

      await tester.tap(find.byIcon(Icons.add));
      await tester.tap(find.text('Add another'));
      await tester.tap(find.byIcon(Icons.refresh));
      await tester.pump();

      expect(addCount, 2);
      expect(refreshCount, 1);
      expect(tester.takeException(), isNull);
    });
  });

  group('LivingPositivelyLogo', () {
    testWidgets(
      'should rasterize a lower-region white letter outline only in dark mode',
      (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = const Size(500, 500);
        addTearDown(tester.view.reset);

        for (final width in [120.0, 180.0]) {
          await tester.pumpWidget(
            _logoHarness(theme: buildLightTheme(), width: width),
          );
          await tester.pumpAndSettle();
          await _precacheLogoAsset(tester);

          expect(find.byType(ColorFiltered), findsNothing);
          expect(find.byType(Image), findsOneWidget);
          final lightRaster = (await tester.runAsync(
            () => _captureLogoRaster(tester),
          ))!;

          await tester.pumpWidget(
            _plainLogoHarness(theme: buildLightTheme(), width: width),
          );
          await tester.pumpAndSettle();
          await _precacheLogoAsset(tester);
          final plainRaster = (await tester.runAsync(
            () => _captureLogoRaster(tester),
          ))!;
          expect(lightRaster.bytes, orderedEquals(plainRaster.bytes));

          await tester.pumpWidget(
            _logoHarness(theme: buildDarkTheme(), width: width),
          );
          await tester.pumpAndSettle();
          await _precacheLogoAsset(tester);

          expect(find.byType(ColorFiltered), findsNWidgets(8));
          expect(find.byType(ClipRect), findsNWidgets(8));
          expect(find.byType(Image), findsNWidgets(9));
          for (final filtered in tester.widgetList<ColorFiltered>(
            find.byType(ColorFiltered),
          )) {
            expect(
              filtered.colorFilter,
              const ColorFilter.mode(Colors.white, BlendMode.srcIn),
            );
          }

          final logoSize = tester.getSize(find.byType(Image).last);
          final expectedClipTop = logoSize.height * 0.53;
          for (final clipRect in tester.widgetList<ClipRect>(
            find.byType(ClipRect),
          )) {
            final clip = clipRect.clipper!.getClip(logoSize);
            expect(clip.top, closeTo(expectedClipTop, 0.001));
            expect(clip.height, closeTo(logoSize.height * 0.47, 0.001));
          }

          final darkRaster = (await tester.runAsync(
            () => _captureLogoRaster(tester),
          ))!;
          final preservedEndRow = math.max(
            0,
            (darkRaster.height * 0.53).floor() - 2,
          );
          expect(
            lightRaster.matchesRows(
              darkRaster,
              startRow: 0,
              endRow: preservedEndRow,
            ),
            isTrue,
            reason:
                'Dark-mode outlining must not alter the butterfly or green accent.',
          );
          expect(
            lightRaster.countWhere(
              startRow: 0,
              endRow: preservedEndRow,
              predicate: _isButterflyPixel,
            ),
            greaterThan(0),
          );
          expect(
            lightRaster.countWhere(
              startRow: 0,
              endRow: preservedEndRow,
              predicate: _isGreenAccentPixel,
            ),
            greaterThan(0),
          );
          expect(
            darkRaster.countNewWhitePixelsComparedTo(
              lightRaster,
              startRow: math.max(0, expectedClipTop.floor() - 1),
            ),
            greaterThan(0),
            reason: 'Dark mode must add a white outline around the LP letters.',
          );
        }
      },
    );
  });
}

const _logoRasterBoundaryKey = Key('livingPositivelyLogoRasterBoundary');
const _logoHeightFactor = 465 / 540;
const _logoAssetPath = 'assets/images/Logo.png';

Widget _logoHarness({required ThemeData theme, required double width}) {
  return MaterialApp(
    theme: theme,
    home: Scaffold(
      body: Center(
        child: RepaintBoundary(
          key: _logoRasterBoundaryKey,
          child: SizedBox(
            width: width,
            height: width * _logoHeightFactor,
            child: LivingPositivelyLogo(width: width),
          ),
        ),
      ),
    ),
  );
}

Widget _plainLogoHarness({required ThemeData theme, required double width}) {
  return MaterialApp(
    theme: theme,
    home: Scaffold(
      body: Center(
        child: RepaintBoundary(
          key: _logoRasterBoundaryKey,
          child: SizedBox(
            width: width,
            height: width * _logoHeightFactor,
            child: Image.asset(_logoAssetPath, width: width),
          ),
        ),
      ),
    ),
  );
}

Widget _slotHarness({
  required ThemeData theme,
  TextDirection textDirection = TextDirection.ltr,
  VoidCallback? onTap,
  VoidCallback? onRefresh,
}) {
  return MaterialApp(
    theme: theme,
    themeAnimationDuration: Duration.zero,
    home: Directionality(
      textDirection: textDirection,
      child: Scaffold(
        body: Center(
          child: SizedBox(
            width: 360,
            child: DashedPillAddSlot(
              placeholder: 'Add another',
              onTap: onTap,
              onRefresh: onRefresh,
            ),
          ),
        ),
      ),
    ),
  );
}

Finder _slotCustomPaintFinder() => find.descendant(
  of: find.byType(DashedPillAddSlot),
  matching: find.byType(CustomPaint),
);

List<CustomPaint> _slotCustomPaints(WidgetTester tester) => tester
    .widgetList<CustomPaint>(_slotCustomPaintFinder())
    .where((customPaint) => customPaint.painter != null)
    .toList(growable: false);

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
    alphaCoverage: alphaCoverage,
    effectiveStrokeWidth: alphaCoverage / paintedDashLength(size),
  );
}

double _circleDashLength(Size size) {
  final radius = (size.width - 2) / 2;
  final circumference = 2 * math.pi * radius;
  final dashCount = (circumference / (5 + 3.5)).floor();
  return dashCount * 5;
}

double _pillDashLength(Size size) {
  final path = Path()
    ..addRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(1, 1, size.width - 2, size.height - 2),
        const Radius.circular(24),
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

Future<_LogoRaster> _captureLogoRaster(WidgetTester tester) async {
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(_logoRasterBoundaryKey),
  );
  final image = await boundary.toImage(pixelRatio: 1);
  try {
    final data = await image.toByteData(
      format: ui.ImageByteFormat.rawStraightRgba,
    );
    return _LogoRaster(
      width: image.width,
      height: image.height,
      bytes: Uint8List.fromList(
        data!.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
      ),
    );
  } finally {
    image.dispose();
  }
}

Future<void> _precacheLogoAsset(WidgetTester tester) async {
  await tester.runAsync(
    () => precacheImage(
      const AssetImage(_logoAssetPath),
      tester.element(find.byType(Scaffold)),
    ).timeout(const Duration(seconds: 5)),
  );
  await tester.pump();
}

bool _isButterflyPixel(int red, int green, int blue, int alpha) =>
    alpha > 0 && red > green + 10 && blue > green + 10;

bool _isGreenAccentPixel(int red, int green, int blue, int alpha) =>
    alpha > 0 && green > red + 10 && green > blue + 10;

final class _LogoRaster {
  final int width;
  final int height;
  final Uint8List bytes;

  const _LogoRaster({
    required this.width,
    required this.height,
    required this.bytes,
  });

  bool matchesRows(
    _LogoRaster other, {
    required int startRow,
    required int endRow,
  }) {
    if (width != other.width || height != other.height) {
      return false;
    }

    for (var row = startRow; row < endRow; row++) {
      final rowStart = row * width * 4;
      final rowEnd = rowStart + width * 4;
      for (var offset = rowStart; offset < rowEnd; offset++) {
        if (bytes[offset] != other.bytes[offset]) {
          return false;
        }
      }
    }
    return true;
  }

  int countWhere({
    required int startRow,
    required int endRow,
    required bool Function(int red, int green, int blue, int alpha) predicate,
  }) {
    var count = 0;
    for (var row = startRow; row < endRow; row++) {
      for (var column = 0; column < width; column++) {
        final offset = (row * width + column) * 4;
        if (predicate(
          bytes[offset],
          bytes[offset + 1],
          bytes[offset + 2],
          bytes[offset + 3],
        )) {
          count++;
        }
      }
    }
    return count;
  }

  int countNewWhitePixelsComparedTo(
    _LogoRaster baseline, {
    required int startRow,
  }) {
    if (width != baseline.width || height != baseline.height) {
      return 0;
    }

    var count = 0;
    for (var row = startRow; row < height; row++) {
      for (var column = 0; column < width; column++) {
        final offset = (row * width + column) * 4;
        final isWhite =
            bytes[offset] >= 250 &&
            bytes[offset + 1] >= 250 &&
            bytes[offset + 2] >= 250 &&
            bytes[offset + 3] > 0;
        final baselineIsWhite =
            baseline.bytes[offset] >= 250 &&
            baseline.bytes[offset + 1] >= 250 &&
            baseline.bytes[offset + 2] >= 250 &&
            baseline.bytes[offset + 3] > 0;
        if (isWhite && !baselineIsWhite) {
          count++;
        }
      }
    }
    return count;
  }
}

final class _RasterStats {
  final List<int> bytes;
  final double alphaCoverage;
  final double effectiveStrokeWidth;

  const _RasterStats({
    required this.bytes,
    required this.alphaCoverage,
    required this.effectiveStrokeWidth,
  });

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
