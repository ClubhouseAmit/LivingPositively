import 'package:flutter/foundation.dart';
import 'package:mazilon/pages/MoodMedicine/mood_medicine_insights.dart';
import 'package:mazilon/pages/MoodMedicine/mood_medicine_models.dart';
import 'package:mazilon/pages/MoodMedicine/mood_medicine_store.dart';
import 'package:uuid/uuid.dart';

/// Local state for Mood Medicine. The caller provides a store so no global
/// persistence contract is extended and tests can inject a deterministic one.
final class MoodMedicineController extends ChangeNotifier {
  MoodMedicineController(this._store, {String Function()? idGenerator})
    : _idGenerator = idGenerator ?? const Uuid().v4;

  final MoodMedicineStore _store;
  final String Function() _idGenerator;

  MoodMedicineSnapshot _snapshot = const MoodMedicineSnapshot.empty();
  MoodMedicineSnapshot? _failedSnapshot;
  MoodMedicineCheckInDraft? _pendingCheckInDraft;
  Object? _persistenceError;
  bool _isLoading = false;
  bool _isSaving = false;
  bool _isLoaded = false;

  MoodMedicineSnapshot get snapshot => _snapshot;
  List<MoodMedicineEntry> get entries => _snapshot.entries;
  List<MoodMedicineCustomActivity> get customActivities =>
      _snapshot.customActivities;
  Set<String> get hiddenDefaultActivityIds =>
      _snapshot.hiddenDefaultActivityIds;
  MoodMedicineCheckInDraft? get pendingCheckInDraft => _pendingCheckInDraft;
  Object? get persistenceError => _persistenceError;
  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  bool get isLoaded => _isLoaded;
  bool get hasPendingWrite => _failedSnapshot != null;

  List<MoodMedicineDailySummary> get dailySummaries =>
      MoodMedicineInsights.dailySummaries(entries);

  Future<bool> load() async {
    if (_isLoading) {
      return false;
    }
    _isLoading = true;
    _persistenceError = null;
    notifyListeners();
    try {
      _snapshot = await _store.load();
      _isLoaded = true;
      return true;
    } catch (error) {
      _persistenceError = error;
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// True only after a successful load and until a check-in is saved for [now]'s
  /// local calendar day. Dismissing a UI prompt deliberately has no effect.
  bool shouldPromptFor(DateTime now) =>
      _isLoaded &&
      !entries.any(
        (MoodMedicineEntry entry) =>
            entry.localDayKey == moodMedicineLocalDayKey(now),
      );

  Future<bool> saveCheckIn(
    MoodMedicineCheckInDraft draft, {
    DateTime? occurredAt,
  }) async {
    _ensureCanWrite();
    if (draft.mood < 1 || draft.mood > 5) {
      throw ArgumentError.value(
        draft.mood,
        'draft.mood',
        'Must be from 1 to 5.',
      );
    }
    final DateTime occurred = occurredAt ?? DateTime.now();
    final Map<String, String> customSnapshots = <String, String>{
      for (final String activityId in draft.activityIds)
        if (_snapshot.customActivityForId(activityId)
            case final MoodMedicineCustomActivity activity)
          activityId: activity.label,
    };
    final MoodMedicineEntry entry = MoodMedicineEntry(
      id: _idGenerator(),
      occurredAtUtc: occurred.toUtc(),
      localDayKey: moodMedicineLocalDayKey(occurred),
      mood: draft.mood,
      emotionIds: draft.emotionIds,
      activityIds: draft.activityIds,
      note: draft.note,
      customActivityLabelSnapshots: customSnapshots,
    );
    return _persist(
      _snapshot.copyWith(entries: <MoodMedicineEntry>[...entries, entry]),
      pendingCheckInDraft: draft,
    );
  }

  Future<MoodMedicineCustomActivity?> addCustomActivity(String label) async {
    _ensureCanWrite();
    final String normalizedLabel = label.trim();
    if (normalizedLabel.isEmpty) {
      throw ArgumentError.value(label, 'label', 'Cannot be empty.');
    }
    final MoodMedicineCustomActivity activity = MoodMedicineCustomActivity(
      id: _idGenerator(),
      label: normalizedLabel,
    );
    final bool didSave = await _persist(
      _snapshot.copyWith(
        customActivities: <MoodMedicineCustomActivity>[
          ...customActivities,
          activity,
        ],
      ),
    );
    return didSave ? activity : null;
  }

  Future<bool> editCustomActivity(String id, String label) async {
    _ensureCanWrite();
    final String normalizedLabel = label.trim();
    if (normalizedLabel.isEmpty) {
      throw ArgumentError.value(label, 'label', 'Cannot be empty.');
    }
    bool found = false;
    final List<MoodMedicineCustomActivity> updated = customActivities
        .map((MoodMedicineCustomActivity activity) {
          if (activity.id != id) {
            return activity;
          }
          found = true;
          return activity.copyWith(label: normalizedLabel);
        })
        .toList(growable: false);
    if (!found) {
      return false;
    }
    return _persist(_snapshot.copyWith(customActivities: updated));
  }

  Future<bool> deleteCustomActivity(String id) async {
    _ensureCanWrite();
    final List<MoodMedicineCustomActivity> updated = customActivities
        .where((MoodMedicineCustomActivity activity) => activity.id != id)
        .toList(growable: false);
    if (updated.length == customActivities.length) {
      return false;
    }
    // Existing entry snapshots are intentionally left untouched.
    return _persist(_snapshot.copyWith(customActivities: updated));
  }

  Future<bool> hideDefaultActivity(String activityId) async {
    _ensureCanWrite();
    _ensureDefaultActivityId(activityId);
    return _persist(
      _snapshot.copyWith(
        hiddenDefaultActivityIds: <String>{
          ...hiddenDefaultActivityIds,
          activityId,
        },
      ),
    );
  }

  Future<bool> restoreDefaultActivity(String activityId) async {
    _ensureCanWrite();
    _ensureDefaultActivityId(activityId);
    final Set<String> updated = <String>{...hiddenDefaultActivityIds}
      ..remove(activityId);
    return _persist(_snapshot.copyWith(hiddenDefaultActivityIds: updated));
  }

  /// Retries the exact atomic snapshot that failed to persist.
  Future<bool> retryLastWrite() async {
    final MoodMedicineSnapshot? failed = _failedSnapshot;
    if (failed == null || _isSaving) {
      return false;
    }
    return _persist(
      failed,
      isRetry: true,
      pendingCheckInDraft: _pendingCheckInDraft,
    );
  }

  void _ensureCanWrite() {
    if (!_isLoaded) {
      throw StateError('Mood Medicine must load before it can be changed.');
    }
    if (_isSaving || _failedSnapshot != null) {
      throw StateError('Finish or retry the pending Mood Medicine save first.');
    }
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

  Future<bool> _persist(
    MoodMedicineSnapshot next, {
    bool isRetry = false,
    MoodMedicineCheckInDraft? pendingCheckInDraft,
  }) async {
    if (_isSaving || (!isRetry && _failedSnapshot != null)) {
      return false;
    }
    _isSaving = true;
    _persistenceError = null;
    notifyListeners();
    try {
      await _store.save(next);
      _snapshot = next;
      _failedSnapshot = null;
      _pendingCheckInDraft = null;
      return true;
    } catch (error) {
      _failedSnapshot = next;
      _pendingCheckInDraft = pendingCheckInDraft ?? _pendingCheckInDraft;
      _persistenceError = error;
      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }
}
