import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mazilon/design_system/tokens/color_tokens.dart';
import 'package:mazilon/design_system/tokens/colors.dart';
import 'package:mazilon/design_system/widgets/lp_switch.dart';

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
      child: Center(child: child),
    ),
  );
}

LpSwitch _switch({bool value = false, ValueChanged<bool>? onChanged}) =>
    LpSwitch(value: value, onChanged: onChanged, semanticLabel: 'Reminders');

/// The track and knob colors. Container paints the track with a
/// DecoratedBox of its own, so the knob is the last one.
List<Color?> _fills(WidgetTester tester) => [
  for (final Element e
      in find
          .descendant(
            of: find.byType(LpSwitch),
            matching: find.byType(DecoratedBox),
          )
          .evaluate())
    ((e.widget as DecoratedBox).decoration as ShapeDecoration).color,
];

double _opacity(WidgetTester tester) => tester
    .widget<Opacity>(
      find.descendant(
        of: find.byType(LpSwitch),
        matching: find.byType(Opacity),
      ),
    )
    .opacity;

Finder _knob() => find
    .descendant(of: find.byType(LpSwitch), matching: find.byType(DecoratedBox))
    .last;

void main() {
  testWidgets('a tap flips the value with no Material ancestor', (
    tester,
  ) async {
    bool? changed;
    await tester.pumpWidget(_host(_switch(onChanged: (v) => changed = v)));
    await tester.tap(find.byType(LpSwitch));
    expect(changed, isTrue);
  });

  testWidgets('a tap above the 28 track, inside the 48 target, counts', (
    tester,
  ) async {
    bool? changed;
    await tester.pumpWidget(
      _host(_switch(value: true, onChanged: (v) => changed = v)),
    );
    expect(tester.getSize(find.byType(LpSwitch)), const Size(64, 48));
    await tester.tapAt(
      tester.getTopLeft(find.byType(LpSwitch)) + const Offset(32, 4),
    );
    expect(changed, isFalse);
  });

  // That a disabled switch can't be tapped is checked by the screen-reader
  // test below (no tap action).
  testWidgets('disabled on is surface/sunken at half opacity', (
    tester,
  ) async {
    await tester.pumpWidget(_host(_switch(value: true)));
    expect(_opacity(tester), LpSwitch.disabledOpacity);
    expect(_fills(tester), [AppColors.surfaceSunken, AppColors.surfaceWhite]);
  });

  testWidgets('a screen reader hears on and can flip it', (tester) async {
    final SemanticsHandle handle = tester.ensureSemantics();
    bool? changed;
    await tester.pumpWidget(
      _host(_switch(value: true, onChanged: (v) => changed = v)),
    );
    expect(
      tester.getSemantics(find.byType(LpSwitch)),
      matchesSemantics(
        label: 'Reminders',
        hasToggledState: true,
        isToggled: true,
        hasEnabledState: true,
        isEnabled: true,
        hasTapAction: true,
      ),
    );
    tester.semantics.tap(find.semantics.byLabel('Reminders'));
    expect(changed, isFalse);
    handle.dispose();
  });

  testWidgets('a screen reader hears disabled, with no tap action', (
    tester,
  ) async {
    final SemanticsHandle handle = tester.ensureSemantics();
    await tester.pumpWidget(_host(_switch()));
    expect(
      tester.getSemantics(find.byType(LpSwitch)),
      matchesSemantics(
        label: 'Reminders',
        hasToggledState: true,
        hasEnabledState: true,
      ),
    );
    handle.dispose();
  });

  testWidgets('on is accent/primary with the knob at the end', (tester) async {
    await tester.pumpWidget(_host(_switch(value: true, onChanged: (_) {})));
    expect(_fills(tester), [AppColors.accentPrimary, AppColors.surfaceWhite]);
    expect(_opacity(tester), 1);
    expect(tester.getSize(_knob()), const Size(38, 24));
    final Rect track = tester.getRect(find.byType(Container));
    expect(tester.getRect(_knob()).right, track.right - 2);
  });

  testWidgets('off is surface/sunken with the knob at the start', (
    tester,
  ) async {
    await tester.pumpWidget(_host(_switch(onChanged: (_) {})));
    expect(_fills(tester), [AppColors.surfaceSunken, AppColors.surfaceWhite]);
    final Rect track = tester.getRect(find.byType(Container));
    expect(track.size, const Size(64, 28));
    expect(tester.getRect(_knob()).left, track.left + 2);
  });

  testWidgets('on mirrors to the left in right-to-left text', (tester) async {
    await tester.pumpWidget(
      _host(
        _switch(value: true, onChanged: (_) {}),
        direction: TextDirection.rtl,
      ),
    );
    final Rect track = tester.getRect(find.byType(Container));
    expect(tester.getRect(_knob()).left, track.left + 2);
  });

  testWidgets('dark uses the dark tokens, on and off', (tester) async {
    await tester.pumpWidget(
      _host(
        _switch(value: true, onChanged: (_) {}),
        colors: AppColorTokens.dark,
      ),
    );
    expect(_fills(tester), [
      AppColors.darkAccentPrimary,
      AppColors.darkSurfaceWhite,
    ]);
    await tester.pumpWidget(
      _host(_switch(onChanged: (_) {}), colors: AppColorTokens.dark),
    );
    expect(_fills(tester).first, AppColors.darkSurfaceSunken);
    await tester.pumpWidget(
      _host(_switch(value: true), colors: AppColorTokens.dark),
    );
    expect(_fills(tester).first, AppColors.darkSurfaceSunken);
  });

  testWidgets('fails loudly with no AppColorScope above', (tester) async {
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: _switch(onChanged: (_) {}),
      ),
    );
    expect(tester.takeException(), isAssertionError);
  });
}
