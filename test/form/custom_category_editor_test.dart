import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mazilon/form/custom_category_editor.dart';
import 'package:mazilon/l10n/app_localizations.dart';

void main() {
  testWidgets(
    'preserves Hebrew and mixed-direction text after trimming edges',
    (tester) async {
      final editorKey = GlobalKey<CustomCategoryEditorState>();
      MapEntry<String, String>? saved;
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('he'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: Scaffold(
            body: CustomCategoryEditor(
              key: editorKey,
              onSave: (category) async => saved = category,
            ),
          ),
        ),
      );

      await tester.enterText(
        find.byKey(const Key('custom-category-title-field')),
        '  קטגוריה ABC  ',
      );
      await tester.enterText(
        find.byKey(const Key('custom-category-description-field')),
        '  טקסט mixed 123  ',
      );
      await tester.runAsync(() => editorKey.currentState!.save());

      expect(saved?.key, 'קטגוריה ABC');
      expect(saved?.value, 'טקסט mixed 123');
    },
  );

  testWidgets(
    'opens localized title suggestions on tap and supports custom input',
    (tester) async {
      const customInput = 'Write my own category';
      const hebrewSuggestion =
          '\u05e7\u05d8\u05d2\u05d5\u05e8\u05d9\u05d4 \u05d0\u05d9\u05e9\u05d9\u05ea';
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('he'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: Scaffold(
            body: CustomCategoryEditor(
              predefinedTitles: const [hebrewSuggestion, customInput],
              onSave: (_) async {},
            ),
          ),
        ),
      );

      final titleField = find.byKey(const Key('custom-category-title-field'));
      await tester.tap(titleField);
      await tester.pumpAndSettle();

      expect(find.text(hebrewSuggestion), findsOneWidget);
      await tester.tap(find.text(customInput));
      await tester.pumpAndSettle();
      expect(tester.widget<TextField>(titleField).controller?.text, isEmpty);
    },
  );
}
