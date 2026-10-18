import 'package:flutter/material.dart' show Brightness, Icons, Theme, ThemeData;
import 'package:flutter/widgets.dart' hide Text;
import 'package:flutter_test/flutter_test.dart';
import 'package:mazilon/design_system/tokens/colors.dart';
import 'package:mazilon/design_system/widgets/lp_button.dart';
import 'package:mazilon/design_system/widgets/lp_icon_button.dart';
import 'package:mazilon/design_system/widgets/lp_text_button.dart';
import 'package:mazilon/design_system/widgets/lp_pressable.dart';

/// No `MaterialApp`: the LP buttons must work with only `Directionality`
/// above them. [brightness] adds a bare `Theme` for the dark-mode cases.
Widget _host(
  Widget child, {
  Brightness? brightness,
  TextDirection direction = TextDirection.ltr,
}) {
  final Widget centered = Center(child: child);
  return Directionality(
    textDirection: direction,
    child: brightness == null
        ? centered
        : Theme(
            data: ThemeData(brightness: brightness),
            child: centered,
          ),
  );
}

BoxDecoration _decorationIn(WidgetTester tester, Type buttonType) {
  return tester
          .widget<DecoratedBox>(
            find.descendant(
              of: find.byType(buttonType),
              matching: find.byType(DecoratedBox),
            ),
          )
          .decoration
      as BoxDecoration;
}

Color? _iconColorIn(WidgetTester tester, Type buttonType) {
  return tester
      .widget<Icon>(
        find.descendant(
          of: find.byType(buttonType),
          matching: find.byType(Icon),
        ),
      )
      .color;
}

void main() {
  group('LpButton', () {
    testWidgets('fires onPressed with no Material ancestor', (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        _host(LpButton(label: 'Go', onPressed: () => taps++)),
      );
      await tester.tap(find.text('Go'));
      expect(taps, 1);
      expect(
        _decorationIn(tester, LpButton).color,
        AppColors.surfaceSunken,
        reason: 'light theme by default when no Theme is above',
      );
    });

    testWidgets('disabled ignores taps and uses the disabled fill', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(const LpButton(label: 'Go', onPressed: null)),
      );
      await tester.tap(find.text('Go'), warnIfMissed: false);
      expect(_decorationIn(tester, LpButton).color, AppColors.surfaceDisabled);
      expect(_decorationIn(tester, LpButton).border, isNull);
    });

    testWidgets('shows the pressed fill only while held', (tester) async {
      await tester.pumpWidget(
        _host(LpButton(label: 'Go', onPressed: () {})),
      );
      final TestGesture gesture = await tester.startGesture(
        tester.getCenter(find.text('Go')),
      );
      await tester.pump();
      expect(
        _decorationIn(tester, LpButton).color,
        AppColors.surfaceRaisedHighest90,
      );
      await gesture.up();
      await tester.pump();
      expect(_decorationIn(tester, LpButton).color, AppColors.surfaceSunken);
    });

    testWidgets('purple uses the dark tokens under a dark theme', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          LpButton(
            label: 'Go',
            onPressed: () {},
            variant: LpButtonVariant.purple,
            icon: Icons.arrow_back,
          ),
          brightness: Brightness.dark,
        ),
      );
      expect(
        _decorationIn(tester, LpButton).color,
        AppColors.darkAccentPrimary,
      );
      expect(_iconColorIn(tester, LpButton), AppColors.darkSurfaceWhite);
    });

    testWidgets('purple shows the pressed fill while held', (tester) async {
      await tester.pumpWidget(
        _host(
          LpButton(
            label: 'Go',
            onPressed: () {},
            variant: LpButtonVariant.purple,
          ),
        ),
      );
      final TestGesture gesture = await tester.startGesture(
        tester.getCenter(find.text('Go')),
      );
      await tester.pump();
      expect(_decorationIn(tester, LpButton).color, AppColors.accentPressed);
      await gesture.up();
      await tester.pump();
      expect(_decorationIn(tester, LpButton).color, AppColors.accentPrimary);
    });

    testWidgets('white uses the raised-high fill under a dark theme', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          LpButton(
            label: 'Go',
            onPressed: () {},
            variant: LpButtonVariant.white,
          ),
          brightness: Brightness.dark,
        ),
      );
      expect(
        _decorationIn(tester, LpButton).color,
        AppColors.darkSurfaceRaisedHigh,
      );
    });

    testWidgets('size s pressed keeps the border', (tester) async {
      for (final variant in [LpButtonVariant.primary, LpButtonVariant.white]) {
        await tester.pumpWidget(
          _host(
            LpButton(
              label: 'Go',
              onPressed: () {},
              variant: variant,
              size: LpButtonSize.s,
            ),
          ),
        );
        final TestGesture gesture = await tester.startGesture(
          tester.getCenter(find.text('Go')),
        );
        await tester.pump();
        expect(
          _decorationIn(tester, LpButton).border,
          isNotNull,
          reason: '$variant',
        );
        await gesture.up();
        await tester.pump();
      }
    });

    testWidgets('white shows the raised-highest fill while held', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          LpButton(
            label: 'Go',
            onPressed: () {},
            variant: LpButtonVariant.white,
          ),
        ),
      );
      expect(
        _decorationIn(tester, LpButton).color,
        AppColors.surfaceRaisedHigh,
      );
      final TestGesture gesture = await tester.startGesture(
        tester.getCenter(find.text('Go')),
      );
      await tester.pump();
      expect(
        _decorationIn(tester, LpButton).color,
        AppColors.surfaceRaisedHighest,
      );
      await gesture.up();
    });

    testWidgets('size s keeps a 48 tap area', (tester) async {
      await tester.pumpWidget(
        _host(
          LpButton(
            label: 'Go',
            onPressed: () {},
            size: LpButtonSize.s,
            fullWidth: false,
          ),
        ),
      );
      expect(
        tester.getSize(find.byType(LpButton)).height,
        greaterThanOrEqualTo(LpPressable.minTapTarget),
      );
      expect(
        tester.getSize(find.byType(DecoratedBox)).height,
        LpButtonSizes.heightS,
      );
    });

    testWidgets('icon sits on the start side in RTL', (tester) async {
      await tester.pumpWidget(
        _host(
          LpButton(label: 'Go', onPressed: () {}, icon: Icons.arrow_back),
          direction: TextDirection.rtl,
        ),
      );
      expect(
        tester.getCenter(find.byType(Icon)).dx,
        greaterThan(tester.getCenter(find.text('Go')).dx),
      );
    });
  });

  group('LpIconButton', () {
    testWidgets('announces its label and fires onPressed', (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        _host(
          LpIconButton(
            icon: Icons.arrow_back,
            semanticLabel: 'Back',
            onPressed: () => taps++,
          ),
        ),
      );
      expect(find.bySemanticsLabel('Back'), findsOneWidget);
      await tester.tap(find.byType(LpIconButton));
      expect(taps, 1);
    });

    testWidgets('xs keeps a 48 tap area', (tester) async {
      await tester.pumpWidget(
        _host(
          LpIconButton(
            icon: Icons.arrow_back,
            semanticLabel: 'Back',
            onPressed: () {},
            size: LpIconButtonSize.xs,
          ),
        ),
      );
      expect(
        tester.getSize(find.byType(LpIconButton)),
        const Size.square(LpPressable.minTapTarget),
      );
    });

    testWidgets('pressed primary gets a fill and the secondary icon color', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          LpIconButton(
            icon: Icons.arrow_back,
            semanticLabel: 'Back',
            onPressed: () {},
          ),
        ),
      );
      expect(_decorationIn(tester, LpIconButton).color, isNull);
      expect(_iconColorIn(tester, LpIconButton), AppColors.contentPrimary);
      final TestGesture gesture = await tester.startGesture(
        tester.getCenter(find.byType(LpIconButton)),
      );
      await tester.pump();
      expect(
        _decorationIn(tester, LpIconButton).color,
        AppColors.surfaceSunken,
      );
      expect(_iconColorIn(tester, LpIconButton), AppColors.contentSecondary);
      await gesture.up();
    });
  });

  group('LpTextButton', () {
    testWidgets('fires onPressed and keeps a 48 tap area', (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        _host(
          LpTextButton(
            label: 'Not now',
            onPressed: () => taps++,
            icon: Icons.add,
          ),
        ),
      );
      await tester.tap(find.text('Not now'));
      expect(taps, 1);
      expect(
        tester.getSize(find.byType(LpTextButton)).height,
        greaterThanOrEqualTo(LpPressable.minTapTarget),
      );
    });

    testWidgets('disabled uses the tertiary color and ignores taps', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          const LpTextButton(
            label: 'Not now',
            onPressed: null,
            icon: Icons.add,
          ),
        ),
      );
      await tester.tap(find.text('Not now'), warnIfMissed: false);
      expect(_iconColorIn(tester, LpTextButton), AppColors.contentTertiary);
    });
  });
}
