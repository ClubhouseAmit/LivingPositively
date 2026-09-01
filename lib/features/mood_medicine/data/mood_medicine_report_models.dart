import 'dart:ui' show TextDirection;

import 'package:flutter/foundation.dart';

/// The binary document type selected by the person exporting their data.
enum MoodMedicineReportFormat { pdf, png }

extension MoodMedicineReportFormatExtension on MoodMedicineReportFormat {
  String get fileExtension {
    return switch (this) {
      MoodMedicineReportFormat.pdf => 'pdf',
      MoodMedicineReportFormat.png => 'png',
    };
  }

  String get mimeType {
    return switch (this) {
      MoodMedicineReportFormat.pdf => 'application/pdf',
      MoodMedicineReportFormat.png => 'image/png',
    };
  }
}

/// Localized labels supplied by the dashboard when it builds a report.
///
/// Keeping presentation text at the call site means this feature does not
/// duplicate localization state or make an export depend on a [BuildContext].
@immutable
class MoodMedicineReportLabels {
  const MoodMedicineReportLabels({
    required this.moodLabel,
    required this.activitiesLabel,
    required this.associationsLabel,
    required this.notesLabel,
    required this.sourcesLabel,
    required this.noDataLabel,
    required this.withActivityLabel,
    required this.withoutActivityLabel,
    required this.associationDisclaimer,
  });

  final String moodLabel;
  final String activitiesLabel;
  final String associationsLabel;
  final String notesLabel;
  final String sourcesLabel;
  final String noDataLabel;
  final String withActivityLabel;
  final String withoutActivityLabel;

  /// A localized association-not-causation explanation.
  final String associationDisclaimer;
}

/// One local-day aggregate shown in an exported mood report.
@immutable
class MoodMedicineReportDay {
  MoodMedicineReportDay({
    required this.dayLabel,
    required double moodAverage,
    List<String> activities = const <String>[],
    String? note,
  }) : moodAverage = _validatedMoodAverage(moodAverage, 'moodAverage'),
       activities = List<String>.unmodifiable(
         activities.where((activity) => activity.trim().isNotEmpty),
       ),
       note = note?.trim();

  final String dayLabel;
  final double moodAverage;
  final List<String> activities;

  /// The person's optional journal content. It is never exported unless the
  /// enclosing [MoodMedicineReportInput.includeNotes] is explicitly true.
  final String? note;
}

/// A non-causal comparison between days with and without one activity.
@immutable
class MoodMedicineReportAssociation {
  MoodMedicineReportAssociation({
    required this.activityLabel,
    required double withActivityMoodAverage,
    required double withoutActivityMoodAverage,
  }) : withActivityMoodAverage = _validatedMoodAverage(
         withActivityMoodAverage,
         'withActivityMoodAverage',
       ),
       withoutActivityMoodAverage = _validatedMoodAverage(
         withoutActivityMoodAverage,
         'withoutActivityMoodAverage',
       );

  final String activityLabel;
  final double withActivityMoodAverage;
  final double withoutActivityMoodAverage;
}

/// Source context included with an educational report.
@immutable
class MoodMedicineReportSource {
  const MoodMedicineReportSource({
    required this.title,
    required this.url,
    this.description,
  });

  final String title;
  final Uri url;
  final String? description;

  bool get hasSafeHttpsUrl =>
      url.scheme.toLowerCase() == 'https' && url.host.isNotEmpty;
}

/// A simple, renderer-agnostic report section.
@immutable
class MoodMedicineReportSection {
  MoodMedicineReportSection({
    required this.heading,
    required List<String> lines,
    this.isSourceSection = false,
  }) : lines = List<String>.unmodifiable(lines);

  final String heading;
  final List<String> lines;

  /// Identifies the generated source context independently of localized copy.
  ///
  /// Report labels can intentionally coincide in any supported language, so
  /// renderers must not infer this structural role from [heading].
  final bool isSourceSection;
}

/// Narrow data-transfer object consumed by the feature-local report exporter.
///
/// It intentionally has no dependency on the mood persistence models, so the
/// dashboard can map its selected range into a stable export boundary.
@immutable
class MoodMedicineReportInput {
  MoodMedicineReportInput({
    required this.title,
    required this.dateRangeLabel,
    required this.labels,
    required List<MoodMedicineReportDay> days,
    List<MoodMedicineReportSource> sources = const <MoodMedicineReportSource>[],
    List<MoodMedicineReportAssociation> associations =
        const <MoodMedicineReportAssociation>[],
    this.textDirection = TextDirection.ltr,
    this.includeNotes = false,
    this.fileNameStem = 'mood-medicine-report',
  }) : days = List<MoodMedicineReportDay>.unmodifiable(days),
       sources = List<MoodMedicineReportSource>.unmodifiable(sources),
       associations = List<MoodMedicineReportAssociation>.unmodifiable(
         associations,
       );

  final String title;
  final String dateRangeLabel;
  final MoodMedicineReportLabels labels;
  final List<MoodMedicineReportDay> days;
  final List<MoodMedicineReportSource> sources;
  final List<MoodMedicineReportAssociation> associations;
  final TextDirection textDirection;

  /// Defaults to false so journal text is private unless a person opts in at
  /// export time.
  final bool includeNotes;
  final String fileNameStem;

  bool get isRtl => textDirection == TextDirection.rtl;

  String fileNameFor(MoodMedicineReportFormat format) {
    final normalized = fileNameStem
        .replaceAll(RegExp(r'[^A-Za-z0-9_-]+'), '-')
        .replaceAll(RegExp(r'-+'), '-')
        .replaceAll(RegExp(r'^-|-$'), '');
    final stem = normalized.isEmpty ? 'mood-medicine-report' : normalized;
    return '$stem.${format.fileExtension}';
  }

  /// The shared content source for PDF, PNG, and privacy-focused tests.
  List<MoodMedicineReportSection> buildSections() {
    final sections = <MoodMedicineReportSection>[
      MoodMedicineReportSection(
        heading: labels.moodLabel,
        lines: days.isEmpty
            ? <String>[labels.noDataLabel]
            : days.map(_dailyMoodLine).toList(growable: false),
      ),
      MoodMedicineReportSection(
        heading: labels.activitiesLabel,
        lines: _activityLines(),
      ),
    ];

    if (associations.isNotEmpty) {
      sections.add(
        MoodMedicineReportSection(
          heading: labels.associationsLabel,
          lines: <String>[
            labels.associationDisclaimer,
            ...associations.map(_associationLine),
          ],
        ),
      );
    }

    if (includeNotes) {
      final notes = <String>[
        for (final day in days)
          if (day.note != null && day.note!.isNotEmpty)
            '${day.dayLabel}: ${day.note}',
      ];
      if (notes.isNotEmpty) {
        sections.add(
          MoodMedicineReportSection(heading: labels.notesLabel, lines: notes),
        );
      }
    }

    if (sources.isNotEmpty) {
      sections.add(
        MoodMedicineReportSection(
          heading: labels.sourcesLabel,
          lines: sources.map(_sourceLine).toList(growable: false),
          isSourceSection: true,
        ),
      );
    }

    return List<MoodMedicineReportSection>.unmodifiable(sections);
  }

  /// A text representation used by renderers and to make note privacy
  /// independently testable without a platform plugin.
  String buildTextContent() {
    return buildSections()
        .expand((section) => <String>[section.heading, ...section.lines])
        .join('\n');
  }

  String _dailyMoodLine(MoodMedicineReportDay day) {
    final activities = day.activities.isEmpty
        ? labels.noDataLabel
        : day.activities.join(', ');
    return '${day.dayLabel}: ${labels.moodLabel} '
        '${_formatMood(day.moodAverage)}/5 - '
        '${labels.activitiesLabel}: $activities';
  }

  List<String> _activityLines() {
    final activities = <String>{
      for (final day in days) ...day.activities,
    }.toList(growable: false);
    return activities.isEmpty ? <String>[labels.noDataLabel] : activities;
  }

  String _associationLine(MoodMedicineReportAssociation association) {
    return '${association.activityLabel}: '
        '${labels.withActivityLabel} '
        '${_formatMood(association.withActivityMoodAverage)}/5; '
        '${labels.withoutActivityLabel} '
        '${_formatMood(association.withoutActivityMoodAverage)}/5';
  }

  String _sourceLine(MoodMedicineReportSource source) {
    final description = source.description?.trim();
    final descriptionSuffix = description == null || description.isEmpty
        ? ''
        : ' - $description';
    return '${source.title}$descriptionSuffix\n${source.url}';
  }

  static String _formatMood(double value) {
    return value == value.roundToDouble()
        ? value.toStringAsFixed(0)
        : value.toStringAsFixed(1);
  }
}

double _validatedMoodAverage(double value, String parameterName) {
  if (!value.isFinite || value < 0 || value > 5) {
    throw ArgumentError.value(
      value,
      parameterName,
      'must be finite and between 0 and 5.',
    );
  }
  return value;
}
