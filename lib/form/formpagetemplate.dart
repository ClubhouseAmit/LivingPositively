import 'dart:async';

import 'package:flutter/material.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:get_it/get_it.dart';
import 'package:mazilon/AnalyticsService.dart';
import 'package:mazilon/global_enums.dart';

import 'package:mazilon/form/wizard_step.dart';
import 'package:mazilon/l10n/app_localizations.dart';
import 'package:mazilon/pages/FormAnswer.dart';
import 'package:mazilon/util/FormAnswer/addFormAnswer.dart';
import 'package:mazilon/util/persistent_memory_service.dart';
import 'package:mazilon/util/styles.dart';
import 'package:mazilon/util/theme/app_theme.dart';
import 'package:mazilon/util/theme/font_weight.dart';
import 'package:mazilon/util/theme/spacing.dart';

import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:mazilon/util/userInformation.dart';
import 'package:provider/provider.dart';
import 'package:mazilon/util/Form/retrieveInformation.dart';

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

class FormPageTemplate extends WizardStep {
  //next page:
  final Function next;
  //prev page:
  final Function prev;

  final String collectionName;
  final bool scrollable;

  const FormPageTemplate({
    required super.key,
    required this.next,
    required this.prev,
    required this.collectionName,
    this.scrollable = true,
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

class _FormPageTemplateState extends WizardStepState<FormPageTemplate> {
  int displayedLength = 3;
  List<String> suggestionPool = const [];
  List<String> selectedItems = [];
  List<String> selectedItemSources = const [];

  // Identity for the answer rows. Two answers can hold the same text, so a
  // text-derived key is not identity: after swiping one away, the survivor
  // would be matched to the dismissed row and inherit its collapsed state.
  // Ids are reissued whenever the list changes length, which guarantees a
  // removed row's key never comes back.
  List<int> rowIds = const [];
  int _nextRowId = 0;

  void syncRowIds() {
    if (rowIds.length != selectedItems.length) {
      rowIds = List.generate(selectedItems.length, (_) => _nextRowId++);
    }
  }

  @override
  void initState() {
    super.initState();
    if (widget.collectionName == 'PersonalPlan-SafeEnvironment') {
      displayedLength = 4;
    }
  }

  static const int _suggestionBatch = 3;

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
    if (_limitsToOneCustomItem) {
      final index = suggestionPool.indexOf(item);
      return index >= 0 &&
          selectedItemSources.contains(
            dreamsAndGoalsCatalogueSelectionSourceForIndex(index),
          );
    }
    return selectedItems.contains(item);
  }

  bool get _limitsToOneCustomItem =>
      widget.collectionName == 'PersonalPlan-DreamsAndGoals';

  bool get _hasCustomItem =>
      selectedItemSources.contains(dreamsAndGoalsCustomSelectionSource);

  bool get _canAddOwnItem => !_limitsToOneCustomItem || !_hasCustomItem;

  void editItem(int index, String text) {
    if (index < 0 || index >= selectedItems.length) {
      return;
    }
    final editedItem = text.trim();
    if (_limitsToOneCustomItem && editedItem != selectedItems[index]) {
      final source = selectedItemSources[index];
      if (source != dreamsAndGoalsCustomSelectionSource) {
        final hasAnotherCustomItem = selectedItemSources.indexed.any(
          (entry) =>
              entry.$1 != index &&
              entry.$2 == dreamsAndGoalsCustomSelectionSource,
        );
        if (hasAnotherCustomItem) {
          return;
        }
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
    // By index, not by value: two answers can hold the same text, and
    // removing by value would delete both.
    selectedItems.removeAt(index);
    if (_limitsToOneCustomItem) {
      selectedItemSources.removeAt(index);
    }

    setState(() {});
  }

  void addItem(String text, {String? selectionSource}) {
    final source = selectionSource ?? dreamsAndGoalsCustomSelectionSource;
    if (_limitsToOneCustomItem &&
        source == dreamsAndGoalsCustomSelectionSource &&
        _hasCustomItem) {
      return;
    }
    selectedItems.add(text.trim());
    if (_limitsToOneCustomItem) {
      selectedItemSources.add(source);
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

  Future<void> createSelection(userInfo) async {
    PersistentMemoryService service =
        GetIt.instance<
          PersistentMemoryService
        >(); // Get the persistent memory service instance

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
      case 'PersonalPlan-DreamsAndGoals':
        selectedItemSources = normalizeDreamsAndGoalsSelectionSources(
          selectedItems,
          selectedItemSources,
        );
        userInfo.updateDreamsAndGoals([
          ...selectedItems,
        ], selectionSources: selectedItemSources);
        break;
      default:
    }
    await service.setItem(
      "disclaimerConfirmed",
      PersistentMemoryType.Bool,
      true,
    );
    if (_limitsToOneCustomItem) {
      await Future.wait<void>([
        service.setItem(
          'userSelection${widget.collectionName}',
          PersistentMemoryType.StringList,
          [...selectedItems],
        ),
        service.setItem(
          'addedStrings${widget.collectionName}',
          PersistentMemoryType.StringList,
          dreamsAndGoalsCustomItems(selectedItems, selectedItemSources),
        ),
        service.setItem(
          'selectionSources${widget.collectionName}',
          PersistentMemoryType.StringList,
          [...selectedItemSources],
        ),
      ]);
      return;
    }
    await service.setItem(
      'userSelection${widget.collectionName}',
      PersistentMemoryType.StringList,
      [...selectedItems],
    );
    await service.setItem(
      'addedStrings${widget.collectionName}',
      PersistentMemoryType.StringList,
      [...selectedItems],
    );
  }

  void loadItems(userInfo) {
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
        selectedItemSources = normalizeDreamsAndGoalsSelectionSources(
          selectedItems,
          userInfo.dreamsAndGoalsSelectionSources,
        );
        break;
      default:
    }
  }

  /// Figma "Frame 210" — page title + subtitle, both full width, centred.
  Widget _buildTitleBlock(Map<String, dynamic> displayInformation) {
    return Column(
      spacing: _gapWithinBlock,
      children: [
        Text(
          displayInformation['header'],
          style: TextStyle(
            fontWeight: AppFontWeight.medium,
            fontSize: 24.sp,
            color: Theme.of(context).colorScheme.onSurface,
          ),
          textAlign: TextAlign.center,
        ),
        Text(
          displayInformation['subTitle'],
          style: TextStyle(
            fontWeight: AppFontWeight.regular,
            color: Theme.of(context).colorScheme.outline,
            fontSize: 16.sp,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  /// Figma "Frame 216" — the answered-item rows ("Frame 215") followed by the
  /// inline "add your own" link ("Frame 171"), which the design aligns to the
  /// reading start edge rather than centring.
  Widget _buildItemsBlock(UserInformation userInfoProvider, String gender) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      //The design spaces the rows and the "add your own" link uniformly, so
      //one `spacing` covers both — no trailing-item special case.
      spacing: _gapWithinBlock,
      children: [
        //Frame 215 — a plain Column, not a shrink-wrapped ListView: the list
        //never scrolls on its own, and a ListView would silently inherit
        //MediaQuery.padding as sliver padding.
        for (final (index, item) in selectedItems.indexed)
          FormAnswer(
            key: ValueKey('answer-${rowIds[index]}'),
            text: item,
            num: index + 1,
            edit: (int editIndex, String text) {
              editItem(editIndex, text);
              unawaited(createSelection(userInfoProvider));
            },
            remove: (int removeIndex) {
              removeItem(removeIndex);
              unawaited(createSelection(userInfoProvider));
            },
          ),
        //Frame 171 — start-aligned, not centred.
        if (_canAddOwnItem)
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: LinkButton(
              () {
                showDialog(
                  context: context,
                  builder: (context) {
                    return AddFormAnswer(
                      index: selectedItems.length,
                      edit: (int index, String text) {
                        addItem(
                          text,
                          selectionSource: dreamsAndGoalsCustomSelectionSource,
                        );
                        unawaited(createSelection(userInfoProvider));
                      },
                      text: '',
                    );
                  },
                );
              },
              Icons.add,
              widget.collectionName == 'PersonalPlan-DreamsAndGoals'
                  ? appLocale.dreamsAndGoalsAddOwn(gender)
                  : appLocale.addFormPageTemplateAddOwn(gender),
              Theme.of(context).colorScheme.primary,
              designFontSize: 12,
              iconSize: 12,
            ),
          ),
      ],
    );
  }

  /// Figma "Frame 223" — section heading ("Frame 221"), the suggestion cards
  /// ("Frame 220") and the centred "other suggestions" link ("Frame 219").
  Widget _buildSuggestionsBlock(
    Map<String, dynamic> displayInformation,
    List<String> availableSuggestions,
    UserInformation userInfoProvider,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: _gapWithinBlock,
      children: [
        //Frame 221 — heading and its caption.
        Column(
          spacing: _gapLabelToCaption,
          children: [
            Text(
              displayInformation['midTitle'],
              style: TextStyle(
                fontWeight: AppFontWeight.semiBold,
                fontSize: 14.sp,
                color: Theme.of(context).colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            Text(
              displayInformation['midSubTitle'],
              style: TextStyle(
                fontWeight: AppFontWeight.regular,
                color: Theme.of(context).colorScheme.outline,
                fontSize: 12.sp,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        //Frame 220 — the cards and the "other suggestions" link share the
        //tighter within-group spacing.
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: _gapWithinGroup,
          children: [
            for (final item in availableSuggestions)
              _buildSuggestionCard(item, userInfoProvider),
            if (revealedSuggestions < suggestionPool.length)
              Align(
                alignment: Alignment.center,
                child: LinkButton(
                  addSuggestion,
                  Icons.refresh,
                  displayInformation['showMoreButtonText'],
                  Theme.of(context).colorScheme.tertiary,
                ),
              ),
          ],
        ),
      ],
    );
  }

  /// Figma "Frame 181"/"Frame 172" — an unselected suggestion. Picking one
  /// promotes it into the answered list above, so it leaves this pool and no
  /// "selected" treatment is rendered here.
  Widget _buildSuggestionCard(String item, UserInformation userInfoProvider) {
    return InkWell(
      key: ValueKey('suggestion-$item'),
      onTap: () {
        final index = suggestionPool.indexOf(item);
        addItem(
          item,
          selectionSource: _limitsToOneCustomItem
              ? dreamsAndGoalsCatalogueSelectionSourceForIndex(index)
              : null,
        );
        unawaited(createSelection(userInfoProvider));
      },
      child: DottedBorder(
        options: RoundedRectDottedBorderOptions(
          radius: const Radius.circular(16),
          dashPattern: const [6, 6],
          color: AppColors.suggestionCardOutline,
          strokeWidth: 1,
        ),
        child: Container(
          alignment: AlignmentDirectional.centerStart,
          width: double.infinity,
          //Figma: the card's text is inset 10 on every side.
          padding: const EdgeInsetsDirectional.symmetric(
            horizontal: 10,
            vertical: 10,
          ),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [
              BoxShadow(
                color: Color(0x7AF1EDEA),
                offset: Offset(0, 3),
                blurRadius: 11,
              ),
            ],
          ),
          child: Text(
            item,
            style: TextStyle(
              fontFamily: "Rubix",
              fontSize: 14.sp,
              fontWeight: AppFontWeight.regular,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Future<void> onPrimaryAction() async {
    final userInfoProvider = Provider.of<UserInformation>(
      context,
      listen: false,
    );
    AnalyticsService mixPanelService = GetIt.instance<AnalyticsService>();
    mixPanelService.trackEvent("Plan edited", {'page': widget.collectionName});
    // Saved before moving on, so the step cannot be left behind with its
    // answers still in flight.
    await createSelection(userInfoProvider);
    widget.next();
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
