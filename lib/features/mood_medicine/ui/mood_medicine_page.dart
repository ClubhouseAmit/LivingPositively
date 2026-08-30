import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart' as intl;
import 'package:mazilon/l10n/app_localizations.dart';
import 'package:mazilon/features/mood_medicine/data/mood_medicine_models.dart';
import 'package:mazilon/features/mood_medicine/data/mood_medicine_report_delivery_types.dart';
import 'package:mazilon/features/mood_medicine/data/mood_medicine_report_models.dart';
import 'package:mazilon/features/mood_medicine/ui/mood_medicine_content.dart';
import 'package:mazilon/features/mood_medicine/ui/mood_medicine_insights.dart';
import 'package:mazilon/features/mood_medicine/ui/mood_medicine_report_preview.dart';
import 'package:mazilon/features/mood_medicine/ui/mood_medicine_trend_chart.dart';
import 'package:mazilon/features/mood_medicine/ui/mood_medicine_view_model.dart';
import 'package:mazilon/features/mood_medicine/ui/mood_medicine_view_state.dart';
import 'package:mazilon/util/async/persistence_retry_snack_bar.dart';
import 'package:mazilon/util/styles.dart';
import 'package:mazilon/util/theme/app_theme.dart';
import 'package:mazilon/util/theme/spacing.dart';
import 'package:provider/provider.dart';

/// Device-local mood check-ins, education, and insights.
///
/// The page renders [MoodMedicineViewModel] state only. Storage, drafts,
/// aggregation, historical labels, report inputs, retries, and export state
/// remain inside the feature-local view model.
class MoodMedicinePage extends StatefulWidget {
  const MoodMedicinePage({
    super.key,
    required this.viewModel,
    this.initialView = MoodMedicineInitialView.insights,
  });

  /// Fresh factory-scoped view model composed by Menu or a focused test.
  final MoodMedicineViewModel viewModel;

  /// Feature surface selected after snapshot loading finishes.
  final MoodMedicineInitialView initialView;

  @override
  State<MoodMedicinePage> createState() => _MoodMedicinePageState();
}

class _MoodMedicinePageState extends State<MoodMedicinePage> {
  final TextEditingController _noteController = TextEditingController();
  late final StreamSubscription<MoodMedicineUiEffect> _effectSubscription;
  Locale? _presentationLocale;

  MoodMedicineViewModel get _viewModel => widget.viewModel;

  @override
  void initState() {
    super.initState();
    _effectSubscription = _viewModel.effects.listen(_handleEffect);
    if (_viewModel.state is MoodMedicineLoadingState) {
      unawaited(_loadInitialState());
    } else {
      _viewModel.selectView(widget.initialView);
    }
  }

  Future<void> _loadInitialState() async {
    await _viewModel.load(initialView: widget.initialView);
    _applyReportPresentationIfReady();
  }

  void _applyReportPresentationIfReady() {
    if (!mounted || _viewModel.readyState == null) {
      return;
    }
    _viewModel.setReportPresentation(
      _reportPresentation(AppLocalizations.of(context)!),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final Locale locale = Localizations.localeOf(context);
    if (_presentationLocale == locale) {
      return;
    }
    _presentationLocale = locale;
    WidgetsBinding.instance.addPostFrameCallback((Duration _) {
      if (mounted && _presentationLocale == locale) {
        _applyReportPresentationIfReady();
      }
    });
  }

  @override
  void dispose() {
    _effectSubscription.cancel();
    _noteController.dispose();
    _viewModel.dispose();
    super.dispose();
  }

  void _handleEffect(MoodMedicineUiEffect effect) {
    if (!mounted) {
      return;
    }
    switch (effect) {
      case MoodMedicineCheckInSavedEffect():
        _noteController.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!.moodMedicineCheckInSaved,
            ),
          ),
        );
      case MoodMedicinePersistenceFailedEffect(:final canRetry):
        _showWriteFailure(canRetry: canRetry);
      case MoodMedicineSourceOpenFailedEffect():
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.asyncErrorMessage),
          ),
        );
      case MoodMedicineReportDeliveryEffect(:final delivery):
        if (!delivery.didDeliver &&
            delivery.status != MoodMedicineReportDeliveryStatus.dismissed) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                AppLocalizations.of(context)!.moodMedicineExportError,
              ),
            ),
          );
        }
      case MoodMedicineReportReadyEffect():
        // The export sheet explicitly decides whether to view or share it.
        break;
    }
  }

  void _showWriteFailure({required bool canRetry}) {
    if (!mounted) {
      return;
    }
    if (!canRetry) {
      final ScaffoldMessengerState? messenger = ScaffoldMessenger.maybeOf(
        context,
      );
      final AppLocalizations? l10n = AppLocalizations.of(context);
      if (messenger == null || l10n == null) {
        return;
      }
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(l10n.asyncErrorMessage)));
      return;
    }
    showPersistenceRetrySnackBar(context, () async {
      final bool saved = await _viewModel.retryLastWrite();
      if (!saved &&
          mounted &&
          _viewModel.readyState?.persistence.hasPendingWrite == true) {
        _showWriteFailure(canRetry: true);
      }
    });
  }

  Future<void> _retryLoad() async {
    await _viewModel.retryLoad();
    _applyReportPresentationIfReady();
  }

  String _reportBuildFailureMessage(
    AppLocalizations l10n,
    MoodMedicineViewModel viewModel, {
    required bool preview,
  }) {
    if (viewModel.readyState?.export.buildFailureKind ==
        MoodMedicineReportBuildFailureKind.pngTooLarge) {
      return l10n.moodMedicinePngTooLarge;
    }
    return preview
        ? l10n.moodMedicinePreviewError
        : l10n.moodMedicineExportError;
  }

  List<MoodMedicineActivityContent> _activities(AppLocalizations l10n) =>
      MoodMedicineContent.activities(l10n);

  MoodMedicineReportPresentation _reportPresentation(AppLocalizations l10n) {
    final List<MoodMedicineActivityContent> activities = _activities(l10n);
    final Map<String, MoodMedicineReportSource> sources =
        <String, MoodMedicineReportSource>{
          for (final MoodMedicineActivityContent activity in activities)
            activity.sourceUri.toString(): MoodMedicineReportSource(
              title: activity.sourceLabel,
              url: activity.sourceUri,
            ),
        };
    return MoodMedicineReportPresentation(
      title: l10n.moodMedicineExportReportTitle,
      rangeLabels: _rangeLabels(l10n),
      labels: MoodMedicineReportLabels(
        moodLabel: l10n.moodMedicineTrend,
        activitiesLabel: l10n.moodMedicineActivities,
        associationsLabel: l10n.moodMedicineAssociation,
        notesLabel: l10n.moodMedicineIncludeNotes,
        sourcesLabel: l10n.moodMedicineExportSources,
        noDataLabel: l10n.moodMedicineNoEntries,
        withActivityLabel: l10n.moodMedicineWithActivity,
        withoutActivityLabel: l10n.moodMedicineWithoutActivity,
        associationDisclaimer: l10n.moodMedicineAssociationNotCausation,
      ),
      defaultActivityLabels: <String, String>{
        for (final MoodMedicineActivityContent activity in activities)
          activity.id: activity.label,
      },
      sources: sources.values.toList(growable: false),
      textDirection: Directionality.of(context),
      dayLabelFor: (String key) => key,
    );
  }

  Map<String, String> _emotionLabels(AppLocalizations l10n) => <String, String>{
    'calm': l10n.moodMedicineEmotionCalm,
    'sad': l10n.moodMedicineEmotionSad,
    'anxious': l10n.moodMedicineEmotionAnxious,
    'irritated': l10n.moodMedicineEmotionIrritated,
    'tired': l10n.moodMedicineEmotionTired,
    'grateful': l10n.moodMedicineEmotionGrateful,
    'hopeful': l10n.moodMedicineEmotionHopeful,
    'overwhelmed': l10n.moodMedicineEmotionOverwhelmed,
    'lonely': l10n.moodMedicineEmotionLonely,
    'energized': l10n.moodMedicineEmotionEnergized,
  };

  List<_MoodOption> _moodOptions(AppLocalizations l10n) => <_MoodOption>[
    _MoodOption(
      1,
      Icons.sentiment_very_dissatisfied_rounded,
      l10n.moodMedicineMoodVeryLow,
    ),
    _MoodOption(
      2,
      Icons.sentiment_dissatisfied_rounded,
      l10n.moodMedicineMoodLow,
    ),
    _MoodOption(3, Icons.sentiment_neutral_rounded, l10n.moodMedicineMoodOkay),
    _MoodOption(
      4,
      Icons.sentiment_satisfied_rounded,
      l10n.moodMedicineMoodGood,
    ),
    _MoodOption(
      5,
      Icons.sentiment_very_satisfied_rounded,
      l10n.moodMedicineMoodVeryGood,
    ),
  ];

  Map<MoodMedicineInsightRange, String> _rangeLabels(AppLocalizations l10n) {
    return <MoodMedicineInsightRange, String>{
      MoodMedicineInsightRange.day: l10n.moodMedicineToday,
      MoodMedicineInsightRange.week: l10n.moodMedicineWeek,
      MoodMedicineInsightRange.month: l10n.moodMedicineMonth,
      MoodMedicineInsightRange.year: l10n.moodMedicineYear,
    };
  }

  String _rangeLabel(AppLocalizations l10n, MoodMedicineInsightRange range) =>
      _rangeLabels(l10n)[range]!;

  String _trendSummary(
    AppLocalizations l10n,
    MoodMedicineTrendSeries trendSeries,
  ) {
    return trendSeries.checkIns
        .map(
          (MoodMedicineTrendCheckIn checkIn) =>
              '${_formatTrendDay(l10n, checkIn.localDayKey)}: ${checkIn.mood}',
        )
        .join(', ');
  }

  /// UI-only accessibility formatting; the ViewModel keeps [dayKey] as the
  /// persisted local-day key for filtering and analytics. Parsing is local
  /// calendar arithmetic, never a UTC conversion.
  String _formatTrendDay(AppLocalizations l10n, String dayKey) {
    final List<String> parts = dayKey.split('-');
    if (parts.length != 3) {
      return dayKey;
    }
    final int? year = int.tryParse(parts[0]);
    final int? month = int.tryParse(parts[1]);
    final int? day = int.tryParse(parts[2]);
    if (year == null || month == null || day == null) {
      return dayKey;
    }
    return intl.DateFormat.yMMMMd(
      l10n.localeName,
    ).format(DateTime(year, month, day));
  }

  Future<void> _openActivityManager() async {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext sheetContext) =>
          ChangeNotifierProvider<MoodMedicineViewModel>.value(
            value: _viewModel,
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
                      final MoodMedicineReadyState? ready =
                          viewModel.readyState;
                      if (ready == null) {
                        return const SizedBox.shrink();
                      }
                      final List<MoodMedicineActivityContent> defaults =
                          _activities(l10n);
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
                          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
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
                            const SizedBox(height: 18),
                            _ManagerSection(
                              title: l10n.moodMedicineDefaultActivities,
                              children: visible
                                  .map(
                                    (MoodMedicineActivityContent item) =>
                                        ListTile(
                                          leading: Icon(item.icon),
                                          title: Text(item.label),
                                          trailing: TextButton(
                                            onPressed: ready.writesBlocked
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
                                            trailing: TextButton(
                                              onPressed: ready.writesBlocked
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
                                              : () => _showActivityEditor(
                                                  activity: activity,
                                                ),
                                          icon: const Icon(Icons.edit_outlined),
                                        ),
                                        IconButton(
                                          tooltip: l10n.moodMedicineDelete,
                                          onPressed: ready.writesBlocked
                                              ? null
                                              : () => _confirmDeleteActivity(
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
                                        : _showActivityEditor,
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

  Future<void> _showActivityEditor({MoodMedicineCustomActivity? activity}) {
    return showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) => _ActivityEditorDialog(
        activity: activity,
        l10n: AppLocalizations.of(context)!,
        viewModel: _viewModel,
      ),
    );
  }

  Future<void> _confirmDeleteActivity(
    MoodMedicineCustomActivity activity,
  ) async {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: Text(l10n.moodMedicineDeleteActivityTitle),
        content: Text(l10n.moodMedicineDeleteActivityBody),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.moodMedicineCancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(dialogContext).colorScheme.error,
              foregroundColor: Theme.of(dialogContext).colorScheme.onError,
            ),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.moodMedicineDeleteActivityConfirm),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await _viewModel.deleteCustomActivity(activity.id);
    }
  }

  Future<void> _openActivityEducation(
    MoodMedicineActivityContent activity,
  ) async {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    await showModalBottomSheet<void>(
      context: context,
      builder: (BuildContext sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xxl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Icon(activity.icon),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text(
                      activity.label,
                      style: Theme.of(sheetContext).textTheme.titleLarge,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(activity.description),
              const SizedBox(height: AppSpacing.md),
              Text(activity.guidance),
              const SizedBox(height: 14),
              TextButton.icon(
                key: Key('moodMedicineActivitySource${activity.id}'),
                onPressed: () =>
                    _viewModel.openEducationSource(activity.sourceUri),
                icon: const Icon(Icons.open_in_new),
                label: Text(
                  '${l10n.moodMedicineOpenSource}: ${activity.sourceLabel}',
                ),
              ),
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: TextButton(
                  onPressed: () => Navigator.of(sheetContext).pop(),
                  child: Text(l10n.moodMedicineClose),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCheckIn(AppLocalizations l10n, MoodMedicineReadyState ready) {
    final MoodMedicineCheckInForm form = ready.checkInForm;
    final List<_ActivityChip> activityChips = <_ActivityChip>[
      ..._activities(l10n)
          .where(
            (MoodMedicineActivityContent activity) =>
                !ready.snapshot.hiddenDefaultActivityIds.contains(activity.id),
          )
          .map(
            (MoodMedicineActivityContent activity) => _ActivityChip(
              id: activity.id,
              label: activity.label,
              icon: activity.icon,
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
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      children: <Widget>[
        _PageHeading(
          title: l10n.moodMedicineCheckIn,
          subtitle: l10n.moodMedicineHowFeel,
          trailing: IconButton(
            tooltip: l10n.moodMedicineViewInsights,
            onPressed: () =>
                _viewModel.selectView(MoodMedicineInitialView.insights),
            icon: const Icon(Icons.insights_outlined),
          ),
        ),
        const SizedBox(height: 18),
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
                children: _moodOptions(l10n)
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
                              : (_) => _viewModel.selectMood(option.value),
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
          const SizedBox(height: 14),
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
                  children: _emotionLabels(l10n).entries
                      .map(
                        (MapEntry<String, String> item) => FilterChip(
                          key: Key('moodMedicineEmotion${item.key}'),
                          selected: form.emotionIds.contains(item.key),
                          onSelected: ready.writesBlocked
                              ? null
                              : (_) => _viewModel.toggleEmotion(item.key),
                          label: Text(item.value),
                        ),
                      )
                      .toList(growable: false),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
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
                          : _openActivityManager,
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
                                : (_) => _viewModel.toggleActivity(item.id),
                            avatar: Icon(item.icon, size: 18),
                            label: Text(item.label),
                            deleteIcon: item.source == null
                                ? null
                                : const Icon(Icons.info_outline, size: 18),
                            onDeleted: item.source == null
                                ? null
                                : () => _openActivityEducation(item.source!),
                          ),
                        )
                        .toList(growable: false),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 14),
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
                      controller: _noteController,
                      enabled: !ready.writesBlocked,
                      minLines: 3,
                      maxLines: 6,
                      textCapitalization: TextCapitalization.sentences,
                      onChanged: _viewModel.setJournalNote,
                      decoration: _moodInputDecoration(
                        context,
                        hintText: l10n.moodMedicineNoteHint,
                        multiline: true,
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
          const SizedBox(height: 18),
          FilledButton.icon(
            key: const Key('moodMedicineSaveCheckIn'),
            onPressed: ready.writesBlocked || !form.canSave
                ? null
                : () => _viewModel.saveCheckIn(),
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
          const SizedBox(height: 18),
          FilledButton(
            key: const Key('moodMedicineContinueCheckIn'),
            onPressed: form.canSave
                ? () => _viewModel.setCheckInDetailsExpanded(true)
                : null,
            child: Text(l10n.moodMedicineContinue),
          ),
        ],
      ],
    );
  }

  Widget _buildInsights(AppLocalizations l10n, MoodMedicineReadyState ready) {
    final MoodMedicineDashboard dashboard = ready.dashboard;
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
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      children: <Widget>[
        _PageHeading(
          title: l10n.moodMedicineInsights,
          subtitle: l10n.moodMedicineSubtitle,
          trailing: IconButton(
            tooltip: l10n.moodMedicineQuickCheckIn,
            onPressed: () =>
                _viewModel.selectView(MoodMedicineInitialView.checkIn),
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
                  label: Text(_rangeLabel(l10n, range)),
                  selected: ready.selectedRange == range,
                  onSelected: (_) => _viewModel.selectRange(range),
                ),
              )
              .toList(growable: false),
        ),
        const SizedBox(height: 14),
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
                  _rangeLabel(l10n, ready.selectedRange),
                  _trendSummary(l10n, trendSeries),
                ),
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
                const SizedBox(height: 6),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: overlayActivityIds
                      .map(
                        (String activityId) => ChoiceChip(
                          selected: ready.highlightedActivityId == activityId,
                          label: Text(
                            dashboard.activityLabelForRange(activityId),
                          ),
                          onSelected: (bool selected) =>
                              _viewModel.setHighlightedActivity(
                                selected ? activityId : null,
                              ),
                        ),
                      )
                      .toList(growable: false),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 14),
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
        const SizedBox(height: 14),
        Wrap(
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.md,
          children: <Widget>[
            FilledButton.icon(
              key: const Key('moodMedicineManualCheckIn'),
              onPressed: () =>
                  _viewModel.selectView(MoodMedicineInitialView.checkIn),
              icon: const Icon(Icons.add),
              label: Text(l10n.moodMedicineQuickCheckIn),
            ),
            OutlinedButton.icon(
              key: const Key('moodMedicineExportButton'),
              onPressed: ready.writesBlocked || ready.export.isWorking
                  ? null
                  : _showExportSheet,
              icon: const Icon(Icons.ios_share_outlined),
              label: Text(l10n.moodMedicineExport),
            ),
            TextButton.icon(
              key: const Key('moodMedicineEducationButton'),
              onPressed: () =>
                  _viewModel.selectView(MoodMedicineInitialView.education),
              icon: const Icon(Icons.menu_book_outlined),
              label: Text(l10n.moodMedicineEducation),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _showExportSheet() async {
    final Future<void> sheet = showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext sheetContext) =>
          ChangeNotifierProvider<MoodMedicineViewModel>.value(
            value: _viewModel,
            child: Consumer<MoodMedicineViewModel>(
              builder:
                  (BuildContext context, MoodMedicineViewModel viewModel, _) {
                    final AppLocalizations l10n = AppLocalizations.of(context)!;
                    final MoodMedicineReadyState? ready = viewModel.readyState;
                    if (ready == null) {
                      return const SizedBox.shrink();
                    }
                    final MoodMedicineExportState export = ready.export;

                    Future<MoodMedicineReportBuildOutcome>
                    buildForCurrentPresentation() async {
                      while (sheetContext.mounted) {
                        final MoodMedicineReportBuildOutcome outcome =
                            await viewModel.buildReport();
                        if (outcome
                            is MoodMedicineReportBuildStalePresentationOutcome) {
                          continue;
                        }
                        return outcome;
                      }
                      return const MoodMedicineReportBuildCancelledOutcome();
                    }

                    void showReportBuildFailure({required bool preview}) {
                      final AppLocalizations currentL10n = AppLocalizations.of(
                        sheetContext,
                      )!;
                      ScaffoldMessenger.of(sheetContext).showSnackBar(
                        SnackBar(
                          content: Text(
                            _reportBuildFailureMessage(
                              currentL10n,
                              viewModel,
                              preview: preview,
                            ),
                          ),
                        ),
                      );
                    }

                    Future<void> buildAndView() async {
                      final MoodMedicineReportBuildOutcome outcome =
                          await buildForCurrentPresentation();
                      if (!sheetContext.mounted) {
                        return;
                      }
                      switch (outcome) {
                        case MoodMedicineReportBuiltOutcome(:final report):
                          final AppLocalizations currentL10n =
                              AppLocalizations.of(sheetContext)!;
                          await Navigator.of(context).push<void>(
                            MaterialPageRoute<void>(
                              builder: (_) => MoodMedicineReportPreviewPage(
                                report: report,
                                title:
                                    report.format ==
                                        MoodMedicineReportFormat.pdf
                                    ? currentL10n.moodMedicinePreviewPdf
                                    : currentL10n.moodMedicinePreviewPng,
                                pngPrintGuidance:
                                    currentL10n.moodMedicinePngPrintGuidance,
                              ),
                            ),
                          );
                        case MoodMedicineReportBuildFailedOutcome():
                          showReportBuildFailure(preview: true);
                        case MoodMedicineReportBuildCancelledOutcome() ||
                            MoodMedicineReportBuildStalePresentationOutcome():
                          return;
                      }
                    }

                    Future<void> buildAndShare() async {
                      if (viewModel.readyState?.export.report == null) {
                        final MoodMedicineReportBuildOutcome outcome =
                            await buildForCurrentPresentation();
                        if (!sheetContext.mounted) {
                          return;
                        }
                        switch (outcome) {
                          case MoodMedicineReportBuiltOutcome():
                            break;
                          case MoodMedicineReportBuildFailedOutcome():
                            showReportBuildFailure(preview: false);
                            return;
                          case MoodMedicineReportBuildCancelledOutcome() ||
                              MoodMedicineReportBuildStalePresentationOutcome():
                            return;
                        }
                      }
                      if (!sheetContext.mounted) {
                        return;
                      }
                      final AppLocalizations currentL10n = AppLocalizations.of(
                        sheetContext,
                      )!;
                      final bool shared = await viewModel.shareBuiltReport(
                        shareText: currentL10n.moodMedicineExportReportTitle,
                      );
                      if (shared && sheetContext.mounted) {
                        Navigator.of(sheetContext).pop();
                      }
                    }

                    return SafeArea(
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(
                          AppSpacing.xxl,
                          AppSpacing.xxl,
                          AppSpacing.xxl,
                          AppSpacing.xxl +
                              MediaQuery.viewInsetsOf(context).bottom,
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              l10n.moodMedicineExport,
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: AppSpacing.md),
                            Text(
                              '${l10n.moodMedicineExportRange}: '
                              '${_rangeLabel(l10n, ready.selectedRange)}',
                            ),
                            const SizedBox(height: AppSpacing.md),
                            SegmentedButton<MoodMedicineReportFormat>(
                              segments:
                                  <ButtonSegment<MoodMedicineReportFormat>>[
                                    ButtonSegment<MoodMedicineReportFormat>(
                                      value: MoodMedicineReportFormat.pdf,
                                      label: Text(l10n.moodMedicineExportPdf),
                                      icon: const Icon(
                                        Icons.picture_as_pdf_outlined,
                                      ),
                                    ),
                                    ButtonSegment<MoodMedicineReportFormat>(
                                      value: MoodMedicineReportFormat.png,
                                      label: Text(l10n.moodMedicineExportPng),
                                      icon: const Icon(Icons.image_outlined),
                                    ),
                                  ],
                              selected: <MoodMedicineReportFormat>{
                                export.format,
                              },
                              onSelectionChanged: export.isWorking
                                  ? null
                                  : (Set<MoodMedicineReportFormat> selection) =>
                                        viewModel.setReportOptions(
                                          format: selection.first,
                                        ),
                            ),
                            if (export.format == MoodMedicineReportFormat.png)
                              Padding(
                                padding: const EdgeInsets.only(
                                  top: AppSpacing.sm,
                                ),
                                child: Text(
                                  l10n.moodMedicinePngPrintGuidance,
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ),
                            const SizedBox(height: AppSpacing.sm),
                            SwitchListTile.adaptive(
                              key: const Key('moodMedicineIncludeNotes'),
                              contentPadding: EdgeInsets.zero,
                              value: export.includeNotes,
                              onChanged: export.isWorking
                                  ? null
                                  : (bool value) => viewModel.setReportOptions(
                                      includeNotes: value,
                                    ),
                              title: Text(l10n.moodMedicineIncludeNotes),
                              subtitle: Text(l10n.moodMedicineNotesPrivacy),
                            ),
                            if (!export.includeNotes)
                              Padding(
                                padding: const EdgeInsets.only(
                                  top: AppSpacing.xs,
                                ),
                                child: Text(
                                  l10n.moodMedicineNotesExcluded,
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ),
                            const SizedBox(height: AppSpacing.lg),
                            Wrap(
                              spacing: AppSpacing.md,
                              runSpacing: AppSpacing.sm,
                              children: <Widget>[
                                OutlinedButton.icon(
                                  key: const Key('moodMedicineViewExport'),
                                  onPressed: export.isWorking
                                      ? null
                                      : buildAndView,
                                  icon:
                                      export.phase ==
                                          MoodMedicineExportPhase.building
                                      ? const SizedBox(
                                          width: 18,
                                          height: 18,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : const Icon(Icons.visibility_outlined),
                                  label: Text(l10n.moodMedicineView),
                                ),
                                FilledButton.icon(
                                  key: const Key('moodMedicineStartExport'),
                                  onPressed: export.isWorking
                                      ? null
                                      : buildAndShare,
                                  icon: export.isWorking
                                      ? const SizedBox(
                                          width: 18,
                                          height: 18,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : const Icon(Icons.ios_share_outlined),
                                  label: Text(
                                    export.isWorking
                                        ? l10n.moodMedicinePreparingExport
                                        : l10n.moodMedicineShare,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
            ),
          ),
    );
    try {
      await sheet;
    } finally {
      _viewModel.endReportExportSession();
    }
  }

  Widget _buildEducation(AppLocalizations l10n, MoodMedicineReadyState ready) {
    final List<MoodMedicineDoseContent> doseItems =
        MoodMedicineContent.doseItems(l10n);
    final MoodMedicineActivityContent selfCareSource =
        MoodMedicineContent.activityFor(
          l10n,
          MoodMedicineContent.nourishingMealId,
        )!;
    return ListView(
      key: const Key('moodMedicineEducation'),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      children: <Widget>[
        _PageHeading(
          title: l10n.moodMedicineEducation,
          subtitle: l10n.moodMedicineNotMedicalAdvice,
          trailing: IconButton(
            tooltip: l10n.moodMedicineViewInsights,
            onPressed: () =>
                _viewModel.selectView(MoodMedicineInitialView.insights),
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
                              color: Theme.of(
                                context,
                              ).colorScheme.secondary.withValues(alpha: 0.32),
                              child: Padding(
                                padding: const EdgeInsets.all(AppSpacing.md),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
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
              const SizedBox(height: 14),
              TextButton.icon(
                key: const Key('moodMedicineEducationSource'),
                onPressed: () =>
                    _viewModel.openEducationSource(selfCareSource.sourceUri),
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
        const SizedBox(height: 14),
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

  Widget _buildRecovery(
    AppLocalizations l10n,
    MoodMedicineRecoveryRequiredState recovery,
  ) {
    return Scaffold(
      appBar: AppBar(title: Text(l10n.moodMedicineTitle)),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.xxl),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    l10n.moodMedicineRecoveryTitle,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(l10n.moodMedicineRecoveryBody),
                  if (recovery.discardError != null)
                    Padding(
                      padding: const EdgeInsets.only(top: AppSpacing.sm),
                      child: Text(
                        l10n.asyncErrorMessage,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ),
                  const SizedBox(height: AppSpacing.lg),
                  Wrap(
                    spacing: AppSpacing.md,
                    runSpacing: AppSpacing.sm,
                    children: <Widget>[
                      FilledButton(
                        key: const Key('moodMedicineRecoveryRetry'),
                        onPressed: recovery.isDiscarding ? null : _retryLoad,
                        child: Text(l10n.moodMedicineRetry),
                      ),
                      OutlinedButton(
                        key: const Key('moodMedicineDiscardUnreadable'),
                        onPressed: recovery.isDiscarding
                            ? null
                            : () => _confirmDiscardUnreadable(l10n),
                        child: Text(l10n.moodMedicineDiscardUnreadable),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _confirmDiscardUnreadable(AppLocalizations l10n) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: Text(l10n.moodMedicineDiscardUnreadableTitle),
        content: Text(l10n.moodMedicineDiscardUnreadableBody),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.moodMedicineCancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(dialogContext).colorScheme.error,
              foregroundColor: Theme.of(dialogContext).colorScheme.onError,
            ),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.moodMedicineDiscardUnreadable),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      final bool discarded = await _viewModel.discardUnreadableSnapshot();
      if (discarded) {
        _applyReportPresentationIfReady();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<MoodMedicineViewModel>.value(
      value: _viewModel,
      child: Consumer<MoodMedicineViewModel>(
        builder: (BuildContext context, MoodMedicineViewModel viewModel, _) {
          final AppLocalizations l10n = AppLocalizations.of(context)!;
          return switch (viewModel.state) {
            MoodMedicineLoadingState() => Scaffold(
              appBar: AppBar(title: Text(l10n.moodMedicineTitle)),
              body: Center(
                child: Semantics(
                  label: l10n.moodMedicineLoading,
                  child: const CircularProgressIndicator(),
                ),
              ),
            ),
            MoodMedicineRecoveryRequiredState recovery => _buildRecovery(
              l10n,
              recovery,
            ),
            MoodMedicineReadyState ready => Scaffold(
              appBar: AppBar(
                title: Text(l10n.moodMedicineTitle),
                actions: <Widget>[
                  IconButton(
                    tooltip: l10n.moodMedicineQuickCheckIn,
                    onPressed: () =>
                        _viewModel.selectView(MoodMedicineInitialView.checkIn),
                    icon: const Icon(Icons.add_chart_rounded),
                  ),
                ],
              ),
              body: SafeArea(
                child: switch (ready.selectedView) {
                  MoodMedicineInitialView.checkIn => _buildCheckIn(l10n, ready),
                  MoodMedicineInitialView.insights => _buildInsights(
                    l10n,
                    ready,
                  ),
                  MoodMedicineInitialView.education => _buildEducation(
                    l10n,
                    ready,
                  ),
                },
              ),
            ),
          };
        },
      ),
    );
  }
}

InputDecoration _moodInputDecoration(
  BuildContext context, {
  required String hintText,
  bool multiline = false,
}) {
  final ThemeData theme = Theme.of(context);
  final Color outline = theme.brightness == Brightness.dark
      ? theme.colorScheme.outline
      : AppColors.neutralLight;
  final OutlineInputBorder border = OutlineInputBorder(
    borderRadius: BorderRadius.circular(10),
    borderSide: BorderSide(color: outline),
  );
  return InputDecoration(
    hintText: hintText,
    isDense: true,
    contentPadding: EdgeInsets.symmetric(
      horizontal: AppSpacing.md,
      vertical: multiline ? AppSpacing.md : 7,
    ),
    border: border,
    enabledBorder: border,
    focusedBorder: border.copyWith(
      borderSide: BorderSide(color: theme.colorScheme.primary, width: 1.5),
    ),
    disabledBorder: border.copyWith(
      borderSide: BorderSide(color: outline.withValues(alpha: 0.65)),
    ),
  );
}

class _MoodOption {
  const _MoodOption(this.value, this.icon, this.label);

  final int value;
  final IconData icon;
  final String label;
}

class _ActivityEditorDialog extends StatefulWidget {
  const _ActivityEditorDialog({
    required this.activity,
    required this.l10n,
    required this.viewModel,
  });

  final MoodMedicineCustomActivity? activity;
  final AppLocalizations l10n;
  final MoodMedicineViewModel viewModel;

  @override
  State<_ActivityEditorDialog> createState() => _ActivityEditorDialogState();
}

class _ActivityEditorDialogState extends State<_ActivityEditorDialog> {
  late final TextEditingController _nameController = TextEditingController(
    text: widget.activity?.label,
  );
  bool _submitting = false;
  String? _validationError;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_submitting) {
      return;
    }
    final String label = _nameController.text.trim();
    if (label.isEmpty) {
      setState(
        () => _validationError = widget.l10n.moodMedicineActivityNameRequired,
      );
      return;
    }
    setState(() => _submitting = true);
    final bool saved;
    try {
      saved = widget.activity == null
          ? await widget.viewModel.addCustomActivity(label) != null
          : await widget.viewModel.editCustomActivity(
              widget.activity!.id,
              label,
            );
    } on ArgumentError {
      if (mounted) {
        setState(() {
          _submitting = false;
          _validationError = widget.l10n.moodMedicineActivityNameRequired;
        });
      }
      return;
    }
    if (!mounted) {
      return;
    }
    if (saved) {
      Navigator.of(context).pop();
      return;
    }
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = widget.l10n;
    return AlertDialog(
      title: Text(
        widget.activity == null
            ? l10n.moodMedicineAddCustomActivity
            : l10n.moodMedicineEditCustomActivity,
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            l10n.moodMedicineActivityName,
            style: Theme.of(context).textTheme.labelLarge,
          ),
          const SizedBox(height: AppSpacing.xs),
          ConstrainedBox(
            constraints: BoxConstraints(maxWidth: formFieldWidth(context)),
            child: SizedBox(
              height: 40,
              child: TextField(
                key: const Key('moodMedicineActivityEditorField'),
                controller: _nameController,
                autofocus: true,
                textInputAction: TextInputAction.done,
                decoration: _moodInputDecoration(
                  context,
                  hintText: l10n.moodMedicineActivityNameHint,
                ),
                onSubmitted: (_) => _save(),
              ),
            ),
          ),
          if (_validationError != null)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.xs),
              child: Text(
                _validationError!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
        ],
      ),
      actions: <Widget>[
        TextButton(
          onPressed: _submitting ? null : () => Navigator.of(context).pop(),
          child: Text(l10n.moodMedicineCancel),
        ),
        FilledButton(
          onPressed: _submitting ? null : _save,
          child: Text(l10n.moodMedicineSaveActivity),
        ),
      ],
    );
  }
}

class _ActivityChip {
  const _ActivityChip({
    required this.id,
    required this.label,
    required this.icon,
    this.source,
  });

  final String id;
  final String label;
  final IconData icon;
  final MoodMedicineActivityContent? source;
}

class _MoodSurface extends StatelessWidget {
  const _MoodSurface({required this.child, this.color});

  final Widget child;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color outline = theme.brightness == Brightness.dark
        ? theme.colorScheme.outline
        : AppColors.neutralLight;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color ?? theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadii.card),
        border: Border.all(color: outline),
      ),
      child: child,
    );
  }
}

class _FeatureCard extends StatelessWidget {
  const _FeatureCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return _MoodSurface(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: child,
      ),
    );
  }
}

class _PageHeading extends StatelessWidget {
  const _PageHeading({
    required this.title,
    required this.subtitle,
    this.trailing,
  });

  final String title;
  final String subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(title, style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: AppSpacing.xs),
              Text(subtitle),
            ],
          ),
        ),
        if (trailing case final Widget trailing) trailing,
      ],
    );
  }
}

class _ManagerSection extends StatelessWidget {
  const _ManagerSection({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return _MoodSurface(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: AppSpacing.xs),
            ...children,
          ],
        ),
      ),
    );
  }
}
