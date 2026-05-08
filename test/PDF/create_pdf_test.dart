import 'package:flutter_test/flutter_test.dart';
import 'package:mazilon/util/PDF/create_pdf.dart';
import 'package:pdf/widgets.dart' as pw;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PDF helpers: getDirection / getAlign / getAlignment', () {
    test('getDirection returns ltr for Latin', () {
      expect(getDirection('hello'), pw.TextDirection.ltr);
    });

    test('getDirection returns rtl for Hebrew', () {
      expect(getDirection('שלום'), pw.TextDirection.rtl);
    });

    test('getDirection returns rtl for mixed (Hebrew dominates)', () {
      expect(getDirection('hello שלום'), pw.TextDirection.rtl);
    });

    test('getAlign returns left for Latin', () {
      expect(getAlign('hello'), pw.TextAlign.left);
    });

    test('getAlign returns right for Hebrew', () {
      expect(getAlign('שלום'), pw.TextAlign.right);
    });

    test('getAlignment returns centerRight regardless (current behavior)', () {
      // Current implementation returns centerRight in both branches.
      expect(getAlignment('hello'), pw.Alignment.centerRight);
      expect(getAlignment('שלום'), pw.Alignment.centerRight);
    });
  });

  group('createPDF', () {
    final defaultTexts = {
      'text1': 'first',
      'text2': 'first link',
      'text2Link': 'https://example.com/1',
      'text3': 'second',
      'text4': 'third',
      'text5': 'second link',
      'text5Link': 'https://example.com/2',
      'text6': 'fourth',
    };

    test('creates a non-empty PDF with one section', () async {
      final result = await createPDF(
        ['Title 1', 'Title 2'],
        ['Sub 1', 'Sub 2'],
        defaultTexts,
        'My Plan',
        [
          ['item-a', 'item-b'],
          ['item-c'],
        ],
        'rtl',
      );
      expect(result['format'], 'pdf');
      final doc = result['file'] as pw.Document;
      final bytes = await doc.save();
      expect(bytes.lengthInBytes, greaterThan(500));
    });

    test('skips empty data sections', () async {
      final result = await createPDF(
        ['Title 1', 'Title 2'],
        ['Sub 1', 'Sub 2'],
        defaultTexts,
        'My Plan',
        [
          [],
          ['only-section-with-data'],
        ],
        'ltr',
      );
      final doc = result['file'] as pw.Document;
      final bytes = await doc.save();
      expect(bytes.lengthInBytes, greaterThan(500));
    });

    test('handles empty data list', () async {
      final result = await createPDF(
        <String>[],
        <String>[],
        defaultTexts,
        'Empty Plan',
        <List<String>>[],
        'rtl',
      );
      final doc = result['file'] as pw.Document;
      final bytes = await doc.save();
      // Even with no data, the footer/header still produces output
      expect(bytes.lengthInBytes, greaterThan(500));
    });

    test('returns format=pdf', () async {
      final result = await createPDF(
        ['T'],
        ['S'],
        defaultTexts,
        'Plan',
        [
          ['x'],
        ],
        'ltr',
      );
      expect(result['format'], 'pdf');
    });
  });
}
