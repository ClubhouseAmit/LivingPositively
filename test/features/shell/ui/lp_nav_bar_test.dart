import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mazilon/design_system/tokens/color_tokens.dart';
import 'package:mazilon/design_system/tokens/colors.dart';
import 'package:mazilon/features/shell/ui/lp_nav_bar.dart';

// Any IconData will do; the test checks which one is drawn, not its glyph.
const IconData _home = IconData(0xe001);
const IconData _homeFilled = IconData(0xe002);
const IconData _plan = IconData(0xe003);
const IconData _tools = IconData(0xe004);

const List<LpNavTab> _tabs = [
  LpNavTab(icon: _home, selectedIcon: _homeFilled, label: 'Home'),
  LpNavTab(icon: _plan, label: 'My Plan'),
  LpNavTab(icon: _tools, label: 'Tools'),
];

/// No `MaterialApp` or `Theme`: only `Directionality` and the color tokens.
Widget _host({
  int selected = 0,
  ValueChanged<int>? onSelected,
  AppColorTokens colors = AppColorTokens.light,
  TextDirection direction = TextDirection.ltr,
}) {
  return Directionality(
    textDirection: direction,
    child: AppColorScope(
      tokens: colors,
      child: Align(
        alignment: Alignment.bottomCenter,
        child: SizedBox(
          width: 366,
          child: LpNavBar(
            tabs: _tabs,
            selectedIndex: selected,
            onSelected: onSelected ?? (_) {},
          ),
        ),
      ),
    ),
  );
}

/// The icon pill fills, one per tab, in tab order.
List<Color?> _pills(WidgetTester tester) => [
  for (final Element e
      in find
          .descendant(
            of: find.byType(LpNavBar),
            matching: find.byType(DecoratedBox),
          )
          .evaluate()
          .skip(1)) // the bar itself
    ((e.widget as DecoratedBox).decoration as ShapeDecoration).color,
];

Color? _barFill(WidgetTester tester) =>
    ((tester
                    .widgetList<DecoratedBox>(
                      find.descendant(
                        of: find.byType(LpNavBar),
                        matching: find.byType(DecoratedBox),
                      ),
                    )
                    .first)
                .decoration
            as ShapeDecoration)
        .color;

Color? _labelColor(WidgetTester tester, String label) => tester
    .widget<RichText>(
      find.descendant(
        of: find.text(label),
        matching: find.byType(RichText),
      ),
    )
    .text
    .style
    ?.color;

void main() {
  testWidgets('a tap reports the tab index with no Material ancestor', (
    tester,
  ) async {
    int? tapped;
    await tester.pumpWidget(_host(onSelected: (i) => tapped = i));
    await tester.tap(find.text('Tools'));
    expect(tapped, 2);
    await tester.tap(find.text('Home'));
    expect(tapped, 0);
  });

  testWidgets('light: frosted bar, selected tab in a content/primary pill', (
    tester,
  ) async {
    await tester.pumpWidget(_host(selected: 1));
    expect(_barFill(tester), AppColors.surfaceRaisedHighest90);
    expect(_pills(tester), [null, AppColors.contentPrimary12, null]);
    expect(_labelColor(tester, 'My Plan'), AppColors.contentPrimary);
    expect(_labelColor(tester, 'Home'), AppColors.contentSecondary);
  });

  testWidgets('dark uses the dark tokens', (tester) async {
    await tester.pumpWidget(_host(colors: AppColorTokens.dark));
    expect(_barFill(tester), AppColors.darkSurfaceRaisedHighest90);
    expect(_pills(tester), [AppColors.darkContentPrimary12, null, null]);
    expect(_labelColor(tester, 'Home'), AppColors.darkContentPrimary);
    expect(_labelColor(tester, 'Tools'), AppColors.darkContentSecondary);
  });

  testWidgets('the selected tab shows its filled icon, if it has one', (
    tester,
  ) async {
    await tester.pumpWidget(_host());
    expect(find.byIcon(_homeFilled), findsOneWidget);
    expect(find.byIcon(_home), findsNothing);
    await tester.pumpWidget(_host(selected: 1));
    expect(find.byIcon(_home), findsOneWidget);
    expect(find.byIcon(_plan), findsOneWidget);
  });

  testWidgets('tabs share the width, and each is at least 48 high', (
    tester,
  ) async {
    await tester.pumpWidget(_host());
    for (final LpNavTab tab in _tabs) {
      final Size size = tester.getSize(
        find.ancestor(
          of: find.text(tab.label),
          matching: find.byType(GestureDetector),
        ),
      );
      expect(size.width, (366 - 16) / 3);
      expect(size.height, greaterThanOrEqualTo(48));
    }
  });

  testWidgets('right-to-left puts the first tab on the right', (tester) async {
    await tester.pumpWidget(_host(direction: TextDirection.rtl));
    expect(
      tester.getCenter(find.text('Home')).dx,
      greaterThan(tester.getCenter(find.text('Tools')).dx),
    );
  });

  testWidgets('a screen reader hears each tab and which one is selected', (
    tester,
  ) async {
    final SemanticsHandle handle = tester.ensureSemantics();
    int? tapped;
    await tester.pumpWidget(_host(selected: 1, onSelected: (i) => tapped = i));
    expect(
      tester.getSemantics(find.text('My Plan')),
      matchesSemantics(
        label: 'My Plan',
        isButton: true,
        hasSelectedState: true,
        isSelected: true,
        hasTapAction: true,
      ),
    );
    expect(
      tester.getSemantics(find.text('Home')),
      matchesSemantics(
        label: 'Home',
        isButton: true,
        hasSelectedState: true,
        hasTapAction: true,
      ),
    );
    tester.semantics.tap(find.semantics.byLabel('Tools'));
    expect(tapped, 2);
    handle.dispose();
  });

  testWidgets('fails loudly with no AppColorScope above', (tester) async {
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: LpNavBar(tabs: _tabs, selectedIndex: 0, onSelected: (_) {}),
      ),
    );
    expect(tester.takeException(), isAssertionError);
  });
}
