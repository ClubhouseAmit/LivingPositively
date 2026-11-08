import 'package:flutter/material.dart' show Icons;
import 'package:flutter/widgets.dart' hide Text;
import 'package:flutter_test/flutter_test.dart';
import 'package:mazilon/design_system/tokens/button_sizes.dart';
import 'package:mazilon/design_system/tokens/color_tokens.dart';
import 'package:mazilon/design_system/tokens/colors.dart';
import 'package:mazilon/design_system/widgets/lp_button.dart';

/// No `MaterialApp` or `Theme`: the LP buttons need only `Directionality`
/// and the color tokens above them. [colors] picks the mode.
Widget _host(
  Widget child, {
  AppColorTokens colors = AppColorTokens.light,
  TextDirection direction = TextDirection.ltr,
}) {
  return Directionality(
    textDirection: direction,
    child: AppColorScope(
      tokens: colors,
      child: Center(child: child),
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
      expect(_decorationIn(tester, LpButton).color, AppColors.surfaceSunken);
    });

    testWidgets('fails loudly with no AppColorScope above', (tester) async {
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: LpButton(label: 'Go', onPressed: () {}),
        ),
      );
      expect(tester.takeException(), isAssertionError);
    });

    testWidgets('a screen reader can activate it', (tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      var taps = 0;
      await tester.pumpWidget(
        _host(LpButton(label: 'Go', onPressed: () => taps++)),
      );
      tester.semantics.tap(find.semantics.byLabel('Go'));
      expect(taps, 1);
      handle.dispose();
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

    testWidgets('emphasis uses the dark tokens under a dark theme', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          LpButton(
            label: 'Go',
            onPressed: () {},
            variant: LpButtonVariant.emphasis,
            icon: Icons.arrow_back,
          ),
          colors: AppColorTokens.dark,
        ),
      );
      expect(
        _decorationIn(tester, LpButton).color,
        AppColors.darkAccentPrimary,
      );
      expect(_iconColorIn(tester, LpButton), AppColors.darkSurfaceWhite);
    });

    testWidgets('emphasis shows the pressed fill while held', (tester) async {
      await tester.pumpWidget(
        _host(
          LpButton(
            label: 'Go',
            onPressed: () {},
            variant: LpButtonVariant.emphasis,
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

    testWidgets('raised uses the raised-high fill under a dark theme', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          LpButton(
            label: 'Go',
            onPressed: () {},
            variant: LpButtonVariant.raised,
          ),
          colors: AppColorTokens.dark,
        ),
      );
      expect(
        _decorationIn(tester, LpButton).color,
        AppColors.darkSurfaceRaisedHigh,
      );
    });

    testWidgets('size s pressed keeps the border', (tester) async {
      for (final variant in [LpButtonVariant.primary, LpButtonVariant.raised]) {
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

    testWidgets('raised shows the raised-highest fill while held', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          LpButton(
            label: 'Go',
            onPressed: () {},
            variant: LpButtonVariant.raised,
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
        greaterThanOrEqualTo(LpButtonSizes.minTapTarget),
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

  group('LpButton.icon', () {
    testWidgets('announces its label and fires onPressed', (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        _host(
          LpButton.icon(
            icon: Icons.arrow_back,
            semanticLabel: 'Back',
            onPressed: () => taps++,
          ),
        ),
      );
      expect(find.bySemanticsLabel('Back'), findsOneWidget);
      await tester.tap(find.byType(LpButton));
      expect(taps, 1);
    });

    testWidgets('xs keeps a 48 tap area', (tester) async {
      await tester.pumpWidget(
        _host(
          LpButton.icon(
            icon: Icons.arrow_back,
            semanticLabel: 'Back',
            onPressed: () {},
            size: LpIconSize.xs,
          ),
        ),
      );
      expect(
        tester.getSize(find.byType(LpButton)),
        const Size.square(LpButtonSizes.minTapTarget),
      );
    });

    testWidgets('pressed primary gets a fill and the secondary icon color', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          LpButton.icon(
            icon: Icons.arrow_back,
            semanticLabel: 'Back',
            onPressed: () {},
          ),
        ),
      );
      expect(_decorationIn(tester, LpButton).color, isNull);
      expect(_iconColorIn(tester, LpButton), AppColors.contentPrimary);
      final TestGesture gesture = await tester.startGesture(
        tester.getCenter(find.byType(LpButton)),
      );
      await tester.pump();
      expect(
        _decorationIn(tester, LpButton).color,
        AppColors.surfaceSunken,
      );
      expect(_iconColorIn(tester, LpButton), AppColors.contentSecondary);
      await gesture.up();
    });
  });

  group('LpButtonVariant.text', () {
    testWidgets('fires onPressed and keeps a 48 tap area', (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        _host(
          LpButton(
            variant: LpButtonVariant.text,
            label: 'Not now',
            onPressed: () => taps++,
            icon: Icons.add,
          ),
        ),
      );
      await tester.tap(find.text('Not now'));
      expect(taps, 1);
      expect(
        tester.getSize(find.byType(LpButton)).height,
        greaterThanOrEqualTo(LpButtonSizes.minTapTarget),
      );
    });

    testWidgets('disabled uses the tertiary color and ignores taps', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          const LpButton(
            variant: LpButtonVariant.text,
            label: 'Not now',
            onPressed: null,
            icon: Icons.add,
          ),
        ),
      );
      await tester.tap(find.text('Not now'), warnIfMissed: false);
      expect(_iconColorIn(tester, LpButton), AppColors.contentTertiary);
    });

    testWidgets('hugs its content and dims the label while held', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          LpButton(
            variant: LpButtonVariant.text,
            label: 'Not now',
            onPressed: () {},
            icon: Icons.add,
          ),
        ),
      );
      expect(
        tester.getSize(find.byType(LpButton)).width,
        lessThan(tester.getSize(find.byType(Directionality)).width),
        reason: 'ignores fullWidth, which defaults to true',
      );
      final TestGesture gesture = await tester.startGesture(
        tester.getCenter(find.text('Not now')),
      );
      await tester.pump();
      expect(_iconColorIn(tester, LpButton), AppColors.contentSecondary);
      await gesture.up();
    });
  });
}
