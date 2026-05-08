import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mazilon/util/styles.dart';

void main() {
  Widget wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

  group('returnSizedBox', () {
    testWidgets('< 400 width returns size / 2', (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      double? out;
      await tester.pumpWidget(wrap(Builder(builder: (ctx) {
        out = returnSizedBox(ctx, 20);
        return const SizedBox.shrink();
      })));
      expect(out, 10);
    });

    testWidgets('400..499 width returns size + 0.1', (tester) async {
      tester.view.physicalSize = const Size(450, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      double? out;
      await tester.pumpWidget(wrap(Builder(builder: (ctx) {
        out = returnSizedBox(ctx, 20);
        return const SizedBox.shrink();
      })));
      expect(out, closeTo(20.1, 0.0001));
    });

    testWidgets('500..599 width returns size + 10', (tester) async {
      tester.view.physicalSize = const Size(550, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      double? out;
      await tester.pumpWidget(wrap(Builder(builder: (ctx) {
        out = returnSizedBox(ctx, 20);
        return const SizedBox.shrink();
      })));
      expect(out, 30);
    });

    testWidgets('>= 600 width returns size + 20', (tester) async {
      tester.view.physicalSize = const Size(800, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      double? out;
      await tester.pumpWidget(wrap(Builder(builder: (ctx) {
        out = returnSizedBox(ctx, 20);
        return const SizedBox.shrink();
      })));
      expect(out, 40);
    });
  });

  group('myText / myAutoSizedText', () {
    test('myText falls back to empty style when style is null', () {
      final t = myText('hello', null, TextAlign.left);
      expect(t, isA<Text>());
      expect(t.data, 'hello');
      expect(t.style?.fontFamily, 'Rubix');
      expect(t.textAlign, TextAlign.left);
    });

    test('myText preserves provided style fields and overrides fontFamily', () {
      final base = const TextStyle(color: Colors.red, fontSize: 12);
      final t = myText('x', base, TextAlign.right);
      expect(t.style?.color, Colors.red);
      expect(t.style?.fontSize, 12);
      expect(t.style?.fontFamily, 'Rubix');
    });

    test('myAutoSizedText defaults align to center when null', () {
      final t = myAutoSizedText('a', null, null, 30);
      expect(t, isA<AutoSizeText>());
      expect(t.textAlign, TextAlign.center);
      expect(t.maxFontSize, 30);
      // maxLines default 20 should map to null
      expect(t.maxLines, isNull);
    });

    test('myAutoSizedText with explicit maxLines is preserved', () {
      final t = myAutoSizedText('a', null, TextAlign.start, 30, 3);
      expect(t.maxLines, 3);
      expect(t.textAlign, TextAlign.start);
    });
  });

  group('button factories', () {
    testWidgets('ConfirmationButton invokes function on tap', (tester) async {
      var taps = 0;
      await tester.pumpWidget(wrap(Builder(builder: (ctx) {
        return ConfirmationButton(ctx, () => taps++, 'go',
            const TextStyle(fontSize: 20));
      })));
      await tester.tap(find.byType(TextButton));
      await tester.pump();
      expect(taps, 1);
    });

    testWidgets('CancelButton invokes function on tap', (tester) async {
      var taps = 0;
      await tester.pumpWidget(wrap(Builder(builder: (ctx) {
        return CancelButton(ctx, () => taps++, 'cancel',
            const TextStyle(fontSize: 20));
      })));
      await tester.tap(find.byType(TextButton));
      await tester.pump();
      expect(taps, 1);
    });

    testWidgets('ResetButton invokes function on tap', (tester) async {
      var taps = 0;
      await tester.pumpWidget(wrap(Builder(builder: (ctx) {
        return ResetButton(ctx, () => taps++, 'reset',
            const TextStyle(fontSize: 20));
      })));
      await tester.tap(find.byType(TextButton));
      await tester.pump();
      expect(taps, 1);
    });

    testWidgets('myTextButton renders icon and invokes callback', (tester) async {
      var taps = 0;
      await tester.pumpWidget(wrap(myTextButton(
        () => taps++,
        Icons.star,
        Colors.blue,
      )));
      expect(find.byIcon(Icons.star), findsOneWidget);
      await tester.tap(find.byType(TextButton));
      await tester.pump();
      expect(taps, 1);
    });
  });

  group('button width breakpoints', () {
    testWidgets('ConfirmationButton uses 0.6 of width when <= 1000',
        (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      Container? container;
      await tester.pumpWidget(wrap(Builder(builder: (ctx) {
        container = ConfirmationButton(
            ctx, () {}, 'x', const TextStyle(fontSize: 18));
        return container!;
      })));
      expect(container, isNotNull);
      // 400 * 0.6 = 240
      final width = (container!.constraints?.maxWidth) ??
          tester.getSize(find.byType(Container)).width;
      expect(width, closeTo(240, 0.01));
    });

    testWidgets('ConfirmationButton uses fixed 600 when width > 1000',
        (tester) async {
      tester.view.physicalSize = const Size(1200, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      Container? container;
      await tester.pumpWidget(wrap(Builder(builder: (ctx) {
        container = ConfirmationButton(
            ctx, () {}, 'x', const TextStyle(fontSize: 18));
        return container!;
      })));
      final width = container!.constraints?.maxWidth ?? 0;
      expect(width, 600);
    });
  });

  group('myImage', () {
    testWidgets('returns Image with screen-relative size', (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      Image? img;
      await tester.pumpWidget(wrap(Builder(builder: (ctx) {
        img = myImage('assets/does_not_exist.png', ctx, 0.5, 0.25);
        return const SizedBox.shrink();
      })));
      expect(img, isNotNull);
      expect(img!.width, 200);
      expect(img!.height, 200);
    });
  });

  group('color constants', () {
    test('exposed colors are defined', () {
      expect(primaryPurple, isA<Color>());
      expect(appWhite, isA<Color>());
      expect(appBlue, isA<Color>());
      expect(appGreen, isA<Color>());
      expect(lightPurple, isA<Color>());
      expect(lightGray, isA<Color>());
      expect(darkGray, isA<Color>());
      expect(backgroundGray, isA<Color>());
      expect(pdfpurple, isA<Color>());
    });

    test('mainpageListsAddIcon uses primary purple', () {
      expect(mainpageListsAddIcon.color, primaryPurple);
      expect(mainpageListsAddIcon.icon, Icons.add);
    });
  });
}
