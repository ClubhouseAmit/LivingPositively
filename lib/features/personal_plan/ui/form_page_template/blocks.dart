part of 'form_page_template.dart';

mixin _FormPageBlocks on _FormPagePersist {
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

  Widget _buildAddOwnItem(UserInformation userInfoProvider, String gender) {
    return Align(
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
                  unawaited(_saveSelectionAfterMutation(userInfoProvider));
                },
                text: '',
              );
            },
          );
        },
        Icons.add,
        _tracksDreamsAndGoalsSelectionSources
            ? appLocale.dreamsAndGoalsAddOwn(gender)
            : appLocale.addFormPageTemplateAddOwn(gender),
        Theme.of(context).colorScheme.primary,
        designFontSize: 12,
        iconSize: 12,
      ),
    );
  }

  /// Figma "Frame 216" — the answered-item rows ("Frame 215") and the
  /// inline "add your own" link ("Frame 171"). Dreams and Goals places the
  /// link before its selected rows so it stays available as selections grow;
  /// the other wizard sections retain the existing rows-then-link layout.
  Widget _buildItemsBlock(UserInformation userInfoProvider, String gender) {
    final addOwnItem = _buildAddOwnItem(userInfoProvider, gender);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      // The design spaces the rows and the "add your own" link uniformly, so
      // one `spacing` covers both — no trailing-item special case.
      spacing: _gapWithinBlock,
      children: [
        if (_tracksDreamsAndGoalsSelectionSources) addOwnItem,
        // Frame 215 — a plain Column, not a shrink-wrapped ListView: the list
        // never scrolls on its own, and a ListView would silently inherit
        // MediaQuery.padding as sliver padding.
        for (final (index, item) in selectedItems.indexed)
          FormAnswer(
            key: ValueKey('answer-${rowIds[index]}'),
            text: item,
            num: index + 1,
            edit: (int editIndex, String text) {
              editItem(editIndex, text);
              unawaited(_saveSelectionAfterMutation(userInfoProvider));
            },
            remove: (int removeIndex) {
              removeItem(removeIndex);
              unawaited(_saveSelectionAfterMutation(userInfoProvider));
            },
          ),
        if (!_tracksDreamsAndGoalsSelectionSources) addOwnItem,
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
          selectionSource: _tracksDreamsAndGoalsSelectionSources
              ? dreamsAndGoalsCatalogueSelectionSourceForIndex(index)
              : null,
        );
        unawaited(_saveSelectionAfterMutation(userInfoProvider));
      },
      child: DottedBorder(
        options: RoundedRectDottedBorderOptions(
          radius: const Radius.circular(AppRadii.card),
          dashPattern: const [6, 6],
          color: AppColors.suggestionCardOutline,
          strokeWidth: 1,
        ),
        child: Container(
          alignment: AlignmentDirectional.centerStart,
          width: double.infinity,
          //Figma: the card's text is inset 10 on every side.
          padding: const EdgeInsetsDirectional.symmetric(
            horizontal: _suggestionInset,
            vertical: _suggestionInset,
          ),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(AppRadii.card),
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
}
