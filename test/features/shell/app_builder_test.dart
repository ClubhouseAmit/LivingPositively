import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mazilon/design_system/tokens/colors.dart';
import 'package:mazilon/design_system/widgets/lp_button.dart';
import 'package:mazilon/features/shell/ui/app_builder.dart';

/// The full path: `MaterialApp.themeMode` → [appBuilder] → an LP widget's
/// colors, the way `main.dart` wires both of its app roots.
Widget _app(ThemeMode mode) => MaterialApp(
  builder: appBuilder,
  theme: ThemeData(brightness: Brightness.light),
  darkTheme: ThemeData(brightness: Brightness.dark),
  themeMode: mode,
  themeAnimationDuration: Duration.zero,
  home: Center(
    child: LpButton(label: 'Go', onPressed: () {}),
  ),
);

Color? _fill(WidgetTester tester) =>
    (tester
                .widget<DecoratedBox>(
                  find.descendant(
                    of: find.byType(LpButton),
                    matching: find.byType(DecoratedBox),
                  ),
                )
                .decoration
            as BoxDecoration)
        .color;

void main() {
  testWidgets('a light app gives LP widgets the light tokens', (tester) async {
    await tester.pumpWidget(_app(ThemeMode.light));
    expect(_fill(tester), AppColors.surfaceSunken);
  });

  testWidgets('a dark app gives LP widgets the dark tokens', (tester) async {
    await tester.pumpWidget(_app(ThemeMode.dark));
    expect(_fill(tester), AppColors.darkSurfaceSunken);
  });

  testWidgets('switching the mode mid-session recolors at once', (
    tester,
  ) async {
    await tester.pumpWidget(_app(ThemeMode.light));
    await tester.pumpWidget(_app(ThemeMode.dark));
    expect(_fill(tester), AppColors.darkSurfaceSunken);
  });
}
