import 'dart:ui' show TextDirection;

import 'package:flutter_test/flutter_test.dart';
import 'package:mazilon/pages/MoodMedicine/mood_medicine_report_exporter.dart';
import 'package:mazilon/pages/MoodMedicine/mood_medicine_report_renderer.dart';

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

  test('report content omits notes unless they are explicitly selected', () {
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

  test('report content includes notes only after explicit opt-in', () {
    final report = input(includeNotes: true);

    expect(report.buildTextContent(), contains('Private journal detail'));
    expect(
      report.buildSections().map((section) => section.heading),
      contains('Notes'),
    );
  });

  test(
    'report includes daily mood, activity union, association, and sources',
    () {
      final content = input().buildTextContent();

      expect(content, contains('1 January: Mood 3.5/5'));
      expect(content, contains('Walk'));
      expect(content, contains('Sleep'));
      expect(content, contains('This is an association, not causation.'));
      expect(content, contains('https://example.org/source'));
    },
  );

  test('report file names are safe and format-specific', () {
    final report = input();

    expect(report.fileNameFor(MoodMedicineReportFormat.pdf), 'mood-report.pdf');
    expect(report.fileNameFor(MoodMedicineReportFormat.png), 'mood-report.png');
  });

  testWidgets('an oversized PNG returns an explicit non-delivery status', (
    tester,
  ) async {
    final exporter = MoodMedicineReportExporter(
      pngRenderer: const MoodMedicinePngReportRenderer(maxImageHeight: 1),
    );

    final delivery = await exporter.export(
      input(includeNotes: true),
      MoodMedicineReportFormat.png,
    );

    expect(delivery.status, MoodMedicineReportDeliveryStatus.tooLarge);
  });
}
