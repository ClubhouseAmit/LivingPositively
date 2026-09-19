import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mazilon/design_system/primitives/app_button.dart';
import 'package:mazilon/design_system/primitives/app_glass.dart';
import 'package:mazilon/design_system/primitives/app_surface.dart';
import 'package:mazilon/design_system/primitives/app_text.dart';
import 'package:mazilon/design_system/tokens/type_scale.dart';

/// The property under test isn't "does it render" — it's "does it render
/// with NO MaterialApp/Theme ancestor at all". That's the whole point of
/// building these on `widgets.dart` instead of wrapping `Text`/`Card`: a
/// design-system primitive that secretly needs `Theme.of(context)` would
/// pass a normal widget test (which wraps everything in MaterialApp) while
/// failing the actual claim. `WidgetsApp` here has none of that.
Widget _withoutMaterial(Widget child) {
  return WidgetsApp(
    color: const Color(0xFFFFFFFF),
    builder: (context, _) => child,
  );
}

void main() {
  testWidgets('AppText renders its token style with no Material ancestor', (
    tester,
  ) async {
    await tester.pumpWidget(
      _withoutMaterial(
        const AppText('hello', style: AppTextStyle.headlineLarge),
      ),
    );

    final Text rendered = tester.widget(find.byType(Text));
    expect(rendered.data, 'hello');
    expect(rendered.style!.fontSize, AppTypeScale.headlineLarge.fontSize);
    expect(rendered.style!.fontFamily, 'Rubix');
  });

  testWidgets('AppSurface renders its child with no Material ancestor', (
    tester,
  ) async {
    await tester.pumpWidget(
      _withoutMaterial(const AppSurface(child: SizedBox(key: Key('leaf')))),
    );

    expect(find.byKey(const Key('leaf')), findsOneWidget);
  });

  testWidgets('AppGlass blurs its backdrop with no Material ancestor', (
    tester,
  ) async {
    await tester.pumpWidget(
      _withoutMaterial(const AppGlass(child: SizedBox(key: Key('leaf')))),
    );

    expect(find.byType(BackdropFilter), findsOneWidget);
    expect(find.byKey(const Key('leaf')), findsOneWidget);
  });

  testWidgets('AppButton fires onPressed with no Material ancestor', (
    tester,
  ) async {
    int taps = 0;
    await tester.pumpWidget(
      _withoutMaterial(
        AppButton(label: 'Go', onPressed: () => taps++),
      ),
    );

    await tester.tap(find.text('Go'));
    expect(taps, 1);
  });

  testWidgets('AppButton disabled (onPressed: null) ignores taps', (
    tester,
  ) async {
    await tester.pumpWidget(
      _withoutMaterial(const AppButton(label: 'Go', onPressed: null)),
    );

    await tester.tap(find.text('Go'));
    // No exception, no crash: a null onPressed must not be invoked.

    final Semantics semantics = tester.widget(
      find.ancestor(of: find.text('Go'), matching: find.byType(Semantics)).first,
    );
    expect(semantics.properties.enabled, isFalse);
  });

  testWidgets('AppButton dips opacity while pressed', (tester) async {
    await tester.pumpWidget(
      _withoutMaterial(AppButton(label: 'Go', onPressed: () {})),
    );

    final TestGesture gesture = await tester.startGesture(
      tester.getCenter(find.text('Go')),
    );
    await tester.pump();
    final AnimatedOpacity pressed = tester.widget(
      find.byType(AnimatedOpacity),
    );
    expect(pressed.opacity, lessThan(1));

    await gesture.up();
  });
}
