import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:get_it/get_it.dart';

import 'package:mazilon/global_enums.dart';
import 'package:mazilon/file_service.dart';
import 'package:mazilon/form/formpagetemplate.dart';
import 'package:mazilon/form/dreams_and_goals_custom_conflict_dialog.dart';
import 'package:mazilon/form/speech_dictation_suffix_action.dart';
import 'package:mazilon/form/wizard_step.dart';
import 'package:mazilon/l10n/app_localizations.dart';
import 'package:mazilon/util/SignIn/popup_toast.dart';
import 'package:mazilon/util/async/persistence_retry_snack_bar.dart';
import 'package:mazilon/util/logger_service.dart';
import 'package:mazilon/util/persistent_memory_service.dart';
import 'package:mazilon/util/languages_util_functions.dart';
import 'package:mazilon/util/theme/spacing.dart';
import 'package:provider/provider.dart';
import 'package:mazilon/util/styles.dart';
import 'package:mazilon/util/type_utils.dart';

import 'package:mazilon/util/appInformation.dart';
import 'package:mazilon/util/personal_plan_export_metadata.dart';
import 'package:mazilon/util/userInformation.dart';
import 'package:mazilon/util/Share/show_share_dialog.dart';

const String _customCategoryTitlesKey = 'customCategoryTitles';
const String _customCategoryDescriptionsKey = 'customCategoryDescriptions';

enum _DreamsAndGoalsActionPreparationState { ready, blocked, failed }

/// The result of preparing a Share action that depends on Dreams and Goals.
///
/// [retryRevision] is captured before each persistence await so a retry never
/// replays an older snapshot over a newer edit.
class _DreamsAndGoalsActionPreparation {
  const _DreamsAndGoalsActionPreparation._(
    this.state, {
    required this.retryRevision,
    this.error,
    this.stackTrace,
  });

  const _DreamsAndGoalsActionPreparation.ready(int retryRevision)
    : this._(
        _DreamsAndGoalsActionPreparationState.ready,
        retryRevision: retryRevision,
      );

  const _DreamsAndGoalsActionPreparation.blocked(int retryRevision)
    : this._(
        _DreamsAndGoalsActionPreparationState.blocked,
        retryRevision: retryRevision,
      );

  const _DreamsAndGoalsActionPreparation.failed(
    int retryRevision,
    Object error,
    StackTrace stackTrace,
  ) : this._(
        _DreamsAndGoalsActionPreparationState.failed,
        retryRevision: retryRevision,
        error: error,
        stackTrace: stackTrace,
      );

  final _DreamsAndGoalsActionPreparationState state;
  final int retryRevision;
  final Object? error;
  final StackTrace? stackTrace;
}

class ShareForm extends WizardStep {
  final Function prev;
  final FutureOr<void> Function(BuildContext context) submit;

  const ShareForm({
    required super.key,
    required this.prev,
    required this.submit,
  });

  @override
  String primaryActionLabel(BuildContext context) => AppLocalizations.of(
    context,
  )!.sharePageFinishButton(Provider.of<UserInformation>(context).gender);

  @override
  WizardStepState<ShareForm> createState() => _ShareFormState();
}

class _ShareFormState extends WizardStepState<ShareForm> {
  late FileService fileService;
  final _dreamsAndGoalsStepKey = GlobalKey<WizardStepState>(
    debugLabel: 'share-dreams-and-goals',
  );
  final TextEditingController _customCategoryTitleController =
      TextEditingController();
  final TextEditingController _customCategoryDescriptionController =
      TextEditingController();
  final FocusNode _customCategoryTitleFocusNode = FocusNode();
  final List<MapEntry<String, String>> _customCategories = [];
  bool _isEditingDreamsAndGoals = false;
  bool _isOpeningDreamsAndGoals = false;
  bool _isAddingCustomCategory = false;
  bool _showCustomCategoryValidation = false;
  int? _editingCustomCategoryIndex;
  int _customCategoryFormGeneration = 0;

  void setHasFilled() {
    unawaited(_setHasFilled());
  }

  Future<void> _setHasFilled() async {
    final UserInformation userInformation = Provider.of<UserInformation>(
      context,
      listen: false,
    );
    try {
      await userInformation.persistHasFilled();
    } catch (error, stackTrace) {
      try {
        await GetIt.instance<IncidentLoggerService>().captureLog(
          error,
          stackTrace: stackTrace,
        );
      } catch (_) {
        // The storage service already attempted its own logging. This
        // best-effort initialization write must not escape as an async error.
      }
    }
  }

  @override
  void initState() {
    super.initState();
    fileService = GetIt.instance<FileService>();
    setHasFilled();
    loadCustomCategories();
  }

  @override
  void dispose() {
    _customCategoryTitleController.dispose();
    _customCategoryDescriptionController.dispose();
    _customCategoryTitleFocusNode.dispose();
    super.dispose();
  }

  Future<void> loadCustomCategories() async {
    PersistentMemoryService service = GetIt.instance<PersistentMemoryService>();
    final titles = TypeUtils.castToStringList(
      await service.getItem(
        _customCategoryTitlesKey,
        PersistentMemoryType.StringList,
      ),
    );
    final descriptions = TypeUtils.castToStringList(
      await service.getItem(
        _customCategoryDescriptionsKey,
        PersistentMemoryType.StringList,
      ),
    );
    final loadedCategories = <MapEntry<String, String>>[];

    for (var i = 0; i < titles.length && i < descriptions.length; i++) {
      final title = titles[i].trim();
      final description = descriptions[i].trim();
      if (title.isEmpty || description.isEmpty) {
        continue;
      }
      loadedCategories.add(MapEntry(title, description));
    }

    if (!mounted) {
      return;
    }
    setState(() {
      _customCategories
        ..clear()
        ..addAll(loadedCategories);
    });
  }

  Future<void> saveCustomCategories() async {
    PersistentMemoryService service = GetIt.instance<PersistentMemoryService>();
    await service.setItem(
      _customCategoryTitlesKey,
      PersistentMemoryType.StringList,
      _customCategories.map((category) => category.key).toList(),
    );
    await service.setItem(
      _customCategoryDescriptionsKey,
      PersistentMemoryType.StringList,
      _customCategories.map((category) => category.value).toList(),
    );
  }

  Future<void> _persistCustomCategoriesSafely() async {
    try {
      await saveCustomCategories();
    } catch (error, stackTrace) {
      await _captureDreamsAndGoalsFailure(error, stackTrace);
      if (mounted) {
        _showCustomCategorySaveFailure();
      }
    }
  }

  void _showCustomCategorySaveFailure() {
    showPersistenceRetrySnackBar(context, _persistCustomCategoriesSafely);
  }

  List<String> predefinedCategoryTitles() {
    return [
      appLocale.customCategoryOptionEmpoweringQuotes,
      appLocale.customCategoryOptionPastEvents,
      appLocale.customCategoryOptionAboutMe,
      appLocale.customCategoryOptionCustomInput,
    ];
  }

  TextDirection textDirectionFor(String text) {
    return getDirectionOfText(text) == 'rtl'
        ? TextDirection.rtl
        : TextDirection.ltr;
  }

  TextAlign textAlignFor(String text) {
    return getDirectionOfText(text) == 'rtl' ? TextAlign.right : TextAlign.left;
  }

  void resetCustomCategoryForm() {
    _customCategoryTitleController.clear();
    _customCategoryDescriptionController.clear();
    _customCategoryTitleFocusNode.unfocus();
    _showCustomCategoryValidation = false;
    _editingCustomCategoryIndex = null;
    _customCategoryFormGeneration++;
  }

  void startAddingCustomCategory() {
    setState(() {
      resetCustomCategoryForm();
      _isAddingCustomCategory = true;
    });
  }

  void editCustomCategory(int index) {
    final category = _customCategories[index];
    setState(() {
      _customCategoryTitleController.text = category.key;
      _customCategoryDescriptionController.text = category.value;
      _showCustomCategoryValidation = false;
      _editingCustomCategoryIndex = index;
      _isAddingCustomCategory = true;
      _customCategoryFormGeneration++;
    });
  }

  Future<void> deleteCustomCategory(int index) async {
    if (index < 0 || index >= _customCategories.length) {
      return;
    }

    setState(() {
      _customCategories.removeAt(index);
      if (_editingCustomCategoryIndex == index) {
        resetCustomCategoryForm();
        _isAddingCustomCategory = false;
      } else if (_editingCustomCategoryIndex != null &&
          _editingCustomCategoryIndex! > index) {
        _editingCustomCategoryIndex = _editingCustomCategoryIndex! - 1;
      }
    });

    await _persistCustomCategoriesSafely();
  }

  Future<void> saveCustomCategory() async {
    final title = _customCategoryTitleController.text.trim();
    final description = _customCategoryDescriptionController.text.trim();

    if (title.isEmpty || description.isEmpty) {
      setState(() {
        _showCustomCategoryValidation = true;
      });
      return;
    }

    setState(() {
      final editingIndex = _editingCustomCategoryIndex;
      if (editingIndex != null &&
          editingIndex >= 0 &&
          editingIndex < _customCategories.length) {
        _customCategories[editingIndex] = MapEntry(title, description);
      } else {
        _customCategories.add(MapEntry(title, description));
      }
      resetCustomCategoryForm();
      _isAddingCustomCategory = false;
    });

    await _persistCustomCategoriesSafely();
  }

  String? _customCategoryValidationError(TextEditingController controller) {
    return _showCustomCategoryValidation && controller.text.trim().isEmpty
        ? appLocale.validateEmpty
        : null;
  }

  void refreshCustomCategoryTitleOptions(
    TextEditingController textEditingController,
  ) {
    final value = textEditingController.value;
    final offset = value.selection.isValid
        ? value.selection.baseOffset.clamp(0, value.text.length).toInt()
        : value.text.length;
    final nextAffinity = value.selection.affinity == TextAffinity.downstream
        ? TextAffinity.upstream
        : TextAffinity.downstream;

    // Nudges RawAutocomplete to rebuild options when tapping unchanged text.
    textEditingController.value = value.copyWith(
      selection: TextSelection.collapsed(
        offset: offset,
        affinity: nextAffinity,
      ),
    );
  }

  Widget buildCustomCategoryTitleField() {
    return RawAutocomplete<String>(
      key: ValueKey(
        'custom-category-title-autocomplete-$_customCategoryFormGeneration',
      ),
      textEditingController: _customCategoryTitleController,
      focusNode: _customCategoryTitleFocusNode,
      displayStringForOption: (option) => option,
      optionsBuilder: (TextEditingValue textEditingValue) {
        final input = textEditingValue.text.trim();
        final options = predefinedCategoryTitles();
        final editingIndex = _editingCustomCategoryIndex;
        final isInitialEditingTitle =
            editingIndex != null &&
            editingIndex >= 0 &&
            editingIndex < _customCategories.length &&
            _customCategories[editingIndex].key == input;
        if (input.isEmpty || isInitialEditingTitle) {
          return options;
        }
        return options.where((option) => option.contains(input));
      },
      onSelected: (option) {
        if (option == appLocale.customCategoryOptionCustomInput) {
          _customCategoryTitleController.clear();
          _customCategoryTitleFocusNode.requestFocus();
        }
      },
      fieldViewBuilder:
          (context, textEditingController, focusNode, onFieldSubmitted) {
            return TextField(
              key: const Key('custom-category-title-field'),
              controller: textEditingController,
              focusNode: focusNode,
              textDirection: appLocale.textDirection == 'rtl'
                  ? TextDirection.rtl
                  : null,
              onTap: () =>
                  refreshCustomCategoryTitleOptions(textEditingController),
              decoration: InputDecoration(
                labelText: appLocale.sharePageCustomCategoryTitle,
                suffixIcon: SpeechDictationSuffixAction.isSupportedPlatform
                    ? SpeechDictationSuffixAction(
                        controller: textEditingController,
                        onTextApplied: (_) => refreshCustomCategoryTitleOptions(
                          textEditingController,
                        ),
                      )
                    : null,
                errorText: _customCategoryValidationError(
                  _customCategoryTitleController,
                ),
              ),
            );
          },
      optionsViewBuilder: (context, onSelected, options) {
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 4,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 280, maxWidth: 340),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: options.map((option) {
                    return ListTile(
                      title: Directionality(
                        textDirection: textDirectionFor(option),
                        child: Text(option, textAlign: textAlignFor(option)),
                      ),
                      onTap: () => onSelected(option),
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget buildCustomCategoryForm(BuildContext context) {
    return Container(
      width: MediaQuery.sizeOf(context).width > 1000
          ? 600
          : MediaQuery.sizeOf(context).width * 0.85,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        border: Border.all(color: Theme.of(context).colorScheme.primary),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          buildCustomCategoryTitleField(),
          const SizedBox(height: 12),
          TextField(
            key: const Key('custom-category-description-field'),
            controller: _customCategoryDescriptionController,
            minLines: 3,
            maxLines: 6,
            textDirection: appLocale.textDirection == 'rtl'
                ? TextDirection.rtl
                : null,
            decoration: InputDecoration(
              labelText: appLocale.sharePageCustomCategoryDescription,
              alignLabelWithHint: true,
              suffixIcon: SpeechDictationSuffixAction.isSupportedPlatform
                  ? SpeechDictationSuffixAction(
                      controller: _customCategoryDescriptionController,
                    )
                  : null,
              border: const OutlineInputBorder(),
              errorText: _customCategoryValidationError(
                _customCategoryDescriptionController,
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () {
              unawaited(saveCustomCategory());
            },
            style: primaryButtonStyle(context),
            child: Text(
              appLocale.sharePageSaveCustomCategory,
              style: primaryButtonTextStyle(context).copyWith(fontSize: 16.sp),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildCustomCategoryCard(
    MapEntry<String, String> category,
    int index,
    String gender,
  ) {
    return Container(
      width: MediaQuery.sizeOf(context).width > 1000
          ? 600
          : MediaQuery.sizeOf(context).width * 0.85,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        border: Border.all(color: Theme.of(context).colorScheme.secondary),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Directionality(
        textDirection: textDirectionFor(category.key),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    category.key,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16.sp,
                      fontFamily: 'Rubix',
                    ),
                    textAlign: textAlignFor(category.key),
                  ),
                ),
                IconButton(
                  key: Key('custom-category-edit-button-$index'),
                  tooltip: appLocale.addFormEdit(gender),
                  icon: const Icon(Icons.edit, size: 20),
                  onPressed: () => editCustomCategory(index),
                ),
                IconButton(
                  key: Key('custom-category-delete-button-$index'),
                  tooltip: appLocale.deleteButton(gender),
                  icon: const Icon(Icons.delete, size: 20),
                  onPressed: () {
                    unawaited(deleteCustomCategory(index));
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
            Directionality(
              textDirection: textDirectionFor(category.value),
              child: Text(
                category.value,
                style: TextStyle(fontSize: 14.sp, fontFamily: 'Rubix'),
                textAlign: textAlignFor(category.value),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildCustomCategoriesSection(BuildContext context, String gender) {
    return Column(
      children: [
        ..._customCategories.asMap().entries.map(
          (entry) => buildCustomCategoryCard(entry.value, entry.key, gender),
        ),
        if (_isAddingCustomCategory) buildCustomCategoryForm(context),
        if (!_isAddingCustomCategory)
          TextButton(
            onPressed: startAddingCustomCategory,
            child: Text(
              appLocale.sharePageAddCustomCategory,
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.bold,
                fontSize: 16.sp,
              ),
            ),
          ),
      ],
    );
  }

  Future<void> _persistInlineDreamsAndGoals(
    UserInformation userInformation, {
    bool retry = false,
  }) {
    final WizardStepState? inlineStep =
        _dreamsAndGoalsStepKey.currentState;
    if (inlineStep != null) {
      return retry
          ? inlineStep.retryPersistBeforeExit()
          : inlineStep.persistBeforeExit();
    }
    return retry
        ? userInformation.retryDreamsAndGoalsSave(
            userInformation.dreamsAndGoalsSaveRevision,
          )
        : userInformation.pendingDreamsAndGoalsSave;
  }

  /// Prepares Dreams and Goals state for a Share action.
  ///
  /// The returned outcome keeps persistence failures separate from the action
  /// that follows, and records the current revision before each await that can
  /// fail. A retry therefore replays the latest prepared snapshot rather than
  /// an earlier state.
  Future<_DreamsAndGoalsActionPreparation> _prepareDreamsAndGoalsAction(
    UserInformation userInformation, {
    required bool retry,
    required int retryRevision,
  }) async {
    try {
      final bool retriedPendingConflictResolution =
          userInformation.hasPendingDreamsAndGoalsCustomConflictResolution;
      if (retriedPendingConflictResolution) {
        await userInformation.retryDreamsAndGoalsCustomConflictResolution();
      } else {
        await _persistInlineDreamsAndGoals(userInformation, retry: retry);
      }

      final int revisionBeforeRepair =
          userInformation.dreamsAndGoalsSaveRevision;
      retryRevision = revisionBeforeRepair;
      final Future<void> repair = userInformation
          .repairDreamsAndGoalsSelectionSources();
      retryRevision = userInformation.dreamsAndGoalsSaveRevision;
      await repair;
      if (userInformation.hasPendingDreamsAndGoalsCustomConflictResolution) {
        return _DreamsAndGoalsActionPreparation.blocked(retryRevision);
      }

      final _DreamsAndGoalsActionPreparation conflictResolution =
          await _resolveDreamsAndGoalsCustomConflict(
            userInformation,
            retryRevision: retryRevision,
          );
      if (conflictResolution.state !=
          _DreamsAndGoalsActionPreparationState.ready) {
        return conflictResolution;
      }
      retryRevision = conflictResolution.retryRevision;

      // A retry has already persisted the current snapshot through
      // _persistInlineDreamsAndGoals. Repeating it here would enqueue the
      // same three-key snapshot a second time before the deferred action runs.
      if (!retry &&
          !retriedPendingConflictResolution &&
          userInformation.dreamsAndGoalsSaveRevision == revisionBeforeRepair) {
        retryRevision = userInformation.dreamsAndGoalsSaveRevision;
        await userInformation.queueDreamsAndGoalsSave();
      }
      return _DreamsAndGoalsActionPreparation.ready(retryRevision);
    } catch (error, stackTrace) {
      return _DreamsAndGoalsActionPreparation.failed(
        retryRevision,
        error,
        stackTrace,
      );
    }
  }

  Future<_DreamsAndGoalsActionPreparation>
  _resolveDreamsAndGoalsCustomConflict(
    UserInformation userInformation, {
    required int retryRevision,
  }) async {
    try {
      if (!mounted ||
          userInformation.hasPendingDreamsAndGoalsCustomConflictResolution) {
        return _DreamsAndGoalsActionPreparation.blocked(retryRevision);
      }
      final List<int> customSelectionIndexes =
          userInformation.dreamsAndGoalsCustomSelectionIndexes;
      if (customSelectionIndexes.length <= 1) {
        return _DreamsAndGoalsActionPreparation.ready(retryRevision);
      }

      final int? retainedSelectionIndex =
          await showDreamsAndGoalsCustomConflictDialog(
            context,
            selections: userInformation.dreamsAndGoals,
            customSelectionIndexes: customSelectionIndexes,
            gender: userInformation.gender,
          );
      if (retainedSelectionIndex == null) {
        return _DreamsAndGoalsActionPreparation.blocked(retryRevision);
      }

      retryRevision = userInformation.dreamsAndGoalsSaveRevision;
      final Future<void> resolution = userInformation
          .resolveDreamsAndGoalsCustomConflict(retainedSelectionIndex);
      retryRevision = userInformation.dreamsAndGoalsSaveRevision;
      await resolution;
      return _DreamsAndGoalsActionPreparation.ready(retryRevision);
    } catch (error, stackTrace) {
      return _DreamsAndGoalsActionPreparation.failed(
        retryRevision,
        error,
        stackTrace,
      );
    }
  }

  Future<void> _toggleDreamsAndGoals({bool retry = false}) async {
    final UserInformation userInformation = Provider.of<UserInformation>(
      context,
      listen: false,
    );
    if (!_isEditingDreamsAndGoals) {
      if (_isOpeningDreamsAndGoals) {
        return;
      }
      _isOpeningDreamsAndGoals = true;
      final bool retryingPendingResolution =
          userInformation.hasPendingDreamsAndGoalsCustomConflictResolution;
      try {
        if (retryingPendingResolution) {
          await userInformation
              .retryDreamsAndGoalsCustomConflictResolution();
        } else if (retry) {
          await userInformation.retryDreamsAndGoalsSave(
            userInformation.dreamsAndGoalsSaveRevision,
          );
        } else {
          // The editor requires one source token per selected row. Repair the
          // model-owned snapshot before mounting FormPageTemplate so legacy
          // selections cannot reach its edit path with unaligned sources.
          await userInformation.repairDreamsAndGoalsSelectionSources();
        }
        if (userInformation.hasPendingDreamsAndGoalsCustomConflictResolution) {
          return;
        }
        final _DreamsAndGoalsActionPreparation conflictResolution =
            await _resolveDreamsAndGoalsCustomConflict(
              userInformation,
              retryRevision: userInformation.dreamsAndGoalsSaveRevision,
            );
        if (conflictResolution.state ==
            _DreamsAndGoalsActionPreparationState.failed) {
          Error.throwWithStackTrace(
            conflictResolution.error!,
            conflictResolution.stackTrace!,
          );
        }
        if (conflictResolution.state !=
            _DreamsAndGoalsActionPreparationState.ready) {
          return;
        }
        if (mounted) {
          setState(() {
            _isEditingDreamsAndGoals = true;
          });
        }
      } catch (error, stackTrace) {
        if (retry || retryingPendingResolution) {
          await _captureDreamsAndGoalsFailure(error, stackTrace);
        }
        if (mounted) {
          _showDreamsAndGoalsSaveFailure(
            () => _toggleDreamsAndGoals(retry: true),
          );
        }
      } finally {
        _isOpeningDreamsAndGoals = false;
      }
      return;
    }

    try {
      await _persistInlineDreamsAndGoals(userInformation, retry: retry);
      if (mounted) {
        setState(() {
          _isEditingDreamsAndGoals = false;
        });
      }
    } catch (error, stackTrace) {
      if (retry) {
        await _captureDreamsAndGoalsFailure(error, stackTrace);
      }
      if (mounted) {
        _showDreamsAndGoalsSaveFailure(
          () => _toggleDreamsAndGoals(retry: true),
        );
      }
    }
  }

  Future<void> _runDreamsAndGoalsAction(
    UserInformation userInformation,
    FutureOr<void> Function() action,
  ) async {
    final _DreamsAndGoalsActionPreparation preparation =
        await _prepareDreamsAndGoalsAction(
          userInformation,
          retry: false,
          retryRevision: userInformation.dreamsAndGoalsSaveRevision,
        );
    if (preparation.state == _DreamsAndGoalsActionPreparationState.blocked) {
      return;
    }
    if (preparation.state == _DreamsAndGoalsActionPreparationState.failed) {
      await _captureDreamsAndGoalsFailure(
        preparation.error!,
        preparation.stackTrace!,
      );
      if (mounted) {
        _showDreamsAndGoalsSaveFailure(
          () => _retryDreamsAndGoalsAction(
            userInformation,
            preparation.retryRevision,
            action,
          ),
        );
      }
      return;
    }

    if (mounted) {
      await action();
    }
  }

  Future<void> _retryDreamsAndGoalsAction(
    UserInformation userInformation,
    int capturedRevision,
    FutureOr<void> Function() action,
  ) async {
    final _DreamsAndGoalsActionPreparation preparation =
        await _prepareDreamsAndGoalsAction(
          userInformation,
          retry: true,
          retryRevision: capturedRevision,
        );
    if (preparation.state == _DreamsAndGoalsActionPreparationState.blocked) {
      return;
    }
    if (preparation.state == _DreamsAndGoalsActionPreparationState.failed) {
      await _captureDreamsAndGoalsFailure(
        preparation.error!,
        preparation.stackTrace!,
      );
      if (mounted) {
        _showDreamsAndGoalsSaveFailure(
          () => _retryDreamsAndGoalsAction(
            userInformation,
            preparation.retryRevision,
            action,
          ),
        );
      }
      return;
    }

    await _runRetriedDreamsAndGoalsAction(action);
  }

  void _showDreamsAndGoalsSaveFailure(Future<void> Function() retry) {
    showPersistenceRetrySnackBar(context, retry);
  }

  Future<void> _runRetriedDreamsAndGoalsAction(
    FutureOr<void> Function() action,
  ) async {
    if (!mounted) {
      return;
    }
    try {
      await action();
    } catch (error, stackTrace) {
      await _captureDreamsAndGoalsFailure(error, stackTrace);
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: error,
          stack: stackTrace,
          library: 'ShareForm',
          context: ErrorDescription('while retrying a Dreams and Goals action'),
        ),
      );
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

  Widget buildDreamsAndGoalsSection(BuildContext context, String gender) {
    return SizedBox(
      width: formFieldWidth(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          KeyedSubtree(
            key: const Key('share-dreams-and-goals-toggle'),
            child: LinkButton(
              () {
                unawaited(_toggleDreamsAndGoals());
              },
              _isEditingDreamsAndGoals
                  ? Icons.keyboard_arrow_up
                  : Icons.keyboard_arrow_down,
              appLocale.dreamsAndGoalsHeader(gender),
              Theme.of(context).colorScheme.primary,
              minHeight: 40,
            ),
          ),
          if (_isEditingDreamsAndGoals) ...[
            const SizedBox(height: AppSpacing.sm),
            FormPageTemplate(
              key: _dreamsAndGoalsStepKey,
              next: () {},
              prev: () {},
              collectionName: 'PersonalPlan-DreamsAndGoals',
              scrollable: false,
            ),
          ],
        ],
      ),
    );
  }

  @override
  Future<void> onPrimaryAction() async {
    final UserInformation userInformation = Provider.of<UserInformation>(
      context,
      listen: false,
    );
    await _runDreamsAndGoalsAction(
      userInformation,
      () => widget.submit(context),
    );
  }

  @override
  Future<void> persistBeforeExit() async {
    final UserInformation userInformation = Provider.of<UserInformation>(
      context,
      listen: false,
    );
    if (userInformation.hasPendingDreamsAndGoalsCustomConflictResolution) {
      await userInformation.retryDreamsAndGoalsCustomConflictResolution();
      return;
    }
    await _persistInlineDreamsAndGoals(userInformation);
  }

  @override
  Future<void> retryPersistBeforeExit() async {
    final UserInformation userInformation = Provider.of<UserInformation>(
      context,
      listen: false,
    );
    if (userInformation.hasPendingDreamsAndGoalsCustomConflictResolution) {
      await userInformation.retryDreamsAndGoalsCustomConflictResolution();
      return;
    }
    await _persistInlineDreamsAndGoals(userInformation, retry: true);
  }

  @override
  Widget build(BuildContext context) {
    final appInfoProvider = Provider.of<AppInformation>(context, listen: true);
    final userInfoProvider = Provider.of<UserInformation>(
      context,
      listen: true,
    );
    final gender = userInfoProvider.gender;

    return SingleChildScrollView(
      child: Center(
        child: Column(
          children: [
            Text(
              appLocale.sharePageHeader(gender),
              style: TextStyle(
                fontSize: 30.sp,
                fontWeight: FontWeight.w500,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            Text(
              appLocale.sharePageSubTitle(gender),
              style: TextStyle(
                fontWeight: FontWeight.normal,
                fontSize: 16.sp,
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
            myImage('assets/images/FormSubmit.png', context, 0.6, 0.25),
            SizedBox(
              width: MediaQuery.sizeOf(context).width * 0.8,
              child: Text(
                appLocale.sharePageMidTitle(gender),
                style: TextStyle(
                  fontWeight: FontWeight.normal,
                  fontSize: 16.sp,
                ),
              ),
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: MediaQuery.sizeOf(context).width * 0.5,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  //share personal plan PDF button:
                  IconButton(
                    onPressed: () {
                      unawaited(
                        _runDreamsAndGoalsAction(userInfoProvider, () async {
                          if (!mounted) {
                            return;
                          }
                          await showShareDialog(context);
                        }),
                      );
                    },
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      padding: const EdgeInsets.all(10),
                      shape: RoundedRectangleBorder(
                        borderRadius: const BorderRadius.all(
                          Radius.circular(16),
                        ),
                        side: BorderSide(
                          color: Theme.of(context).colorScheme.primary,
                        ), // Set the border color
                      ),
                    ),
                    icon: Icon(
                      Icons.share,
                      color: Theme.of(context).colorScheme.primary,
                    ), // Set the icon color
                    padding: const EdgeInsets.all(10),
                  ),
                  //download personal plan PDF button:
                  IconButton(
                    onPressed: () {
                      unawaited(
                        _runDreamsAndGoalsAction(userInfoProvider, () async {
                          final exportMetadata = buildPersonalPlanExportMetadata(
                            appLocale,
                            gender,
                            userInfoProvider.name,
                          );
                          final result = await fileService.download(
                            exportMetadata.titles,
                            exportMetadata.subTitles,
                            appInfoProvider.sharePDFtexts,
                            ShareFileType.PDF,
                            mainTitle: exportMetadata.mainTitle,
                            textDirection: appLocale.textDirection,
                          );
                          if (result == null) {
                            showToast(message: appLocale.downloadFailed(gender));
                            return;
                          }
                          showToast(
                            message: appLocale.finishedDownloading(gender),
                          );
                        }),
                      );
                    },

                    style: TextButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      padding: const EdgeInsets.all(10),
                      shape: RoundedRectangleBorder(
                        borderRadius: const BorderRadius.all(
                          Radius.circular(16),
                        ),
                        side: BorderSide(
                          color: Theme.of(context).colorScheme.primary,
                        ), // Set the border color
                      ),
                    ),
                    icon: Icon(
                      Icons.download,
                      color: Theme.of(context).colorScheme.primary,
                    ), // Set the icon color
                    padding: const EdgeInsets.all(10),
                  ),
                ],
              ),
            ),
            buildDreamsAndGoalsSection(context, gender),
            buildCustomCategoriesSection(context, gender),
          ],
        ),
      ),
    );
  }
}
