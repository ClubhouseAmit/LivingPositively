import 'package:flutter/widgets.dart' hide Text;
import 'package:flutter_test/flutter_test.dart';
import 'package:mazilon/design_system/tokens/color_tokens.dart';
import 'package:mazilon/design_system/tokens/colors.dart';
import 'package:mazilon/design_system/widgets/text.dart';
import 'package:mazilon/design_system/widgets/chip.dart';

/// No `MaterialApp` or `Theme`: only `Directionality` and the color tokens.
Widget _host(Widget child, {AppColorTokens colors = AppColorTokens.light}) {
  return Directionality(
    textDirection: TextDirection.ltr,
    child: AppColorScope(
      tokens: colors,
      child: Center(child: child),
    ),
  );
}

BoxDecoration _decoration(WidgetTester tester) {
  return tester
          .widget<DecoratedBox>(
            find.descendant(
              of: find.byType(Chip),
              matching: find.byType(DecoratedBox),
            ),
          )
          .decoration
      as BoxDecoration;
}

Color? _labelColor(WidgetTester tester) =>
    tester.widget<Text>(find.byType(Text)).color;

void main() {
  testWidgets('fires onPressed with no Material ancestor', (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      _host(Chip(label: 'Walk', pressed: false, onPressed: () => taps++)),
    );
    await tester.tap(find.text('Walk'));
    expect(taps, 1);
  });

  testWidgets('fails loudly with no AppColorScope above', (tester) async {
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Chip(label: 'Walk', pressed: false, onPressed: () {}),
      ),
    );
    expect(tester.takeException(), isAssertionError);
  });

  testWidgets('a screen reader hears toggled and can press it', (
    tester,
  ) async {
    final SemanticsHandle handle = tester.ensureSemantics();
    var taps = 0;
    await tester.pumpWidget(
      _host(Chip(label: 'Walk', pressed: true, onPressed: () => taps++)),
    );
    expect(
      tester.getSemantics(find.byType(Chip)),
      matchesSemantics(
        label: 'Walk',
        isButton: true,
        hasToggledState: true,
        isToggled: true,
        hasTapAction: true,
      ),
    );
    tester.semantics.tap(find.semantics.byLabel('Walk'));
    expect(taps, 1);
    handle.dispose();
  });

  testWidgets('idle is raised with a hairline border', (tester) async {
    await tester.pumpWidget(
      _host(Chip(label: 'Walk', pressed: false, onPressed: () {})),
    );
    final BoxDecoration d = _decoration(tester);
    expect(d.color, AppColors.surfaceRaised);
    expect((d.border! as Border).top.color, AppColors.effectHairline);
    expect(_labelColor(tester), AppColors.contentPrimary);
  });

  testWidgets('pressed uses the dark accent tokens under dark colors', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        Chip(label: 'Walk', pressed: true, onPressed: () {}),
        colors: AppColorTokens.dark,
      ),
    );
    final BoxDecoration d = _decoration(tester);
    expect(d.color, AppColors.darkAccentPrimary);
    expect((d.border! as Border).top.color, AppColors.darkAccentPrimary);
    expect(_labelColor(tester), AppColors.darkSurfaceWhite);
  });

  testWidgets('takes only its Figma height, no extra tap area', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(Chip(label: 'Walk', pressed: false, onPressed: () {})),
    );
    final double drawn = tester.getSize(find.byType(DecoratedBox)).height;
    expect(drawn, greaterThanOrEqualTo(Chip.height));
    expect(tester.getSize(find.byType(Chip)).height, drawn);
  });
}
