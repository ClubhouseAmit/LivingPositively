part of 'mood_medicine_page.dart';

Widget buildMoodMedicineInsights(
  _MoodMedicinePageState state,
  AppLocalizations l10n,
  MoodMedicineReadyState ready,
) {
  final BuildContext context = state.context;
  final MoodMedicineViewModel viewModel = state._viewModel;
  final MoodMedicineDashboard dashboard = ready.dashboard;
  final ThemeData theme = Theme.of(context);
  final Color activityFallback = theme.colorScheme.tertiary;
  final MoodMedicineTrendSeries trendSeries = dashboard.trendSeries;
  final List<MoodMedicineTrendCheckIn> checkIns = trendSeries.checkIns;
  final List<MoodMedicineTrendPoint> points = checkIns
      .map(
        (MoodMedicineTrendCheckIn item) => MoodMedicineTrendPoint(
          label: item.localDayKey,
          mood: item.mood.toDouble(),
          activityIds: item.activityIds,
        ),
      )
      .toList(growable: false);
  final List<String> overlayActivityIds = checkIns
      .expand((MoodMedicineTrendCheckIn item) => item.activityIds)
      .toSet()
      .toList(growable: false);
  return ListView(
    key: const Key('moodMedicineInsights'),
    padding: const EdgeInsets.fromLTRB(
      AppSpacing.xl,
      AppSpacing.md,
      AppSpacing.xl,
      AppSpacing.xxxl,
    ),
    children: <Widget>[
      _PageHeading(
        title: l10n.moodMedicineInsights,
        subtitle: l10n.moodMedicineSubtitle,
        trailing: IconButton(
          tooltip: l10n.moodMedicineQuickCheckIn,
          onPressed: () =>
              viewModel.selectView(MoodMedicineInitialView.checkIn),
          icon: const Icon(Icons.add_chart_rounded),
        ),
      ),
      const SizedBox(height: AppSpacing.md),
      Wrap(
        spacing: AppSpacing.sm,
        runSpacing: AppSpacing.sm,
        children: MoodMedicineInsightRange.values
            .map(
              (MoodMedicineInsightRange range) => ChoiceChip(
                label: Text(state._rangeLabel(l10n, range)),
                selected: ready.selectedRange == range,
                onSelected: (_) => viewModel.selectRange(range),
              ),
            )
            .toList(growable: false),
      ),
      const SizedBox(height: AppSpacing.md),
      _FeatureCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              l10n.moodMedicineTrend,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(l10n.moodMedicineEachCheckIn),
            const SizedBox(height: AppSpacing.sm),
            MoodMedicineTrendChart(
              points: points,
              emptyLabel: l10n.moodMedicineNoEntries,
              semanticSummary: l10n.moodMedicineTrendSummary(
                state._rangeLabel(l10n, ready.selectedRange),
                state._trendSummary(l10n, trendSeries),
              ),
              activityColors: MoodMedicineContent.activityColors,
              fallbackActivityColor: activityFallback,
              highlightedActivityId: ready.highlightedActivityId,
            ),
            if (points.length == 1)
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.sm),
                child: Text(l10n.moodMedicineOneEntry),
              ),
            if (trendSeries.omittedCount > 0)
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.sm),
                child: Text(
                  l10n.moodMedicineTrendOmitted(
                    MoodMedicineInsights.maxYearTrendPoints,
                    trendSeries.omittedCount,
                  ),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            if (points.isNotEmpty) ...<Widget>[
              const SizedBox(height: AppSpacing.sm),
              Text(
                l10n.moodMedicineActivitiesOverlay,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: overlayActivityIds
                    .map((String activityId) {
                      final Color activityColor =
                          MoodMedicineContent.resolveActivityColor(
                            activityId,
                            palette: MoodMedicineContent.activityColors,
                            fallback: activityFallback,
                          );
                      return ChoiceChip(
                        key: Key('moodMedicineOverlay$activityId'),
                        selected: ready.highlightedActivityId == activityId,
                        backgroundColor: activityColor.withValues(
                          alpha: theme.brightness == Brightness.dark
                              ? 0.24
                              : 0.12,
                        ),
                        selectedColor: activityColor.withValues(
                          alpha: theme.brightness == Brightness.dark
                              ? 0.42
                              : 0.24,
                        ),
                        avatar: ExcludeSemantics(
                          child: _ActivityColorSwatch(color: activityColor),
                        ),
                        label: Text(
                          dashboard.activityLabelForRange(activityId),
                        ),
                        onSelected: (bool selected) =>
                            viewModel.setHighlightedActivity(
                              selected ? activityId : null,
                            ),
                      );
                    })
                    .toList(growable: false),
              ),
            ],
          ],
        ),
      ),
      const SizedBox(height: AppSpacing.md),
      _FeatureCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              l10n.moodMedicineAssociation,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(l10n.moodMedicineAssociationExplanation),
            const SizedBox(height: AppSpacing.md),
            if (dashboard.associations.isEmpty)
              Text(l10n.moodMedicineAssociationUnavailable)
            else
              ...dashboard.associations.map(
                (MoodMedicineAssociation association) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: Semantics(
                    label: l10n.moodMedicineAssociationSummary(
                      dashboard.activityLabelForRange(association.activityId),
                      association.withActivityAverageMood.toStringAsFixed(1),
                      association.withoutActivityAverageMood.toStringAsFixed(
                        1,
                      ),
                    ),
                    child: ExcludeSemantics(
                      child: Text(
                        l10n.moodMedicineAssociationSummary(
                          dashboard.activityLabelForRange(
                            association.activityId,
                          ),
                          association.withActivityAverageMood.toStringAsFixed(
                            1,
                          ),
                          association.withoutActivityAverageMood
                              .toStringAsFixed(1),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            Text(
              l10n.moodMedicineAssociationNotCausation,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
      const SizedBox(height: AppSpacing.md),
      Wrap(
        spacing: AppSpacing.md,
        runSpacing: AppSpacing.md,
        children: <Widget>[
          FilledButton.icon(
            key: const Key('moodMedicineManualCheckIn'),
            onPressed: () =>
                viewModel.selectView(MoodMedicineInitialView.checkIn),
            icon: const Icon(Icons.add),
            label: Text(l10n.moodMedicineQuickCheckIn),
          ),
          OutlinedButton.icon(
            key: const Key('moodMedicineExportButton'),
            onPressed: ready.writesBlocked || ready.export.isWorking
                ? null
                : state._showExportSheet,
            icon: const Icon(Icons.ios_share_outlined),
            label: Text(l10n.moodMedicineExport),
          ),
          TextButton.icon(
            key: const Key('moodMedicineEducationButton'),
            onPressed: () =>
                viewModel.selectView(MoodMedicineInitialView.education),
            icon: const Icon(Icons.menu_book_outlined),
            label: Text(l10n.moodMedicineEducation),
          ),
        ],
      ),
    ],
  );
}
