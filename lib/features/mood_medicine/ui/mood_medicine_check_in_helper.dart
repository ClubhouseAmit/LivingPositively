part of 'mood_medicine_page.dart';

Widget buildMoodMedicineCheckIn(
  _MoodMedicinePageState state,
  AppLocalizations l10n,
  MoodMedicineReadyState ready,
) {
  final BuildContext context = state.context;
  final MoodMedicineViewModel viewModel = state._viewModel;
  final MoodMedicineCheckInForm form = ready.checkInForm;
  final ThemeData theme = Theme.of(context);
  final List<_ActivityChip> activityChips = <_ActivityChip>[
    ...state
        ._activities(l10n)
        .where(
          (MoodMedicineActivityContent activity) =>
              !ready.snapshot.hiddenDefaultActivityIds.contains(activity.id),
        )
        .map(
          (MoodMedicineActivityContent activity) => _ActivityChip(
            id: activity.id,
            label: activity.label,
            icon: activity.icon,
            color: activity.color,
            source: activity,
          ),
        ),
    ...ready.snapshot.customActivities.map(
      (MoodMedicineCustomActivity activity) => _ActivityChip(
        id: activity.id,
        label: activity.label,
        icon: Icons.favorite_outline,
      ),
    ),
  ];
  return ListView(
    key: const Key('moodMedicineCheckIn'),
    padding: const EdgeInsets.fromLTRB(
      AppSpacing.xl,
      AppSpacing.md,
      AppSpacing.xl,
      AppSpacing.xxxl,
    ),
    children: <Widget>[
      _PageHeading(
        title: l10n.moodMedicineCheckIn,
        subtitle: l10n.moodMedicineHowFeel,
        trailing: IconButton(
          tooltip: l10n.moodMedicineViewInsights,
          onPressed: () =>
              viewModel.selectView(MoodMedicineInitialView.insights),
          icon: const Icon(Icons.insights_outlined),
        ),
      ),
      const SizedBox(height: AppSpacing.lg),
      _FeatureCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              l10n.moodMedicineChooseMood,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              alignment: WrapAlignment.spaceBetween,
              children: state
                  ._moodOptions(l10n)
                  .map(
                    (_MoodOption option) => Semantics(
                      button: true,
                      selected: form.mood == option.value,
                      label: option.label,
                      child: ChoiceChip(
                        key: Key('moodMedicineMood${option.value}'),
                        selected: form.mood == option.value,
                        onSelected: ready.writesBlocked
                            ? null
                            : (_) => viewModel.selectMood(option.value),
                        avatar: Icon(option.icon),
                        label: Text(option.label),
                      ),
                    ),
                  )
                  .toList(growable: false),
            ),
          ],
        ),
      ),
      if (ready.isCheckInDetailsExpanded) ...<Widget>[
        const SizedBox(height: AppSpacing.md),
        _FeatureCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                l10n.moodMedicineEmotions,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(l10n.moodMedicineEmotionsHint),
              const SizedBox(height: AppSpacing.md),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: state
                    ._emotionLabels(l10n)
                    .entries
                    .map(
                      (MapEntry<String, String> item) => FilterChip(
                        key: Key('moodMedicineEmotion${item.key}'),
                        selected: form.emotionIds.contains(item.key),
                        onSelected: ready.writesBlocked
                            ? null
                            : (_) => viewModel.toggleEmotion(item.key),
                        label: Text(item.value),
                      ),
                    )
                    .toList(growable: false),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        _FeatureCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      l10n.moodMedicineActivities,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  TextButton(
                    onPressed: ready.writesBlocked
                        ? null
                        : state._openActivityManager,
                    child: Text(l10n.moodMedicineManageActivities),
                  ),
                ],
              ),
              Text(l10n.moodMedicineActivitiesHint),
              const SizedBox(height: AppSpacing.md),
              if (activityChips.isEmpty)
                Text(l10n.moodMedicineNoActivitiesSelected)
              else
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: activityChips
                      .map(
                        (_ActivityChip item) => FilterChip(
                          key: Key('moodMedicineActivity${item.id}'),
                          selected: form.activityIds.contains(item.id),
                          onSelected: ready.writesBlocked
                              ? null
                              : (_) => viewModel.toggleActivity(item.id),
                          backgroundColor: item.color?.withValues(
                            alpha: theme.brightness == Brightness.dark
                                ? 0.24
                                : 0.12,
                          ),
                          selectedColor: item.color?.withValues(
                            alpha: theme.brightness == Brightness.dark
                                ? 0.42
                                : 0.24,
                          ),
                          avatar: Icon(
                            item.icon,
                            size: 18,
                            color:
                                item.color ??
                                theme.colorScheme.onSurfaceVariant,
                          ),
                          label: Text(item.label),
                          deleteIcon: item.source == null
                              ? null
                              : const Icon(Icons.info_outline, size: 18),
                          onDeleted: item.source == null
                              ? null
                              : () =>
                                    state._openActivityEducation(item.source!),
                        ),
                      )
                      .toList(growable: false),
                ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        _FeatureCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                l10n.moodMedicineOptionalNote,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: AppSpacing.sm),
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: formFieldWidth(context),
                  ),
                  child: TextField(
                    key: const Key('moodMedicineNoteField'),
                    controller: state._noteController,
                    enabled: !ready.writesBlocked,
                    minLines: 3,
                    maxLines: 6,
                    textCapitalization: TextCapitalization.sentences,
                    onChanged: viewModel.setJournalNote,
                    decoration: InputDecoration(
                      hintText: l10n.moodMedicineNoteHint,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                l10n.moodMedicineNotePrivacy,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        FilledButton.icon(
          key: const Key('moodMedicineSaveCheckIn'),
          onPressed: ready.writesBlocked || !form.canSave
              ? null
              : () => viewModel.saveCheckIn(),
          icon: ready.persistence.isSaving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.check),
          label: Text(
            ready.persistence.isSaving
                ? l10n.moodMedicineSaving
                : l10n.moodMedicineSave,
          ),
        ),
      ] else ...<Widget>[
        const SizedBox(height: AppSpacing.lg),
        FilledButton(
          key: const Key('moodMedicineContinueCheckIn'),
          onPressed: form.canSave
              ? () => viewModel.setCheckInDetailsExpanded(true)
              : null,
          child: Text(l10n.moodMedicineContinue),
        ),
      ],
    ],
  );
}
