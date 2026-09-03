import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:get_it/get_it.dart';

import 'package:mazilon/file_service.dart';
import 'package:mazilon/form/formpagetemplate.dart';
import 'package:mazilon/form/custom_category_editor.dart';
import 'package:mazilon/form/custom_category_options.dart';
import 'package:mazilon/form/wizard_step.dart';
import 'package:mazilon/l10n/app_localizations.dart';
import 'package:mazilon/util/async/persistence_retry_snack_bar.dart';
import 'package:mazilon/util/logger_service.dart';
import 'package:mazilon/util/persistent_memory_service.dart';
import 'package:mazilon/util/theme/spacing.dart';
import 'package:provider/provider.dart';
import 'package:mazilon/util/styles.dart';

import 'package:mazilon/util/appInformation.dart';
import 'package:mazilon/util/Share/personal_plan_download.dart';
import 'package:mazilon/util/userInformation.dart';
import 'package:mazilon/util/Share/show_share_dialog.dart';
import 'package:mazilon/util/Form/retrieveInformation.dart';
import 'package:mazilon/util/dreams_and_goals_selection.dart';
import 'package:mazilon/pages/PersonalPlan/myPlan.dart';

/// The result of preparing a Share action that depends on Dreams and Goals.
///
/// The variants make each preparation path explicit so callers cannot run an
/// action for a newly added, unhandled preparation state.
sealed class _DreamsAndGoalsActionPreparation {
  const _DreamsAndGoalsActionPreparation();
}

final class _DreamsAndGoalsActionReady
    extends _DreamsAndGoalsActionPreparation {
  const _DreamsAndGoalsActionReady();
}

/// A preparation failure with the revision safe to retry.
///
/// [retryRevision] is captured before each persistence await so a retry never
/// replays an older snapshot over a newer edit.
final class _DreamsAndGoalsActionFailed
    extends _DreamsAndGoalsActionPreparation {
  const _DreamsAndGoalsActionFailed(
    this.retryRevision,
    this.error,
    this.stackTrace,
  );

  final int retryRevision;
  final Object error;
  final StackTrace stackTrace;
}

class ShareForm extends WizardStep {
  final Function prev;
  final FutureOr<void> Function(BuildContext context) submit;
  final PersistentMemoryService? memoryService;
  final void Function(int step)? goToStep;
  final int? shareStepIndex;

  const ShareForm({
    required super.key,
    required this.prev,
    required this.submit,
    this.memoryService,
    this.goToStep,
    this.shareStepIndex,
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
  bool _isEditingDreamsAndGoals = false;
  bool _isOpeningDreamsAndGoals = false;
  bool _hideDreamsAndGoalsSummaryUntilRepair = false;
  bool _isRunningDreamsAndGoalsAction = false;
  bool _isAddingCustomCategory = false;
  int? _editingCustomCategoryIndex;
  int _customCategoryFormGeneration = 0;

  UserInformation? get _userInformation {
    if (!mounted) return null;
    try {
      // Resolve the same non-null provider that the Share form requires. A
      // nullable type argument can miss a ChangeNotifierProvider<UserInformation>
      // at runtime, silently skipping all custom-category mutations.
      return Provider.of<UserInformation>(context, listen: false);
    } catch (_) {
      return null;
    }
  }

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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _userInformation?.loadCustomCategories(
          memoryService: widget.memoryService,
        );
      }
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _persistCustomCategoriesSafely(
    List<MapEntry<String, String>> categories,
  ) async {
    try {
      final userInformation = _userInformation;
      if (userInformation != null) {
        await userInformation.saveCustomCategories(
          categories: categories,
          memoryService: widget.memoryService,
        );
      }
    } catch (error, stackTrace) {
      await _captureDreamsAndGoalsFailure(error, stackTrace);
      if (mounted) {
        _showCustomCategorySaveFailure(categories);
      }
    }
  }

  void _showCustomCategorySaveFailure(
    List<MapEntry<String, String>> categories,
  ) {
    showPersistenceRetrySnackBar(
      context,
      () => _persistCustomCategoriesSafely(categories),
    );
  }

  List<String> predefinedCategoryTitles() {
    return localizedCustomCategoryTitles(appLocale);
  }

  void resetCustomCategoryForm() {
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
    final categories = _userInformation?.customCategories ?? const [];
    if (index < 0 || index >= categories.length) {
      return;
    }
    setState(() {
      _editingCustomCategoryIndex = index;
      _isAddingCustomCategory = true;
      _customCategoryFormGeneration++;
    });
  }

  Future<void> deleteCustomCategory(int index) async {
    final categories = _userInformation?.customCategories ?? const [];
    if (index < 0 || index >= categories.length) {
      return;
    }
    if (!await _confirmDelete(categories[index].key)) {
      return;
    }

    final updated = List<MapEntry<String, String>>.from(categories)
      ..removeAt(index);
    setState(() {
      if (_editingCustomCategoryIndex == index) {
        resetCustomCategoryForm();
        _isAddingCustomCategory = false;
      } else if (_editingCustomCategoryIndex != null &&
          _editingCustomCategoryIndex! > index) {
        _editingCustomCategoryIndex = _editingCustomCategoryIndex! - 1;
      }
    });

    await _persistCustomCategoriesSafely(updated);
  }

  Widget buildCustomCategoryForm(BuildContext context) {
    final categories = _userInformation?.customCategories ?? const [];
    final editingIndex = _editingCustomCategoryIndex;
    final initialCategory =
        editingIndex != null &&
            editingIndex >= 0 &&
            editingIndex < categories.length
        ? categories[editingIndex]
        : null;
    return CustomCategoryEditor(
      key: ValueKey(
        'share-custom-category-editor-$_customCategoryFormGeneration',
      ),
      initialCategory: initialCategory,
      predefinedTitles: predefinedCategoryTitles(),
      optionsViewOpenDirection: OptionsViewOpenDirection.up,
      saveLabel: appLocale.sharePageSaveCustomCategory,
      onCancel: () {
        setState(() {
          resetCustomCategoryForm();
          _isAddingCustomCategory = false;
        });
      },
      onSave: (category) async {
        final updated = List<MapEntry<String, String>>.from(categories);
        if (editingIndex != null &&
            editingIndex >= 0 &&
            editingIndex < updated.length) {
          updated[editingIndex] = category;
        } else {
          updated.add(category);
        }
        setState(() {
          resetCustomCategoryForm();
          _isAddingCustomCategory = false;
        });
        await _persistCustomCategoriesSafely(updated);
      },
    );
  }

  Widget buildCustomCategoryCard(
    MapEntry<String, String> category,
    int index,
    String gender,
  ) {
    return CustomCategoryCard(
      category: category,
      index: index,
      onEdit: () => editCustomCategory(index),
      onDelete: () => unawaited(deleteCustomCategory(index)),
    );
  }

  Future<bool> _confirmDelete(String title) async {
    final localizations = AppLocalizations.of(context)!;
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(localizations.deleteButton('other')),
            content: Text(
              '$title\n\n${localizations.customCategoryDeleteConfirmation}',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(localizations.closeButton('other')),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(localizations.deleteButton('other')),
              ),
            ],
          ),
        ) ??
        false;
  }

  Widget buildCustomCategoriesSection(BuildContext context, String gender) {
    return Column(
      children: [
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

  List<Widget> _buildPlanSummary(
    BuildContext context,
    UserInformation userInformation,
    String gender,
  ) {
    final definitions = <({String collection, List<String> answers})>[
      (
        collection: 'PersonalPlan-Distractions',
        answers: userInformation.distractions,
      ),
      (
        collection: 'PersonalPlan-DifficultEvents',
        answers: userInformation.difficultEvents,
      ),
      (
        collection: 'PersonalPlan-FeelBetter',
        answers: userInformation.feelBetter,
      ),
      (
        collection: 'PersonalPlan-MakeSafer',
        answers: userInformation.makeSafer,
      ),
      (
        collection: 'PersonalPlan-SafeEnvironment',
        answers: userInformation.safeEnvironment,
      ),
    ];
    final result = <Widget>[];
    for (final definition in definitions) {
      if (definition.answers.isEmpty) continue;
      final info = retrieveInformation(
        definition.collection,
        gender,
        appLocale,
      );
      final step = definitions.indexOf(definition);
      result.add(
        MyPlanSection(
          key: ValueKey('share-summary-$step'),
          title: info['header'] ?? '',
          subTitle: info['subTitle'] ?? '',
          answers: definition.answers,
          onEdit: widget.goToStep == null ? null : () => widget.goToStep!(step),
          onDelete: () =>
              unawaited(_deleteBuiltInCategory(definition.collection)),
        ),
      );
    }
    for (final entry in userInformation.customCategories.indexed) {
      final categoryIndex = entry.$1;
      result.add(
        CustomCategoryCard(
          key: ValueKey('share-summary-custom-$categoryIndex'),
          category: entry.$2,
          index: categoryIndex,
          onEdit: widget.goToStep == null
              ? () => editCustomCategory(categoryIndex)
              : () => widget.goToStep!(6 + categoryIndex),
          onDelete: () => unawaited(deleteCustomCategory(categoryIndex)),
        ),
      );
    }
    return result;
  }

  Future<void> _deleteBuiltInCategory(String collectionName) async {
    final localizations = AppLocalizations.of(context)!;
    final userInformation = Provider.of<UserInformation>(
      context,
      listen: false,
    );
    if (!await _confirmDelete(
      localizations.builtInCategoryDeleteConfirmation,
    )) {
      return;
    }
    try {
      await userInformation.saveCategorySelection(collectionName, const []);
    } catch (error, stackTrace) {
      await _captureDreamsAndGoalsFailure(error, stackTrace);
      if (mounted) {
        showPersistenceRetrySnackBar(
          context,
          () => _deleteBuiltInCategory(collectionName),
        );
      }
    }
  }

  Future<void> _persistInlineDreamsAndGoals(
    UserInformation userInformation, {
    bool retry = false,
  }) {
    final WizardStepState? inlineStep = _dreamsAndGoalsStepKey.currentState;
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
    required int initialRetryRevision,
  }) async {
    int retryRevision = initialRetryRevision;
    if (!_dreamsAndGoalsSourcesAreAligned(userInformation) && mounted) {
      setState(() {
        _hideDreamsAndGoalsSummaryUntilRepair = true;
      });
    }
    try {
      while (true) {
        final bool hadInlineStep = _dreamsAndGoalsStepKey.currentState != null;
        await _persistInlineDreamsAndGoals(userInformation, retry: retry);
        retryRevision = userInformation.dreamsAndGoalsSaveRevision;
        await userInformation.pendingDreamsAndGoalsSave;
        await userInformation.pendingCustomCategoriesSave;

        final int revisionBeforeRepair =
            userInformation.dreamsAndGoalsSaveRevision;
        await userInformation.repairDreamsAndGoalsSelectionSources();
        await userInformation.pendingDreamsAndGoalsSave;
        await userInformation.pendingCustomCategoriesSave;

        // If no inline editor persisted this snapshot and repair left the revision
        // unchanged, queue the save now so in-memory state is durable in storage.
        if (!retry &&
            !hadInlineStep &&
            userInformation.dreamsAndGoalsSaveRevision ==
                revisionBeforeRepair) {
          await userInformation.queueDreamsAndGoalsSave();
          await userInformation.pendingDreamsAndGoalsSave;
          await userInformation.pendingCustomCategoriesSave;
        }

        final int expectedRevision = userInformation.dreamsAndGoalsSaveRevision;
        retryRevision = expectedRevision;
        if (userInformation.dreamsAndGoalsSaveRevision == expectedRevision) {
          await userInformation.pendingDreamsAndGoalsSave;
          await userInformation.pendingCustomCategoriesSave;
          if (mounted) {
            setState(() {
              _hideDreamsAndGoalsSummaryUntilRepair = false;
            });
          }
          break;
        }
      }
      return const _DreamsAndGoalsActionReady();
    } catch (error, stackTrace) {
      return _DreamsAndGoalsActionFailed(retryRevision, error, stackTrace);
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
      if (mounted) {
        setState(() {
          _hideDreamsAndGoalsSummaryUntilRepair = true;
        });
      }
      try {
        if (retry) {
          await userInformation.retryDreamsAndGoalsSave(
            userInformation.dreamsAndGoalsSaveRevision,
          );
        } else {
          // The editor requires one source token per selected row. Repair the
          // model-owned snapshot before mounting FormPageTemplate so legacy
          // selections cannot reach its edit path with unaligned sources.
          await userInformation.repairDreamsAndGoalsSelectionSources();
        }
        if (mounted) {
          setState(() {
            _isEditingDreamsAndGoals = true;
            _hideDreamsAndGoalsSummaryUntilRepair = false;
          });
        }
      } catch (error, stackTrace) {
        if (retry) {
          await _captureDreamsAndGoalsFailure(error, stackTrace);
        }
        if (mounted) {
          setState(() {
            _hideDreamsAndGoalsSummaryUntilRepair = true;
          });
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
          _hideDreamsAndGoalsSummaryUntilRepair = false;
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
  ) => _runGuardedDreamsAndGoalsAction(
    userInformation,
    action,
    retry: false,
    retryRevision: userInformation.dreamsAndGoalsSaveRevision,
  );

  Future<void> _retryDreamsAndGoalsAction(
    UserInformation userInformation,
    int capturedRevision,
    FutureOr<void> Function() action,
  ) => _runGuardedDreamsAndGoalsAction(
    userInformation,
    action,
    retry: true,
    retryRevision: capturedRevision,
  );

  /// Runs one Dreams-dependent action at a time for this Share form.
  ///
  /// The guard spans preparation, persistence retry UI, and the final action
  /// so rapid taps cannot duplicate an export or finish.
  Future<void> _runGuardedDreamsAndGoalsAction(
    UserInformation userInformation,
    FutureOr<void> Function() action, {
    required bool retry,
    required int retryRevision,
  }) async {
    if (_isRunningDreamsAndGoalsAction) {
      return;
    }
    _isRunningDreamsAndGoalsAction = true;
    try {
      final _DreamsAndGoalsActionPreparation preparation =
          await _prepareDreamsAndGoalsAction(
            userInformation,
            retry: retry,
            initialRetryRevision: retryRevision,
          );
      switch (preparation) {
        case _DreamsAndGoalsActionFailed(
          :final int retryRevision,
          :final Object error,
          :final StackTrace stackTrace,
        ):
          await _captureDreamsAndGoalsFailure(error, stackTrace);
          if (mounted) {
            _showDreamsAndGoalsSaveFailure(
              () => _retryDreamsAndGoalsAction(
                userInformation,
                retryRevision,
                action,
              ),
            );
          }
          return;
        case _DreamsAndGoalsActionReady():
          if (!retry && mounted) {
            await action();
          } else if (retry) {
            await _runRetriedDreamsAndGoalsAction(action);
          }
      }
    } finally {
      _isRunningDreamsAndGoalsAction = false;
    }
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

  bool _dreamsAndGoalsSourcesAreAligned(UserInformation userInformation) {
    return listEquals(
      userInformation.dreamsAndGoalsSelectionSources,
      normalizeDreamsAndGoalsSelectionSources(
        userInformation.dreamsAndGoals,
        userInformation.dreamsAndGoalsSelectionSources,
      ),
    );
  }

  bool _dreamsAndGoalsSummaryIsReady(UserInformation userInformation) {
    if (_hideDreamsAndGoalsSummaryUntilRepair ||
        userInformation.dreamsAndGoals.isEmpty) {
      return false;
    }
    return _dreamsAndGoalsSourcesAreAligned(userInformation);
  }

  Widget buildDreamsAndGoalsSection(BuildContext context, String gender) {
    final userInformation = Provider.of<UserInformation>(
      context,
      listen: false,
    );
    final dreamsSummaryIsReady = _dreamsAndGoalsSummaryIsReady(userInformation);
    final dreamsInformation = retrieveInformation(
      'PersonalPlan-DreamsAndGoals',
      gender,
      appLocale,
    );
    return SizedBox(
      width: formFieldWidth(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (dreamsSummaryIsReady && !_isEditingDreamsAndGoals)
            MyPlanSection(
              key: const ValueKey('share-summary-5'),
              title: dreamsInformation['header'] ?? '',
              subTitle: dreamsInformation['subTitle'] ?? '',
              answers: userInformation.dreamsAndGoals,
              onEdit: widget.goToStep == null
                  ? () => unawaited(_toggleDreamsAndGoals())
                  : () => widget.goToStep!(5),
              onDelete: () => unawaited(
                _deleteBuiltInCategory('PersonalPlan-DreamsAndGoals'),
              ),
            ),
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
    await Future.wait<void>([
      _persistInlineDreamsAndGoals(userInformation),
      userInformation.pendingCustomCategoriesSave,
    ]);
  }

  @override
  Future<void> retryPersistBeforeExit() async {
    final UserInformation userInformation = Provider.of<UserInformation>(
      context,
      listen: false,
    );
    await Future.wait<void>([
      _persistInlineDreamsAndGoals(userInformation, retry: true),
      userInformation.retryCustomCategoriesSave(
        userInformation.customCategoriesSaveRevision,
        memoryService: widget.memoryService,
      ),
    ]);
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
                          await downloadPersonalPlanFile(
                            appLocale: appLocale,
                            gender: gender,
                            username: userInfoProvider.name,
                            appInformation: appInfoProvider,
                            userInformation: userInfoProvider,
                            fileService: fileService,
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
            ..._buildPlanSummary(context, userInfoProvider, gender),
            buildDreamsAndGoalsSection(context, gender),
            buildCustomCategoriesSection(context, gender),
          ],
        ),
      ),
    );
  }
}
