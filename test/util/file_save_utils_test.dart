import 'package:flutter_test/flutter_test.dart';
import 'package:mazilon/util/file_save_utils.dart';

void main() {
  group('FileSaveUtils.normalizeSavedFilePath', () {
    test('returns null when input is null', () {
      expect(FileSaveUtils.normalizeSavedFilePath(null), isNull);
    });

    test('returns null when input is an empty or whitespace-only string', () {
      expect(FileSaveUtils.normalizeSavedFilePath(''), isNull);
      expect(FileSaveUtils.normalizeSavedFilePath('   '), isNull);
    });

    test('returns exact string when input is a non-empty String', () {
      expect(
        FileSaveUtils.normalizeSavedFilePath('/path/to/file.pdf'),
        '/path/to/file.pdf',
      );
    });

    test('returns Uri.path when input is a file Uri or a scheme-less Uri', () {
      expect(
        FileSaveUtils.normalizeSavedFilePath(
          Uri.parse('file:///storage/emulated/0/Download/plan.pdf'),
        ),
        '/storage/emulated/0/Download/plan.pdf',
      );
      expect(
        FileSaveUtils.normalizeSavedFilePath(
          Uri(path: '/storage/emulated/0/Download/plan.pdf'),
        ),
        '/storage/emulated/0/Download/plan.pdf',
      );
    });

    test('preserves full URI string for non-file URIs such as content://', () {
      expect(
        FileSaveUtils.normalizeSavedFilePath(
          Uri.parse('content://media/external/images/media/123'),
        ),
        'content://media/external/images/media/123',
      );
    });

    test('returns null when Uri path and string are empty', () {
      expect(FileSaveUtils.normalizeSavedFilePath(Uri.parse('')), isNull);
    });

    test('returns null for unsupported arbitrary types', () {
      expect(FileSaveUtils.normalizeSavedFilePath(12345), isNull);
      expect(FileSaveUtils.normalizeSavedFilePath(true), isNull);
      expect(FileSaveUtils.normalizeSavedFilePath(Object()), isNull);
      expect(FileSaveUtils.normalizeSavedFilePath(['/path']), isNull);
    });
  });
}
