import 'dart:typed_data';
import 'dart:ui' show TextDirection;

import 'package:flutter/widgets.dart' show Widget;
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mazilon/features/mood_medicine/data/mood_medicine_report_exporter.dart';
import 'package:mazilon/features/mood_medicine/data/mood_medicine_report_renderer.dart';
import 'package:mazilon/util/logger_service.dart';

void main() {
  const labels = MoodMedicineReportLabels(
    moodLabel: 'Mood',
    activitiesLabel: 'Activities',
    associationsLabel: 'Associations',
    notesLabel: 'Notes',
    sourcesLabel: 'Sources',
    noDataLabel: 'No data',
    withActivityLabel: 'With activity',
    withoutActivityLabel: 'Without activity',
    associationDisclaimer: 'This is an association, not causation.',
  );

  MoodMedicineReportInput input({bool includeNotes = false}) {
    return MoodMedicineReportInput(
      title: 'Mood report',
      dateRangeLabel: '1-7 January',
      labels: labels,
      includeNotes: includeNotes,
      textDirection: TextDirection.rtl,
      fileNameStem: 'מזילון mood report!',
      days: <MoodMedicineReportDay>[
        MoodMedicineReportDay(
          dayLabel: '1 January',
          moodAverage: 3.5,
          activities: <String>['Walk', 'Sleep'],
          note: 'Private journal detail',
        ),
        MoodMedicineReportDay(
          dayLabel: '2 January',
          moodAverage: 4,
          activities: <String>['Walk'],
        ),
      ],
      associations: const <MoodMedicineReportAssociation>[
        MoodMedicineReportAssociation(
          activityLabel: 'Walk',
          withActivityMoodAverage: 4,
          withoutActivityMoodAverage: 3,
        ),
      ],
      sources: <MoodMedicineReportSource>[
        MoodMedicineReportSource(
          title: 'A trusted source',
          url: Uri.parse('https://example.org/source'),
        ),
      ],
    );
  }

  group('MoodMedicineReportInput', () {
    test('should omit notes unless they are explicitly selected', () {
      final report = input();

      expect(
        report.buildTextContent(),
        isNot(contains('Private journal detail')),
      );
      expect(
        report.buildSections().map((section) => section.heading),
        isNot(contains('Notes')),
      );
    });

    test('should include notes only after explicit opt-in', () {
      final report = input(includeNotes: true);

      expect(report.buildTextContent(), contains('Private journal detail'));
      expect(
        report.buildSections().map((section) => section.heading),
        contains('Notes'),
      );
    });

    test(
      'should include daily mood, activity union, association, and sources',
      () {
        final content = input().buildTextContent();

        expect(content, contains('1 January: Mood 3.5/5'));
        expect(content, contains('Walk'));
        expect(content, contains('Sleep'));
        expect(content, contains('This is an association, not causation.'));
        expect(content, contains('https://example.org/source'));
      },
    );

    test('should create safe format-specific file names', () {
      final report = input();

      expect(
        report.fileNameFor(MoodMedicineReportFormat.pdf),
        'mood-report.pdf',
      );
      expect(
        report.fileNameFor(MoodMedicineReportFormat.png),
        'mood-report.png',
      );
    });

    testWidgets(
      'should return an explicit non-delivery status for oversized PNG',
      (tester) async {
        final exporter = MoodMedicineReportExporter(
          pngRenderer: const MoodMedicinePngReportRenderer(maxImageHeight: 1),
        );

        final delivery = await exporter.export(
          input(includeNotes: true),
          MoodMedicineReportFormat.png,
        );

        expect(delivery.status, MoodMedicineReportDeliveryStatus.tooLarge);
      },
    );

    test('should log renderer failures without report contents', () async {
      final _CapturingLogger logger = _CapturingLogger();
      await GetIt.instance.reset();
      addTearDown(GetIt.instance.reset);
      GetIt.instance.registerSingleton<IncidentLoggerService>(logger);
      final MoodMedicineReportExporter exporter = MoodMedicineReportExporter(
        pdfRenderer: _ThrowingPdfRenderer(),
      );

      await expectLater(
        exporter.build(input(), MoodMedicineReportFormat.pdf),
        throwsA(isA<StateError>()),
      );

      expect(logger.logs, hasLength(1));
      final String payload = logger.logs.single.toString();
      expect(payload, contains('render'));
      expect(payload, contains('StateError'));
      expect(payload, isNot(contains('private note')));
      expect(payload, isNot(contains('https://example.test/source')));
      expect(logger.stackTraces.single, isNotNull);
    });
  });
}

final class _ThrowingPdfRenderer extends MoodMedicinePdfReportRenderer {
  @override
  Future<Uint8List> render(MoodMedicineReportInput input) async {
    throw StateError('private note https://example.test/source');
  }
}

final class _CapturingLogger implements IncidentLoggerService {
  final List<Object> logs = <Object>[];
  final List<StackTrace?> stackTraces = <StackTrace?>[];

  @override
  Future<void> captureLog(
    dynamic exception, {
    StackTrace? stackTrace,
    dynamic exceptionData,
  }) async {
    logs.add(exception as Object);
    stackTraces.add(stackTrace);
  }

  @override
  Future<void> initializeSentry(Widget myApp) async {}
}
