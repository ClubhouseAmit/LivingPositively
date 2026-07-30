import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'coverage gate accepts reports for the active integration targets',
    () async {
      final tempDirectory = await Directory.systemTemp.createTemp(
        'mazilon-integration-coverage-',
      );
      addTearDown(() => tempDirectory.delete(recursive: true));

      final coverageDirectory = Directory(
        '${tempDirectory.path}${Platform.pathSeparator}coverage',
      )..createSync();
      File(
        '${coverageDirectory.path}${Platform.pathSeparator}integration.info',
      ).writeAsStringSync(
        [
          _coveredFile('lib/main.dart'),
          _coveredFile('lib/pages/WellnessTools/player.dart'),
          _coveredFile('lib/util/logger_service.dart'),
        ].join(),
      );

      final scriptPath =
          '${Directory.current.path}${Platform.pathSeparator}scripts'
          '${Platform.pathSeparator}check_integration_coverage.dart';
      final flutterRoot = Platform.environment['FLUTTER_ROOT']!;
      final dartExecutable =
          '$flutterRoot${Platform.pathSeparator}bin${Platform.pathSeparator}cache'
          '${Platform.pathSeparator}dart-sdk${Platform.pathSeparator}bin'
          '${Platform.pathSeparator}dart${Platform.isWindows ? '.exe' : ''}';
      final result = await Process.run(dartExecutable, [
        scriptPath,
      ], workingDirectory: tempDirectory.path);

      expect(result.exitCode, 0, reason: '${result.stdout}\n${result.stderr}');
    },
  );
}

String _coveredFile(String path) {
  return 'SF:$path\n'
      'DA:1,1\n'
      'LF:1\n'
      'LH:1\n'
      'end_of_record\n';
}
