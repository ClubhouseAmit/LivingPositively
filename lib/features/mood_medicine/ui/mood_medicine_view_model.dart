import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import 'package:mazilon/features/mood_medicine/data/mood_medicine_models.dart';
import 'package:mazilon/features/mood_medicine/data/mood_medicine_report_exporter.dart';
import 'package:mazilon/features/mood_medicine/data/mood_medicine_report_renderer.dart';
import 'package:mazilon/features/mood_medicine/data/mood_medicine_repository.dart';
import 'package:mazilon/features/mood_medicine/data/mood_medicine_source_link_service.dart';
import 'package:mazilon/features/mood_medicine/ui/mood_medicine_insights.dart';
import 'package:mazilon/features/mood_medicine/ui/mood_medicine_view_state.dart';
import 'package:mazilon/util/logger_service.dart';

/// Feature-local MVVM state holder for Mood Tracker and Personal Medicine.
///
/// It owns snapshot loading, recovery, drafts, dashboard aggregation, report
/// input construction, and platform-neutral export state. The page supplies
/// localized presentation values but never accesses persistence or renderers.
final class MoodMedicineViewModel extends ChangeNotifier {
  /// Creates a fresh page-scoped Mood Medicine view model.
  MoodMedicineViewModel(
    this._repository,
    this._reportExportService, {
    required MoodMedicineSourceLinkService sourceLinkService,
    required IncidentLoggerService incidentLoggerService,
    DateTime Function()? clock,
    String Function()? idGenerator,
  }) : // The public injection name intentionally differs from the private field.
       // ignore: prefer_initializing_formals
       _sourceLinkService = sourceLinkService,
       // ignore: prefer_initializing_formals
       _incidentLoggerService = incidentLoggerService,
       _clock = clock ?? DateTime.now,
       _idGenerator = idGenerator ?? const Uuid().v4;

  final MoodMedicineRepository _repository;
  final MoodMedicineReportExportService _reportExportService;
  final MoodMedicineSourceLinkService _sourceLinkService;
  final IncidentLoggerService _incidentLoggerService;
  final DateTime Function() _clock;
  final String Function() _idGenerator;
  final StreamController<MoodMedicineUiEffect> _effects =
      StreamController<MoodMedicineUiEffect>.broadcast();

  MoodMedicineViewState _state = const MoodMedicineLoadingState();
  int _loadGeneration = 0;
  bool _isDisposed = false;
  MoodMedicineSnapshotMutation? _pendingMutation;
  _MoodMedicineCheckInIntent? _pendingCheckInIntent;
  String? _pendingDeselectActivityId;
  int _nextReportBuildGeneration = 0;
  int? _activeReportBuildGeneration;
  _MoodMedicineReportInvalidation _activeReportBuildInvalidation =
      _MoodMedicineReportInvalidation.none;
  int _nextReportDeliveryGeneration = 0;
  int? _activeReportDeliveryGeneration;
  bool _activeReportDeliveryInvalidated = false;

  static const Object _unset = Object();

  /// Current immutable state rendered by the Mood Medicine page.
  MoodMedicineViewState get state => _state;

  /// Ready state, or null while loading or recovery requires confirmation.
  MoodMedicineReadyState? get readyState => switch (_state) {
    MoodMedicineReadyState ready => ready,
    _ => null,
  };

  /// One-shot UI effects such as retry snackbars and report preview requests.
  Stream<MoodMedicineUiEffect> get effects => _effects.stream;

  /// Loads the feature-local snapshot without ever replacing unreadable data.
  ///
  /// Repeated calls after a ready or recovery-required result are ignored. A
  /// malformed or unreadable result enters recovery instead of creating an
  /// empty snapshot; ordinary writes remain unavailable until retry or discard.
  Future<void> load({
    MoodMedicineInitialView initialView = MoodMedicineInitialView.insights,
  }) async {
    if (_isDisposed ||
        _state is MoodMedicineReadyState ||
        _state is MoodMedicineRecoveryRequiredState ||
        _state is MoodMedicineLoadingState && _loadGeneration > 0) {
      return;
    }
    await _load(initialView: initialView);
  }

  /// Retries only the repository read that produced a recovery state.
  ///
  /// It has no effect while loading or after disposal. A successful read moves
  /// to ready state; another unreadable result remains recoverable and writable
  /// history is still not replaced.
  Future<void> retryLoad() async {
    final MoodMedicineViewState currentState = _state;
    if (_isDisposed ||
        currentState is! MoodMedicineRecoveryRequiredState ||
        currentState.isDiscarding) {
      return;
    }
    await _load(
      initialView: currentState.initialView,
      checkInForm: currentState.checkInForm,
      isCheckInDetailsExpanded: currentState.isCheckInDetailsExpanded,
    );
  }

  /// Replaces only the unreadable feature snapshot after UI confirmation.
  ///
  /// This writes an empty v1 snapshot under the namespaced Mood Medicine key;
  /// it never calls the global reset contract or changes unrelated data.
  Future<bool> discardUnreadableSnapshot() async {
    final MoodMedicineViewState currentState = _state;
    if (currentState is! MoodMedicineRecoveryRequiredState) {
      return false;
    }
    final MoodMedicineRecoveryRequiredState recovery = currentState;
    if (recovery.isDiscarding || _isDisposed) {
      return false;
    }
    _setState(
      MoodMedicineRecoveryRequiredState(
        failure: recovery.failure,
        initialView: recovery.initialView,
        checkInForm: recovery.checkInForm,
        isCheckInDetailsExpanded: recovery.isCheckInDetailsExpanded,
        isDiscarding: true,
      ),
    );
    try {
      final MoodMedicineLoadResult result = await _repository
          .discardUnreadableSnapshot();
      if (result case MoodMedicineUnreadableSnapshot(:final failure)) {
        _setState(
          MoodMedicineRecoveryRequiredState(
            failure: failure,
            initialView: recovery.initialView,
            checkInForm: recovery.checkInForm,
            isCheckInDetailsExpanded: recovery.isCheckInDetailsExpanded,
          ),
        );
        return false;
      }
      final MoodMedicineSnapshot snapshot = switch (result) {
        MoodMedicineMissingSnapshot() => const MoodMedicineSnapshot.empty(),
        MoodMedicineLoadedSnapshot(:final MoodMedicineSnapshot snapshot) =>
          snapshot,
        MoodMedicineUnreadableSnapshot() => throw StateError(
          'Unreadable snapshots return before recovery completion.',
        ),
      };
      _pendingMutation = null;
      _pendingCheckInIntent = null;
      _pendingDeselectActivityId = null;
      _setState(
        _readyState(
          snapshot: snapshot,
          selectedView: recovery.initialView,
          checkInForm: recovery.checkInForm,
          isCheckInDetailsExpanded: recovery.isCheckInDetailsExpanded,
        ),
      );
      return true;
    } catch (error) {
      _setState(
        MoodMedicineRecoveryRequiredState(
          failure: recovery.failure,
          initialView: recovery.initialView,
          checkInForm: recovery.checkInForm,
          isCheckInDetailsExpanded: recovery.isCheckInDetailsExpanded,
          discardError: error,
        ),
      );
      return false;
    }
  }

  /// Returns true only for loaded, writable history with no entry for [now].
  ///
  /// Recovery, loading, and pending writes deliberately suppress automatic
  /// prompts. Dismissing a prompt never changes this answer.
  bool shouldPromptFor(DateTime now) {
    final MoodMedicineReadyState? ready = readyState;
    return ready != null &&
        !ready.writesBlocked &&
        !ready.snapshot.entries.any(
          (MoodMedicineEntry entry) =>
              entry.localDayKey == moodMedicineLocalDayKey(now),
        );
  }

  /// Selects the top-level surface shown by the page.
  void selectView(MoodMedicineInitialView view) {
    final MoodMedicineReadyState? ready = readyState;
    if (ready == null || ready.selectedView == view) {
      return;
    }
    _setState(_copyReady(ready, selectedView: view));
  }

  /// Selects the insight interval and recomputes its deterministic dashboard.
  void selectRange(MoodMedicineInsightRange range) {
    final MoodMedicineReadyState? ready = readyState;
    if (ready == null || ready.selectedRange == range) {
      return;
    }
    _setState(
      _copyReady(
        ready,
        selectedRange: range,
        export: _invalidatedExport(
          ready.export,
          reason: _MoodMedicineReportInvalidation.other,
        ),
      ),
    );
  }

  /// Supplies localized labels and sources without giving the VM a UI context.
  ///
  /// Call this from a dependency-aware page lifecycle method, not every build.
  void setReportPresentation(MoodMedicineReportPresentation presentation) {
    final MoodMedicineReadyState? ready = readyState;
    if (ready == null) {
      return;
    }
    _setState(
      _copyReady(
        ready,
        presentation: presentation,
        export: _invalidatedExport(
          ready.export,
          reason: _MoodMedicineReportInvalidation.presentation,
        ),
      ),
    );
  }

  /// Opens a researched education source through the feature data boundary.
  ///
  /// The page remains platform-plugin-free. A launcher rejection or exception
  /// emits the existing generic asynchronous-error presentation effect.
  Future<void> openEducationSource(Uri source) async {
    if (_isDisposed) {
      return;
    }
    try {
      final bool opened = await _sourceLinkService.openExternal(source);
      if (!opened) {
        _emit(const MoodMedicineSourceOpenFailedEffect());
      }
    } catch (error, stackTrace) {
      await _logSourceOpenFailure(error, stackTrace);
      _emit(const MoodMedicineSourceOpenFailedEffect());
    }
  }

  /// Selects one of the five allowed mood values for the current check-in.
  void selectMood(int mood) {
    if (mood < 1 || mood > 5) {
      throw ArgumentError.value(mood, 'mood', 'Must be from 1 to 5.');
    }
    final MoodMedicineReadyState? ready = _writableReadyState();
    if (ready == null) {
      return;
    }
    _setState(
      _copyReady(
        ready,
        checkInForm: MoodMedicineCheckInForm(
          mood: mood,
          emotionIds: ready.checkInForm.emotionIds,
          activityIds: ready.checkInForm.activityIds,
          journalNote: ready.checkInForm.journalNote,
        ),
        isCheckInDetailsExpanded: true,
      ),
    );
  }

  /// Toggles [emotionId] in the current in-memory check-in form.
  void toggleEmotion(String emotionId) {
    final MoodMedicineReadyState? ready = _writableReadyState();
    final String normalizedId = emotionId.trim();
    if (ready == null || normalizedId.isEmpty) {
      return;
    }
    final Set<String> emotionIds = <String>{...ready.checkInForm.emotionIds};
    if (!emotionIds.add(normalizedId)) {
      emotionIds.remove(normalizedId);
    }
    _setState(
      _copyReady(
        ready,
        checkInForm: MoodMedicineCheckInForm(
          mood: ready.checkInForm.mood,
          emotionIds: emotionIds,
          activityIds: ready.checkInForm.activityIds,
          journalNote: ready.checkInForm.journalNote,
        ),
      ),
    );
  }

  /// Toggles a default or active custom [activityId] in a future check-in.
  ///
  /// Deleted historical ids and unknown ids are intentionally ignored so they
  /// cannot reach new insights or reports.
  void toggleActivity(String activityId) {
    final MoodMedicineReadyState? ready = _writableReadyState();
    final String normalizedId = activityId.trim();
    if (ready == null || !_isSelectableActivity(ready.snapshot, normalizedId)) {
      return;
    }
    final Set<String> activityIds = <String>{...ready.checkInForm.activityIds};
    if (!activityIds.add(normalizedId)) {
      activityIds.remove(normalizedId);
    }
    _setState(
      _copyReady(
        ready,
        checkInForm: MoodMedicineCheckInForm(
          mood: ready.checkInForm.mood,
          emotionIds: ready.checkInForm.emotionIds,
          activityIds: activityIds,
          journalNote: ready.checkInForm.journalNote,
        ),
      ),
    );
  }

  /// Stores optional journal text in immutable view state until save succeeds.
  void setJournalNote(String? value) {
    final MoodMedicineReadyState? ready = _writableReadyState();
    if (ready == null) {
      return;
    }
    _setState(
      _copyReady(
        ready,
        checkInForm: MoodMedicineCheckInForm(
          mood: ready.checkInForm.mood,
          emotionIds: ready.checkInForm.emotionIds,
          activityIds: ready.checkInForm.activityIds,
          journalNote: value,
        ),
      ),
    );
  }

  /// Expands or collapses optional check-in details without changing the draft.
  void setCheckInDetailsExpanded(bool value) {
    final MoodMedicineReadyState? ready = readyState;
    if (ready == null || ready.isCheckInDetailsExpanded == value) {
      return;
    }
    _setState(_copyReady(ready, isCheckInDetailsExpanded: value));
  }

  /// Highlights [activityId] on the trend chart, or clears the highlight.
  void setHighlightedActivity(String? activityId) {
    final MoodMedicineReadyState? ready = readyState;
    if (ready == null) {
      return;
    }
    final String? normalizedId = activityId?.trim();
    _setState(
      _copyReady(
        ready,
        highlightedActivityId: normalizedId == null || normalizedId.isEmpty
            ? null
            : normalizedId,
      ),
    );
  }

  /// Saves the selected check-in after filtering to currently selectable ids.
  ///
  /// Returns false until a writable snapshot is loaded, while another write is
  /// pending, when no valid mood is selected, or when persistence fails. A
  /// failed write keeps the original draft and a rebased mutation intent for
  /// [retryLastWrite]; a successful save clears the check-in form.
  Future<bool> saveCheckIn() async {
    final MoodMedicineReadyState? ready = _writableReadyState();
    final MoodMedicineCheckInDraft? sourceDraft = ready?.checkInForm.draft;
    if (ready == null || sourceDraft == null) {
      return false;
    }
    final _MoodMedicineCheckInIntent intent = _MoodMedicineCheckInIntent(
      id: _newId(ready.snapshot),
      occurredAt: _clock(),
      draft: sourceDraft,
      isSelectableActivity: _isSelectableActivity,
    );
    return _persist(
      ready,
      intent.apply,
      pendingCheckInDraft: intent.draft,
      checkInIntent: intent,
    );
  }

  /// Adds a new active custom activity and returns it after persistence succeeds.
  ///
  /// Throws [ArgumentError] for a blank [label]. Returns null when history is
  /// not writable or persistence fails; in the latter case the pending
  /// mutation remains available through [retryLastWrite].
  Future<MoodMedicineCustomActivity?> addCustomActivity(String label) async {
    final MoodMedicineReadyState? ready = _writableReadyState();
    final String normalizedLabel = label.trim();
    if (ready == null) {
      return null;
    }
    if (normalizedLabel.isEmpty) {
      throw ArgumentError.value(label, 'label', 'Cannot be empty.');
    }
    final MoodMedicineCustomActivity activity = MoodMedicineCustomActivity(
      id: _newId(ready.snapshot),
      label: normalizedLabel,
    );
    final bool didSave = await _persist(ready, (
      MoodMedicineSnapshot currentSnapshot,
    ) {
      if (currentSnapshot.customActivityForId(activity.id) != null) {
        return currentSnapshot;
      }
      return currentSnapshot.copyWith(
        customActivities: <MoodMedicineCustomActivity>[
          ...currentSnapshot.customActivities,
          activity,
        ],
      );
    });
    return didSave ? activity : null;
  }

  /// Renames an active custom activity without changing historical snapshots.
  ///
  /// Throws [ArgumentError] for a blank [label]. Returns false when history is
  /// not writable, [id] is not an active custom activity, or the awaited write
  /// fails; failed writes retain a retryable mutation.
  Future<bool> editCustomActivity(String id, String label) async {
    final MoodMedicineReadyState? ready = _writableReadyState();
    final String normalizedLabel = label.trim();
    if (ready == null) {
      return false;
    }
    if (normalizedLabel.isEmpty) {
      throw ArgumentError.value(label, 'label', 'Cannot be empty.');
    }
    if (ready.snapshot.customActivityForId(id) == null) {
      return false;
    }
    final bool didSave = await _persist(ready, (
      MoodMedicineSnapshot currentSnapshot,
    ) {
      final List<MoodMedicineCustomActivity> updated = currentSnapshot
          .customActivities
          .map((MoodMedicineCustomActivity activity) {
            if (activity.id != id) {
              return activity;
            }
            return activity.copyWith(label: normalizedLabel);
          })
          .toList(growable: false);
      return currentSnapshot.copyWith(customActivities: updated);
    });
    return didSave &&
        readyState?.snapshot.customActivityForId(id)?.label == normalizedLabel;
  }

  /// Deletes an active custom activity while retaining labelled history.
  ///
  /// Returns false when history is not writable, [id] is unknown, or
  /// persistence fails. Existing entry label snapshots remain unchanged, and a
  /// failed deletion is retained for [retryLastWrite].
  Future<bool> deleteCustomActivity(String id) async {
    final MoodMedicineReadyState? ready = _writableReadyState();
    if (ready == null) {
      return false;
    }
    if (ready.snapshot.customActivityForId(id) == null) {
      return false;
    }
    final bool didSave = await _persist(ready, (
      MoodMedicineSnapshot currentSnapshot,
    ) {
      final List<MoodMedicineCustomActivity> updated = currentSnapshot
          .customActivities
          .where((MoodMedicineCustomActivity activity) => activity.id != id)
          .toList(growable: false);
      return currentSnapshot.copyWith(customActivities: updated);
    }, deselectActivityId: id);
    return didSave && readyState?.snapshot.customActivityForId(id) == null;
  }

  /// Hides one stable default activity from future check-ins.
  ///
  /// Throws [ArgumentError] when [activityId] is not a stable default ID.
  /// Returns false when history is not writable or persistence fails; the
  /// failed mutation remains retryable without changing historical entries.
  Future<bool> hideDefaultActivity(String activityId) async {
    final MoodMedicineReadyState? ready = _writableReadyState();
    _ensureDefaultActivityId(activityId);
    if (ready == null) {
      return false;
    }
    return _persist(
      ready,
      (MoodMedicineSnapshot currentSnapshot) => currentSnapshot.copyWith(
        hiddenDefaultActivityIds: <String>{
          ...currentSnapshot.hiddenDefaultActivityIds,
          activityId,
        },
      ),
      deselectActivityId: activityId,
    );
  }

  /// Restores a hidden stable default activity for future check-ins.
  ///
  /// Throws [ArgumentError] when [activityId] is not a stable default ID.
  /// Returns false when history is not writable or persistence fails; the
  /// failed mutation remains retryable without changing historical entries.
  Future<bool> restoreDefaultActivity(String activityId) async {
    final MoodMedicineReadyState? ready = _writableReadyState();
    _ensureDefaultActivityId(activityId);
    if (ready == null) {
      return false;
    }
    return _persist(ready, (MoodMedicineSnapshot currentSnapshot) {
      final Set<String> updated = <String>{
        ...currentSnapshot.hiddenDefaultActivityIds,
      }..remove(activityId);
      return currentSnapshot.copyWith(hiddenDefaultActivityIds: updated);
    });
  }

  /// Retries the mutation retained after the latest failed write.
  ///
  /// Returns false when there is no loaded retry payload or a write is already
  /// in progress. A failed retry preserves the same mutation and draft again;
  /// a successful retry applies the normal successful-write state transition,
  /// including any activity removal that accompanied a hide or delete.
  Future<bool> retryLastWrite() async {
    final MoodMedicineReadyState? ready = readyState;
    final MoodMedicinePersistenceState persistence =
        ready?.persistence ?? const MoodMedicinePersistenceState();
    final MoodMedicineSnapshotMutation? mutation = _pendingMutation;
    if (ready == null ||
        mutation == null ||
        !persistence.hasPendingWrite ||
        persistence.isSaving) {
      return false;
    }
    return _persist(
      ready,
      mutation,
      pendingCheckInDraft: persistence.pendingCheckInDraft,
      checkInIntent: _pendingCheckInIntent,
      deselectActivityId: _pendingDeselectActivityId,
      isRetry: true,
    );
  }

  /// Updates the selected report [format] and private-note opt-in setting.
  void setReportOptions({
    MoodMedicineReportFormat? format,
    bool? includeNotes,
  }) {
    final MoodMedicineReadyState? ready = readyState;
    if (ready == null || ready.export.isWorking) {
      return;
    }
    final MoodMedicineReportFormat nextFormat = format ?? ready.export.format;
    final bool nextIncludeNotes = includeNotes ?? ready.export.includeNotes;
    if (nextFormat == ready.export.format &&
        nextIncludeNotes == ready.export.includeNotes &&
        ready.export.phase == MoodMedicineExportPhase.idle) {
      return;
    }
    _setState(
      _copyReady(
        ready,
        export: MoodMedicineExportState(
          format: nextFormat,
          includeNotes: nextIncludeNotes,
        ),
      ),
    );
  }

  /// Ends the current export sheet's privacy-consent session.
  ///
  /// The selected format is retained, but private-note consent and any built
  /// payload are cleared. In-flight work keeps its busy phase until its own
  /// completion so reopening the sheet cannot start an overlapping operation.
  void endReportExportSession() {
    final MoodMedicineReadyState? ready = readyState;
    if (ready == null) {
      return;
    }
    _setState(
      _copyReady(
        ready,
        export: _invalidatedExport(
          ready.export,
          reason: _MoodMedicineReportInvalidation.other,
          resetIncludeNotes: true,
        ),
      ),
    );
  }

  /// Builds the selected report for a preview without invoking platform UI.
  ///
  /// A renderer completion is typed so the page retries only if localized
  /// presentation changed during rendering. Changes to the selected range,
  /// report settings, data, or page lifecycle cancel the stale work instead.
  Future<MoodMedicineReportBuildOutcome> buildReport() async {
    final MoodMedicineReadyState? ready = readyState;
    if (ready == null || ready.export.isWorking) {
      return const MoodMedicineReportBuildCancelledOutcome();
    }
    final MoodMedicineReportInput? input = _buildReportInput(ready);
    final MoodMedicineReportPresentation? presentation = ready.presentation;
    if (input == null || presentation == null) {
      return const MoodMedicineReportBuildCancelledOutcome();
    }
    final MoodMedicineReportFormat format = ready.export.format;
    final int generation = ++_nextReportBuildGeneration;
    _activeReportBuildGeneration = generation;
    _activeReportBuildInvalidation = _MoodMedicineReportInvalidation.none;
    _setState(
      _copyReady(
        ready,
        export: MoodMedicineExportState(
          format: format,
          includeNotes: ready.export.includeNotes,
          phase: MoodMedicineExportPhase.building,
          input: input,
        ),
      ),
    );
    try {
      final MoodMedicineBuiltReport report = await _reportExportService.build(
        input,
        format,
      );
      return _completeReportBuildSuccess(
        generation: generation,
        input: input,
        report: report,
      );
    } on MoodMedicinePngReportTooLargeException catch (error) {
      return _completeReportBuildFailure(
        generation: generation,
        input: input,
        error: error,
        failureKind: MoodMedicineReportBuildFailureKind.pngTooLarge,
      );
    } catch (error) {
      return _completeReportBuildFailure(
        generation: generation,
        input: input,
        error: error,
        failureKind: MoodMedicineReportBuildFailureKind.renderer,
      );
    }
  }

  MoodMedicineReportBuildOutcome _completeReportBuildSuccess({
    required int generation,
    required MoodMedicineReportInput input,
    required MoodMedicineBuiltReport report,
  }) {
    final MoodMedicineReportBuildOutcome? invalidated =
        _completeInvalidatedReportBuild(generation);
    if (invalidated != null) {
      return invalidated;
    }
    final MoodMedicineReadyState? current = readyState;
    if (current == null ||
        current.export.phase != MoodMedicineExportPhase.building ||
        !identical(current.export.input, input)) {
      _clearUnexpectedReportBuildFence(current);
      return const MoodMedicineReportBuildCancelledOutcome();
    }
    _setState(
      _copyReady(
        current,
        export: MoodMedicineExportState(
          format: current.export.format,
          includeNotes: current.export.includeNotes,
          phase: MoodMedicineExportPhase.ready,
          input: input,
          report: report,
        ),
      ),
    );
    _emit(MoodMedicineReportReadyEffect(report));
    return MoodMedicineReportBuiltOutcome(report);
  }

  MoodMedicineReportBuildOutcome _completeReportBuildFailure({
    required int generation,
    required MoodMedicineReportInput input,
    required Object error,
    required MoodMedicineReportBuildFailureKind failureKind,
  }) {
    final MoodMedicineReportBuildOutcome? invalidated =
        _completeInvalidatedReportBuild(generation);
    if (invalidated != null) {
      return invalidated;
    }
    final MoodMedicineReadyState? current = readyState;
    if (current == null ||
        current.export.phase != MoodMedicineExportPhase.building ||
        !identical(current.export.input, input)) {
      _clearUnexpectedReportBuildFence(current);
      return const MoodMedicineReportBuildCancelledOutcome();
    }
    _setState(
      _copyReady(
        current,
        export: MoodMedicineExportState(
          format: current.export.format,
          includeNotes: current.export.includeNotes,
          phase: MoodMedicineExportPhase.failed,
          input: input,
          error: failureKind == MoodMedicineReportBuildFailureKind.renderer
              ? error
              : null,
          buildFailureKind: failureKind,
        ),
      ),
    );
    return const MoodMedicineReportBuildFailedOutcome();
  }

  MoodMedicineReportBuildOutcome? _completeInvalidatedReportBuild(
    int generation,
  ) {
    if (_activeReportBuildGeneration != generation) {
      return const MoodMedicineReportBuildCancelledOutcome();
    }
    final _MoodMedicineReportInvalidation invalidation =
        _activeReportBuildInvalidation;
    _activeReportBuildGeneration = null;
    _activeReportBuildInvalidation = _MoodMedicineReportInvalidation.none;
    if (invalidation == _MoodMedicineReportInvalidation.none) {
      return null;
    }
    final MoodMedicineReadyState? current = readyState;
    if (current != null &&
        current.export.phase == MoodMedicineExportPhase.building) {
      _setState(
        _copyReady(
          current,
          export: MoodMedicineExportState(
            format: current.export.format,
            includeNotes: current.export.includeNotes,
          ),
        ),
      );
    }
    return invalidation == _MoodMedicineReportInvalidation.presentation
        ? const MoodMedicineReportBuildStalePresentationOutcome()
        : const MoodMedicineReportBuildCancelledOutcome();
  }

  void _clearUnexpectedReportBuildFence(MoodMedicineReadyState? current) {
    if (current == null ||
        current.export.phase != MoodMedicineExportPhase.building) {
      return;
    }
    _setState(
      _copyReady(
        current,
        export: MoodMedicineExportState(
          format: current.export.format,
          includeNotes: current.export.includeNotes,
        ),
      ),
    );
  }

  /// Hands the most recently built report to the existing share/download path.
  Future<bool> shareBuiltReport({String? shareText}) async {
    final MoodMedicineReadyState? ready = readyState;
    final MoodMedicineBuiltReport? report = ready?.export.report;
    if (ready == null || report == null || ready.export.isWorking) {
      return false;
    }
    final int generation = ++_nextReportDeliveryGeneration;
    _activeReportDeliveryGeneration = generation;
    _activeReportDeliveryInvalidated = false;
    _setState(
      _copyReady(
        ready,
        export: MoodMedicineExportState(
          format: ready.export.format,
          includeNotes: ready.export.includeNotes,
          phase: MoodMedicineExportPhase.delivering,
          input: ready.export.input,
          report: report,
        ),
      ),
    );
    try {
      final MoodMedicineReportDelivery delivery = await _reportExportService
          .deliver(report, shareText: shareText);
      final MoodMedicineReadyState? current = readyState;
      final bool isCurrentDelivery =
          _activeReportDeliveryGeneration == generation;
      final bool wasInvalidated =
          isCurrentDelivery && _activeReportDeliveryInvalidated;
      if (isCurrentDelivery) {
        _activeReportDeliveryGeneration = null;
        _activeReportDeliveryInvalidated = false;
      }
      if (current != null && wasInvalidated) {
        _setState(
          _copyReady(
            current,
            export: MoodMedicineExportState(
              format: current.export.format,
              includeNotes: current.export.includeNotes,
            ),
          ),
        );
      } else if (current != null &&
          isCurrentDelivery &&
          current.export.phase == MoodMedicineExportPhase.delivering &&
          identical(current.export.report, report)) {
        _setState(
          _copyReady(
            current,
            export: MoodMedicineExportState(
              format: current.export.format,
              includeNotes: current.export.includeNotes,
              phase: MoodMedicineExportPhase.ready,
              input: current.export.input,
              report: report,
            ),
          ),
        );
      }
      _emit(MoodMedicineReportDeliveryEffect(delivery));
      return delivery.didDeliver;
    } catch (error) {
      final MoodMedicineReadyState? current = readyState;
      final bool isCurrentDelivery =
          _activeReportDeliveryGeneration == generation;
      final bool wasInvalidated =
          isCurrentDelivery && _activeReportDeliveryInvalidated;
      if (isCurrentDelivery) {
        _activeReportDeliveryGeneration = null;
        _activeReportDeliveryInvalidated = false;
      }
      if (current != null && wasInvalidated) {
        _setState(
          _copyReady(
            current,
            export: MoodMedicineExportState(
              format: current.export.format,
              includeNotes: current.export.includeNotes,
            ),
          ),
        );
      } else if (current != null &&
          isCurrentDelivery &&
          current.export.phase == MoodMedicineExportPhase.delivering &&
          identical(current.export.report, report)) {
        _setState(
          _copyReady(
            current,
            export: MoodMedicineExportState(
              format: current.export.format,
              includeNotes: current.export.includeNotes,
              phase: MoodMedicineExportPhase.failed,
              input: current.export.input,
              report: report,
              error: error,
            ),
          ),
        );
      }
      return false;
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    unawaited(_effects.close());
    super.dispose();
  }

  Future<void> _load({
    required MoodMedicineInitialView initialView,
    MoodMedicineCheckInForm checkInForm = const MoodMedicineCheckInForm.empty(),
    bool isCheckInDetailsExpanded = false,
  }) async {
    final int generation = ++_loadGeneration;
    _setState(MoodMedicineLoadingState(initialView: initialView));
    late final MoodMedicineLoadResult result;
    try {
      result = await _repository.loadSnapshot();
    } catch (error) {
      result = MoodMedicineUnreadableSnapshot(
        MoodMedicineLoadFailure(
          MoodMedicineLoadFailureKind.readError,
          cause: error,
        ),
      );
    }
    if (_isDisposed || generation != _loadGeneration) {
      return;
    }
    switch (result) {
      case MoodMedicineMissingSnapshot():
        _setState(
          _readyState(
            snapshot: const MoodMedicineSnapshot.empty(),
            selectedView: initialView,
            checkInForm: checkInForm,
            isCheckInDetailsExpanded: isCheckInDetailsExpanded,
          ),
        );
      case MoodMedicineLoadedSnapshot(:final MoodMedicineSnapshot snapshot):
        _setState(
          _readyState(
            snapshot: snapshot,
            selectedView: initialView,
            checkInForm: checkInForm,
            isCheckInDetailsExpanded: isCheckInDetailsExpanded,
          ),
        );
      case MoodMedicineUnreadableSnapshot(
        :final MoodMedicineLoadFailure failure,
      ):
        _setState(
          MoodMedicineRecoveryRequiredState(
            failure: failure,
            initialView: initialView,
            checkInForm: checkInForm,
            isCheckInDetailsExpanded: isCheckInDetailsExpanded,
          ),
        );
    }
  }

  MoodMedicineReadyState _readyState({
    required MoodMedicineSnapshot snapshot,
    required MoodMedicineInitialView selectedView,
    MoodMedicineInsightRange selectedRange = MoodMedicineInsightRange.week,
    MoodMedicineCheckInForm checkInForm = const MoodMedicineCheckInForm.empty(),
    bool isCheckInDetailsExpanded = false,
    String? highlightedActivityId,
    MoodMedicineReportPresentation? presentation,
    MoodMedicinePersistenceState persistence =
        const MoodMedicinePersistenceState(),
    MoodMedicineExportState export = const MoodMedicineExportState(),
  }) {
    return MoodMedicineReadyState(
      snapshot: snapshot,
      selectedView: selectedView,
      selectedRange: selectedRange,
      dashboard: _dashboard(
        snapshot: snapshot,
        range: selectedRange,
        presentation: presentation,
      ),
      checkInForm: checkInForm,
      isCheckInDetailsExpanded: isCheckInDetailsExpanded,
      highlightedActivityId: highlightedActivityId,
      presentation: presentation,
      persistence: persistence,
      export: export,
    );
  }

  MoodMedicineReadyState _copyReady(
    MoodMedicineReadyState current, {
    MoodMedicineSnapshot? snapshot,
    MoodMedicineInitialView? selectedView,
    MoodMedicineInsightRange? selectedRange,
    MoodMedicineCheckInForm? checkInForm,
    bool? isCheckInDetailsExpanded,
    Object? highlightedActivityId = _unset,
    Object? presentation = _unset,
    MoodMedicinePersistenceState? persistence,
    MoodMedicineExportState? export,
  }) {
    final MoodMedicineSnapshot nextSnapshot = snapshot ?? current.snapshot;
    final MoodMedicineInsightRange nextRange =
        selectedRange ?? current.selectedRange;
    return _readyState(
      snapshot: nextSnapshot,
      selectedView: selectedView ?? current.selectedView,
      selectedRange: nextRange,
      checkInForm: checkInForm ?? current.checkInForm,
      isCheckInDetailsExpanded:
          isCheckInDetailsExpanded ?? current.isCheckInDetailsExpanded,
      highlightedActivityId: identical(highlightedActivityId, _unset)
          ? current.highlightedActivityId
          : highlightedActivityId as String?,
      presentation: identical(presentation, _unset)
          ? current.presentation
          : presentation as MoodMedicineReportPresentation?,
      persistence: persistence ?? current.persistence,
      export: export ?? current.export,
    );
  }

  MoodMedicineDashboard _dashboard({
    required MoodMedicineSnapshot snapshot,
    required MoodMedicineInsightRange range,
    required MoodMedicineReportPresentation? presentation,
  }) {
    final List<MoodMedicineDailySummary> summaries =
        MoodMedicineInsights.summariesForRange(
          snapshot.entries,
          range: range,
          anchor: _clock(),
        );
    final Set<String> dayKeys = summaries
        .map((MoodMedicineDailySummary summary) => summary.dayKey)
        .toSet();
    final Set<String> activityIds = summaries
        .expand((MoodMedicineDailySummary summary) => summary.activityIds)
        .toSet();
    final Map<String, String> rangeLabels = <String, String>{
      for (final String activityId in activityIds)
        activityId: _resolveActivityLabel(
          snapshot: snapshot,
          activityId: activityId,
          dayKeys: dayKeys,
          presentation: presentation,
        ),
    };
    final Map<String, Map<String, String>> dayLabels =
        <String, Map<String, String>>{
          for (final MoodMedicineDailySummary summary in summaries)
            summary.dayKey: <String, String>{
              for (final String activityId in summary.activityIds)
                activityId: _resolveActivityLabel(
                  snapshot: snapshot,
                  activityId: activityId,
                  dayKeys: <String>{summary.dayKey},
                  presentation: presentation,
                ),
            },
        };
    return MoodMedicineDashboard(
      summaries: summaries,
      associations: MoodMedicineInsights.associations(summaries),
      rangeActivityLabels: rangeLabels,
      dayActivityLabels: dayLabels,
    );
  }

  String _resolveActivityLabel({
    required MoodMedicineSnapshot snapshot,
    required String activityId,
    required Set<String> dayKeys,
    required MoodMedicineReportPresentation? presentation,
  }) {
    MoodMedicineEntry? latestSnapshotEntry;
    for (final MoodMedicineEntry entry in snapshot.entries) {
      if (!dayKeys.contains(entry.localDayKey) ||
          !entry.activityIds.contains(activityId) ||
          entry.customActivityLabelSnapshots[activityId] == null) {
        continue;
      }
      final DateTime? latestTime = latestSnapshotEntry?.occurredAtUtc;
      if (latestTime == null || entry.occurredAtUtc.isAfter(latestTime)) {
        latestSnapshotEntry = entry;
      }
    }
    final String? historicalLabel =
        latestSnapshotEntry?.customActivityLabelSnapshots[activityId];
    if (historicalLabel != null && historicalLabel.isNotEmpty) {
      return historicalLabel;
    }
    final MoodMedicineCustomActivity? activeCustom = snapshot
        .customActivityForId(activityId);
    if (activeCustom != null) {
      return activeCustom.label;
    }
    return presentation?.defaultActivityLabels[activityId] ?? activityId;
  }

  MoodMedicineReportInput? _buildReportInput(MoodMedicineReadyState ready) {
    final MoodMedicineReportPresentation? presentation = ready.presentation;
    if (presentation == null) {
      return null;
    }
    final Map<String, List<MoodMedicineEntry>> entriesByDay =
        <String, List<MoodMedicineEntry>>{};
    for (final MoodMedicineEntry entry in ready.snapshot.entries) {
      (entriesByDay[entry.localDayKey] ??= <MoodMedicineEntry>[]).add(entry);
    }
    final List<MoodMedicineReportDay> days = ready.dashboard.summaries
        .map((MoodMedicineDailySummary summary) {
          final List<MoodMedicineEntry> entries =
              List<MoodMedicineEntry>.from(
                entriesByDay[summary.dayKey] ?? const <MoodMedicineEntry>[],
              )..sort(
                (MoodMedicineEntry a, MoodMedicineEntry b) =>
                    a.occurredAtUtc.compareTo(b.occurredAtUtc),
              );
          final List<String> activityIds = summary.activityIds.toList()..sort();
          return MoodMedicineReportDay(
            dayLabel: presentation.dayLabelFor(summary.dayKey),
            moodAverage: summary.averageMood,
            activities: activityIds
                .map(
                  (String id) =>
                      ready.dashboard.activityLabelForDay(summary.dayKey, id),
                )
                .toList(growable: false),
            note: entries
                .where((MoodMedicineEntry entry) => entry.note != null)
                .map((MoodMedicineEntry entry) => entry.note!)
                .join('\n'),
          );
        })
        .toList(growable: false);
    return MoodMedicineReportInput(
      title: presentation.title,
      dateRangeLabel:
          presentation.rangeLabels[ready.selectedRange] ??
          ready.selectedRange.name,
      labels: presentation.labels,
      days: days,
      associations: ready.dashboard.associations
          .map(
            (MoodMedicineAssociation association) =>
                MoodMedicineReportAssociation(
                  activityLabel: ready.dashboard.activityLabelForRange(
                    association.activityId,
                  ),
                  withActivityMoodAverage: association.withActivityAverageMood,
                  withoutActivityMoodAverage:
                      association.withoutActivityAverageMood,
                ),
          )
          .toList(growable: false),
      sources: presentation.sources,
      textDirection: presentation.textDirection,
      includeNotes: ready.export.includeNotes,
      fileNameStem: presentation.fileNameStem,
    );
  }

  Future<bool> _persist(
    MoodMedicineReadyState before,
    MoodMedicineSnapshotMutation mutation, {
    MoodMedicineCheckInDraft? pendingCheckInDraft,
    _MoodMedicineCheckInIntent? checkInIntent,
    String? deselectActivityId,
    bool isRetry = false,
  }) async {
    if (_isDisposed ||
        before.persistence.isSaving ||
        (!isRetry && before.persistence.hasPendingWrite)) {
      return false;
    }
    _setState(
      _copyReady(
        before,
        persistence: const MoodMedicinePersistenceState(isSaving: true),
      ),
    );
    late final MoodMedicineSnapshot next;
    try {
      final MoodMedicineLoadResult result = await _repository.mutateSnapshot(
        mutation,
      );
      if (result case MoodMedicineUnreadableSnapshot(:final failure)) {
        _pendingMutation = null;
        _pendingCheckInIntent = null;
        _pendingDeselectActivityId = null;
        _setState(
          MoodMedicineRecoveryRequiredState(
            failure: failure,
            initialView: before.selectedView,
            checkInForm: before.checkInForm,
            isCheckInDetailsExpanded: before.isCheckInDetailsExpanded,
          ),
        );
        return false;
      }
      next = switch (result) {
        MoodMedicineLoadedSnapshot(:final MoodMedicineSnapshot snapshot) =>
          snapshot,
        MoodMedicineMissingSnapshot() => throw StateError(
          'A completed Mood Medicine mutation must return a snapshot.',
        ),
        MoodMedicineUnreadableSnapshot() => throw StateError(
          'Unreadable snapshots return before persistence completion.',
        ),
      };
      if (checkInIntent != null && !checkInIntent.isCommittedIn(next)) {
        throw const _MoodMedicineCheckInPostconditionFailure();
      }
      _pendingMutation = null;
      _pendingCheckInIntent = null;
      _pendingDeselectActivityId = null;
    } on _MoodMedicineCheckInCollision catch (error) {
      final MoodMedicineReadyState current = readyState ?? before;
      _pendingMutation = null;
      _pendingCheckInIntent = null;
      _pendingDeselectActivityId = null;
      _setState(
        _copyReady(
          current,
          persistence: MoodMedicinePersistenceState(error: error),
        ),
      );
      _emit(MoodMedicinePersistenceFailedEffect(error, canRetry: false));
      return false;
    } catch (error) {
      final MoodMedicineReadyState current = readyState ?? before;
      _pendingMutation = mutation;
      _pendingCheckInIntent = checkInIntent;
      _pendingDeselectActivityId = deselectActivityId;
      _setState(
        _copyReady(
          current,
          persistence: MoodMedicinePersistenceState(
            hasPendingWrite: true,
            pendingCheckInDraft: pendingCheckInDraft,
            error: error,
          ),
        ),
      );
      _emit(MoodMedicinePersistenceFailedEffect(error));
      return false;
    }

    final MoodMedicineReadyState current = readyState ?? before;
    final bool savedCheckIn = pendingCheckInDraft != null;
    final MoodMedicineCheckInForm nextForm = savedCheckIn
        ? const MoodMedicineCheckInForm.empty()
        : _withoutActivity(current.checkInForm, deselectActivityId);
    _setState(
      _readyState(
        snapshot: next,
        selectedView: savedCheckIn
            ? MoodMedicineInitialView.insights
            : current.selectedView,
        selectedRange: current.selectedRange,
        checkInForm: nextForm,
        isCheckInDetailsExpanded: savedCheckIn
            ? false
            : current.isCheckInDetailsExpanded,
        highlightedActivityId: current.highlightedActivityId,
        presentation: current.presentation,
        export: _invalidatedExport(
          current.export,
          reason: _MoodMedicineReportInvalidation.other,
        ),
      ),
    );
    if (savedCheckIn) {
      _emit(const MoodMedicineCheckInSavedEffect());
    }
    return true;
  }

  MoodMedicineReadyState? _writableReadyState() {
    final MoodMedicineReadyState? ready = readyState;
    return ready == null || ready.writesBlocked ? null : ready;
  }

  MoodMedicineExportState _invalidatedExport(
    MoodMedicineExportState current, {
    required _MoodMedicineReportInvalidation reason,
    bool resetIncludeNotes = false,
  }) {
    if (current.phase == MoodMedicineExportPhase.building &&
        _activeReportBuildGeneration != null) {
      if (reason == _MoodMedicineReportInvalidation.other ||
          _activeReportBuildInvalidation ==
              _MoodMedicineReportInvalidation.none) {
        _activeReportBuildInvalidation = reason;
      }
    }
    if (current.phase == MoodMedicineExportPhase.delivering &&
        _activeReportDeliveryGeneration != null) {
      _activeReportDeliveryInvalidated = true;
    }
    return MoodMedicineExportState(
      format: current.format,
      includeNotes: resetIncludeNotes ? false : current.includeNotes,
      phase: current.isWorking ? current.phase : MoodMedicineExportPhase.idle,
    );
  }

  Future<void> _logSourceOpenFailure(
    Object error,
    StackTrace stackTrace,
  ) async {
    try {
      await _incidentLoggerService.captureLog(
        _MoodMedicineSourceOpenFailureLog(error.runtimeType),
        stackTrace: stackTrace,
      );
    } catch (_) {
      // Incident telemetry must not hide the feature's local recovery UI.
    }
  }

  bool _isSelectableActivity(MoodMedicineSnapshot snapshot, String id) {
    return (moodMedicineDefaultActivityIds.contains(id) &&
            !snapshot.hiddenDefaultActivityIds.contains(id)) ||
        snapshot.customActivityForId(id) != null;
  }

  void _ensureDefaultActivityId(String activityId) {
    if (!moodMedicineDefaultActivityIds.contains(activityId)) {
      throw ArgumentError.value(
        activityId,
        'activityId',
        'Unknown default activity.',
      );
    }
  }

  String _newId(MoodMedicineSnapshot snapshot) {
    final String id = _idGenerator().trim();
    final bool collision =
        moodMedicineDefaultActivityIds.contains(id) ||
        snapshot.customActivityForId(id) != null ||
        snapshot.entries.any((MoodMedicineEntry entry) => entry.id == id);
    if (id.isEmpty || collision) {
      throw StateError('Mood Medicine id generation must return a new id.');
    }
    return id;
  }

  MoodMedicineCheckInForm _withoutActivity(
    MoodMedicineCheckInForm form,
    String? activityId,
  ) {
    if (activityId == null || !form.activityIds.contains(activityId)) {
      return form;
    }
    final Set<String> activityIds = <String>{...form.activityIds}
      ..remove(activityId);
    return MoodMedicineCheckInForm(
      mood: form.mood,
      emotionIds: form.emotionIds,
      activityIds: activityIds,
      journalNote: form.journalNote,
    );
  }

  void _setState(MoodMedicineViewState value) {
    if (_isDisposed) {
      return;
    }
    _state = value;
    notifyListeners();
  }

  void _emit(MoodMedicineUiEffect effect) {
    if (!_isDisposed && !_effects.isClosed) {
      _effects.add(effect);
    }
  }
}

enum _MoodMedicineReportInvalidation { none, presentation, other }

/// Sanitized incident payload that intentionally excludes the source URI.
final class _MoodMedicineSourceOpenFailureLog implements Exception {
  const _MoodMedicineSourceOpenFailureLog(this.errorType);

  final Type errorType;

  @override
  String toString() =>
      'MoodMedicineFailure(stage: sourceOpen, errorType: $errorType)';
}

/// A single immutable check-in save intent retained across an awaited retry.
///
/// The draft, identifier, UTC timestamp, and original local day are captured
/// once. Its pure mutation is then rebased on the latest persisted snapshot so
/// visibility and custom labels cannot become stale while a write is queued.
@immutable
final class _MoodMedicineCheckInIntent {
  _MoodMedicineCheckInIntent({
    required String id,
    required DateTime occurredAt,
    required MoodMedicineCheckInDraft draft,
    required this.isSelectableActivity,
  }) : id = id.trim(),
       occurredAtUtc = occurredAt.toUtc(),
       localDayKey = moodMedicineLocalDayKey(occurredAt),
       draft = MoodMedicineCheckInDraft(
         mood: draft.mood,
         emotionIds: draft.emotionIds,
         activityIds: draft.activityIds,
         note: draft.note,
       );

  final String id;
  final DateTime occurredAtUtc;
  final String localDayKey;
  final MoodMedicineCheckInDraft draft;
  final bool Function(MoodMedicineSnapshot snapshot, String activityId)
  isSelectableActivity;

  /// Applies this intent to the latest snapshot without mutating captured data.
  MoodMedicineSnapshot apply(MoodMedicineSnapshot currentSnapshot) {
    final MoodMedicineEntry intendedEntry = _entryFor(currentSnapshot);
    final MoodMedicineEntry? existingEntry = _entryWithId(currentSnapshot, id);
    if (existingEntry != null) {
      if (_entriesMatch(existingEntry, intendedEntry)) {
        return currentSnapshot;
      }
      throw const _MoodMedicineCheckInCollision();
    }
    return currentSnapshot.copyWith(
      entries: <MoodMedicineEntry>[...currentSnapshot.entries, intendedEntry],
    );
  }

  /// Whether a repository result contains this exact rebased check-in entry.
  bool isCommittedIn(MoodMedicineSnapshot snapshot) {
    final MoodMedicineEntry intendedEntry = _entryFor(snapshot);
    final MoodMedicineEntry? existingEntry = _entryWithId(snapshot, id);
    return existingEntry != null && _entriesMatch(existingEntry, intendedEntry);
  }

  MoodMedicineEntry _entryFor(MoodMedicineSnapshot snapshot) {
    final List<String> activityIds = draft.activityIds
        .where(
          (String activityId) => isSelectableActivity(snapshot, activityId),
        )
        .toList(growable: false);
    final Map<String, String> customActivityLabelSnapshots = <String, String>{
      for (final String activityId in activityIds)
        if (snapshot.customActivityForId(activityId)
            case final MoodMedicineCustomActivity activity)
          activityId: activity.label,
    };
    return MoodMedicineEntry(
      id: id,
      occurredAtUtc: occurredAtUtc,
      localDayKey: localDayKey,
      mood: draft.mood,
      emotionIds: draft.emotionIds,
      activityIds: activityIds,
      note: draft.note,
      customActivityLabelSnapshots: customActivityLabelSnapshots,
    );
  }
}

MoodMedicineEntry? _entryWithId(MoodMedicineSnapshot snapshot, String id) {
  for (final MoodMedicineEntry entry in snapshot.entries) {
    if (entry.id == id) {
      return entry;
    }
  }
  return null;
}

bool _entriesMatch(MoodMedicineEntry first, MoodMedicineEntry second) {
  return first.id == second.id &&
      first.occurredAtUtc == second.occurredAtUtc &&
      first.localDayKey == second.localDayKey &&
      first.mood == second.mood &&
      listEquals(first.emotionIds, second.emotionIds) &&
      listEquals(first.activityIds, second.activityIds) &&
      first.note == second.note &&
      mapEquals(
        first.customActivityLabelSnapshots,
        second.customActivityLabelSnapshots,
      );
}

/// A generated check-in id already belongs to different persisted content.
final class _MoodMedicineCheckInCollision implements Exception {
  const _MoodMedicineCheckInCollision();
}

/// A repository claimed success without returning the intended check-in entry.
final class _MoodMedicineCheckInPostconditionFailure implements Exception {
  const _MoodMedicineCheckInPostconditionFailure();
}
