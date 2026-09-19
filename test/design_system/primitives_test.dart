import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
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
}
