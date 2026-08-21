import 'package:flutter_test/flutter_test.dart';
import 'package:mazilon/util/file_save_utils.dart';

void main() {
  group('FileSaveUtils.normalizeSavedFilePath', () {
    test('returns null when input is null', () {
      expect(FileSaveUtils.normalizeSavedFilePath(null), isNull);
    });

    test('returns exact string when input is String', () {
      expect(
        FileSaveUtils.normalizeSavedFilePath('/path/to/file.pdf'),
        '/path/to/file.pdf',
      );
    });

    test('returns Uri.path when input is Uri', () {
      expect(
        FileSaveUtils.normalizeSavedFilePath(
          Uri.parse('file:///storage/emulated/0/Download/plan.pdf'),
        ),
        '/storage/emulated/0/Download/plan.pdf',
      );
    });

    test('returns toString representation for custom objects', () {
      expect(FileSaveUtils.normalizeSavedFilePath(12345), '12345');
    });
  });
}
