part of 'package:mazilon/pages/mood_medicine_page.dart';

Future<void> buildMoodMedicineActivityManager(
  _MoodMedicinePageState state,
) async {
  final BuildContext context = state.context;
  final MoodMedicineViewModel viewModel = state._viewModel;
  final AppLocalizations l10n = AppLocalizations.of(context)!;
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (BuildContext sheetContext) =>
        ChangeNotifierProvider<MoodMedicineViewModel>.value(
          value: viewModel,
          child: DraggableScrollableSheet(
            expand: false,
            initialChildSize: 0.72,
            maxChildSize: 0.92,
            builder:
                (
                  BuildContext context,
                  ScrollController scrollController,
                ) => Consumer<MoodMedicineViewModel>(
                  builder: (_, MoodMedicineViewModel viewModel, _) {
                    final MoodMedicineReadyState? ready = viewModel.readyState;
                    if (ready == null) {
                      return const SizedBox.shrink();
                    }
                    final List<MoodMedicineActivityContent> defaults = state
                        ._activities(l10n);
                    final List<MoodMedicineActivityContent> hidden = defaults
                        .where(
                          (MoodMedicineActivityContent item) => ready
                              .snapshot
                              .hiddenDefaultActivityIds
                              .contains(item.id),
                        )
                        .toList(growable: false);
                    final List<MoodMedicineActivityContent> visible = defaults
                        .where(
                          (MoodMedicineActivityContent item) => !ready
                              .snapshot
                              .hiddenDefaultActivityIds
                              .contains(item.id),
                        )
                        .toList(growable: false);
                    return SafeArea(
                      child: ListView(
                        controller: scrollController,
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.xl,
                          AppSpacing.md,
                          AppSpacing.xl,
                          AppSpacing.xxxl,
                        ),
                        children: <Widget>[
                          Center(
                            child: Container(
                              width: 38,
                              height: 4,
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.outline,
                                borderRadius: BorderRadius.circular(
                                  AppSpacing.xs,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          Text(
                            l10n.moodMedicineManageActivities,
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Text(l10n.moodMedicineActivityHistoryNote),
                          const SizedBox(height: AppSpacing.lg),
                          _ManagerSection(
                            title: l10n.moodMedicineDefaultActivities,
                            children: visible
                                .map(
                                  (MoodMedicineActivityContent item) =>
                                      ListTile(
                                        leading: Icon(item.icon),
                                        title: Text(item.label),
                                        trailing: GestureDetector(
                                          onTap: ready.writesBlocked
                                              ? null
                                              : () => viewModel
                                                    .hideDefaultActivity(
                                                      item.id,
                                                    ),
                                          child: Text(l10n.moodMedicineHide),
                                        ),
                                      ),
                                )
                                .toList(growable: false),
                          ),
                          if (hidden.isNotEmpty) ...<Widget>[
                            const SizedBox(height: AppSpacing.md),
                            _ManagerSection(
                              title: l10n.moodMedicineHiddenActivities,
                              children: hidden
                                  .map(
                                    (MoodMedicineActivityContent item) =>
                                        ListTile(
                                          leading: Icon(item.icon),
                                          title: Text(item.label),
                                          trailing: GestureDetector(
                                            onTap: ready.writesBlocked
                                                ? null
                                                : () => viewModel
                                                      .restoreDefaultActivity(
                                                        item.id,
                                                      ),
                                            child: Text(
                                              l10n.moodMedicineRestore,
                                            ),
                                          ),
                                        ),
                                  )
                                  .toList(growable: false),
                            ),
                          ],
                          const SizedBox(height: AppSpacing.md),
                          _ManagerSection(
                            title: l10n.moodMedicineCustomActivities,
                            children: <Widget>[
                              if (ready.snapshot.customActivities.isEmpty)
                                Padding(
                                  padding: const EdgeInsets.all(
                                    AppSpacing.lg,
                                  ),
                                  child: Text(
                                    l10n.moodMedicineNoCustomActivities,
                                  ),
                                ),
                              ...ready.snapshot.customActivities.map(
                                (
                                  MoodMedicineCustomActivity activity,
                                ) => ListTile(
                                  leading: const Icon(Icons.favorite_outline),
                                  title: Text(activity.label),
                                  trailing: Wrap(
                                    spacing: AppSpacing.xs,
                                    children: <Widget>[
                                      IconButton(
                                        tooltip: l10n.moodMedicineEdit,
                                        onPressed: ready.writesBlocked
                                            ? null
                                            : () => state._showActivityEditor(
                                                activity: activity,
                                              ),
                                        icon: const Icon(Icons.edit_outlined),
                                      ),
                                      IconButton(
                                        tooltip: l10n.moodMedicineDelete,
                                        onPressed: ready.writesBlocked
                                            ? null
                                            : () =>
                                                  state._confirmDeleteActivity(
                                                    activity,
                                                  ),
                                        icon: const Icon(
                                          Icons.delete_outline,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              Align(
                                alignment: AlignmentDirectional.centerStart,
                                child: FilledButton.icon(
                                  onPressed: ready.writesBlocked
                                      ? null
                                      : state._showActivityEditor,
                                  icon: const Icon(Icons.add),
                                  label: Text(
                                    l10n.moodMedicineAddCustomActivity,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
          ),
        ),
  );
}

Widget buildMoodMedicineEducation(
  _MoodMedicinePageState state,
  AppLocalizations l10n,
  MoodMedicineReadyState ready,
) {
  final BuildContext context = state.context;
  final MoodMedicineViewModel viewModel = state._viewModel;
  final List<MoodMedicineDoseContent> doseItems = MoodMedicineContent.doseItems(
    l10n,
  );
  final MoodMedicineActivityContent selfCareSource =
      MoodMedicineContent.activityFor(
        l10n,
        MoodMedicineContent.nourishingMealId,
      )!;
  return ListView(
    key: const Key('moodMedicineEducation'),
    padding: const EdgeInsets.fromLTRB(
      AppSpacing.xl,
      AppSpacing.md,
      AppSpacing.xl,
      AppSpacing.xxxl,
    ),
    children: <Widget>[
      _PageHeading(
        title: l10n.moodMedicineEducation,
        subtitle: l10n.moodMedicineNotMedicalAdvice,
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
              l10n.moodMedicineEducationDoseTitle,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(l10n.moodMedicineEducationDoseIntro),
            const SizedBox(height: AppSpacing.md),
            LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
                final bool oneColumn = constraints.maxWidth < 560;
                final double width = oneColumn
                    ? constraints.maxWidth
                    : (constraints.maxWidth - AppSpacing.sm) / 2;
                return Wrap(
                  key: const Key('moodMedicineDoseItems'),
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: doseItems
                      .map(
                        (MoodMedicineDoseContent item) => SizedBox(
                          width: width,
                          child: _MoodSurface(
                            key: Key('moodMedicineDose${item.kind.name}'),
                            color: item.color.withValues(
                              alpha:
                                  Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? 0.28
                                  : 0.14,
                            ),
                            borderColor: item.color,
                            child: Padding(
                              padding: const EdgeInsets.all(AppSpacing.md),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  ExcludeSemantics(
                                    child: DecoratedBox(
                                      decoration: BoxDecoration(
                                        color: item.color,
                                        borderRadius: BorderRadius.circular(
                                          AppRadii.card,
                                        ),
                                      ),
                                      child: const SizedBox(
                                        width: 36,
                                        height: 4,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: AppSpacing.sm),
                                  Text(
                                    item.title,
                                    style: Theme.of(
                                      context,
                                    ).textTheme.titleSmall,
                                  ),
                                  const SizedBox(height: AppSpacing.xs),
                                  Text(item.description),
                                ],
                              ),
                            ),
                          ),
                        ),
                      )
                      .toList(growable: false),
                );
              },
            ),
            const SizedBox(height: AppSpacing.md),
            TextButton.icon(
              key: const Key('moodMedicineEducationSource'),
              onPressed: () =>
                  viewModel.openEducationSource(selfCareSource.sourceUri),
              icon: const Icon(Icons.open_in_new),
              label: Text(
                '${l10n.moodMedicineOpenSource}: '
                '${selfCareSource.sourceLabel}',
              ),
            ),
            Text(
              l10n.moodMedicineEducationDisclaimer,
              style: Theme.of(context).textTheme.bodySmall,
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
              l10n.moodMedicineVideoTitle,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.md),
            AspectRatio(
              aspectRatio: 16 / 9,
              child: _MoodSurface(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        const Icon(Icons.play_circle_outline, size: 42),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          l10n.moodMedicineVideoPlaceholder,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ],
  );
}
