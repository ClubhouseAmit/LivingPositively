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

import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:mazilon/util/userInformation.dart';
import 'package:provider/provider.dart';
import 'package:mazilon/util/Form/retrieveInformation.dart';

/// Spacing scale for the shared onboarding template, read off the Figma
/// frames' own container boxes (`Android Large - 10/15`, frames "Frame 210"
/// title block, "Frame 216" items block, "Frame 223" suggestions block).
/// The widget tree below mirrors that container hierarchy one-for-one, so
/// every gap here is the distance between two named design containers
/// rather than a hand-tuned number.
const double _gapLabelToCaption = 4; // section heading <-> its caption
const double _gapWithinGroup =
    8; // card <-> card, cards <-> "other suggestions"
const double _gapWithinBlock =
    16; // title <-> subtitle, row <-> row, rows <-> "add your own"
const double _gapBetweenBlocks =
    16; // title block <-> items block <-> suggestions block

class FormPageTemplate extends WizardStep {
  //next page:
  final Function next;
  //prev page:
  final Function prev;

  final String collectionName;

  const FormPageTemplate({
    required super.key,
    required this.next,
    required this.prev,
    required this.collectionName,
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
  @override
  void initState() {
    super.initState();
    if (widget.collectionName == 'PersonalPlan-SafeEnvironment') {
      displayedLength = 4;
    }
  }

  /// How much of the pool a tap on "other suggestions" uncovers, and how much
  /// a used-up batch is replaced by.
  static const int _suggestionBatch = 3;

  /// How far into the pool the suggestions section currently reaches.
  ///
  /// It starts at [displayedLength] and skips forward over batches the user
  /// has already picked clean, so selecting the last remaining card brings up
  /// the next batch instead of leaving an empty section. Derived on every
  /// build rather than stored, because a step also reopens with items the
  /// user selected on an earlier visit.
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
    return selectedItems.contains(item);
  }

  void editItem(int index, String text) {
    selectedItems[index] = text;
    setState(() {});
  }

  void removeItem(int index) {
    final text = selectedItems[index];
    selectedItems.removeWhere((element) => element == text);

    setState(() {});
  }

  void addItem(String text) {
    selectedItems.add(text.trim());

    setState(() {});
  }

  //uncover the next batch of suggestions from the database list at the bottom
  //of the screen. Counts from what is actually on screen, so it never re-shows
  //a batch the auto-refill already stepped past.
  void addSuggestion() {
    setState(() {
      displayedLength = (revealedSuggestions + _suggestionBatch).clamp(
        0,
        suggestionPool.length,
      );
    });
  }

  void createSelection(userInfo) async {
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
      default:
    }
    await service.setItem(
      "disclaimerConfirmed",
      PersistentMemoryType.Bool,
      true,
    );
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
      default:
    }
  }

  /// Figma "Frame 210" — page title + subtitle, both full width, centred.
  Widget _buildTitleBlock(Map<String, dynamic> displayInformation) {
    return Column(
      spacing: _gapWithinBlock,
      children: [
        myAutoSizedText(
          displayInformation['header'],
          TextStyle(
            fontWeight: AppFontWeight.medium,
            fontSize: 24.sp,
            color: Theme.of(context).colorScheme.onSurface,
          ),
          TextAlign.center,
          24,
        ),
        myAutoSizedText(
          displayInformation['subTitle'],
          TextStyle(
            fontWeight: AppFontWeight.regular,
            color: Theme.of(context).colorScheme.outline,
            fontSize: 16.sp,
          ),
          TextAlign.center,
          16,
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
            text: item,
            num: index + 1,
            edit: (int editIndex, String text) {
              editItem(editIndex, text);
              createSelection(userInfoProvider);
            },
            remove: (int removeIndex) {
              removeItem(removeIndex);
              createSelection(userInfoProvider);
            },
          ),
        //Frame 171 — start-aligned, not centred.
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
                      addItem(text);
                      createSelection(userInfoProvider);
                    },
                    text: '',
                  );
                },
              );
            },
            Icons.add,
            appLocale.addFormPageTemplateAddOwn(gender),
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
            myAutoSizedText(
              displayInformation['midTitle'],
              TextStyle(
                fontWeight: AppFontWeight.semiBold,
                fontSize: 14.sp,
                color: Theme.of(context).colorScheme.onSurface,
              ),
              TextAlign.center,
              14,
            ),
            myAutoSizedText(
              displayInformation['midSubTitle'],
              TextStyle(
                fontWeight: AppFontWeight.regular,
                color: Theme.of(context).colorScheme.outline,
                fontSize: 12.sp,
              ),
              TextAlign.center,
              12,
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
            //Frame 219 — centred. Offered only while the pool still holds
            //suggestions the user hasn't been shown.
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
        setState(() {
          addItem(item);
          createSelection(userInfoProvider);
        });
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
              fontSize: 16.sp,
              fontWeight: AppFontWeight.regular,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ),
      ),
    );
  }

  @override
  void onPrimaryAction() {
    final userInfoProvider = Provider.of<UserInformation>(
      context,
      listen: false,
    );
    AnalyticsService mixPanelService = GetIt.instance<AnalyticsService>();
    mixPanelService.trackEvent("Plan edited", {'page': widget.collectionName});
    createSelection(userInfoProvider);
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
    //suggestions still available to pick — a suggestion drops out of this
    //pool as soon as it's selected (it's promoted to the answered list above),
    //and `revealedSuggestions` pulls in the next batch once a batch runs dry.
    final availableSuggestions = suggestionPool
        .take(revealedSuggestions)
        .where((item) => !isAlreadySelected(item))
        .toList();

    //Mirrors the Figma frame: a stack of blocks that flows from the top. The
    //continue button ("Group 86") is not here — WizardStepPage pins it below
    //this content, at the same y on every step.
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: _gapBetweenBlocks,
        children: [
          _buildTitleBlock(displayInformation),
          _buildItemsBlock(userInfoProvider, gender),
          //Once the user has picked the pool clean there is nothing left to
          //suggest, so the whole block goes rather than leaving its heading
          //standing over an empty space.
          if (availableSuggestions.isNotEmpty ||
              revealedSuggestions < suggestionPool.length)
            _buildSuggestionsBlock(
              displayInformation,
              availableSuggestions,
              userInfoProvider,
            ),
        ],
      ),
    );
  }
}
