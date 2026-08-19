import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('merge CLI accepts and normalizes one LCOV input', () async {
    final tempDirectory = Directory.systemTemp.createTempSync(
      'merge_lcov_cli_test_',
    );
    addTearDown(() => tempDirectory.deleteSync(recursive: true));

    final input = File('${tempDirectory.path}/single.info')
      ..writeAsStringSync(r'''SF:lib\example.dart
DA:10,2
DA:3,0
LF:99
LH:99
end_of_record
''');
    final output = File('${tempDirectory.path}/merged.info');

    final result = await Process.run(_dartExecutable(), <String>[
      'run',
      'scripts/merge_lcov.dart',
      output.path,
      input.path,
    ], workingDirectory: Directory.current.path);

    expect(
      result.exitCode,
      0,
      reason: 'stderr: ${result.stderr}\nstdout: ${result.stdout}',
    );
    expect(output.readAsStringSync(), '''SF:lib/example.dart
DA:3,0
DA:10,2
LF:2
LH:1
end_of_record
''');
  });

  test(
    'merge CLI combines multiple LCOV inputs by maximum line hits',
    () async {
      final tempDirectory = Directory.systemTemp.createTempSync(
        'merge_lcov_cli_multiple_inputs_test_',
      );
      addTearDown(() => tempDirectory.deleteSync(recursive: true));

      final firstInput = File('${tempDirectory.path}/first.info')
        ..writeAsStringSync('''SF:lib/example.dart
DA:10,1
DA:3,0
end_of_record
SF:lib/other.dart
DA:7,0
end_of_record
''');
      final secondInput = File('${tempDirectory.path}/second.info')
        ..writeAsStringSync('''SF:lib/example.dart
DA:10,4
DA:5,2
DA:3,0
end_of_record
SF:lib/other.dart
DA:7,1
DA:9,0
end_of_record
''');
      final output = File('${tempDirectory.path}/merged.info');

      final result = await Process.run(_dartExecutable(), <String>[
        'run',
        'scripts/merge_lcov.dart',
        output.path,
        firstInput.path,
        secondInput.path,
      ], workingDirectory: Directory.current.path);

      expect(
        result.exitCode,
        0,
        reason: 'stderr: ${result.stderr}\nstdout: ${result.stdout}',
      );
      expect(output.readAsStringSync(), '''SF:lib/example.dart
DA:3,0
DA:5,2
DA:10,4
LF:3
LH:2
end_of_record
SF:lib/other.dart
DA:7,1
DA:9,0
LF:2
LH:1
end_of_record
''');
    },
  );

  test('merge CLI rejects invocations without LCOV inputs', () async {
    final tempDirectory = Directory.systemTemp.createTempSync(
      'merge_lcov_cli_invalid_test_',
    );
    addTearDown(() => tempDirectory.deleteSync(recursive: true));
    final output = File('${tempDirectory.path}/merged.info');

    final noArguments = await Process.run(_dartExecutable(), <String>[
      'run',
      'scripts/merge_lcov.dart',
    ], workingDirectory: Directory.current.path);
    expect(noArguments.exitCode, 2);
    expect(tempDirectory.listSync(), isEmpty);

    final outputOnly = await Process.run(_dartExecutable(), <String>[
      'run',
      'scripts/merge_lcov.dart',
      output.path,
    ], workingDirectory: Directory.current.path);
    expect(outputOnly.exitCode, 2);
    expect(output.existsSync(), isFalse);
  });
}

String _dartExecutable() {
  final executableName = Platform.isWindows ? 'dart.exe' : 'dart';
  var directory = File(Platform.resolvedExecutable).parent;

  while (directory.parent.path != directory.path) {
    final candidate = File(
      '${directory.path}${Platform.pathSeparator}dart-sdk'
      '${Platform.pathSeparator}bin${Platform.pathSeparator}$executableName',
    );
    if (candidate.existsSync()) {
      return candidate.path;
    }
    directory = directory.parent;
  }

  fail(
    'Could not locate $executableName by walking up from '
    '${Platform.resolvedExecutable}.',
  );
}
