import 'dart:io';
import 'dart:ui' show Tristate;

import 'package:flutter/material.dart' show Icons;
import 'package:flutter/services.dart' show ByteData, FontLoader;
import 'package:flutter/widgets.dart' hide Text;
import 'package:flutter_test/flutter_test.dart';
import 'package:mazilon/design_system/tokens/color_tokens.dart';
import 'package:mazilon/design_system/tokens/colors.dart';
import 'package:mazilon/design_system/widgets/lp_text_field.dart';

/// No `MaterialApp` or `Theme`: only `Directionality`, `MediaQuery` (for the
/// editor) and the color tokens.
Widget _host(Widget child, {AppColorTokens colors = AppColorTokens.light}) {
  return MediaQuery(
    data: const MediaQueryData(),
    child: Directionality(
      textDirection: TextDirection.ltr,
      child: AppColorScope(
        tokens: colors,
        child: Center(child: child),
      ),
    ),
  );
}

BoxDecoration _box(WidgetTester tester) {
  return tester
          .widget<DecoratedBox>(
            find
                .descendant(
                  of: find.byType(LpTextField),
                  matching: find.byType(DecoratedBox),
                )
                .first,
          )
          .decoration
      as BoxDecoration;
}

Color _borderColor(WidgetTester tester) =>
    (_box(tester).border! as Border).top.color;

void main() {
  group('box (Figma Input Field)', () {
    testWidgets('idle: sunken fill, hairline border, label inside', (
      tester,
    ) async {
      await tester.pumpWidget(_host(const LpTextField(label: 'Email')));
      expect(_box(tester).color, AppColors.surfaceSunken);
      expect(_borderColor(tester), AppColors.effectHairline);
      expect(find.text('Email'), findsOneWidget);
      expect(
        tester.getSize(find.byType(LpTextField)).height,
        LpTextField.boxHeight,
      );
    });

    testWidgets('tapping focuses: raised fill, accent border, same height', (
      tester,
    ) async {
      await tester.pumpWidget(_host(const LpTextField(label: 'Email')));
      await tester.tap(find.byType(LpTextField));
      await tester.pump();
      expect(_box(tester).color, AppColors.surfaceRaised);
      expect(_borderColor(tester), AppColors.accentPrimary);
      expect(
        tester.getSize(find.byType(LpTextField)).height,
        LpTextField.boxHeight,
      );
    });

    testWidgets('typing reports the text and keeps focus', (tester) async {
      final values = <String>[];
      await tester.pumpWidget(
        _host(LpTextField(label: 'Email', onChanged: values.add)),
      );
      await tester.tap(find.byType(LpTextField));
      await tester.pump();
      await tester.enterText(find.byType(EditableText), 'a@b.c');
      await tester.pump();
      expect(values, ['a@b.c']);
      final EditableText editor = tester.widget(find.byType(EditableText));
      expect(editor.focusNode.hasFocus, isTrue);
    });

    testWidgets('double tap selects a word, and the selection is painted', (
      tester,
    ) async {
      final controller = TextEditingController(text: 'hello world');
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        _host(LpTextField(label: 'Note', controller: controller)),
      );
      final Offset word =
          tester.getTopLeft(find.byType(EditableText)) + const Offset(10, 8);
      await tester.tapAt(word);
      await tester.pump(const Duration(milliseconds: 50));
      await tester.tapAt(word);
      await tester.pumpAndSettle();
      expect(
        controller.selection,
        const TextSelection(baseOffset: 0, extentOffset: 5),
      );
      final EditableText editor = tester.widget(find.byType(EditableText));
      // EditableText selects but paints nothing without a selection color.
      expect(editor.selectionColor, isNotNull);

      // Unfocused, the selection is kept but no longer painted.
      editor.focusNode.unfocus();
      await tester.pumpAndSettle();
      final EditableText blurred = tester.widget(find.byType(EditableText));
      expect(blurred.selectionColor, isNull);
    });

    testWidgets('error: danger border and message', (tester) async {
      await tester.pumpWidget(
        _host(const LpTextField(label: 'Email', errorText: 'Not an email')),
      );
      expect(_borderColor(tester), AppColors.statusDanger);
      expect(find.text('Not an email'), findsOneWidget);
      final EditableText editor = tester.widget(find.byType(EditableText));
      expect(editor.cursorColor, AppColors.statusDanger);
    });

    testWidgets('the cursor is content/primary without an error', (
      tester,
    ) async {
      await tester.pumpWidget(_host(const LpTextField(label: 'Email')));
      final EditableText editor = tester.widget(find.byType(EditableText));
      expect(editor.cursorColor, AppColors.contentPrimary);
    });

    testWidgets('disabled ignores taps', (tester) async {
      await tester.pumpWidget(
        _host(const LpTextField(label: 'Email', enabled: false)),
      );
      await tester.tap(find.byType(LpTextField), warnIfMissed: false);
      await tester.pump();
      final EditableText editor = tester.widget(find.byType(EditableText));
      expect(editor.focusNode.hasFocus, isFalse);
      expect(_box(tester).color, AppColors.surfaceDisabled);
    });

    testWidgets('disabled: no focus, and screen readers hear it disabled', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      final focus = FocusNode();
      addTearDown(focus.dispose);
      await tester.pumpWidget(
        _host(LpTextField(label: 'Email', focusNode: focus, enabled: false)),
      );
      focus.requestFocus();
      await tester.pumpAndSettle();
      expect(focus.hasFocus, isFalse);
      final node = tester.getSemantics(find.byType(EditableText));
      // isFalse, not none: it has an enabled state, and it's off.
      expect(node.flagsCollection.isEnabled, Tristate.isFalse);
      handle.dispose();
    });

    testWidgets('disabling a focused field drops its focus', (tester) async {
      final focus = FocusNode();
      addTearDown(focus.dispose);
      await tester.pumpWidget(
        _host(LpTextField(label: 'Email', focusNode: focus)),
      );
      focus.requestFocus();
      await tester.pumpAndSettle();
      expect(focus.hasFocus, isTrue);
      await tester.pumpWidget(
        _host(LpTextField(label: 'Email', focusNode: focus, enabled: false)),
      );
      await tester.pumpAndSettle();
      expect(focus.hasFocus, isFalse);
    });

    testWidgets('dark mode takes the dark tokens', (tester) async {
      await tester.pumpWidget(
        _host(
          const LpTextField(label: 'Email'),
          colors: AppColorTokens.dark,
        ),
      );
      expect(_box(tester).color, AppColors.darkSurfaceSunken);
    });

    testWidgets('a screen reader finds one labeled text field', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(_host(const LpTextField(label: 'Email')));
      expect(
        find.semantics.byPredicate(
          (node) => node.label == 'Email' && node.flagsCollection.isTextField,
        ),
        findsOne,
      );
      handle.dispose();
    });
  });

  group('swapping controller or focus node', () {
    testWidgets('a new controller is used for text and the label', (
      tester,
    ) async {
      final first = TextEditingController(text: 'old');
      final second = TextEditingController();
      addTearDown(first.dispose);
      addTearDown(second.dispose);
      await tester.pumpWidget(
        _host(LpTextField(label: 'Email', controller: first)),
      );
      await tester.pumpWidget(
        _host(LpTextField(label: 'Email', controller: second)),
      );
      // Empty and unfocused again: the label is back inside the box.
      expect(find.text('old'), findsNothing);
      await tester.tap(find.byType(LpTextField));
      await tester.pump();
      await tester.enterText(find.byType(EditableText), 'new');
      expect(second.text, 'new');
      expect(first.text, 'old');
    });

    testWidgets('dropping the controller keeps its text', (tester) async {
      final given = TextEditingController(text: 'kept');
      addTearDown(given.dispose);
      await tester.pumpWidget(
        _host(LpTextField(label: 'Email', controller: given)),
      );
      await tester.pumpWidget(_host(const LpTextField(label: 'Email')));
      expect(find.text('kept'), findsOneWidget);
    });

    testWidgets('passing a controller disposes the field\'s own', (
      tester,
    ) async {
      final given = TextEditingController();
      addTearDown(given.dispose);
      await tester.pumpWidget(_host(const LpTextField(label: 'Email')));
      final TextEditingController own = tester
          .widget<EditableText>(find.byType(EditableText))
          .controller;
      await tester.pumpWidget(
        _host(LpTextField(label: 'Email', controller: given)),
      );
      // A disposed ChangeNotifier refuses new listeners in debug.
      expect(() => own.addListener(() {}), throwsFlutterError);
    });

    testWidgets('a new focus node drives the focused look', (tester) async {
      final first = FocusNode();
      final second = FocusNode();
      addTearDown(first.dispose);
      addTearDown(second.dispose);
      await tester.pumpWidget(
        _host(LpTextField(label: 'Email', focusNode: first)),
      );
      await tester.pumpWidget(
        _host(LpTextField(label: 'Email', focusNode: second)),
      );
      second.requestFocus();
      await tester.pumpAndSettle();
      expect(_borderColor(tester), AppColors.accentPrimary);
    });
  });

  group('line (Figma text field)', () {
    testWidgets('a disabled line field never shows the clear button', (
      tester,
    ) async {
      final focus = FocusNode();
      final controller = TextEditingController(text: 'abc');
      addTearDown(focus.dispose);
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        _host(
          LpTextField.line(
            placeholder: 'Write',
            controller: controller,
            focusNode: focus,
            enabled: false,
            clearIcon: Icons.cancel,
            clearLabel: 'Clear',
          ),
        ),
      );
      focus.requestFocus();
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.cancel), findsNothing);
    });

    testWidgets('m has a separator and placeholder; typing hides it', (
      tester,
    ) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        _host(LpTextField.line(placeholder: 'Write', controller: controller)),
      );
      expect(find.byType(ColoredBox), findsOneWidget);
      expect(find.text('Write'), findsOneWidget);
      controller.text = 'x';
      await tester.pump();
      expect(find.text('Write'), findsNothing);
    });

    testWidgets('s has no separator', (tester) async {
      await tester.pumpWidget(
        _host(
          const LpTextField.line(
            placeholder: 'Detail',
            size: LpTextFieldSize.s,
          ),
        ),
      );
      expect(find.byType(ColoredBox), findsNothing);
    });

    testWidgets('clear shows only while focused with text, and clears', (
      tester,
    ) async {
      final values = <String>[];
      await tester.pumpWidget(
        _host(
          LpTextField.line(
            placeholder: 'Write',
            clearIcon: Icons.cancel,
            clearLabel: 'Clear',
            onChanged: values.add,
          ),
        ),
      );
      expect(find.byIcon(Icons.cancel), findsNothing);
      await tester.tap(find.byType(LpTextField));
      await tester.pump();
      await tester.enterText(find.byType(EditableText), 'abc');
      await tester.pump();
      expect(find.byIcon(Icons.cancel), findsOneWidget);
      await tester.tap(find.byIcon(Icons.cancel));
      await tester.pump();
      expect(values, ['abc', '']);
      expect(find.text('abc'), findsNothing);
      expect(find.byIcon(Icons.cancel), findsNothing);
    });

    testWidgets('the clear button is a labeled button for screen readers', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      final controller = TextEditingController(text: 'abc');
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        _host(
          LpTextField.line(
            placeholder: 'Write',
            controller: controller,
            clearIcon: Icons.cancel,
            clearLabel: 'Clear',
          ),
        ),
      );
      await tester.tap(find.byType(LpTextField));
      await tester.pump();
      expect(
        tester.getSemantics(find.byIcon(Icons.cancel)),
        matchesSemantics(
          label: 'Clear',
          isButton: true,
          hasTapAction: true,
        ),
      );
      tester.semantics.tap(find.semantics.byLabel('Clear'));
      await tester.pump();
      expect(controller.text, isEmpty);
      handle.dispose();
    });
  });

  // Last in the file: loaded fonts stay loaded for every later test.
  group('with the app fonts', () {
    Future<void> load(String family, List<String> files) async {
      final loader = FontLoader(family);
      for (final String file in files) {
        loader.addFont(
          Future.value(ByteData.sublistView(File(file).readAsBytesSync())),
        );
      }
      await loader.load();
    }

    for (final String language in ['en', 'he']) {
      testWidgets('the box stays 56 when the label moves up ($language)', (
        tester,
      ) async {
        // The test font draws 13px text 13 high, so only real fonts catch a
        // value line taller than Figma's (Heebo grew the box to 59).
        await load('Heebo', [
          'fonts/Heebo-Regular.ttf',
          'fonts/Heebo-SemiBold.ttf',
        ]);
        await load('Rubik', [
          'fonts/Rubik-Regular.ttf',
          'fonts/Rubik-SemiBold.ttf',
        ]);
        final controller = TextEditingController(text: 'a@b.c');
        addTearDown(controller.dispose);
        Widget field(TextEditingController? c) => Localizations(
          locale: Locale(language),
          delegates: const [DefaultWidgetsLocalizations.delegate],
          child: _host(LpTextField(label: 'Email', controller: c)),
        );
        await tester.pumpWidget(field(null));
        expect(tester.getSize(find.byType(LpTextField)).height, 56);
        await tester.pumpWidget(field(controller));
        expect(tester.getSize(find.byType(LpTextField)).height, 56);
      });
    }
  });
}
