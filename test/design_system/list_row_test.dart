import 'package:flutter/material.dart' show Icons;
import 'package:flutter/widgets.dart' hide Text;
import 'package:flutter/rendering.dart' show RenderParagraph;
import 'package:flutter_test/flutter_test.dart';
import 'package:mazilon/design_system/tokens/color_tokens.dart';
import 'package:mazilon/design_system/tokens/colors.dart';
import 'package:mazilon/design_system/widgets/list_row.dart';
import 'package:mazilon/design_system/widgets/lp_button.dart';
import 'package:mazilon/design_system/widgets/lp_checkbox.dart';

/// No `MaterialApp` or `Theme`: only `Directionality` and the color tokens.
Widget _host(
  Widget child, {
  AppColorTokens colors = AppColorTokens.light,
  TextDirection direction = TextDirection.ltr,
}) {
  return Directionality(
    textDirection: direction,
    child: AppColorScope(
      tokens: colors,
      child: Center(child: SizedBox(width: 350, child: child)),
    ),
  );
}

BoxDecoration _decoration(WidgetTester tester) {
  return tester
          .widget<DecoratedBox>(
            find
                .descendant(
                  of: find.byType(ListRow),
                  matching: find.byType(DecoratedBox),
                )
                .first,
          )
          .decoration
      as BoxDecoration;
}

void main() {
  testWidgets('tapping the title or the box toggles, with no Material', (
    tester,
  ) async {
    final values = <bool>[];
    await tester.pumpWidget(
      _host(ListRow(title: 'Breathe', checked: false, onChanged: values.add)),
    );
    await tester.tap(find.text('Breathe'));
    await tester.tap(find.byType(LpCheckbox));
    expect(values, [true, true]);
  });

  testWidgets('a checked row reports false when tapped', (tester) async {
    final values = <bool>[];
    await tester.pumpWidget(
      _host(ListRow(title: 'Breathe', checked: true, onChanged: values.add)),
    );
    await tester.tap(find.text('Breathe'));
    expect(values, [false]);
  });

  testWidgets('tapping the action does not toggle the row', (tester) async {
    final values = <bool>[];
    var actions = 0;
    await tester.pumpWidget(
      _host(
        ListRow(
          title: 'Breathe',
          checked: false,
          onChanged: values.add,
          actionIcon: Icons.graphic_eq,
          actionLabel: 'Play',
          onAction: () => actions++,
        ),
      ),
    );
    await tester.tap(find.byType(LpButton));
    expect(actions, 1);
    expect(values, isEmpty);
  });

  testWidgets('a screen reader hears one checkbox, and the action apart', (
    tester,
  ) async {
    final SemanticsHandle handle = tester.ensureSemantics();
    final values = <bool>[];
    await tester.pumpWidget(
      _host(
        ListRow(
          title: 'Breathe',
          checked: true,
          onChanged: values.add,
          actionIcon: Icons.graphic_eq,
          actionLabel: 'Play',
          onAction: () {},
        ),
      ),
    );
    expect(
      tester.getSemantics(find.bySemanticsLabel('Breathe')),
      matchesSemantics(
        label: 'Breathe',
        hasCheckedState: true,
        isChecked: true,
        hasEnabledState: true,
        isEnabled: true,
        hasTapAction: true,
      ),
    );
    expect(find.bySemanticsLabel('Breathe'), findsOneWidget);
    expect(find.bySemanticsLabel('Play'), findsOneWidget);
    tester.semantics.tap(find.semantics.byLabel('Breathe'));
    expect(values, [false]);
    handle.dispose();
  });

  testWidgets('is a raised card with a hairline border and 17px title', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(ListRow(title: 'Breathe', checked: false, onChanged: (_) {})),
    );
    final BoxDecoration d = _decoration(tester);
    expect(d.color, AppColors.surfaceRaised);
    expect((d.border! as Border).top.color, AppColors.effectHairline);
    expect((d.border! as Border).top.width, ListRow.border);
    expect(d.borderRadius, BorderRadius.circular(ListRow.radius));
    final RenderParagraph title = tester.renderObject(find.byType(RichText));
    expect(title.text.style!.fontSize, 17);
    expect(title.text.style!.color, AppColors.contentPrimary);
    expect(
      tester.widget<LpCheckbox>(find.byType(LpCheckbox)).variant,
      LpCheckboxVariant.rounded,
    );
  });

  testWidgets('is Figma\'s 57 high with or without the action', (
    tester,
  ) async {
    for (final bool withAction in [false, true]) {
      await tester.pumpWidget(
        _host(
          ListRow(
            title: 'Breathe',
            checked: false,
            onChanged: (_) {},
            actionIcon: withAction ? Icons.graphic_eq : null,
            actionLabel: 'Play',
            onAction: () {},
          ),
        ),
      );
      expect(tester.getSize(find.byType(ListRow)).height, ListRow.height);
    }
  });

  testWidgets('builds the icon button at Figma size s (32, 24 glyph)', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        ListRow(
          title: 'Breathe',
          checked: false,
          onChanged: (_) {},
          actionIcon: Icons.graphic_eq,
          actionLabel: 'Play',
          onAction: () {},
        ),
      ),
    );
    expect(
      tester.widget<LpButton>(find.byType(LpButton)).iconSize,
      LpIconSize.s,
    );
  });

  testWidgets('uses the dark tokens under dark colors', (tester) async {
    await tester.pumpWidget(
      _host(
        ListRow(title: 'Breathe', checked: false, onChanged: (_) {}),
        colors: AppColorTokens.dark,
      ),
    );
    final BoxDecoration d = _decoration(tester);
    expect(d.color, AppColors.darkSurfaceRaised);
    expect((d.border! as Border).top.color, AppColors.darkEffectHairline);
  });

  testWidgets('in RTL the box is on the right and the action on the left', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        ListRow(
          title: 'נשימה',
          checked: false,
          onChanged: (_) {},
          actionIcon: Icons.graphic_eq,
          actionLabel: 'Play',
          onAction: () {},
        ),
        direction: TextDirection.rtl,
      ),
    );
    final double box = tester.getCenter(find.byType(LpCheckbox)).dx;
    final double title = tester.getCenter(find.text('נשימה')).dx;
    final double action = tester.getCenter(find.byType(LpButton)).dx;
    expect(box, greaterThan(title));
    expect(title, greaterThan(action));
  });
}
