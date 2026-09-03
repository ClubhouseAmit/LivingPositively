import 'package:flutter/foundation.dart';

import 'package:mazilon/util/custom_categories_storage.dart';
import 'package:mazilon/util/logger_service.dart';
import 'package:mazilon/util/persistent_memory_service.dart';
import 'package:mazilon/util/userInformation.dart';

@immutable
sealed class ShareFormCustomCategoriesState {
  const ShareFormCustomCategoriesState(this.categories);

  final List<MapEntry<String, String>> categories;
}

final class ShareFormCustomCategoriesReady
    extends ShareFormCustomCategoriesState {
  const ShareFormCustomCategoriesReady(super.categories);
}

final class ShareFormCustomCategoriesSaveFailure
    extends ShareFormCustomCategoriesState {
  const ShareFormCustomCategoriesSaveFailure(
    super.categories, {
    required this.eventId,
  });

  final int eventId;
}

/// Owns the custom-category persistence policy for one [ShareForm].
///
/// The view model keeps alternate export stores isolated from the active user
/// model, rejects stale load/save completions, and retains only the latest
/// sanitized snapshot for a user-requested retry.
final class ShareFormCustomCategoriesViewModel extends ChangeNotifier {
  ShareFormCustomCategoriesViewModel({
    required UserInformation userInformation,
    PersistentMemoryService? memoryService,
    this._incidentLogger,
  }) : _userInformation = userInformation,
       _memoryService = memoryService,
       _usesAlternateSource =
           memoryService != null &&
           !identical(memoryService, userInformation.service),
       _state = ShareFormCustomCategoriesReady(
         List<MapEntry<String, String>>.unmodifiable(
           memoryService != null &&
                   !identical(memoryService, userInformation.service)
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
  ShareFormCustomCategoriesState get state => _state;

  List<MapEntry<String, String>>? _latestSaveSnapshot;
  int _saveRevision = 0;
  int _failureEventId = 0;
  bool _isDisposed = false;

  Future<void> load() async {
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

  Future<void> save(List<MapEntry<String, String>> categories) async {
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
      if (_isDisposed) {
        return;
      }
      _state = ShareFormCustomCategoriesSaveFailure(
        _state.categories,
        eventId: ++_failureEventId,
      );
      notifyListeners();
    }
  }

  Future<void> retryLatestSave() async {
    final latestSaveSnapshot = _latestSaveSnapshot;
    if (latestSaveSnapshot == null) {
      return;
    }
    await save(latestSaveSnapshot);
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
    _isDisposed = true;
    if (!_usesAlternateSource) {
      _userInformation.removeListener(_synchronizeDefaultSource);
    }
    super.dispose();
  }
}
