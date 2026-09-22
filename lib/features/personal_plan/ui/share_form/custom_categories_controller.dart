part of 'share_form.dart';

mixin _ShareFormCustomCategoriesController on WizardStepState<ShareForm> {
  bool _isRunningDreamsAndGoalsAction = false;
  ShareFormCustomCategoriesViewModel? _customCategoriesViewModel;
  UserInformation? _customCategoriesUserInformation;
  Future<void> _customCategoriesReplacement = Future<void>.value();
  int _customCategoriesReplacementRevision = 0;
  int _handledCustomCategoriesFailureEventId = 0;
  int _customCategorySaveRevision = 0;
  ({int revision, VoidCallback? onSuccess})? _customCategorySaveContinuation;

  List<MapEntry<String, String>> get _customCategories =>
      _customCategoriesViewModel?.state.categories ?? const [];

  void _replaceCustomCategoriesViewModel(UserInformation userInformation) {
    resetCustomCategoryForm();
    _isAddingCustomCategory = false;
    final replacementRevision = ++_customCategoriesReplacementRevision;
    final previousViewModel = _customCategoriesViewModel;
    previousViewModel?.removeListener(_onCustomCategoriesStateChanged);
    _customCategoriesViewModel = null;
    _customCategoriesUserInformation = userInformation;
    _handledCustomCategoriesFailureEventId = 0;
    _customCategorySaveRevision++;
    _customCategorySaveContinuation = null;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted &&
          replacementRevision == _customCategoriesReplacementRevision) {
        ScaffoldMessenger.maybeOf(context)?.hideCurrentSnackBar();
      }
    });
    final replacement = _installCustomCategoriesViewModel(
      userInformation,
      previousViewModel,
      _customCategoriesReplacement,
      replacementRevision,
    );
    _customCategoriesReplacement = replacement;
    unawaited(replacement);
  }

  Future<void> _installCustomCategoriesViewModel(
    UserInformation userInformation,
    ShareFormCustomCategoriesViewModel? previousViewModel,
    Future<void> previousReplacement,
    int replacementRevision,
  ) async {
    await previousReplacement;
    await previousViewModel?.close();
    if (!mounted ||
        replacementRevision != _customCategoriesReplacementRevision) {
      return;
    }
    final incidentLogger = GetIt.instance.isRegistered<IncidentLoggerService>()
        ? GetIt.instance<IncidentLoggerService>()
        : null;
    final viewModel = ShareFormCustomCategoriesViewModel(
      userInformation: userInformation,
      memoryService: widget.memoryService,
      incidentLogger: incidentLogger,
    );
    _customCategoriesViewModel = viewModel;
    _handledCustomCategoriesFailureEventId = 0;
    viewModel.addListener(_onCustomCategoriesStateChanged);
    setState(() {});
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && identical(viewModel, _customCategoriesViewModel)) {
        unawaited(viewModel.load());
      }
    });
  }

  void _onCustomCategoriesStateChanged() {
    if (!mounted) return;
    setState(() {});
    final viewModel = _customCategoriesViewModel;
    final state = viewModel?.state;
    if (state is ShareFormCustomCategoriesReady) {
      final continuation = _customCategorySaveContinuation;
      if (continuation != null &&
          continuation.revision == _customCategorySaveRevision) {
        _customCategorySaveContinuation = null;
        continuation.onSuccess?.call();
      }
      return;
    }
    if (state case ShareFormCustomCategoriesSaveFailure(
      :final eventId,
    ) when eventId > _handledCustomCategoriesFailureEventId) {
      if (_isRunningDreamsAndGoalsAction) return;
      _handledCustomCategoriesFailureEventId = eventId;
      _showCustomCategorySaveFailure(viewModel!);
    }
  }

  Future<void> _saveCustomCategories(
    List<MapEntry<String, String>> categories,
  ) async {
    if (_customCategoriesViewModel == null) {
      await _customCategoriesReplacement;
    }
    final viewModel = _customCategoriesViewModel;
    if (viewModel == null) {
      throw StateError('Custom categories are not ready to save.');
    }
    await viewModel.save(categories);
  }

  Future<void> _persistCustomCategoriesWithRetry(
    List<MapEntry<String, String>> categories, {
    VoidCallback? onSuccess,
  }) async {
    final revision = ++_customCategorySaveRevision;
    _customCategorySaveContinuation = (
      revision: revision,
      onSuccess: onSuccess,
    );
    try {
      await _saveCustomCategories(categories);
    } catch (error, stackTrace) {
      if (_customCategorySaveContinuation?.revision == revision) {
        _customCategorySaveContinuation = null;
      }
      await _captureDreamsAndGoalsFailure(error, stackTrace);
      if (mounted && revision == _customCategorySaveRevision) {
        showPersistenceRetrySnackBar(
          context,
          () => _persistCustomCategoriesWithRetry(
            categories,
            onSuccess: onSuccess,
          ),
        );
      }
    }
  }

  void _showCustomCategorySaveFailure(
    ShareFormCustomCategoriesViewModel failedViewModel,
  ) {
    showPersistenceRetrySnackBar(context, () async {
      if (!mounted || !identical(failedViewModel, _customCategoriesViewModel)) {
        return;
      }
      await failedViewModel.retryLatestSave();
    });
  }

  Future<void> _prepareCustomCategories({bool retry = false}) async {
    if (_customCategoriesViewModel == null) {
      await _customCategoriesReplacement;
    }
    final viewModel = _customCategoriesViewModel;
    if (viewModel == null ||
        !await viewModel.prepareForAction(retry: retry) ||
        !mounted ||
        !identical(viewModel, _customCategoriesViewModel)) {
      throw StateError('Custom categories are not ready for this action.');
    }
  }

  Future<void> _captureDreamsAndGoalsFailure(
    Object error,
    StackTrace stackTrace,
  ) async {
    try {
      await GetIt.instance<IncidentLoggerService>().captureLog(
        error,
        stackTrace: stackTrace,
      );
    } catch (_) {
      // Logging is best effort; it must not hide the retry affordance.
    }
  }

  void resetCustomCategoryForm();
  set _isAddingCustomCategory(bool value);
}
