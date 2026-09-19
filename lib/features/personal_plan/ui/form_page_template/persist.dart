part of 'form_page_template.dart';

mixin _FormPagePersist on WizardStepState<FormPageTemplate> {
  int displayedLength = 3;
  List<String> suggestionPool = const [];
  List<String> selectedItems = [];
  List<String> selectedItemSources = const [];
  Future<void> _pendingDreamsAndGoalsPersistence = Future<void>.value();
  int? _pendingDreamsAndGoalsPersistenceRevision;
  List<int> rowIds = const [];
  int _nextRowId = 0;
  static const int _suggestionBatch = 3;

  void syncRowIds() {
    if (rowIds.length != selectedItems.length) {
      rowIds = List.generate(selectedItems.length, (_) => _nextRowId++);
    }
  }

  int get revealedSuggestions {
    var revealed = displayedLength.clamp(0, suggestionPool.length);
    while (revealed < suggestionPool.length &&
        !suggestionPool
            .take(revealed)
            .any((item) => !isAlreadySelected(item))) {
      revealed = (revealed + _suggestionBatch).clamp(0, suggestionPool.length);
    }
    return revealed;
  }

  bool isAlreadySelected(String item) {
    if (_tracksDreamsAndGoalsSelectionSources) {
      final index = suggestionPool.indexOf(item);
      return index >= 0 &&
          selectedItemSources.contains(
            dreamsAndGoalsCatalogueSelectionSourceForIndex(index),
          );
    }
    return selectedItems.contains(item);
  }

  bool get _tracksDreamsAndGoalsSelectionSources =>
      widget.collectionName == 'PersonalPlan-DreamsAndGoals';

  void editItem(int index, String text) {
    if (index < 0 || index >= selectedItems.length) {
      return;
    }
    final editedItem = text.trim();
    if (_tracksDreamsAndGoalsSelectionSources &&
        editedItem != selectedItems[index] &&
        index < selectedItemSources.length) {
      final source = selectedItemSources[index];
      if (source != dreamsAndGoalsCustomSelectionSource) {
        selectedItemSources[index] = dreamsAndGoalsCustomSelectionSource;
      }
    }
    selectedItems[index] = editedItem;
    setState(() {});
  }

  void removeItem(int index) {
    if (index < 0 || index >= selectedItems.length) {
      return;
    }
    selectedItems.removeAt(index);
    if (_tracksDreamsAndGoalsSelectionSources) {
      selectedItemSources.removeAt(index);
    }
    setState(() {});
  }

  void addItem(String text, {String? selectionSource}) {
    selectedItems.add(text.trim());
    if (_tracksDreamsAndGoalsSelectionSources) {
      selectedItemSources.add(
        selectionSource ?? dreamsAndGoalsCustomSelectionSource,
      );
    }
    setState(() {});
  }

  void addSuggestion() {
    setState(() {
      displayedLength = (revealedSuggestions + _suggestionBatch).clamp(
        0,
        suggestionPool.length,
      );
    });
  }

  Future<void> _saveDreamsAndGoalsWithDisclaimer(
    UserInformation userInfo, {
    required int revision,
    required bool retry,
  }) {
    final Future<void> combinedSave = userInfo.saveDreamsAndGoalsWithDisclaimer(
      revision: revision,
      retry: retry,
    );
    _pendingDreamsAndGoalsPersistence = combinedSave;
    _pendingDreamsAndGoalsPersistenceRevision =
        userInfo.dreamsAndGoalsSaveRevision;
    return combinedSave;
  }

  Future<void> createSelection(
    UserInformation userInfo, {
    void Function(int revision)? onDreamsSaveQueued,
  }) async {
    if (widget.persistentMemoryService != null &&
        widget.collectionName != 'PersonalPlan-DreamsAndGoals') {
      switch (widget.collectionName) {
        case 'PersonalPlan-DifficultEvents':
          userInfo.updateDifficultEvents([...selectedItems]);
          break;
        case 'PersonalPlan-MakeSafer':
          userInfo.updateMakeSafer([...selectedItems]);
          break;
        case 'PersonalPlan-FeelBetter':
          userInfo.updateFeelBetter([...selectedItems]);
          break;
        case 'PersonalPlan-Distractions':
          userInfo.updateDistractions([...selectedItems]);
          break;
        case 'PersonalPlan-SafeEnvironment':
          userInfo.updateSafeEnvironment([...selectedItems]);
          break;
        default:
      }
      await userInfo.persistDisclaimerConfirmed();
      await widget.persistentMemoryService!.setItem(
        'userSelection${widget.collectionName}',
        PersistentMemoryType.StringList,
        [...selectedItems],
      );
      await widget.persistentMemoryService!.setItem(
        'addedStrings${widget.collectionName}',
        PersistentMemoryType.StringList,
        [...selectedItems],
      );
      return;
    }

    if (widget.collectionName == 'PersonalPlan-DreamsAndGoals') {
      final Future<void> dreamsAndGoalsSave = userInfo.saveCategorySelection(
        widget.collectionName,
        selectedItems,
        selectionSources: selectedItemSources,
        onDreamsSaveQueued: (int revision) {
          onDreamsSaveQueued?.call(revision);
        },
      );
      selectedItemSources = List<String>.from(
        userInfo.dreamsAndGoalsSelectionSources,
      );
      _pendingDreamsAndGoalsPersistence = dreamsAndGoalsSave;
      _pendingDreamsAndGoalsPersistenceRevision =
          userInfo.dreamsAndGoalsSaveRevision;
      await dreamsAndGoalsSave;
      return;
    }

    await userInfo.saveCategorySelection(
      widget.collectionName,
      selectedItems,
      selectionSources: selectedItemSources,
      onDreamsSaveQueued: onDreamsSaveQueued,
    );
  }

  void loadItems(UserInformation userInfo) {
    switch (widget.collectionName) {
      case 'PersonalPlan-DifficultEvents':
        selectedItems = [...userInfo.difficultEvents];
        break;
      case 'PersonalPlan-MakeSafer':
        selectedItems = [...userInfo.makeSafer];
        break;
      case 'PersonalPlan-FeelBetter':
        selectedItems = [...userInfo.feelBetter];
        break;
      case 'PersonalPlan-Distractions':
        selectedItems = [...userInfo.distractions];
        break;
      case 'PersonalPlan-SafeEnvironment':
        selectedItems = [...userInfo.safeEnvironment];
        break;
      case 'PersonalPlan-DreamsAndGoals':
        selectedItems = [...userInfo.dreamsAndGoals];
        selectedItemSources = [...userInfo.dreamsAndGoalsSelectionSources];
        break;
      default:
    }
  }

  Future<void> _saveSelectionAfterMutation(UserInformation userInfo) async {
    int? dreamsSaveRevision;
    try {
      await createSelection(
        userInfo,
        onDreamsSaveQueued: (int revision) {
          dreamsSaveRevision = revision;
        },
      );
    } catch (_) {
      if (!mounted) {
        return;
      }
      _showSaveFailure(() => _retrySelectionSave(userInfo, dreamsSaveRevision));
    }
  }

  Future<void> _retrySelectionSave(
    UserInformation userInfo,
    int? dreamsSaveRevision,
  ) async {
    if (_tracksDreamsAndGoalsSelectionSources && dreamsSaveRevision != null) {
      await _saveDreamsAndGoalsWithDisclaimer(
        userInfo,
        revision: dreamsSaveRevision,
        retry: true,
      );
      return;
    }
    await createSelection(userInfo);
  }

  void _showSaveFailure(Future<void> Function() retry) {
    showPersistenceRetrySnackBar(context, () => _runSaveRetry(retry));
  }

  Future<void> _runSaveRetry(Future<void> Function() retry) async {
    try {
      await retry();
    } catch (error, stackTrace) {
      await _captureRetryFailure(error, stackTrace);
      if (mounted) {
        _showSaveFailure(retry);
      }
    }
  }

  Future<void> _captureRetryFailure(Object error, StackTrace stackTrace) async {
    try {
      await GetIt.instance<IncidentLoggerService>().captureLog(
        error,
        stackTrace: stackTrace,
      );
    } catch (_) {
      // Logging is best effort; it must not hide the retry affordance.
    }
  }
}
