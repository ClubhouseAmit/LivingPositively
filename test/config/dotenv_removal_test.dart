import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ADR-0001 dotenv removal', () {
    test('Flutter source no longer imports or loads flutter_dotenv', () async {
      final analyticsService = await _readRepoFile('lib/AnalyticsService.dart');
      final mainFile = await _readRepoFile('lib/main.dart');
      final loggerService = await _readRepoFile('lib/util/logger_service.dart');

      expect(analyticsService, isNot(contains('package:flutter_dotenv/')));
      expect(analyticsService, isNot(contains('dotenv.load(')));
      expect(
        analyticsService,
        isNot(contains("dotenv.env['MIXPANEL_PROJECT_TOKEN']")),
      );

      expect(mainFile, isNot(contains('package:flutter_dotenv/')));
      expect(mainFile, isNot(contains('dotenv.load(')));
      expect(mainFile, isNot(contains("dotenv.env['SENTRY_DSN']")));

      expect(loggerService, isNot(contains('package:flutter_dotenv/')));
      expect(loggerService, isNot(contains('dotenv.load(')));
      expect(loggerService, isNot(contains("dotenv.env['SENTRY_DSN']")));
    });

    test('pubspec no longer declares flutter_dotenv or dotenv asset', () async {
      final pubspec = await _readRepoFile('pubspec.yaml');

      expect(pubspec, isNot(contains('flutter_dotenv:')));
      expect(
        pubspec,
        isNot(contains(RegExp(r'^\s*-\s+dotenv\s*$', multiLine: true))),
      );
    });

    test('CI workflow no longer generates a dotenv file', () async {
      final workflow = await _readRepoFile('.github/workflows/main.yml');

      expect(workflow, isNot(contains('Create dotenv file')));
      expect(workflow, isNot(contains('file_name: dotenv')));
      expect(workflow, isNot(contains('SpicyPizza/create-envfile')));
    });
  });
}

Future<String> _readRepoFile(String relativePath) async {
  final file = File(relativePath);
  expect(file.existsSync(), isTrue, reason: 'Expected $relativePath to exist');
  return file.readAsString();
}
