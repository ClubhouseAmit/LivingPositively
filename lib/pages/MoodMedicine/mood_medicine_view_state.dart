import 'dart:collection';
import 'dart:ui' show TextDirection;

import 'package:flutter/foundation.dart';

import 'package:mazilon/pages/MoodMedicine/mood_medicine_insights.dart';
import 'package:mazilon/pages/MoodMedicine/mood_medicine_models.dart';
import 'package:mazilon/pages/MoodMedicine/mood_medicine_report_delivery_types.dart';
import 'package:mazilon/pages/MoodMedicine/mood_medicine_report_models.dart';
import 'package:mazilon/pages/MoodMedicine/mood_medicine_repository.dart';

/// The first surface selected when a Mood Medicine page is composed.
enum MoodMedicineInitialView { checkIn, insights, education }

/// Immutable phases the Mood Medicine page can render.
sealed class MoodMedicineViewState {
  /// Creates a view state.
  const MoodMedicineViewState();
}

/// Indicates that the feature-local snapshot is currently loading.
final class MoodMedicineLoadingState extends MoodMedicineViewState {
  /// Creates the loading state for [initialView].
  const MoodMedicineLoadingState({
    this.initialView = MoodMedicineInitialView.insights,
  });

  /// View to show once loading succeeds.
  final MoodMedicineInitialView initialView;
}

/// Indicates that saved data cannot be read safely and requires confirmation.
final class MoodMedicineRecoveryRequiredState extends MoodMedicineViewState {
  /// Creates a recovery-required state for [failure].
  const MoodMedicineRecoveryRequiredState({
    required this.failure,
    required this.initialView,
    this.isDiscarding = false,
    this.discardError,
  });

  /// Typed failure explaining why normal writes and prompts are blocked.
  final MoodMedicineLoadFailure failure;

  /// View to show only after the person retries or discards the unreadable key.
  final MoodMedicineInitialView initialView;

  /// Whether the confirmed feature-only discard write is running.
  final bool isDiscarding;

  /// Error from a failed feature-only discard attempt, if any.
  final Object? discardError;
}

/// Immutable state rendered after a snapshot was loaded or safely initialized.
final class MoodMedicineReadyState extends MoodMedicineViewState {
  /// Creates a ready state from feature-local data and presentation state.
  MoodMedicineReadyState({
    required this.snapshot,
    required this.selectedView,
    required this.selectedRange,
    required this.dashboard,
    this.checkInForm = const MoodMedicineCheckInForm.empty(),
    this.isCheckInDetailsExpanded = false,
    this.highlightedActivityId,
    this.presentation,
    this.persistence = const MoodMedicinePersistenceState(),
    this.export = const MoodMedicineExportState(),
  });

  /// The one immutable persisted Mood Medicine snapshot.
  final MoodMedicineSnapshot snapshot;

  /// Current top-level Mood Medicine surface.
  final MoodMedicineInitialView selectedView;

  /// Calendar interval selected for insights and exports.
  final MoodMedicineInsightRange selectedRange;

  /// Current range aggregation and activity-label resolution.
  final MoodMedicineDashboard dashboard;

  /// In-progress check-in values, retained after a failed save.
  final MoodMedicineCheckInForm checkInForm;

  /// Whether the optional emotions, activities, and note portion is visible.
  final bool isCheckInDetailsExpanded;

  /// Activity id currently highlighted in the chart, if any.
  final String? highlightedActivityId;

  /// Localized, UI-supplied presentation values used to build report input.
  final MoodMedicineReportPresentation? presentation;

  /// Awaited snapshot write state and retry payload.
  final MoodMedicinePersistenceState persistence;

  /// Current report build and delivery state.
  final MoodMedicineExportState export;

  /// Whether a snapshot write is in progress or waiting for an explicit retry.
  bool get writesBlocked => persistence.isSaving || persistence.hasPendingWrite;
}

/// Immutable in-progress check-in values owned by [MoodMedicineViewState].
@immutable
final class MoodMedicineCheckInForm {
  /// Creates a normalized check-in form.
  MoodMedicineCheckInForm({
    this.mood,
    Iterable<String> emotionIds = const <String>[],
    Iterable<String> activityIds = const <String>[],
    String? journalNote,
  }) : emotionIds = Set<String>.unmodifiable(_normalizedIds(emotionIds)),
       activityIds = Set<String>.unmodifiable(_normalizedIds(activityIds)),
       journalNote = _normalizedNote(journalNote);

  /// An empty form with no selected mood.
  const MoodMedicineCheckInForm.empty()
    : mood = null,
      emotionIds = const <String>{},
      activityIds = const <String>{},
      journalNote = null;

  /// Selected mood, or null until the person makes a choice.
  final int? mood;

  /// Selected emotion ids.
  final Set<String> emotionIds;

  /// Selected activity ids.
  final Set<String> activityIds;

  /// Optional private journal text.
  final String? journalNote;

  /// Whether a valid mood has been selected and a check-in can be saved.
  bool get canSave => mood != null && mood! >= 1 && mood! <= 5;

  /// Converts this form into a persistence draft when [canSave] is true.
  MoodMedicineCheckInDraft? get draft => canSave
      ? MoodMedicineCheckInDraft(
          mood: mood!,
          emotionIds: emotionIds,
          activityIds: activityIds,
          note: journalNote,
        )
      : null;
}

/// Current range aggregation and presentation-ready activity labels.
@immutable
final class MoodMedicineDashboard {
  /// Creates immutable derived insights for the selected range.
  MoodMedicineDashboard({
    required Iterable<MoodMedicineDailySummary> summaries,
    required Iterable<MoodMedicineAssociation> associations,
    Map<String, String> rangeActivityLabels = const <String, String>{},
    Map<String, Map<String, String>> dayActivityLabels =
        const <String, Map<String, String>>{},
  }) : summaries = List<MoodMedicineDailySummary>.unmodifiable(summaries),
       associations = List<MoodMedicineAssociation>.unmodifiable(associations),
       rangeActivityLabels = UnmodifiableMapView<String, String>(
         Map<String, String>.from(rangeActivityLabels),
       ),
       dayActivityLabels = UnmodifiableMapView<String, Map<String, String>>(
         Map<String, Map<String, String>>.unmodifiable(
           dayActivityLabels.map(
             (String dayKey, Map<String, String> labels) =>
                 MapEntry<String, Map<String, String>>(
                   dayKey,
                   UnmodifiableMapView<String, String>(
                     Map<String, String>.from(labels),
                   ),
                 ),
           ),
         ),
       );

  /// Daily averages and activity unions inside the selected interval.
  final List<MoodMedicineDailySummary> summaries;

  /// Non-causal activity associations meeting the minimum-day threshold.
  final List<MoodMedicineAssociation> associations;

  /// Latest relevant historical label for each activity in the selected range.
  final Map<String, String> rangeActivityLabels;

  /// Latest relevant label for each activity on each represented day.
  final Map<String, Map<String, String>> dayActivityLabels;

  /// Returns a presentation-safe label for [activityId] on [dayKey].
  String activityLabelForDay(String dayKey, String activityId) {
    return dayActivityLabels[dayKey]?[activityId] ??
        rangeActivityLabels[activityId] ??
        activityId;
  }

  /// Returns a presentation-safe label for [activityId] across this range.
  String activityLabelForRange(String activityId) =>
      rangeActivityLabels[activityId] ?? activityId;
}

/// State retained for an awaited snapshot write and its explicit retry.
@immutable
final class MoodMedicinePersistenceState {
  /// Creates persistence state for a ready Mood Medicine screen.
  const MoodMedicinePersistenceState({
    this.isSaving = false,
    this.hasPendingWrite = false,
    this.pendingCheckInDraft,
    this.error,
  });

  /// Whether a write is currently awaiting the repository.
  final bool isSaving;

  /// Whether the view model retained a feature-local mutation for retry.
  ///
  /// The retry intent is deliberately not a stale full snapshot: the
  /// repository rebases it on the latest committed history.
  final bool hasPendingWrite;

  /// Check-in draft retained only when the failed write was a check-in.
  final MoodMedicineCheckInDraft? pendingCheckInDraft;

  /// Write error shown through the existing retry pattern.
  final Object? error;
}

/// Stages for a locally built report and its explicit platform handoff.
enum MoodMedicineExportPhase { idle, building, ready, delivering, failed }

/// The bounded reason a report build could not create a previewable document.
enum MoodMedicineReportBuildFailureKind {
  /// A single PNG would exceed the feature's safe canvas limit.
  pngTooLarge,

  /// The renderer could not produce a report for another reason.
  renderer,
}

/// Immutable report settings, bytes, and delivery state.
@immutable
final class MoodMedicineExportState {
  /// Creates report export state.
  const MoodMedicineExportState({
    this.format = MoodMedicineReportFormat.pdf,
    this.includeNotes = false,
    this.phase = MoodMedicineExportPhase.idle,
    this.input,
    this.report,
    this.error,
    this.buildFailureKind,
  });

  /// Binary format selected by the person.
  final MoodMedicineReportFormat format;

  /// Whether private journal notes are explicitly included.
  final bool includeNotes;

  /// Build or handoff stage for the current report.
  final MoodMedicineExportPhase phase;

  /// Immutable report DTO built by the view model.
  final MoodMedicineReportInput? input;

  /// Defensively owned report bytes ready for preview or explicit sharing.
  final MoodMedicineBuiltReport? report;

  /// Build or delivery error, if any.
  final Object? error;

  /// Typed build failure used for privacy-safe, localized recovery guidance.
  final MoodMedicineReportBuildFailureKind? buildFailureKind;

  /// Whether the page should disable export controls while work is in progress.
  bool get isWorking =>
      phase == MoodMedicineExportPhase.building ||
      phase == MoodMedicineExportPhase.delivering;
}

/// Pure localized values supplied by the page without a [BuildContext].
@immutable
final class MoodMedicineReportPresentation {
  /// Creates localized report and activity-label presentation data.
  MoodMedicineReportPresentation({
    required this.title,
    required Map<MoodMedicineInsightRange, String> rangeLabels,
    required this.labels,
    required Map<String, String> defaultActivityLabels,
    required List<MoodMedicineReportSource> sources,
    required this.textDirection,
    required this.dayLabelFor,
    this.fileNameStem = 'mood-medicine-report',
  }) : rangeLabels = UnmodifiableMapView<MoodMedicineInsightRange, String>(
         Map<MoodMedicineInsightRange, String>.from(rangeLabels),
       ),
       defaultActivityLabels = UnmodifiableMapView<String, String>(
         Map<String, String>.from(defaultActivityLabels),
       ),
       sources = List<MoodMedicineReportSource>.unmodifiable(sources);

  /// Localized report title.
  final String title;

  /// Localized names for each supported insight range.
  final Map<MoodMedicineInsightRange, String> rangeLabels;

  /// Localized report section labels.
  final MoodMedicineReportLabels labels;

  /// Localized labels for the eight stable default activity ids.
  final Map<String, String> defaultActivityLabels;

  /// Educational sources to include in a report.
  final List<MoodMedicineReportSource> sources;

  /// Text direction for the report renderer.
  final TextDirection textDirection;

  /// Formats the persisted local day key without exposing UI context to the VM.
  final String Function(String dayKey) dayLabelFor;

  /// Safe filename stem chosen by the composition layer.
  final String fileNameStem;
}

/// One-shot side effects emitted by [MoodMedicineViewModel] consumers.
sealed class MoodMedicineUiEffect {
  /// Creates a one-shot UI effect.
  const MoodMedicineUiEffect();
}

/// Announces that a check-in persisted and the page should show insights.
final class MoodMedicineCheckInSavedEffect extends MoodMedicineUiEffect {
  /// Creates the saved-check-in effect.
  const MoodMedicineCheckInSavedEffect();
}

/// Requests the existing retry snackbar after a persistence write failed.
final class MoodMedicinePersistenceFailedEffect extends MoodMedicineUiEffect {
  /// Creates a persistence-failed effect for [error].
  const MoodMedicinePersistenceFailedEffect(this.error);

  /// Error retained in state for an explicit retry.
  final Object error;
}

/// Announces that a report was built and is ready for the preview page.
final class MoodMedicineReportReadyEffect extends MoodMedicineUiEffect {
  /// Creates a ready-report effect.
  const MoodMedicineReportReadyEffect(this.report);

  /// Defensively owned bytes to pass to a display-only preview.
  final MoodMedicineBuiltReport report;
}

/// Announces the result of an explicit report delivery attempt.
final class MoodMedicineReportDeliveryEffect extends MoodMedicineUiEffect {
  /// Creates a report delivery effect.
  const MoodMedicineReportDeliveryEffect(this.delivery);

  /// Platform-neutral handoff result.
  final MoodMedicineReportDelivery delivery;
}

Set<String> _normalizedIds(Iterable<String> values) {
  final Set<String> result = <String>{};
  for (final String value in values) {
    final String normalized = value.trim();
    if (normalized.isNotEmpty) {
      result.add(normalized);
    }
  }
  return result;
}

String? _normalizedNote(String? value) {
  final String normalized = value?.trim() ?? '';
  return normalized.isEmpty ? null : normalized;
}
