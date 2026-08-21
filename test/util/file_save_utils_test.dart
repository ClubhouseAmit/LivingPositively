import 'package:flutter_test/flutter_test.dart';
import 'package:mazilon/util/file_save_utils.dart';

void main() {
  group('FileSaveUtils.normalizeSavedFileDestination', () {
    test('returns null when input is null', () {
      expect(FileSaveUtils.normalizeSavedFileDestination(null), isNull);
    });

    test('returns null when input is an empty or whitespace-only string', () {
      expect(FileSaveUtils.normalizeSavedFileDestination(''), isNull);
      expect(FileSaveUtils.normalizeSavedFileDestination('   '), isNull);
    });

    test('returns exact string when input is a non-empty String', () {
      expect(
        FileSaveUtils.normalizeSavedFileDestination('/path/to/file.pdf'),
        '/path/to/file.pdf',
      );
    });

    test('returns Uri.path when input is a file Uri or a scheme-less Uri', () {
      expect(
        FileSaveUtils.normalizeSavedFileDestination(
          Uri.parse('file:///storage/emulated/0/Download/plan.pdf'),
        ),
        '/storage/emulated/0/Download/plan.pdf',
      );
      expect(
        FileSaveUtils.normalizeSavedFileDestination(
          Uri(path: '/storage/emulated/0/Download/plan.pdf'),
        ),
        '/storage/emulated/0/Download/plan.pdf',
      );
    });

    test('preserves full URI string for non-file URIs such as content://', () {
      expect(
        FileSaveUtils.normalizeSavedFileDestination(
          Uri.parse('content://media/external/images/media/123'),
        ),
        'content://media/external/images/media/123',
      );
    });

    test('returns null when Uri path and string are empty', () {
      expect(FileSaveUtils.normalizeSavedFileDestination(Uri.parse('')), isNull);
    });

    test('returns null for unsupported arbitrary types', () {
      expect(FileSaveUtils.normalizeSavedFileDestination(12345), isNull);
      expect(FileSaveUtils.normalizeSavedFileDestination(true), isNull);
      expect(FileSaveUtils.normalizeSavedFileDestination(Object()), isNull);
      expect(FileSaveUtils.normalizeSavedFileDestination(['/path']), isNull);
    });
  });
}
