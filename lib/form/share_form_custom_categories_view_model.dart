import 'package:flutter/foundation.dart';

import 'package:mazilon/util/custom_categories_storage.dart';
import 'package:mazilon/util/logger_service.dart';
import 'package:mazilon/util/persistent_memory_service.dart';
import 'package:mazilon/util/userInformation.dart';

/// Immutable custom-category state rendered by a ShareForm screen.
@immutable
sealed class ShareFormCustomCategoriesState {
  /// Creates state containing an immutable [categories] snapshot.
  const ShareFormCustomCategoriesState(this.categories);

  /// The sanitized custom categories currently visible to the screen.
  final List<MapEntry<String, String>> categories;
}

/// State emitted when the latest applicable load or save is ready to render.
final class ShareFormCustomCategoriesReady
    extends ShareFormCustomCategoriesState {
  /// Creates ready state for [categories].
  const ShareFormCustomCategoriesReady(super.categories);
}

/// State emitted when the latest applicable save cannot be persisted.
final class ShareFormCustomCategoriesSaveFailure
    extends ShareFormCustomCategoriesState {
  /// Creates a failure event while retaining the last renderable [categories].
  const ShareFormCustomCategoriesSaveFailure(
    super.categories, {
    required this.eventId,
  });

  /// A monotonically increasing identifier for one-shot failure UI.
  final int eventId;
}

/// Owns the custom-category persistence policy for one [ShareForm].
///
/// The view model keeps alternate export stores isolated from the active user
/// model, rejects stale load/save completions, and retains only the latest
/// sanitized snapshot for a user-requested retry.
final class ShareFormCustomCategoriesViewModel extends ChangeNotifier {
  /// Creates a model for the default user store or an explicit alternate store.
  factory ShareFormCustomCategoriesViewModel({
    required UserInformation userInformation,
    PersistentMemoryService? memoryService,
    IncidentLoggerService? incidentLogger,
  }) {
    final bool usesAlternateSource =
        memoryService != null &&
        !identical(memoryService, userInformation.service);
    return ShareFormCustomCategoriesViewModel._(
      userInformation,
      memoryService,
      incidentLogger,
      usesAlternateSource,
    );
  }

  ShareFormCustomCategoriesViewModel._(
    UserInformation userInformation,
    this._memoryService,
    this._incidentLogger,
    bool usesAlternateSource,
  ) : _userInformation = userInformation,
      _usesAlternateSource = usesAlternateSource,
      _state = ShareFormCustomCategoriesReady(
        List<MapEntry<String, String>>.unmodifiable(
          usesAlternateSource
              ? const <MapEntry<String, String>>[]
              : userInformation.customCategories,
        ),
      ) {
    if (!_usesAlternateSource) {
      _userInformation.addListener(_synchronizeDefaultSource);
    }
  }

  final UserInformation _userInformation;
  final PersistentMemoryService? _memoryService;
  final IncidentLoggerService? _incidentLogger;
  final bool _usesAlternateSource;

  ShareFormCustomCategoriesState _state;

  /// The latest immutable state available to the screen.
  ShareFormCustomCategoriesState get state => _state;

  List<MapEntry<String, String>>? _latestSaveSnapshot;
  final Set<Future<void>> _activeSaves = <Future<void>>{};
  int _saveRevision = 0;
  int _failureEventId = 0;
  bool _isDisposed = false;
  bool _notifierDisposed = false;

  /// Loads categories without allowing an older load to replace a newer save.
  ///
  /// Default-store loads publish through [UserInformation]. Alternate-store
  /// loads update only this model. Failures are reported and leave [state]
  /// unchanged.
  Future<void> load() async {
    if (_isDisposed) {
      return;
    }
    final int saveRevisionAtStart = _saveRevision;
    try {
      final categories = await _userInformation.loadCustomCategories(
        memoryService: _memoryService,
      );
      if (_isDisposed || saveRevisionAtStart != _saveRevision) {
        return;
      }
      if (_usesAlternateSource) {
        _emitReady(categories);
      }
    } catch (error, stackTrace) {
      await _reportFailure(error, stackTrace);
    }
  }

  /// Sanitizes and persists [categories], retaining the snapshot for retry.
  ///
  /// A failure from the latest save emits one
  /// [ShareFormCustomCategoriesSaveFailure]. Obsolete save completions are
  /// reported but cannot replace state from a newer save.
  Future<void> save(List<MapEntry<String, String>> categories) {
    if (_isDisposed) {
      return Future<void>.value();
    }
    late final Future<void> saveOperation;
    saveOperation = _save(
      categories,
    ).whenComplete(() => _activeSaves.remove(saveOperation));
    _activeSaves.add(saveOperation);
    return saveOperation;
  }

  Future<void> _save(List<MapEntry<String, String>> categories) async {
    final snapshot = List<MapEntry<String, String>>.unmodifiable(
      sanitizeAndFilterCustomCategoryEntries(categories),
    );
    _latestSaveSnapshot = snapshot;
    final int revision = ++_saveRevision;
    try {
      await _userInformation.saveCustomCategories(
        categories: snapshot,
        memoryService: _memoryService,
      );
      if (_isDisposed || revision != _saveRevision) {
        return;
      }
      _emitReady(
        _usesAlternateSource ? snapshot : _userInformation.customCategories,
      );
    } catch (error, stackTrace) {
      await _reportFailure(error, stackTrace);
      if (_isDisposed || revision != _saveRevision) {
        return;
      }
      _state = ShareFormCustomCategoriesSaveFailure(
        _state.categories,
        eventId: ++_failureEventId,
      );
      notifyListeners();
    }
  }

  /// Retries the most recently requested sanitized save snapshot, if any.
  ///
  /// The retry is a new save revision and therefore emits the same ready or
  /// failure state semantics as [save].
  Future<void> retryLatestSave() async {
    final latestSaveSnapshot = _latestSaveSnapshot;
    if (latestSaveSnapshot == null) {
      return;
    }
    await save(latestSaveSnapshot);
  }

  /// Stops accepting commands and waits for all accepted saves to settle.
  ///
  /// Replacement owners should await this before loading another model that
  /// may use the same persistence service. Persistence failures remain
  /// reported but do not make this drain fail.
  Future<void> close() async {
    _beginDisposal();
    while (_activeSaves.isNotEmpty) {
      final activeSaves = List<Future<void>>.of(_activeSaves);
      await Future.wait<void>(activeSaves.map(_settle));
    }
    _disposeNotifier();
  }

  Future<void> _settle(Future<void> operation) async {
    try {
      await operation;
    } catch (_) {
      // Persistence failures were already reported by the save operation.
    }
  }

  void _synchronizeDefaultSource() {
    if (_isDisposed) {
      return;
    }
    _emitReady(_userInformation.customCategories);
  }

  void _emitReady(List<MapEntry<String, String>> categories) {
    if (_isDisposed) {
      return;
    }
    _state = ShareFormCustomCategoriesReady(
      List<MapEntry<String, String>>.unmodifiable(categories),
    );
    notifyListeners();
  }

  Future<void> _reportFailure(Object error, StackTrace stackTrace) async {
    final incidentLogger = _incidentLogger;
    if (incidentLogger != null) {
      try {
        await incidentLogger.captureLog(error, stackTrace: stackTrace);
        return;
      } catch (_) {
        // Fall through so logger failure never hides the persistence failure.
      }
    }
    FlutterError.reportError(
      FlutterErrorDetails(
        exception: error,
        stack: stackTrace,
        library: 'ShareFormCustomCategoriesViewModel',
        context: ErrorDescription('while persisting custom categories'),
      ),
    );
  }

  @override
  void dispose() {
    _beginDisposal();
    if (_notifierDisposed) {
      return;
    }
    _notifierDisposed = true;
    super.dispose();
  }

  void _beginDisposal() {
    if (_isDisposed) {
      return;
    }
    _isDisposed = true;
    if (!_usesAlternateSource) {
      _userInformation.removeListener(_synchronizeDefaultSource);
    }
  }

  void _disposeNotifier() {
    if (_notifierDisposed) {
      return;
    }
    _notifierDisposed = true;
    super.dispose();
  }
}
