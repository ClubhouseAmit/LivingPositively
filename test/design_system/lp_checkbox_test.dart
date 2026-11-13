import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mazilon/design_system/tokens/color_tokens.dart';
import 'package:mazilon/design_system/tokens/colors.dart';
import 'package:mazilon/design_system/widgets/lp_checkbox.dart';

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
              of: find.byType(LpCheckbox),
              matching: find.byType(DecoratedBox),
            ),
          )
          .decoration
      as BoxDecoration;
}

Finder _check() => find.descendant(
  of: find.byType(LpCheckbox),
  matching: find.byType(CustomPaint),
);

void main() {
  testWidgets('a tap flips the value with no Material ancestor', (
    tester,
  ) async {
    bool? changed;
    await tester.pumpWidget(
      _host(
        LpCheckbox(
          value: false,
          onChanged: (v) => changed = v,
          semanticLabel: 'Walk',
        ),
      ),
    );
    await tester.tap(find.byType(LpCheckbox));
    expect(changed, isTrue);
  });

  testWidgets('fails loudly with no AppColorScope above', (tester) async {
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: LpCheckbox(value: false, onChanged: (_) {}, semanticLabel: 'x'),
      ),
    );
    expect(tester.takeException(), isAssertionError);
  });

  testWidgets('a screen reader hears checked and can flip it', (tester) async {
    final SemanticsHandle handle = tester.ensureSemantics();
    bool? changed;
    await tester.pumpWidget(
      _host(
        LpCheckbox(
          value: true,
          onChanged: (v) => changed = v,
          semanticLabel: 'Walk',
        ),
      ),
    );
    expect(
      tester.getSemantics(find.byType(LpCheckbox)),
      matchesSemantics(
        label: 'Walk',
        hasCheckedState: true,
        isChecked: true,
        hasEnabledState: true,
        isEnabled: true,
        hasTapAction: true,
      ),
    );
    tester.semantics.tap(find.semantics.byLabel('Walk'));
    expect(changed, isFalse);
    handle.dispose();
  });

  testWidgets('idle square has a content border and no check', (tester) async {
    await tester.pumpWidget(
      _host(LpCheckbox(value: false, onChanged: (_) {}, semanticLabel: 'x')),
    );
    final BoxDecoration d = _decoration(tester);
    expect(d.color, isNull);
    expect((d.border! as Border).top.color, AppColors.contentPrimary);
    expect(_check(), findsNothing);
    expect(tester.getSize(find.byType(DecoratedBox)), const Size.square(28));
  });

  testWidgets('idle rounded has a hairline border at 24', (tester) async {
    await tester.pumpWidget(
      _host(
        LpCheckbox(
          value: false,
          onChanged: (_) {},
          semanticLabel: 'x',
          variant: LpCheckboxVariant.rounded,
        ),
      ),
    );
    expect(
      (_decoration(tester).border! as Border).top.color,
      AppColors.effectHairline,
    );
    expect(tester.getSize(find.byType(DecoratedBox)), const Size.square(24));
  });

  testWidgets('checked uses the dark tokens under dark colors', (tester) async {
    await tester.pumpWidget(
      _host(
        LpCheckbox(value: true, onChanged: (_) {}, semanticLabel: 'x'),
        colors: AppColorTokens.dark,
      ),
    );
    expect(_decoration(tester).color, AppColors.darkContentPrimary);
    expect(_check(), findsOneWidget);
  });

  for (final (variant, size) in [
    (LpCheckboxVariant.square, LpCheckbox.squareSize),
    (LpCheckboxVariant.rounded, LpCheckbox.roundedSize),
  ]) {
    testWidgets('${variant.name} takes only its Figma size', (tester) async {
      await tester.pumpWidget(
        _host(
          LpCheckbox(
            value: false,
            onChanged: (_) {},
            semanticLabel: 'x',
            variant: variant,
          ),
        ),
      );
      expect(tester.getSize(find.byType(LpCheckbox)), Size.square(size));
    });
  }

  testWidgets('rounded is drawn as a circle', (tester) async {
    await tester.pumpWidget(
      _host(
        LpCheckbox(
          value: true,
          onChanged: (_) {},
          semanticLabel: 'x',
          variant: LpCheckboxVariant.rounded,
        ),
      ),
    );
    expect(_decoration(tester).shape, BoxShape.circle);
  });
}
