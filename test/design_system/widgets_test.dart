import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart' hide Text;
import 'package:flutter/widgets.dart' as flutter show Text;
import 'package:flutter_test/flutter_test.dart';
import 'package:mazilon/design_system/widgets/alert.dart';
import 'package:mazilon/design_system/widgets/avatar.dart';
import 'package:mazilon/design_system/widgets/badge.dart';
import 'package:mazilon/design_system/widgets/button.dart';
import 'package:mazilon/design_system/widgets/card.dart';
import 'package:mazilon/design_system/widgets/divider.dart';
import 'package:mazilon/design_system/widgets/glass.dart';
import 'package:mazilon/design_system/widgets/checkbox.dart';
import 'package:mazilon/design_system/widgets/date_field.dart';
import 'package:mazilon/design_system/widgets/dialog.dart';
import 'package:mazilon/design_system/widgets/label.dart';
import 'package:mazilon/design_system/widgets/otp_field.dart';
import 'package:mazilon/design_system/widgets/progress.dart';
import 'package:mazilon/design_system/widgets/radio.dart';
import 'package:mazilon/design_system/widgets/select.dart';
import 'package:mazilon/design_system/widgets/sheet.dart';
import 'package:mazilon/design_system/widgets/slider.dart';
import 'package:mazilon/design_system/widgets/switch.dart';
import 'package:mazilon/design_system/widgets/text.dart';
import 'package:mazilon/design_system/widgets/text_field.dart';
import 'package:mazilon/design_system/widgets/time_field.dart';
import 'package:mazilon/design_system/widgets/tooltip.dart';
import 'package:mazilon/design_system/tokens/colors.dart';
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
    builder: (context, _) => Overlay(
      initialEntries: <OverlayEntry>[
        OverlayEntry(builder: (BuildContext context) => child),
      ],
    ),
  );
}

void main() {
  testWidgets('Text renders its token style with no Material ancestor', (
    tester,
  ) async {
    await tester.pumpWidget(
      _withoutMaterial(
        const Text('hello', style: AppTextStyle.headlineLarge),
      ),
    );

    final Text rendered = tester.widget(find.byType(Text));
    expect(rendered.data, 'hello');
    expect(rendered.style, AppTextStyle.headlineLarge);
    final flutter.Text inner = tester.widget(find.byType(flutter.Text));
    expect(inner.style!.fontSize, AppTypeScale.headlineLarge.fontSize);
    expect(inner.style!.fontFamily, 'Rubix');
  });

  testWidgets('Card renders its child with no Material ancestor', (
    tester,
  ) async {
    await tester.pumpWidget(
      _withoutMaterial(const Card(child: SizedBox(key: Key('leaf')))),
    );

    expect(find.byKey(const Key('leaf')), findsOneWidget);
  });

  testWidgets('Glass blurs its backdrop with no Material ancestor', (
    tester,
  ) async {
    await tester.pumpWidget(
      _withoutMaterial(const Glass(child: SizedBox(key: Key('leaf')))),
    );

    expect(find.byType(BackdropFilter), findsOneWidget);
    expect(find.byKey(const Key('leaf')), findsOneWidget);
  });

  testWidgets('Button fires onPressed with no Material ancestor', (
    tester,
  ) async {
    int taps = 0;
    await tester.pumpWidget(
      _withoutMaterial(
        Button(label: 'Go', onPressed: () => taps++),
      ),
    );

    await tester.tap(find.text('Go'));
    expect(taps, 1);
  });

  testWidgets('Button disabled (onPressed: null) ignores taps', (
    tester,
  ) async {
    await tester.pumpWidget(
      _withoutMaterial(const Button(label: 'Go', onPressed: null)),
    );

    await tester.tap(find.text('Go'));
    // No exception, no crash: a null onPressed must not be invoked.

    final Semantics semantics = tester.widget(
      find
          .ancestor(of: find.text('Go'), matching: find.byType(Semantics))
          .first,
    );
    expect(semantics.properties.enabled, isFalse);
  });

  testWidgets('Button dips opacity while pressed', (tester) async {
    await tester.pumpWidget(
      _withoutMaterial(Button(label: 'Go', onPressed: () {})),
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

  testWidgets('Badge renders its label with no Material ancestor', (
    tester,
  ) async {
    await tester.pumpWidget(_withoutMaterial(const Badge(label: 'New')));
    expect(find.text('New'), findsOneWidget);
  });

  testWidgets('Badge destructive uses dark-on-tint, not white-on-red', (
    tester,
  ) async {
    await tester.pumpWidget(
      _withoutMaterial(
        const Badge(label: 'Err', variant: BadgeVariant.destructive),
      ),
    );
    final flutter.Text rendered = tester.widget(find.text('Err'));
    expect(rendered.style!.color, AppColors.error);
  });

  testWidgets('Divider paints a rule with no Material ancestor', (
    tester,
  ) async {
    await tester.pumpWidget(_withoutMaterial(const Divider()));
    expect(find.byType(ColoredBox), findsWidgets);
  });

  testWidgets('Progress fills by value with no Material ancestor', (
    tester,
  ) async {
    await tester.pumpWidget(_withoutMaterial(const Progress(value: 0.5)));
    expect(find.byType(FractionallySizedBox), findsOneWidget);
  });

  testWidgets('Alert renders title with no Material ancestor', (
    tester,
  ) async {
    await tester.pumpWidget(
      _withoutMaterial(const Alert(title: 'Heads up', subtitle: 'detail')),
    );
    expect(find.text('Heads up'), findsOneWidget);
    expect(find.text('detail'), findsOneWidget);
  });

  testWidgets('Alert destructive is a live region', (tester) async {
    await tester.pumpWidget(
      _withoutMaterial(
        const Alert(title: 'Failed', variant: AlertVariant.destructive),
      ),
    );
    final Semantics semantics = tester.widget(
      find.descendant(
        of: find.byType(Alert),
        matching: find.byType(Semantics),
      ),
    );
    expect(semantics.properties.liveRegion, isTrue);
  });

  testWidgets('Avatar renders initials with no Material ancestor', (
    tester,
  ) async {
    await tester.pumpWidget(_withoutMaterial(const Avatar(initials: 'AB')));
    expect(find.text('AB'), findsOneWidget);
  });

  testWidgets('Avatar empty still paints a fallback mark', (tester) async {
    await tester.pumpWidget(_withoutMaterial(const Avatar()));
    expect(find.byType(DecoratedBox), findsWidgets);
    expect(find.byType(Text), findsNothing);
  });

  testWidgets('Label stacks label above child with no Material ancestor', (
    tester,
  ) async {
    await tester.pumpWidget(
      _withoutMaterial(
        const Label(
          label: 'Name',
          description: 'hint',
          child: SizedBox(key: Key('field')),
        ),
      ),
    );
    expect(find.text('Name'), findsOneWidget);
    expect(find.text('hint'), findsOneWidget);
    expect(find.byKey(const Key('field')), findsOneWidget);
  });

  testWidgets('TextField accepts text with no Material ancestor', (
    tester,
  ) async {
    String? typed;
    await tester.pumpWidget(
      _withoutMaterial(TextField(onChanged: (String v) => typed = v)),
    );
    await tester.enterText(find.byType(EditableText), 'hi');
    expect(typed, 'hi');
  });

  testWidgets('Checkbox toggles', (tester) async {
    bool? next;
    await tester.pumpWidget(
      _withoutMaterial(
        Checkbox(
          value: false,
          label: 'Agree',
          onChanged: (bool v) => next = v,
        ),
      ),
    );
    await tester.tap(find.text('Agree'));
    expect(next, isTrue);
  });

  testWidgets('Radio and Switch toggle', (tester) async {
    bool radio = false;
    bool sw = false;
    await tester.pumpWidget(
      _withoutMaterial(
        Column(
          children: [
            Radio(
              value: radio,
              label: 'A',
              onChanged: (bool v) => radio = v,
            ),
            Switch(
              value: sw,
              label: 'On',
              onChanged: (bool v) => sw = v,
            ),
          ],
        ),
      ),
    );
    await tester.tap(find.text('A'));
    await tester.tap(find.text('On'));
    expect(radio, isTrue);
    expect(sw, isTrue);
  });

  testWidgets('Slider drag reports a value', (tester) async {
    double? next;
    await tester.pumpWidget(
      _withoutMaterial(
        SizedBox(
          width: 200,
          child: Slider(value: 0, onChanged: (double v) => next = v),
        ),
      ),
    );
    await tester.tap(find.byType(Slider));
    expect(next, isNotNull);
  });

  testWidgets('Select picks an option from the popover', (tester) async {
    String? picked;
    await tester.pumpWidget(
      _withoutMaterial(
        Align(
          alignment: Alignment.topCenter,
          child: SizedBox(
            width: 200,
            child: Select(
              options: const <String>['One', 'Two'],
              onChanged: (String v) => picked = v,
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Select'));
    await tester.pump();
    await tester.tap(find.text('Two'));
    expect(picked, 'Two');
  });

  testWidgets('DateField parses ISO dates', (tester) async {
    DateTime? parsed;
    await tester.pumpWidget(
      _withoutMaterial(DateField(onChanged: (DateTime v) => parsed = v)),
    );
    await tester.enterText(find.byType(EditableText), '2026-09-19');
    expect(parsed, DateTime(2026, 9, 19));
  });

  testWidgets('TimeField parses HH:MM to minutes', (tester) async {
    int? minutes;
    await tester.pumpWidget(
      _withoutMaterial(TimeField(onChanged: (int v) => minutes = v)),
    );
    await tester.enterText(find.byType(EditableText), '13:30');
    expect(minutes, 13 * 60 + 30);
  });

  testWidgets('OtpField completes when every cell is filled', (
    tester,
  ) async {
    String? code;
    await tester.pumpWidget(
      _withoutMaterial(
        OtpField(length: 2, onCompleted: (String v) => code = v),
      ),
    );
    final Finder cells = find.byType(EditableText);
    await tester.enterText(cells.at(0), '1');
    await tester.enterText(cells.at(1), '2');
    expect(code, '12');
  });

  testWidgets('Tooltip exposes its message to semantics', (tester) async {
    await tester.pumpWidget(
      _withoutMaterial(
        const Tooltip(message: 'Hint', child: Text('Target')),
      ),
    );
    final Semantics semantics = tester.widget(
      find.descendant(
        of: find.byType(Tooltip),
        matching: find.byType(Semantics),
      ),
    );
    expect(semantics.properties.tooltip, 'Hint');
  });

  testWidgets('showDialog presents Dialog without Material', (
    tester,
  ) async {
    await tester.pumpWidget(
      WidgetsApp(
        color: const Color(0xFFFFFFFF),
        onGenerateRoute: (RouteSettings settings) {
          return PageRouteBuilder<void>(
            pageBuilder:
                (
                  BuildContext context,
                  Animation<double> a,
                  Animation<double> b,
                ) {
                  return Center(
                    child: Button(
                      label: 'Open',
                      onPressed: () {
                        showDialog<void>(
                          context: context,
                          dialog: const Dialog(
                            title: 'Sure?',
                            primaryLabel: 'OK',
                          ),
                        );
                      },
                    ),
                  );
                },
          );
        },
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    expect(find.text('Sure?'), findsOneWidget);
  });

  testWidgets('showSheet presents Sheet without Material', (tester) async {
    await tester.pumpWidget(_sheetHost(const Sheet(child: Text('Drawer'))));
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    expect(find.text('Drawer'), findsOneWidget);
    expect(find.byType(Sheet), findsOneWidget);
  });

  testWidgets('showSheet Escape dismisses the sheet', (tester) async {
    await tester.pumpWidget(_sheetHost(const Sheet(child: Text('Drawer'))));
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.byType(Sheet), findsNothing);
  });

  testWidgets('showSheet from an open sheet replaces it', (tester) async {
    await tester.pumpWidget(_sheetHost(const Sheet(child: _OpenNextSheet())));
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    expect(find.text('Two'), findsOneWidget);
    expect(find.text('Next'), findsNothing);
    expect(find.byType(Sheet), findsOneWidget);
  });
}

Widget _sheetHost(Widget sheet) {
  return WidgetsApp(
    color: const Color(0xFFFFFFFF),
    onGenerateRoute: (RouteSettings settings) {
      return PageRouteBuilder<void>(
        pageBuilder:
            (
              BuildContext context,
              Animation<double> a,
              Animation<double> b,
            ) {
              return Center(
                child: Button(
                  label: 'Open',
                  onPressed: () {
                    showSheet<void>(context: context, sheet: sheet);
                  },
                ),
              );
            },
      );
    },
  );
}

class _OpenNextSheet extends StatelessWidget {
  const _OpenNextSheet();

  @override
  Widget build(BuildContext context) {
    return Button(
      label: 'Next',
      onPressed: () {
        showSheet<void>(
          context: context,
          sheet: const Sheet(child: Text('Two')),
        );
      },
    );
  }
}
