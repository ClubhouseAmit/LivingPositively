import 'package:flutter/material.dart' show Icons;
import 'package:flutter/rendering.dart' show RenderParagraph;
import 'package:flutter/widgets.dart' hide Text;
import 'package:flutter_test/flutter_test.dart';
import 'package:mazilon/design_system/tokens/color_tokens.dart';
import 'package:mazilon/design_system/tokens/colors.dart';
import 'package:mazilon/design_system/widgets/lp_alert.dart';

/// No `MaterialApp` or `Theme`: only `Directionality` and the color tokens.
Widget _host(Widget child, {AppColorTokens colors = AppColorTokens.light}) {
  return Directionality(
    textDirection: TextDirection.ltr,
    child: AppColorScope(
      tokens: colors,
      child: Center(child: SizedBox(width: 343, child: child)),
    ),
  );
}

Color _background(WidgetTester tester) {
  final box = tester.widget<DecoratedBox>(
    find
        .descendant(
          of: find.byType(LpAlert),
          matching: find.byType(DecoratedBox),
        )
        .first,
  );
  return (box.decoration as BoxDecoration).color!;
}

Color? _textColor(WidgetTester tester, String text) =>
    tester.renderObject<RenderParagraph>(find.text(text)).text.style?.color;

void main() {
  // Expected values written out from AppColors, not read back from the
  // token sets, so a token wired to the wrong constant fails.
  const expected = {
    (LpAlertVariant.info, false): (
      AppColors.notificationsInfoBg,
      AppColors.contentPrimary,
    ),
    (LpAlertVariant.warning, false): (
      AppColors.notificationsWarningBg,
      AppColors.notificationsWarningContent,
    ),
    (LpAlertVariant.error, false): (
      AppColors.notificationsErrorBg,
      AppColors.notificationsErrorContent,
    ),
    (LpAlertVariant.success, false): (
      AppColors.notificationsSuccessBg,
      AppColors.notificationsSuccessContent,
    ),
    (LpAlertVariant.info, true): (
      AppColors.darkNotificationsInfoBg,
      AppColors.darkContentPrimary,
    ),
    (LpAlertVariant.warning, true): (
      AppColors.darkNotificationsWarningBg,
      AppColors.darkNotificationsWarningContent,
    ),
    (LpAlertVariant.error, true): (
      AppColors.darkNotificationsErrorBg,
      AppColors.darkNotificationsErrorContent,
    ),
    (LpAlertVariant.success, true): (
      AppColors.darkNotificationsSuccessBg,
      AppColors.darkNotificationsSuccessContent,
    ),
  };

  for (final MapEntry(key: (variant, dark), value: (bg, fg))
      in expected.entries) {
    testWidgets('${variant.name} in ${dark ? 'dark' : 'light'}', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          LpAlert(
            variant: variant,
            icon: Icons.info_outline,
            title: 'Title',
            message: 'Message',
            trailingIcon: Icons.chevron_right,
          ),
          colors: dark ? AppColorTokens.dark : AppColorTokens.light,
        ),
      );
      expect(_background(tester), bg);
      expect(_textColor(tester, 'Title'), fg);
      expect(_textColor(tester, 'Message'), fg);
      for (final Icon icon in tester.widgetList<Icon>(find.byType(Icon))) {
        expect(icon.color, fg, reason: '${icon.icon}');
      }
    });
  }

  testWidgets('a screen reader hears title and message as one node', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      _host(
        const LpAlert(
          icon: Icons.info_outline,
          title: 'Saved',
          message: 'Your plan is up to date',
        ),
      ),
    );
    expect(
      find.bySemanticsLabel('Saved\nYour plan is up to date'),
      findsOneWidget,
    );
    expect(
      tester.getSemantics(find.byType(LpAlert)),
      isSemantics(isButton: false, hasTapAction: false),
    );
    handle.dispose();
  });

  testWidgets('with onTap it is a button, tappable anywhere', (tester) async {
    final handle = tester.ensureSemantics();
    var taps = 0;
    await tester.pumpWidget(
      _host(
        LpAlert(
          icon: Icons.info_outline,
          message: 'Open settings',
          trailingIcon: Icons.chevron_right,
          onTap: () => taps++,
        ),
      ),
    );
    await tester.tap(find.text('Open settings'));
    await tester.tap(find.byIcon(Icons.chevron_right));
    expect(taps, 2);
    expect(
      tester.getSemantics(find.byType(LpAlert)),
      isSemantics(isButton: true, hasTapAction: true),
    );
    handle.dispose();
  });

  testWidgets('a title alone is enough', (tester) async {
    await tester.pumpWidget(
      _host(const LpAlert(icon: Icons.info_outline, title: 'Only a title')),
    );
    expect(find.text('Only a title'), findsOneWidget);
    expect(find.byType(LpAlert), findsOneWidget);
  });
}
