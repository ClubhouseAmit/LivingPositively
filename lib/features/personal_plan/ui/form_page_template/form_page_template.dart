import 'dart:async';

import 'package:flutter/material.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:get_it/get_it.dart';
import 'package:mazilon/util/async/analytics_service.dart';
import 'package:mazilon/util/async/global_enums.dart';

import 'package:mazilon/features/wizard/ui/wizard_step.dart';
import 'package:mazilon/l10n/app_localizations.dart';
import 'package:mazilon/features/personal_plan/ui/form_answer.dart';
import 'package:mazilon/features/personal_plan/ui/addFormAnswer.dart';
import 'package:mazilon/features/shell/ui/persistence_retry_snack_bar.dart';
import 'package:mazilon/features/personal_plan/data/dreams_and_goals_models.dart';
import 'package:mazilon/util/async/logger_service.dart';
import 'package:mazilon/util/async/persistent_memory_service.dart';
import 'package:mazilon/features/shell/ui/styles.dart';
import 'package:mazilon/util/async/app_theme.dart';
import 'package:mazilon/design_system/tokens/font_weight.dart';
import 'package:mazilon/design_system/tokens/spacing.dart';

import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:mazilon/util/userInformation.dart';
import 'package:provider/provider.dart';
import 'package:mazilon/features/personal_plan/ui/retrieveInformation.dart';

part 'blocks.dart';
part 'persist.dart';

/// Spacing for the shared onboarding template, read off the Figma frames' own
/// container boxes (`Android Large - 10/15`, frames "Frame 210" title block,
/// "Frame 216" items block, "Frame 223" suggestions block). The widget tree
/// below mirrors that container hierarchy one-for-one, so every gap here is the
/// distance between two named design containers rather than a hand-tuned
/// number.
///
/// The values moved to [OnboardingGaps] once the intro flow was ported onto the
/// same wizard shell — both flows' frames set the same container spacing, so
/// they share one definition rather than two copies that can drift.
const double _gapLabelToCaption = OnboardingGaps.labelToCaption;
const double _gapWithinGroup = OnboardingGaps.withinGroup;
const double _gapWithinBlock = OnboardingGaps.withinBlock;
const double _gapBetweenBlocks = OnboardingGaps.betweenBlocks;
const double _suggestionInset = 10;

class FormPageTemplate extends WizardStep {
  //next page:
  final Function next;
  //prev page:
  final Function prev;

  final String collectionName;
  final bool scrollable;
  final PersistentMemoryService? persistentMemoryService;

  const FormPageTemplate({
    required super.key,
    required this.next,
    required this.prev,
    required this.collectionName,
    this.scrollable = true,
    this.persistentMemoryService,
  });

  @override
  String primaryActionLabel(BuildContext context) => retrieveInformation(
    collectionName,
    Provider.of<UserInformation>(context).gender,
    AppLocalizations.of(context)!,
  )['nextButtonText'];

  @override
  WizardStepState<FormPageTemplate> createState() => _FormPageTemplateState();
}

class _FormPageTemplateState extends WizardStepState<FormPageTemplate>
    with _FormPagePersist, _FormPageBlocks {
  @override
  void initState() {
    super.initState();
    if (widget.collectionName == 'PersonalPlan-SafeEnvironment') {
      displayedLength = 4;
    }
  }

  @override
  Future<void> onPrimaryAction() async {
    final userInfoProvider = Provider.of<UserInformation>(
      context,
      listen: false,
    );
    AnalyticsService mixPanelService = GetIt.instance<AnalyticsService>();
    mixPanelService.trackEvent("Plan edited", {'page': widget.collectionName});
    int? dreamsSaveRevision;
    try {
      await createSelection(
        userInfoProvider,
        onDreamsSaveQueued: (int revision) {
          dreamsSaveRevision = revision;
        },
      );
      if (mounted) {
        widget.next();
      }
    } catch (_) {
      if (mounted) {
        _showSaveFailure(
          () => _completePrimaryAction(userInfoProvider, dreamsSaveRevision),
        );
      }
      rethrow;
    }
  }

  Future<void> _completePrimaryAction(
    UserInformation userInfoProvider,
    int? dreamsSaveRevision,
  ) async {
    if (_tracksDreamsAndGoalsSelectionSources && dreamsSaveRevision != null) {
      await _retrySelectionSave(userInfoProvider, dreamsSaveRevision);
    } else {
      await createSelection(userInfoProvider);
    }
    if (mounted) {
      widget.next();
    }
  }

  @override
  Future<void> persistBeforeExit() async {
    if (!_tracksDreamsAndGoalsSelectionSources) {
      return;
    }
    final UserInformation userInfoProvider = Provider.of<UserInformation>(
      context,
      listen: false,
    );
    await Future.wait<void>([
      userInfoProvider.pendingDreamsAndGoalsSave,
      _pendingDreamsAndGoalsPersistence,
    ]);
  }

  @override
  Future<void> retryPersistBeforeExit() async {
    if (!_tracksDreamsAndGoalsSelectionSources) {
      return;
    }
    final UserInformation userInfoProvider = Provider.of<UserInformation>(
      context,
      listen: false,
    );
    await _saveDreamsAndGoalsWithDisclaimer(
      userInfoProvider,
      revision:
          _pendingDreamsAndGoalsPersistenceRevision ??
          userInfoProvider.dreamsAndGoalsSaveRevision,
      retry: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    final userInfoProvider = Provider.of<UserInformation>(
      context,
      listen: true,
    );
    final gender = userInfoProvider.gender;

    Map<String, dynamic> displayInformation = retrieveInformation(
      widget.collectionName,
      gender,
      appLocale,
    );
    suggestionPool = (displayInformation['list'] as List).cast<String>();
    loadItems(userInfoProvider);
    syncRowIds();
    //suggestions still available to pick — a suggestion drops out of this
    final availableSuggestions = suggestionPool
        .take(revealedSuggestions)
        .where((item) => !isAlreadySelected(item))
        .toList();

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: _gapBetweenBlocks,
      children: [
        _buildTitleBlock(displayInformation),
        _buildItemsBlock(userInfoProvider, gender),
        if (availableSuggestions.isNotEmpty ||
            revealedSuggestions < suggestionPool.length)
          _buildSuggestionsBlock(
            displayInformation,
            availableSuggestions,
            userInfoProvider,
          ),
      ],
    );
    return widget.scrollable ? SingleChildScrollView(child: content) : content;
  }
}
