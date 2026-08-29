import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:mazilon/l10n/app_localizations.dart';
import 'package:mazilon/pages/MoodMedicine/mood_medicine_content.dart';
import 'package:mazilon/pages/MoodMedicine/mood_medicine_controller.dart';
import 'package:mazilon/pages/MoodMedicine/mood_medicine_insights.dart';
import 'package:mazilon/pages/MoodMedicine/mood_medicine_models.dart';
import 'package:mazilon/pages/MoodMedicine/mood_medicine_report_exporter.dart';
import 'package:mazilon/pages/MoodMedicine/mood_medicine_store.dart';
import 'package:mazilon/pages/MoodMedicine/mood_medicine_trend_chart.dart';
import 'package:mazilon/util/async/persistence_retry_snack_bar.dart';
import 'package:mazilon/util/persistent_memory_service.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

/// The first surface shown when Mood Tracker is opened from an app entry point.
enum MoodMedicineInitialView { checkIn, insights, education }

/// A device-local mood check-in, education, and insights experience.
///
/// This page owns only presentation draft state. The controller owns the
/// persisted snapshot and preserves a failed write for the existing retry UI.
class MoodMedicinePage extends StatefulWidget {
  const MoodMedicinePage({
    super.key,
    this.initialView = MoodMedicineInitialView.insights,
    this.controller,
  });

  final MoodMedicineInitialView initialView;

  /// Allows focused widget tests to use a memory-backed controller.
  final MoodMedicineController? controller;

  @override
  State<MoodMedicinePage> createState() => _MoodMedicinePageState();
}

class _MoodMedicinePageState extends State<MoodMedicinePage> {
  late final MoodMedicineController _controller;
  late MoodMedicineInitialView _view;
  final TextEditingController _noteController = TextEditingController();
  final Set<String> _emotionIds = <String>{};
  final Set<String> _activityIds = <String>{};
  MoodMedicineInsightRange _range = MoodMedicineInsightRange.week;
  String? _highlightedActivityId;
  int? _mood;
  bool _showCheckInDetails = false;

  bool get _writesBlocked =>
      _controller.isSaving || _controller.hasPendingWrite;

  @override
  void initState() {
    super.initState();
    _controller =
        widget.controller ??
        MoodMedicineController(
          MoodMedicineStore(GetIt.instance<PersistentMemoryService>()),
        );
    _view = widget.initialView;
    unawaited(_load());
  }

  Future<void> _load() async {
    final bool loaded = await _controller.load();
    if (!mounted || loaded) {
      return;
    }
    _showRetry();
  }

  @override
  void dispose() {
    _noteController.dispose();
    if (widget.controller == null) {
      _controller.dispose();
    }
    super.dispose();
  }

  void _showRetry() {
    if (!mounted) {
      return;
    }
    showPersistenceRetrySnackBar(context, () async {
      await _controller.retryLastWrite();
      if (!_controller.isLoaded) {
        await _load();
      }
    });
  }

  void _showWriteFailure({VoidCallback? onRetrySucceeded}) {
    if (!mounted) {
      return;
    }
    showPersistenceRetrySnackBar(context, () async {
      final bool saved = await _controller.retryLastWrite();
      if (!mounted) {
        return;
      }
      if (saved) {
        onRetrySucceeded?.call();
      } else {
        _showWriteFailure(onRetrySucceeded: onRetrySucceeded);
      }
    });
  }

  /// A page-level SnackBar sits below the activity-manager modal route, so
  /// close that transient surface before presenting its retry action.
  void _closeActivityManagerAndShowWriteFailure({
    VoidCallback? onRetrySucceeded,
  }) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      Navigator.of(context).pop();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showWriteFailure(onRetrySucceeded: onRetrySucceeded);
      });
    });
  }

  List<MoodMedicineActivityContent> _activities(AppLocalizations l10n) =>
      MoodMedicineContent.activities(l10n);

  String _activityLabel(AppLocalizations l10n, String id) {
    final MoodMedicineCustomActivity? custom = _controller.snapshot
        .customActivityForId(id);
    if (custom != null) {
      return custom.label;
    }
    return MoodMedicineContent.activityFor(l10n, id)?.label ?? id;
  }

  String _entryActivityLabel(
    AppLocalizations l10n,
    MoodMedicineEntry entry,
    String id,
  ) {
    return entry.customActivityLabelSnapshots[id] ?? _activityLabel(l10n, id);
  }

  MoodMedicineEntry? _latestEntryForActivity(
    String id, {
    Iterable<String>? dayKeys,
  }) {
    final Set<String>? allowedDayKeys = dayKeys?.toSet();
    MoodMedicineEntry? latest;
    for (final MoodMedicineEntry entry in _controller.entries) {
      if (!entry.activityIds.contains(id) ||
          (allowedDayKeys != null &&
              !allowedDayKeys.contains(entry.localDayKey))) {
        continue;
      }
      final DateTime? latestTime = latest?.occurredAtUtc;
      if (latestTime == null || entry.occurredAtUtc.isAfter(latestTime)) {
        latest = entry;
      }
    }
    return latest;
  }

  String _activityLabelForDay(
    AppLocalizations l10n,
    MoodMedicineDailySummary summary,
    String id,
  ) {
    final MoodMedicineEntry? entry = _latestEntryForActivity(
      id,
      dayKeys: <String>[summary.dayKey],
    );
    return entry == null
        ? _activityLabel(l10n, id)
        : _entryActivityLabel(l10n, entry, id);
  }

  /// For multi-day labels, use the active custom label when available and
  /// otherwise the most recent historical snapshot in the selected range.
  String _rangeActivityLabel(
    AppLocalizations l10n,
    String id,
    Iterable<MoodMedicineDailySummary> summaries,
  ) {
    final MoodMedicineCustomActivity? activeCustom = _controller.snapshot
        .customActivityForId(id);
    if (activeCustom != null) {
      return activeCustom.label;
    }
    final MoodMedicineActivityContent? defaultActivity =
        MoodMedicineContent.activityFor(l10n, id);
    if (defaultActivity != null) {
      return defaultActivity.label;
    }
    final MoodMedicineEntry? entry = _latestEntryForActivity(
      id,
      dayKeys: summaries.map(
        (MoodMedicineDailySummary summary) => summary.dayKey,
      ),
    );
    return entry == null ? id : _entryActivityLabel(l10n, entry, id);
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

  void _startCheckIn() {
    setState(() {
      _view = MoodMedicineInitialView.checkIn;
      _showCheckInDetails = _mood != null;
    });
  }

  Future<void> _saveCheckIn() async {
    if (_writesBlocked) {
      return;
    }
    final int? mood = _mood;
    if (mood == null) {
      setState(() => _showCheckInDetails = false);
      return;
    }
    final bool saved = await _controller.saveCheckIn(
      MoodMedicineCheckInDraft(
        mood: mood,
        emotionIds: _emotionIds,
        activityIds: _activityIds,
        note: _noteController.text,
      ),
    );
    if (!mounted) {
      return;
    }
    if (!saved) {
      _showWriteFailure(onRetrySucceeded: _finishSavedCheckIn);
      return;
    }
    _finishSavedCheckIn();
  }

  void _finishSavedCheckIn() {
    if (!mounted) {
      return;
    }
    setState(() {
      _mood = null;
      _emotionIds.clear();
      _activityIds.clear();
      _noteController.clear();
      _showCheckInDetails = false;
      _view = MoodMedicineInitialView.insights;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppLocalizations.of(context)!.moodMedicineCheckInSaved),
      ),
    );
  }

  Future<void> _runDefaultActivityMutation(
    Future<bool> Function() mutation, {
    String? deselectId,
  }) async {
    if (_writesBlocked) {
      return;
    }
    final bool saved = await mutation();
    if (!mounted) {
      return;
    }
    if (!saved) {
      _closeActivityManagerAndShowWriteFailure(
        onRetrySucceeded: () {
          if (deselectId != null && mounted) {
            setState(() => _activityIds.remove(deselectId));
          }
        },
      );
      return;
    }
    if (deselectId != null) {
      setState(() => _activityIds.remove(deselectId));
    }
  }

  Future<void> _showActivityEditor({
    MoodMedicineCustomActivity? activity,
  }) async {
    if (_writesBlocked) {
      return;
    }
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    await showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) => _ActivityEditorDialog(
        activity: activity,
        l10n: l10n,
        onSave: (String label) async {
          if (_writesBlocked) {
            return false;
          }
          return activity == null
              ? await _controller.addCustomActivity(label) != null
              : _controller.editCustomActivity(activity.id, label);
        },
        onSaveFailed: _closeActivityManagerAndShowWriteFailure,
      ),
    );
  }

  Future<void> _confirmDeleteActivity(
    MoodMedicineCustomActivity activity,
  ) async {
    if (_writesBlocked) {
      return;
    }
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
    if (confirmed != true) {
      return;
    }
    if (_writesBlocked) {
      return;
    }
    final bool saved = await _controller.deleteCustomActivity(activity.id);
    if (!mounted) {
      return;
    }
    if (!saved) {
      _closeActivityManagerAndShowWriteFailure(
        onRetrySucceeded: () {
          if (mounted) {
            setState(() => _activityIds.remove(activity.id));
          }
        },
      );
      return;
    }
    setState(() => _activityIds.remove(activity.id));
  }

  Future<void> _openActivityManager() async {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext sheetContext) {
        return ChangeNotifierProvider.value(
          value: _controller,
          child: DraggableScrollableSheet(
            expand: false,
            initialChildSize: 0.72,
            maxChildSize: 0.92,
            builder: (BuildContext context, ScrollController scrollController) {
              return Consumer<MoodMedicineController>(
                builder: (_, MoodMedicineController controller, _) {
                  final List<MoodMedicineActivityContent> defaults =
                      _activities(l10n);
                  final List<MoodMedicineActivityContent> hidden = defaults
                      .where(
                        (MoodMedicineActivityContent item) => controller
                            .hiddenDefaultActivityIds
                            .contains(item.id),
                      )
                      .toList(growable: false);
                  final List<MoodMedicineActivityContent> visible = defaults
                      .where(
                        (MoodMedicineActivityContent item) => !controller
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
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          l10n.moodMedicineManageActivities,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        Text(l10n.moodMedicineActivityHistoryNote),
                        const SizedBox(height: 18),
                        _ManagerSection(
                          title: l10n.moodMedicineDefaultActivities,
                          children: visible
                              .map(
                                (MoodMedicineActivityContent activity) =>
                                    ListTile(
                                      leading: Icon(activity.icon),
                                      title: Text(activity.label),
                                      trailing: TextButton(
                                        onPressed:
                                            controller.isSaving ||
                                                controller.hasPendingWrite
                                            ? null
                                            : () => _runDefaultActivityMutation(
                                                () => controller
                                                    .hideDefaultActivity(
                                                      activity.id,
                                                    ),
                                                deselectId: activity.id,
                                              ),
                                        child: Text(l10n.moodMedicineHide),
                                      ),
                                    ),
                              )
                              .toList(growable: false),
                        ),
                        if (hidden.isNotEmpty) ...<Widget>[
                          const SizedBox(height: 12),
                          _ManagerSection(
                            title: l10n.moodMedicineHiddenActivities,
                            children: hidden
                                .map(
                                  (
                                    MoodMedicineActivityContent activity,
                                  ) => ListTile(
                                    leading: Icon(activity.icon),
                                    title: Text(activity.label),
                                    trailing: TextButton(
                                      onPressed:
                                          controller.isSaving ||
                                              controller.hasPendingWrite
                                          ? null
                                          : () => _runDefaultActivityMutation(
                                              () => controller
                                                  .restoreDefaultActivity(
                                                    activity.id,
                                                  ),
                                            ),
                                      child: Text(l10n.moodMedicineRestore),
                                    ),
                                  ),
                                )
                                .toList(growable: false),
                          ),
                        ],
                        const SizedBox(height: 12),
                        _ManagerSection(
                          title: l10n.moodMedicineCustomActivities,
                          children: <Widget>[
                            if (controller.customActivities.isEmpty)
                              Padding(
                                padding: const EdgeInsets.all(16),
                                child: Text(
                                  l10n.moodMedicineNoCustomActivities,
                                ),
                              ),
                            ...controller.customActivities.map(
                              (MoodMedicineCustomActivity activity) => ListTile(
                                leading: const Icon(Icons.favorite_outline),
                                title: Text(activity.label),
                                trailing: Wrap(
                                  spacing: 2,
                                  children: <Widget>[
                                    IconButton(
                                      tooltip: l10n.moodMedicineEdit,
                                      onPressed:
                                          controller.isSaving ||
                                              controller.hasPendingWrite
                                          ? null
                                          : () => _showActivityEditor(
                                              activity: activity,
                                            ),
                                      icon: const Icon(Icons.edit_outlined),
                                    ),
                                    IconButton(
                                      tooltip: l10n.moodMedicineDelete,
                                      onPressed:
                                          controller.isSaving ||
                                              controller.hasPendingWrite
                                          ? null
                                          : () => _confirmDeleteActivity(
                                              activity,
                                            ),
                                      icon: const Icon(Icons.delete_outline),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            Align(
                              alignment: AlignmentDirectional.centerStart,
                              child: FilledButton.icon(
                                onPressed:
                                    controller.isSaving ||
                                        controller.hasPendingWrite
                                    ? null
                                    : () => _showActivityEditor(),
                                icon: const Icon(Icons.add),
                                label: Text(l10n.moodMedicineAddCustomActivity),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        );
      },
    );
  }

  Future<void> _openActivityEducation(
    MoodMedicineActivityContent activity,
  ) async {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    await showModalBottomSheet<void>(
      context: context,
      builder: (BuildContext sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Icon(activity.icon),
                  const SizedBox(width: 10),
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
              const SizedBox(height: 10),
              Text(activity.guidance),
              const SizedBox(height: 14),
              TextButton.icon(
                onPressed: () async {
                  final bool opened = await launchUrl(
                    activity.sourceUri,
                    mode: LaunchMode.externalApplication,
                    webOnlyWindowName: '_blank',
                  );
                  if (!opened && sheetContext.mounted) {
                    ScaffoldMessenger.of(sheetContext).showSnackBar(
                      SnackBar(content: Text(l10n.moodMedicineExportError)),
                    );
                  }
                },
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

  Widget _buildCheckIn(AppLocalizations l10n) {
    final List<MoodMedicineActivityContent> selectableActivities =
        <MoodMedicineActivityContent>[
          ..._activities(l10n).where(
            (MoodMedicineActivityContent item) =>
                !_controller.hiddenDefaultActivityIds.contains(item.id),
          ),
        ];
    final Map<String, String> emotionLabels = _emotionLabels(l10n);
    final List<_ActivityChip> activityChips = <_ActivityChip>[
      ...selectableActivities.map(
        (MoodMedicineActivityContent activity) => _ActivityChip(
          id: activity.id,
          label: activity.label,
          icon: activity.icon,
          source: activity,
        ),
      ),
      ..._controller.customActivities.map(
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
                setState(() => _view = MoodMedicineInitialView.insights),
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
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.spaceBetween,
                children: _moodOptions(l10n)
                    .map(
                      (_MoodOption option) => Semantics(
                        button: true,
                        selected: _mood == option.value,
                        label: option.label,
                        child: ChoiceChip(
                          key: Key('moodMedicineMood${option.value}'),
                          selected: _mood == option.value,
                          onSelected: _writesBlocked
                              ? null
                              : (_) => setState(() {
                                  _mood = option.value;
                                  _showCheckInDetails = true;
                                }),
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
        if (_showCheckInDetails) ...<Widget>[
          const SizedBox(height: 14),
          _FeatureCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  l10n.moodMedicineEmotions,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                Text(l10n.moodMedicineEmotionsHint),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: emotionLabels.entries
                      .map(
                        (MapEntry<String, String> item) => FilterChip(
                          key: Key('moodMedicineEmotion${item.key}'),
                          selected: _emotionIds.contains(item.key),
                          onSelected: _writesBlocked
                              ? null
                              : (bool selected) => setState(() {
                                  if (selected) {
                                    _emotionIds.add(item.key);
                                  } else {
                                    _emotionIds.remove(item.key);
                                  }
                                }),
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
                      onPressed: _writesBlocked ? null : _openActivityManager,
                      child: Text(l10n.moodMedicineManageActivities),
                    ),
                  ],
                ),
                Text(l10n.moodMedicineActivitiesHint),
                const SizedBox(height: 10),
                if (activityChips.isEmpty)
                  Text(l10n.moodMedicineNoActivitiesSelected)
                else
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: activityChips
                        .map(
                          (_ActivityChip item) => FilterChip(
                            key: Key('moodMedicineActivity${item.id}'),
                            selected: _activityIds.contains(item.id),
                            onSelected: _writesBlocked
                                ? null
                                : (bool selected) => setState(() {
                                    if (selected) {
                                      _activityIds.add(item.id);
                                    } else {
                                      _activityIds.remove(item.id);
                                    }
                                  }),
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
                const SizedBox(height: 8),
                TextField(
                  key: const Key('moodMedicineNoteField'),
                  controller: _noteController,
                  enabled: !_writesBlocked,
                  minLines: 3,
                  maxLines: 6,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration(
                    hintText: l10n.moodMedicineNoteHint,
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),
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
            onPressed: _writesBlocked ? null : _saveCheckIn,
            icon: _controller.isSaving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.check),
            label: Text(
              _controller.isSaving
                  ? l10n.moodMedicineSaving
                  : l10n.moodMedicineSave,
            ),
          ),
        ] else ...<Widget>[
          const SizedBox(height: 18),
          FilledButton(
            key: const Key('moodMedicineContinueCheckIn'),
            onPressed: _mood == null
                ? null
                : () => setState(() => _showCheckInDetails = true),
            child: Text(l10n.moodMedicineContinue),
          ),
        ],
      ],
    );
  }

  List<MoodMedicineDailySummary> _summariesForCurrentRange() {
    return MoodMedicineInsights.summariesForRange(
      _controller.entries,
      range: _range,
      anchor: DateTime.now(),
    );
  }

  String _rangeLabel(AppLocalizations l10n) => switch (_range) {
    MoodMedicineInsightRange.day => l10n.moodMedicineToday,
    MoodMedicineInsightRange.week => l10n.moodMedicineWeek,
    MoodMedicineInsightRange.month => l10n.moodMedicineMonth,
    MoodMedicineInsightRange.year => l10n.moodMedicineYear,
  };

  String _trendSummary(List<MoodMedicineDailySummary> summaries) {
    if (summaries.isEmpty) {
      return '';
    }
    return summaries
        .map(
          (MoodMedicineDailySummary item) =>
              '${item.dayKey}: ${item.averageMood.toStringAsFixed(1)}',
        )
        .join(', ');
  }

  Widget _buildInsights(AppLocalizations l10n) {
    final List<MoodMedicineDailySummary> summaries =
        _summariesForCurrentRange();
    final List<MoodMedicineAssociation> associations =
        MoodMedicineInsights.associations(summaries);
    final List<MoodMedicineTrendPoint> points = summaries
        .map(
          (MoodMedicineDailySummary item) => MoodMedicineTrendPoint(
            label: item.dayKey,
            mood: item.averageMood,
            activityIds: item.activityIds,
          ),
        )
        .toList(growable: false);
    final List<String> overlayActivityIds = summaries
        .expand((MoodMedicineDailySummary item) => item.activityIds)
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
            onPressed: _startCheckIn,
            icon: const Icon(Icons.add_chart_rounded),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: MoodMedicineInsightRange.values
              .map(
                (MoodMedicineInsightRange range) => ChoiceChip(
                  label: Text(_rangeName(l10n, range)),
                  selected: _range == range,
                  onSelected: (_) => setState(() => _range = range),
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
              const SizedBox(height: 4),
              Text(l10n.moodMedicineDailyAverage),
              const SizedBox(height: 8),
              MoodMedicineTrendChart(
                points: points,
                emptyLabel: l10n.moodMedicineNoEntries,
                semanticSummary: l10n.moodMedicineTrendSummary(
                  _rangeLabel(l10n),
                  _trendSummary(summaries),
                ),
                highlightedActivityId: _highlightedActivityId,
              ),
              if (points.length == 1)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(l10n.moodMedicineOneEntry),
                ),
              if (points.isNotEmpty) ...<Widget>[
                const SizedBox(height: 8),
                Text(
                  l10n.moodMedicineActivitiesOverlay,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: overlayActivityIds
                      .map(
                        (String activityId) => ChoiceChip(
                          selected: _highlightedActivityId == activityId,
                          label: Text(
                            _rangeActivityLabel(l10n, activityId, summaries),
                          ),
                          onSelected: (bool selected) => setState(
                            () => _highlightedActivityId = selected
                                ? activityId
                                : null,
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
              const SizedBox(height: 8),
              Text(l10n.moodMedicineAssociationExplanation),
              const SizedBox(height: 10),
              if (associations.isEmpty)
                Text(l10n.moodMedicineAssociationUnavailable)
              else
                ...associations.map(
                  (MoodMedicineAssociation item) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Semantics(
                      label: l10n.moodMedicineAssociationSummary(
                        _rangeActivityLabel(l10n, item.activityId, summaries),
                        item.withActivityAverageMood.toStringAsFixed(1),
                        item.withoutActivityAverageMood.toStringAsFixed(1),
                      ),
                      child: ExcludeSemantics(
                        child: Text(
                          l10n.moodMedicineAssociationSummary(
                            _rangeActivityLabel(
                              l10n,
                              item.activityId,
                              summaries,
                            ),
                            item.withActivityAverageMood.toStringAsFixed(1),
                            item.withoutActivityAverageMood.toStringAsFixed(1),
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
          spacing: 10,
          runSpacing: 10,
          children: <Widget>[
            FilledButton.icon(
              key: const Key('moodMedicineManualCheckIn'),
              onPressed: _startCheckIn,
              icon: const Icon(Icons.add),
              label: Text(l10n.moodMedicineQuickCheckIn),
            ),
            OutlinedButton.icon(
              key: const Key('moodMedicineExportButton'),
              onPressed: () => _showExportSheet(summaries),
              icon: const Icon(Icons.ios_share_outlined),
              label: Text(l10n.moodMedicineExport),
            ),
            TextButton.icon(
              key: const Key('moodMedicineEducationButton'),
              onPressed: () =>
                  setState(() => _view = MoodMedicineInitialView.education),
              icon: const Icon(Icons.menu_book_outlined),
              label: Text(l10n.moodMedicineEducation),
            ),
          ],
        ),
      ],
    );
  }

  String _rangeName(AppLocalizations l10n, MoodMedicineInsightRange range) {
    return switch (range) {
      MoodMedicineInsightRange.day => l10n.moodMedicineToday,
      MoodMedicineInsightRange.week => l10n.moodMedicineWeek,
      MoodMedicineInsightRange.month => l10n.moodMedicineMonth,
      MoodMedicineInsightRange.year => l10n.moodMedicineYear,
    };
  }

  Future<void> _showExportSheet(
    List<MoodMedicineDailySummary> summaries,
  ) async {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    bool includeNotes = false;
    MoodMedicineReportFormat selectedFormat = MoodMedicineReportFormat.pdf;
    bool exporting = false;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext sheetContext) => StatefulBuilder(
        builder: (BuildContext context, StateSetter setSheetState) {
          Future<void> export() async {
            setSheetState(() => exporting = true);
            try {
              final MoodMedicineReportInput report = _buildReportInput(
                l10n,
                summaries,
                includeNotes: includeNotes,
              );
              final MoodMedicineReportDelivery delivery =
                  await MoodMedicineReportExporter().export(
                    report,
                    selectedFormat,
                    shareText: l10n.moodMedicineExportReportTitle,
                  );
              if (!sheetContext.mounted) {
                return;
              }
              if (delivery.didDeliver) {
                Navigator.of(sheetContext).pop();
              } else {
                setSheetState(() => exporting = false);
                ScaffoldMessenger.of(sheetContext).showSnackBar(
                  SnackBar(content: Text(l10n.moodMedicineExportError)),
                );
              }
            } catch (_) {
              if (!sheetContext.mounted) {
                return;
              }
              setSheetState(() => exporting = false);
              ScaffoldMessenger.of(sheetContext).showSnackBar(
                SnackBar(content: Text(l10n.moodMedicineExportError)),
              );
            }
          }

          return SafeArea(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                24,
                24,
                24,
                24 + MediaQuery.viewInsetsOf(context).bottom,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    l10n.moodMedicineExport,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  Text('${l10n.moodMedicineExportRange}: ${_rangeLabel(l10n)}'),
                  const SizedBox(height: 12),
                  SegmentedButton<MoodMedicineReportFormat>(
                    segments: <ButtonSegment<MoodMedicineReportFormat>>[
                      ButtonSegment<MoodMedicineReportFormat>(
                        value: MoodMedicineReportFormat.pdf,
                        label: Text(l10n.moodMedicineExportPdf),
                        icon: const Icon(Icons.picture_as_pdf_outlined),
                      ),
                      ButtonSegment<MoodMedicineReportFormat>(
                        value: MoodMedicineReportFormat.png,
                        label: Text(l10n.moodMedicineExportPng),
                        icon: const Icon(Icons.image_outlined),
                      ),
                    ],
                    selected: <MoodMedicineReportFormat>{selectedFormat},
                    onSelectionChanged: exporting
                        ? null
                        : (Set<MoodMedicineReportFormat> selection) {
                            setSheetState(
                              () => selectedFormat = selection.first,
                            );
                          },
                  ),
                  const SizedBox(height: 10),
                  SwitchListTile.adaptive(
                    key: const Key('moodMedicineIncludeNotes'),
                    contentPadding: EdgeInsets.zero,
                    value: includeNotes,
                    onChanged: exporting
                        ? null
                        : (bool value) =>
                              setSheetState(() => includeNotes = value),
                    title: Text(l10n.moodMedicineIncludeNotes),
                    subtitle: Text(l10n.moodMedicineNotesPrivacy),
                  ),
                  if (!includeNotes)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        l10n.moodMedicineNotesExcluded,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    key: const Key('moodMedicineStartExport'),
                    onPressed: exporting ? null : export,
                    icon: exporting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.ios_share_outlined),
                    label: Text(
                      exporting
                          ? l10n.moodMedicinePreparingExport
                          : l10n.moodMedicineShare,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  MoodMedicineReportInput _buildReportInput(
    AppLocalizations l10n,
    List<MoodMedicineDailySummary> summaries, {
    required bool includeNotes,
  }) {
    final List<MoodMedicineReportDay> days = summaries
        .map((MoodMedicineDailySummary summary) {
          final List<MoodMedicineEntry> entries = _controller.entries
              .where(
                (MoodMedicineEntry entry) =>
                    entry.localDayKey == summary.dayKey,
              )
              .toList(growable: false);
          return MoodMedicineReportDay(
            dayLabel: summary.dayKey,
            moodAverage: summary.averageMood,
            activities: summary.activityIds
                .map((String id) => _activityLabelForDay(l10n, summary, id))
                .toList(growable: false),
            note: entries
                .where((MoodMedicineEntry entry) => entry.note != null)
                .map((MoodMedicineEntry entry) => entry.note!)
                .join('\n'),
          );
        })
        .toList(growable: false);
    final List<MoodMedicineAssociation> associations =
        MoodMedicineInsights.associations(summaries);
    final Map<String, MoodMedicineActivityContent> sources =
        <String, MoodMedicineActivityContent>{
          for (final MoodMedicineActivityContent activity in _activities(l10n))
            activity.sourceUri.toString(): activity,
        };
    return MoodMedicineReportInput(
      title: l10n.moodMedicineExportReportTitle,
      dateRangeLabel: _rangeLabel(l10n),
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
      days: days,
      associations: associations
          .map(
            (MoodMedicineAssociation item) => MoodMedicineReportAssociation(
              activityLabel: _rangeActivityLabel(
                l10n,
                item.activityId,
                summaries,
              ),
              withActivityMoodAverage: item.withActivityAverageMood,
              withoutActivityMoodAverage: item.withoutActivityAverageMood,
            ),
          )
          .toList(growable: false),
      sources: sources.values
          .map(
            (MoodMedicineActivityContent item) => MoodMedicineReportSource(
              title: item.sourceLabel,
              url: item.sourceUri,
            ),
          )
          .toList(growable: false),
      textDirection: Directionality.of(context),
      includeNotes: includeNotes,
    );
  }

  Widget _buildEducation(AppLocalizations l10n) {
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
                setState(() => _view = MoodMedicineInitialView.insights),
            icon: const Icon(Icons.insights_outlined),
          ),
        ),
        const SizedBox(height: 16),
        _FeatureCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                l10n.moodMedicineEducationDoseTitle,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(l10n.moodMedicineEducationDoseIntro),
              const SizedBox(height: 12),
              LayoutBuilder(
                builder: (BuildContext context, BoxConstraints constraints) {
                  final bool useOneColumn = constraints.maxWidth < 560;
                  final double cardWidth = useOneColumn
                      ? constraints.maxWidth
                      : (constraints.maxWidth - 8) / 2;
                  return Wrap(
                    key: const Key('moodMedicineDoseItems'),
                    spacing: 8,
                    runSpacing: 8,
                    children: doseItems
                        .map(
                          (MoodMedicineDoseContent item) => SizedBox(
                            width: cardWidth,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                color: Theme.of(
                                  context,
                                ).colorScheme.secondary.withValues(alpha: 0.32),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(10),
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
                                    const SizedBox(height: 4),
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
                onPressed: () => launchUrl(
                  selfCareSource.sourceUri,
                  mode: LaunchMode.externalApplication,
                  webOnlyWindowName: '_blank',
                ),
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
              const SizedBox(height: 10),
              AspectRatio(
                aspectRatio: 16 / 9,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          const Icon(Icons.play_circle_outline, size: 42),
                          const SizedBox(height: 8),
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

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<MoodMedicineController>.value(
      value: _controller,
      child: Consumer<MoodMedicineController>(
        builder: (BuildContext context, MoodMedicineController controller, _) {
          final AppLocalizations l10n = AppLocalizations.of(context)!;
          if (!controller.isLoaded) {
            return Scaffold(
              appBar: AppBar(title: Text(l10n.moodMedicineTitle)),
              body: Center(
                child: controller.isLoading
                    ? Semantics(
                        label: l10n.moodMedicineLoading,
                        child: const CircularProgressIndicator(),
                      )
                    : FilledButton(
                        onPressed: _load,
                        child: Text(l10n.moodMedicineRetry),
                      ),
              ),
            );
          }
          return Scaffold(
            appBar: AppBar(
              title: Text(l10n.moodMedicineTitle),
              actions: <Widget>[
                IconButton(
                  tooltip: l10n.moodMedicineQuickCheckIn,
                  onPressed: _startCheckIn,
                  icon: const Icon(Icons.add_chart_rounded),
                ),
              ],
            ),
            body: SafeArea(
              child: switch (_view) {
                MoodMedicineInitialView.checkIn => _buildCheckIn(l10n),
                MoodMedicineInitialView.insights => _buildInsights(l10n),
                MoodMedicineInitialView.education => _buildEducation(l10n),
              },
            ),
          );
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
    required this.onSave,
    required this.onSaveFailed,
  });

  final MoodMedicineCustomActivity? activity;
  final AppLocalizations l10n;
  final Future<bool> Function(String label) onSave;
  final VoidCallback onSaveFailed;

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
      saved = await widget.onSave(label);
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
    widget.onSaveFailed();
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
      content: TextField(
        controller: _nameController,
        autofocus: true,
        textInputAction: TextInputAction.done,
        decoration: InputDecoration(
          labelText: l10n.moodMedicineActivityName,
          hintText: l10n.moodMedicineActivityNameHint,
          errorText: _validationError,
        ),
        onSubmitted: (_) => _save(),
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

class _FeatureCard extends StatelessWidget {
  const _FeatureCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(padding: const EdgeInsets.all(16), child: child),
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
              const SizedBox(height: 4),
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
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            ...children,
          ],
        ),
      ),
    );
  }
}
