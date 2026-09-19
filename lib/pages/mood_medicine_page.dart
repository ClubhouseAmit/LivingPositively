import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart' as intl;
import 'package:mazilon/design_system/tokens/colors.dart';
import 'package:mazilon/design_system/widgets/button.dart';
import 'package:mazilon/design_system/widgets/sheet.dart';
import 'package:mazilon/l10n/app_localizations.dart';
import 'package:mazilon/features/mood_medicine/data/mood_medicine_models.dart';
import 'package:mazilon/features/mood_medicine/data/mood_medicine_report_delivery_types.dart';
import 'package:mazilon/features/mood_medicine/data/mood_medicine_report_models.dart';
import 'package:mazilon/features/mood_medicine/ui/mood_medicine_content.dart';
import 'package:mazilon/features/mood_medicine/ui/mood_medicine_insights.dart';
import 'package:mazilon/pages/mood_medicine_report_preview_page.dart';
import 'package:mazilon/features/mood_medicine/ui/mood_medicine_trend_chart.dart';
import 'package:mazilon/features/mood_medicine/ui/mood_medicine_view_model.dart';
import 'package:mazilon/features/mood_medicine/ui/mood_medicine_view_state.dart';
import 'package:mazilon/features/shell/ui/persistence_retry_snack_bar.dart';
import 'package:mazilon/features/shell/ui/styles.dart';
import 'package:mazilon/util/async/app_theme.dart';
import 'package:mazilon/design_system/tokens/spacing.dart';
import 'package:provider/provider.dart';

part 'package:mazilon/features/mood_medicine/ui/mood_medicine_misc_helpers.dart';
part 'package:mazilon/features/mood_medicine/ui/mood_medicine_check_in_helper.dart';
part 'package:mazilon/features/mood_medicine/ui/mood_medicine_insights_helper.dart';
part 'package:mazilon/features/mood_medicine/ui/mood_medicine_export_helper.dart';

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
  bool _checkInSheetOpen = false;
  bool _offeredInitialCheckIn = false;
  bool _checkInCommitted = false;
  OverlayEntry? _failureEntry;

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
    _removeFailureOverlay();
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
    if (_checkInSheetOpen) {
      _showSheetWriteFailure(canRetry: canRetry);
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
    showPersistenceRetrySnackBar(context, _retryFailedWriteAsync);
  }

  void _showSheetWriteFailure({required bool canRetry}) {
    _removeFailureOverlay();
    final OverlayState? overlay = Overlay.maybeOf(context, rootOverlay: true);
    final AppLocalizations? l10n = AppLocalizations.of(context);
    if (overlay == null || l10n == null) {
      return;
    }
    _failureEntry = OverlayEntry(
      builder: (BuildContext _) =>
          _sheetFailureBanner(l10n, canRetry: canRetry),
    );
    overlay.insert(_failureEntry!);
  }

  void _removeFailureOverlay() {
    _failureEntry?.remove();
    _failureEntry = null;
  }

  Widget _sheetFailureBanner(
    AppLocalizations l10n, {
    required bool canRetry,
  }) {
    return Positioned(
      left: AppSpacing.lg,
      right: AppSpacing.lg,
      top: AppSpacing.lg,
      child: SnackBar(
        animation: const AlwaysStoppedAnimation<double>(1),
        content: Text(l10n.asyncErrorMessage),
        action: canRetry
            ? SnackBarAction(
                label: l10n.asyncRetryButton,
                onPressed: _retryFailedWrite,
              )
            : null,
      ),
    );
  }

  void _retryFailedWrite() {
    unawaited(_retryFailedWriteAsync());
  }

  Future<void> _retryFailedWriteAsync() async {
    final bool saved = await _viewModel.retryLastWrite();
    if (saved) {
      _popCheckInSheet();
      return;
    }
    if (mounted &&
        _viewModel.readyState?.persistence.hasPendingWrite == true) {
      _showWriteFailure(canRetry: true);
    }
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

  Future<void> _openActivityManager() => buildMoodMedicineActivityManager(this);

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
                  Icon(activity.icon, color: activity.color),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text(
                      activity.label,
                      style: Theme.of(sheetContext).textTheme.titleLarge,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Text(activity.description),
              const SizedBox(height: AppSpacing.md),
              Text(activity.guidance),
              const SizedBox(height: AppSpacing.md),
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

  Widget _buildInsights(AppLocalizations l10n, MoodMedicineReadyState ready) =>
      buildMoodMedicineInsights(this, l10n, ready);

  Future<void> _showExportSheet() => buildMoodMedicineExportSheet(this);

  Widget _buildEducation(AppLocalizations l10n, MoodMedicineReadyState ready) =>
      buildMoodMedicineEducation(this, l10n, ready);

  Widget _buildRecovery(
    AppLocalizations l10n,
    MoodMedicineRecoveryRequiredState recovery,
  ) {
    return SafeArea(
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
                  l10n.moodMedicineTitle,
                  style: Theme.of(context).textTheme.headlineLarge,
                ),
                const SizedBox(height: AppSpacing.lg),
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
    );
  }

  void _offerCheckInSheet(MoodMedicineReadyState ready) {
    if (_offeredInitialCheckIn ||
        ready.selectedView != MoodMedicineInitialView.checkIn) {
      return;
    }
    _offeredInitialCheckIn = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        unawaited(_openCheckInSheet(leavePageOnDismiss: true));
      }
    });
  }

  Future<void> _openCheckInSheet({bool leavePageOnDismiss = false}) async {
    if (!mounted || _checkInSheetOpen) {
      return;
    }
    _checkInSheetOpen = true;
    _checkInCommitted = false;
    final MoodMedicineViewModel viewModel = _viewModel;
    await showSheet<void>(
      context: context,
      sheet: Sheet(
        child: ChangeNotifierProvider<MoodMedicineViewModel>.value(
          value: viewModel,
          child: _CheckInSheet(page: this),
        ),
      ),
    );
    _checkInSheetOpen = false;
    _removeFailureOverlay();
    if (leavePageOnDismiss && !_checkInCommitted && mounted) {
      await Navigator.of(context).maybePop();
    }
  }

  void _popCheckInSheet() {
    if (!_checkInSheetOpen || !mounted) {
      return;
    }
    _checkInCommitted = true;
    _removeFailureOverlay();
    Navigator.of(context).pop();
  }

  Widget _readyBody(AppLocalizations l10n, MoodMedicineReadyState ready) {
    _offerCheckInSheet(ready);
    return switch (ready.selectedView) {
      MoodMedicineInitialView.education => _buildEducation(l10n, ready),
      MoodMedicineInitialView.checkIn ||
      MoodMedicineInitialView.insights => _buildInsights(l10n, ready),
    };
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
              body: Center(
                child: Semantics(
                  label: l10n.moodMedicineLoading,
                  child: const CircularProgressIndicator(),
                ),
              ),
            ),
            MoodMedicineRecoveryRequiredState recovery => Scaffold(
              body: _buildRecovery(l10n, recovery),
            ),
            MoodMedicineReadyState ready => Scaffold(
              body: SafeArea(
                child: _readyBody(l10n, ready),
              ),
            ),
          };
        },
      ),
    );
  }
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
            child: TextField(
              key: const Key('moodMedicineActivityEditorField'),
              controller: _nameController,
              autofocus: true,
              textInputAction: TextInputAction.done,
              decoration: InputDecoration(
                hintText: l10n.moodMedicineActivityNameHint,
              ),
              onSubmitted: (_) => _save(),
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
    this.color,
    this.source,
  });

  final String id;
  final String label;
  final IconData icon;
  final Color? color;
  final MoodMedicineActivityContent? source;
}

class _ActivityColorSwatch extends StatelessWidget {
  const _ActivityColorSwatch({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      child: const SizedBox(
        width: AppSpacing.md,
        height: AppSpacing.md,
      ),
    );
  }
}

class _MoodSurface extends StatelessWidget {
  const _MoodSurface({
    super.key,
    required this.child,
    this.color,
    this.borderColor,
  });

  final Widget child;
  final Color? color;
  final Color? borderColor;

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
        border: Border.all(color: borderColor ?? outline),
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

class _CheckInSheet extends StatelessWidget {
  const _CheckInSheet({required this.page});

  final _MoodMedicinePageState page;

  @override
  Widget build(BuildContext context) {
    return Consumer<MoodMedicineViewModel>(
      builder: (BuildContext context, MoodMedicineViewModel model, _) {
        final MoodMedicineReadyState? ready = model.readyState;
        final AppLocalizations? l10n = AppLocalizations.of(context);
        if (ready == null || l10n == null) {
          return const SizedBox.shrink();
        }
        return Material(
          color: AppColors.white,
          child: buildMoodMedicineCheckIn(page, l10n, ready),
        );
      },
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
