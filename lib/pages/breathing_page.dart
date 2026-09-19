import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:intl/intl.dart' show DateFormat;
import 'package:mazilon/features/remember_to_breathe/data/breathing_models.dart';
import 'package:mazilon/features/remember_to_breathe/ui/breathing_view_model.dart';
import 'package:mazilon/features/remember_to_breathe/ui/breathing_view_state.dart';
import 'package:mazilon/features/remember_to_breathe/ui/breathing_widgets.dart';
import 'package:mazilon/l10n/app_localizations.dart';
import 'package:mazilon/design_system/tokens/spacing.dart';

/// The breathing visit, hosted inside Menu so emergency access stays available.
class BreathingPage extends StatefulWidget {
  const BreathingPage({super.key, required this.viewModel});

  /// This page owns and disposes its factory-created model.
  final BreathingViewModel viewModel;

  @override
  State<BreathingPage> createState() => _BreathingPageState();
}

class _BreathingPageState extends State<BreathingPage>
    with WidgetsBindingObserver {
  int? _beforeRating;
  int? _measurementPointer;
  Offset? _measurementOrigin;
  bool _confirmDiscard = false;
  bool _showControls = true;
  BreathingScreen? _previousScreen;

  BreathingViewModel get _model => widget.viewModel;
  AppLocalizations get _strings => AppLocalizations.of(context)!;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _model.addListener(_screenChanged);
    unawaited(_model.load());
  }

  void _screenChanged() {
    if (_previousScreen != _model.screen) {
      _beforeRating = null;
      _measurementPointer = null;
      _showControls = true;
      _previousScreen = _model.screen;
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) {
      _measurementPointer = null;
      _model.cancelDurationMeasurement();
      _model.handleAppInactive();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _model.removeListener(_screenChanged);
    _model.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _model,
      builder: (context, _) => SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                  child: Row(
                    children: [
                      if (_model.isReady &&
                          _model.screen != BreathingScreen.landing)
                        IconButton(
                          key: const Key('breathingBack'),
                          tooltip: _strings.breathingBack,
                          onPressed: () => _model.handleBack(),
                          icon: const Icon(Icons.arrow_back),
                        ),
                      Expanded(
                        child: Text(
                          _strings.breathingTitle,
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(child: _body()),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _body() {
    if (_model.isLoading) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: AppSpacing.lg),
            Text(_strings.breathingLoading),
          ],
        ),
      );
    }
    if (!_model.isReady) {
      return _recovery();
    }
    return switch (_model.screen) {
      BreathingScreen.landing => _landing(),
      BreathingScreen.info => _info(),
      BreathingScreen.customize => _customize(),
      BreathingScreen.preRating => _rating(isResult: false),
      BreathingScreen.practice => _practice(),
      BreathingScreen.result => _rating(isResult: true),
      BreathingScreen.history => _history(),
    };
  }

  Widget _scroll(List<Widget> children) => ListView(
    key: ValueKey('breathingScreen${_model.screen.name}'),
    padding: const EdgeInsets.only(bottom: 96),
    children: [
      for (final child in children)
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.lg),
          child: child,
        ),
    ],
  );

  Widget _landing() => _scroll([
    ClipRRect(
      borderRadius: BorderRadius.circular(AppRadii.card),
      child: SizedBox(
        height: 150,
        child: BreathingBackgroundImage(settings: _model.settings),
      ),
    ),
    Text(_strings.breathingIntro),
    FilledButton.icon(
      key: const Key('breathingQuickStart'),
      onPressed: _model.quickStart,
      iconAlignment: Directionality.of(context) == TextDirection.rtl
          ? IconAlignment.end
          : IconAlignment.start,
      icon: Transform.flip(
        flipX: Directionality.of(context) == TextDirection.rtl,
        child: const Icon(Icons.play_arrow),
      ),
      label: Text(_strings.breathingQuickStart),
    ),
    Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        for (final pattern in BreathingPattern.values)
          ChoiceChip(
            key: Key('breathingPattern${pattern.name}'),
            label: Text(breathingPatternLabel(_strings, pattern)),
            selected: _model.selectedPattern == pattern,
            onSelected: (_) => _model.selectPattern(pattern),
          ),
      ],
    ),
    OutlinedButton(
      key: const Key('breathingStartSelected'),
      onPressed: _model.preparePractice,
      child: Text(_strings.breathingStart),
    ),
    Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        OutlinedButton.icon(
          key: const Key('breathingCustomize'),
          onPressed: _model.openCustomization,
          icon: const Icon(Icons.tune),
          label: Text(_strings.breathingCustomize),
        ),
        OutlinedButton.icon(
          key: const Key('breathingHistory'),
          onPressed: _model.showHistory,
          icon: const Icon(Icons.history),
          label: Text(_strings.breathingHistory),
        ),
        TextButton.icon(
          key: const Key('breathingInfo'),
          onPressed: _model.showInfo,
          icon: const Icon(Icons.info_outline),
          label: Text(_strings.breathingInfo),
        ),
      ],
    ),
    Text(_strings.breathingExplanation),
    Text(_strings.breathingGuidance),
    Text(
      _strings.breathingCredits,
      style: Theme.of(context).textTheme.bodySmall,
    ),
  ]);

  Widget _info() => _scroll([
    Text(_strings.breathingInfo, style: Theme.of(context).textTheme.titleLarge),
    Text(_strings.breathingExplanation),
    Text(_strings.breathingGuidance),
    Text(_strings.breathingCredits),
  ]);

  Widget _recovery() => _scroll([
    Text(
      _strings.breathingRecoveryTitle,
      style: Theme.of(context).textTheme.titleLarge,
    ),
    Text(_strings.breathingRecoveryBody),
    FilledButton(
      key: const Key('breathingRetryLoad'),
      onPressed: () => unawaited(_model.load()),
      child: Text(_strings.breathingRetry),
    ),
    if (_model.canDiscardUnreadable && !_confirmDiscard)
      TextButton(
        key: const Key('breathingDiscard'),
        onPressed: () => setState(() => _confirmDiscard = true),
        child: Text(_strings.breathingDiscard),
      ),
    if (_confirmDiscard) ...[
      Text(_strings.breathingDiscardConfirm),
      FilledButton(
        key: const Key('breathingConfirmDiscard'),
        onPressed: () {
          setState(() => _confirmDiscard = false);
          unawaited(_model.discardUnreadableSnapshot());
        },
        child: Text(_strings.breathingDiscard),
      ),
      TextButton(
        onPressed: () => setState(() => _confirmDiscard = false),
        child: Text(_strings.breathingCancel),
      ),
    ],
  ]);

  Widget _customize() {
    final step = _model.customizationStep;
    return _scroll([
      Text(_strings.breathingStep(step + 1)),
      LinearProgressIndicator(value: (step + 1) / 3),
      if (step == 0) _backgroundChoices() else _durationStep(step == 1),
      if (_model.error != null) Text(_strings.breathingError),
      if (_model.isSaving || _model.isImporting)
        const LinearProgressIndicator(),
      Wrap(
        spacing: AppSpacing.sm,
        runSpacing: AppSpacing.sm,
        children: [
          FilledButton(
            key: const Key('breathingNextStep'),
            onPressed:
                _model.isSaving || _model.isImporting || _model.isMeasuring
                ? null
                : () => unawaited(_model.nextCustomizationStep()),
            child: Text(
              step == 2 ? _strings.breathingSave : _strings.breathingNext,
            ),
          ),
          TextButton(
            key: const Key('breathingSkipStep'),
            onPressed: _model.isSaving || _model.isImporting
                ? null
                : () => unawaited(_model.skipCustomizationStep()),
            child: Text(_strings.breathingSkip),
          ),
        ],
      ),
    ]);
  }

  Widget _backgroundChoices() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        _strings.breathingBackground,
        style: Theme.of(context).textTheme.titleLarge,
      ),
      const SizedBox(height: AppSpacing.lg),
      ClipRRect(
        borderRadius: BorderRadius.circular(AppRadii.card),
        child: SizedBox(
          height: 180,
          width: double.infinity,
          child: BreathingBackgroundImage(settings: _model.draftSettings),
        ),
      ),
      const SizedBox(height: AppSpacing.sm),
      Wrap(
        spacing: AppSpacing.sm,
        runSpacing: AppSpacing.sm,
        children: [
          for (final background in BreathingBackground.values)
            if (background != BreathingBackground.personal ||
                _model.draftSettings.personalPhotoBase64 != null)
              ChoiceChip(
                key: Key('breathingBackground${background.name}'),
                label: Text(breathingBackgroundLabel(_strings, background)),
                selected: _model.draftSettings.background == background,
                onSelected: _model.isImporting || _model.isSaving
                    ? null
                    : (_) => _model.setBackground(background),
              ),
        ],
      ),
      const SizedBox(height: AppSpacing.sm),
      OutlinedButton.icon(
        key: const Key('breathingChoosePhoto'),
        onPressed: _model.isImporting || _model.isSaving
            ? null
            : () => unawaited(_model.importPhoto()),
        icon: const Icon(Icons.photo_outlined),
        label: Text(_strings.breathingChoosePhoto),
      ),
      Text(_strings.breathingPhotoLocal),
    ],
  );

  Widget _durationStep(bool inhale) {
    return Column(
      children: [
        AnimatedBuilder(
          animation: _model.progressChanges,
          builder: (context, _) => BreathingDurationButtons(
            duration: _model.isMeasuring
                ? _model.measuredDuration
                : inhale
                ? _model.draftSettings.inhaleDuration
                : _model.draftSettings.exhaleDuration,
            label: inhale
                ? _strings.breathingInhaleDuration
                : _strings.breathingExhaleDuration,
            onAdjust: (delta) =>
                _model.adjustDuration(inhale: inhale, delta: delta),
            keyPrefix: inhale ? 'breathingInhale' : 'breathingExhale',
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(_strings.breathingMeasureHint),
        const SizedBox(height: AppSpacing.lg),
        Listener(
          key: const Key('breathingMeasure'),
          onPointerDown: (event) {
            if (_measurementPointer != null || _model.isSaving) return;
            _measurementPointer = event.pointer;
            _measurementOrigin = event.position;
            _model.beginDurationMeasurement(inhale: inhale);
          },
          onPointerMove: (event) {
            if (_measurementPointer == event.pointer &&
                _measurementOrigin != null &&
                (event.position - _measurementOrigin!).distance > kTouchSlop) {
              _measurementPointer = null;
              _measurementOrigin = null;
              _model.cancelDurationMeasurement();
            }
          },
          onPointerUp: (event) {
            if (_measurementPointer != event.pointer) return;
            _measurementPointer = null;
            _measurementOrigin = null;
            _model.finishDurationMeasurement();
          },
          onPointerCancel: (event) {
            if (_measurementPointer != event.pointer) return;
            _measurementPointer = null;
            _measurementOrigin = null;
            _model.cancelDurationMeasurement();
          },
          child: Semantics(
            label: _strings.breathingMeasure,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(AppRadii.card),
              ),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xxl),
                child: SizedBox(
                  width: double.infinity,
                  child: Text(
                    _strings.breathingMeasure,
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _rating({required bool isResult}) {
    final result = _model.result;
    return _scroll([
      Text(
        isResult
            ? result!.isComplete
                  ? _strings.breathingCompleteMessage
                  : _strings.breathingStoppedMessage
            : _strings.breathingPreMessage,
        style: Theme.of(context).textTheme.titleLarge,
      ),
      if (isResult)
        Text(_strings.breathingCompletedCycles(result!.completedCycles)),
      BreathingRatingInput(
        key: ValueKey(isResult ? result!.id : 'preRating'),
        value: isResult ? result!.stressAfter : _beforeRating,
        keyPrefix: isResult ? 'breathingAfter' : 'breathingBefore',
        onChanged: (value) {
          if (isResult) {
            unawaited(_model.updateAfterRating(value));
          } else {
            setState(() => _beforeRating = value);
          }
        },
      ),
      if (isResult) ...[
        if (_model.isSaving) const LinearProgressIndicator(),
        if (_model.error != null) ...[
          Text(_strings.breathingSaveFailed),
          FilledButton(
            key: const Key('breathingRetrySave'),
            onPressed: _model.isSaving
                ? null
                : () => unawaited(_model.retryResultSave()),
            child: Text(_strings.breathingRetry),
          ),
        ],
        FilledButton(
          key: const Key('breathingDone'),
          onPressed: _model.isSaving || _model.hasUnsavedResult
              ? null
              : () => _model.returnToLanding(),
          child: Text(_strings.breathingDone),
        ),
        if (_model.hasUnsavedResult && !_model.isSaving)
          TextButton(
            key: const Key('breathingLeaveWithoutSaving'),
            onPressed: _model.leaveWithoutSaving,
            child: Text(_strings.breathingLeaveWithoutSaving),
          ),
      ] else ...[
        FilledButton(
          key: const Key('breathingStartRated'),
          onPressed: _beforeRating == null
              ? null
              : () => _model.startPractice(_beforeRating),
          child: Text(_strings.breathingStart),
        ),
        TextButton(
          key: const Key('breathingSkipRating'),
          onPressed: () => _model.startPractice(null),
          child: Text(_strings.breathingSkip),
        ),
      ],
    ]);
  }

  Widget _practice() {
    final phase = _model.phase;
    final phaseLabel = switch (phase) {
      BreathingPhase.inhale => _strings.breathingInhale,
      BreathingPhase.exhale => _strings.breathingExhale,
      _ => _strings.breathingHold,
    };
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadii.card),
      child: Stack(
        fit: StackFit.expand,
        children: [
          BreathingBackgroundImage(settings: _model.settings),
          // A fixed dark scrim keeps white cues readable on personal photos too.
          const ColoredBox(color: Color(0xB3000000)),
          DefaultTextStyle.merge(
            style: const TextStyle(color: Colors.white),
            child: IconTheme(
              data: const IconThemeData(color: Colors.white),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                child: Column(
                  children: [
                    Text(
                      _strings.breathingCycle(
                        (_model.completedCycles + 1).clamp(1, 8),
                      ),
                      key: const Key('breathingCycle'),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    if (_model.isPaused) ...[
                      Text(_strings.breathingPaused),
                      const SizedBox(height: AppSpacing.lg),
                      Wrap(
                        spacing: AppSpacing.sm,
                        runSpacing: AppSpacing.sm,
                        alignment: WrapAlignment.center,
                        children: [
                          FilledButton(
                            key: const Key('breathingContinue'),
                            onPressed: _model.resume,
                            child: Text(_strings.breathingContinue),
                          ),
                          FilledButton.tonal(
                            key: const Key('breathingRestart'),
                            onPressed: _model.restart,
                            child: Text(_strings.breathingRestart),
                          ),
                          FilledButton.tonal(
                            key: const Key('breathingEnd'),
                            onPressed: _model.end,
                            child: Text(_strings.breathingEnd),
                          ),
                        ],
                      ),
                    ] else
                      FilledButton.icon(
                        key: const Key('breathingPause'),
                        onPressed: _model.pause,
                        icon: const Icon(Icons.pause),
                        label: Text(_strings.breathingPause),
                      ),
                    const SizedBox(height: AppSpacing.lg),
                    if (_model.settings.showCircle)
                      ExcludeSemantics(
                        child: SizedBox(
                          width: 200,
                          height: 200,
                          child: Center(
                            child: AnimatedBuilder(
                              animation: _model.progressChanges,
                              builder: (context, child) {
                                final expansion = switch (_model.phase) {
                                  BreathingPhase.inhale => _model.phaseProgress,
                                  BreathingPhase.exhale =>
                                    1 - _model.phaseProgress,
                                  BreathingPhase.holdInhale => 1.0,
                                  BreathingPhase.holdExhale => 0.0,
                                };
                                return Transform.scale(
                                  key: const Key('breathingCircle'),
                                  scale: 0.45 + 0.55 * expansion,
                                  child: child,
                                );
                              },
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white.withValues(alpha: 0.35),
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 2,
                                  ),
                                ),
                                child: const SizedBox.expand(),
                              ),
                            ),
                          ),
                        ),
                      ),
                    if (_model.settings.showText)
                      Semantics(
                        liveRegion: true,
                        child: Text(
                          phaseLabel,
                          key: const Key('breathingPhase'),
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    const SizedBox(height: AppSpacing.lg),
                    IconButton(
                      key: const Key('breathingToggleControls'),
                      color: Colors.white,
                      tooltip: _showControls
                          ? _strings.breathingHideControls
                          : _strings.breathingShowControls,
                      onPressed: () =>
                          setState(() => _showControls = !_showControls),
                      icon: Icon(
                        _showControls ? Icons.expand_less : Icons.tune,
                      ),
                    ),
                    if (_showControls) ...[
                      Wrap(
                        alignment: WrapAlignment.center,
                        spacing: AppSpacing.lg,
                        children: [
                          IconButton(
                            key: const Key('breathingToggleCircle'),
                            color: Colors.white,
                            tooltip: _model.settings.showCircle
                                ? _strings.breathingHideCircle
                                : _strings.breathingShowCircle,
                            onPressed: _model.toggleCircle,
                            icon: Icon(
                              _model.settings.showCircle
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                            ),
                          ),
                          IconButton(
                            key: const Key('breathingToggleText'),
                            color: Colors.white,
                            tooltip: _model.settings.showText
                                ? _strings.breathingHideText
                                : _strings.breathingShowText,
                            onPressed: _model.toggleText,
                            icon: const Icon(Icons.closed_caption_outlined),
                          ),
                        ],
                      ),
                      if (_model.selectedPattern == BreathingPattern.custom)
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(AppSpacing.sm),
                            child: Column(
                              children: [
                                for (final inhale in [true, false])
                                  BreathingDurationButtons(
                                    duration: inhale
                                        ? _model.settings.inhaleDuration
                                        : _model.settings.exhaleDuration,
                                    label: inhale
                                        ? _strings.breathingInhaleDuration
                                        : _strings.breathingExhaleDuration,
                                    onAdjust: (delta) => _model.adjustDuration(
                                      inhale: inhale,
                                      delta: delta,
                                    ),
                                    keyPrefix: inhale
                                        ? 'breathingLiveInhale'
                                        : 'breathingLiveExhale',
                                  ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _history() => _scroll([
    Text(
      _strings.breathingHistory,
      style: Theme.of(context).textTheme.titleLarge,
    ),
    if (_model.history.isEmpty) Text(_strings.breathingHistoryEmpty),
    for (final session in _model.history)
      Card(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                DateFormat.yMMMd(
                  _strings.localeName,
                ).add_Hm().format(session.startedAt.toLocal()),
              ),
              Text(breathingPatternLabel(_strings, session.pattern)),
              Text(_strings.breathingCompletedCycles(session.completedCycles)),
              Text(
                session.isComplete
                    ? _strings.breathingCompleted
                    : _strings.breathingStopped,
              ),
              const SizedBox(height: AppSpacing.sm),
              _stressComparison(_strings.breathingBefore, session.stressBefore),
              _stressComparison(_strings.breathingAfter, session.stressAfter),
            ],
          ),
        ),
      ),
  ]);

  Widget _stressComparison(String label, int? value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$label: ${value == null ? _strings.breathingNoRating : '$value / 10'}',
        ),
        if (value != null)
          LinearProgressIndicator(value: value / 10, semanticsLabel: label),
      ],
    ),
  );
}
