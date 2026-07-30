import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'coverage gate accepts reports for the active integration targets',
    () async {
      final result = await _runGate([
        _coverageFile('lib/main.dart', hitLines: 1, totalLines: 1),
        _coverageFile(
          'lib/pages/WellnessTools/player.dart',
          hitLines: 1,
          totalLines: 1,
        ),
        _coverageFile(
          'lib/util/logger_service.dart',
          hitLines: 1,
          totalLines: 1,
        ),
      ]);

      expect(result.exitCode, 0, reason: '${result.stdout}\n${result.stderr}');
    },
  );

  test('coverage gate rejects every configured file below its floor', () async {
    final result = await _runGate([
      _coverageFile('lib/main.dart', hitLines: 1, totalLines: 2),
      _coverageFile(
        'lib/pages/WellnessTools/player.dart',
        hitLines: 1,
        totalLines: 2,
      ),
      _coverageFile('lib/util/logger_service.dart', hitLines: 1, totalLines: 2),
    ]);

    expect(result.exitCode, 1, reason: '${result.stdout}\n${result.stderr}');
    expect(result.stderr, contains('lib/main.dart'));
    expect(result.stderr, contains('lib/pages/WellnessTools/player.dart'));
    expect(result.stderr, contains('lib/util/logger_service.dart'));
  });

  test('coverage gate rejects a missing configured file', () async {
    final result = await _runGate([
      _coverageFile('lib/main.dart', hitLines: 1, totalLines: 1),
      _coverageFile(
        'lib/pages/WellnessTools/player.dart',
        hitLines: 1,
        totalLines: 1,
      ),
    ]);

    expect(result.exitCode, 1, reason: '${result.stdout}\n${result.stderr}');
    expect(result.stderr, contains('lib/util/logger_service.dart'));
  });
}

Future<ProcessResult> _runGate(List<String> records) async {
  final tempDirectory = await Directory.systemTemp.createTemp(
    'mazilon-integration-coverage-',
  );
  addTearDown(() => tempDirectory.delete(recursive: true));

  final coverageDirectory = Directory(
    '${tempDirectory.path}${Platform.pathSeparator}coverage',
  )..createSync();
  File(
    '${coverageDirectory.path}${Platform.pathSeparator}integration.info',
  ).writeAsStringSync(records.join());

  final scriptPath =
      '${Directory.current.path}${Platform.pathSeparator}scripts'
      '${Platform.pathSeparator}check_integration_coverage.dart';
  final flutterRoot = Platform.environment['FLUTTER_ROOT']!;
  final dartExecutable =
      '$flutterRoot${Platform.pathSeparator}bin${Platform.pathSeparator}cache'
      '${Platform.pathSeparator}dart-sdk${Platform.pathSeparator}bin'
      '${Platform.pathSeparator}dart${Platform.isWindows ? '.exe' : ''}';
  return Process.run(dartExecutable, [
    scriptPath,
  ], workingDirectory: tempDirectory.path);
}

String _coverageFile(
  String path, {
  required int hitLines,
  required int totalLines,
}) {
  final lines = List.generate(
    totalLines,
    (index) => 'DA:${index + 1},${index < hitLines ? 1 : 0}\n',
  ).join();
  return 'SF:$path\n'
      '$lines'
      'LF:$totalLines\n'
      'LH:$hitLines\n'
      'end_of_record\n';
}
