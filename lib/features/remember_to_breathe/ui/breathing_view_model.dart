import 'dart:async';
import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import 'package:mazilon/features/remember_to_breathe/data/breathing_models.dart';
import 'package:mazilon/features/remember_to_breathe/data/breathing_photo_importer.dart';
import 'package:mazilon/features/remember_to_breathe/data/breathing_repository.dart';
import 'package:mazilon/features/remember_to_breathe/ui/breathing_view_state.dart';

/// Owns one breathing visit, including its monotonic practice clock and drafts.
///
/// Breathing rules stay independent of rendering. Persistence and photo decoding
/// remain in their existing, approved feature-local collaborators.
final class BreathingViewModel extends ChangeNotifier {
  BreathingViewModel(
    this._repository, {
    required BreathingPhotoImporter photoImporter,
    Duration Function()? monotonicElapsed,
    DateTime Function()? now,
    String Function()? sessionId,
  }) : // Preserve the public injection name while keeping the field private.
       // ignore: prefer_initializing_formals
       _photoImporter = photoImporter,
       _injectedElapsed = monotonicElapsed,
       _now = now ?? DateTime.now,
       _sessionId = sessionId ?? const Uuid().v4 {
    _stopwatch.start();
  }

  final BreathingRepository _repository;
  final BreathingPhotoImporter _photoImporter;
  final Duration Function()? _injectedElapsed;
  final DateTime Function() _now;
  final String Function() _sessionId;
  final Stopwatch _stopwatch = Stopwatch();
  Timer? _timer;
  bool _disposed = false;
  bool _departed = false;
  bool _isReady = false;
  bool _isLoading = false;
  bool _isSavingSettings = false;
  bool _isSavingResult = false;
  bool _isImporting = false;
  bool _canDiscardUnreadable = false;
  Object? _error;
  int _navigationGeneration = 0;
  int _settingsGeneration = 0;
  bool _practiceSettingsDirty = false;
  BreathingScreen _screen = BreathingScreen.landing;
  BreathingSettings _settings = const BreathingSettings();
  BreathingSettings _draftSettings = const BreathingSettings();
  List<BreathingSession> _history = [];
  BreathingPattern _selectedPattern = BreathingPattern.basic;
  int _customizationStep = 0;
  bool? _measuringInhale;
  Duration _measurementStarted = Duration.zero;
  Duration _measuredDuration = Duration.zero;
  BreathingPhase _phase = BreathingPhase.inhale;
  Duration _phaseElapsed = Duration.zero;
  Duration _phaseDuration = const Duration(seconds: 3);
  Duration _lastRefresh = Duration.zero;
  int _completedCycles = 0;
  bool _isPaused = false;
  String? _attemptId;
  DateTime? _startedAt;
  int? _stressBefore;
  BreathingSession? _result;
  int _savedResultRevision = -1;
  Future<void>? _resultSaveFuture;

  bool get _active => !_disposed && !_departed;
  Duration get _elapsed => _injectedElapsed?.call() ?? _stopwatch.elapsed;

  BreathingScreen get screen => _screen;
  bool get isReady => _isReady;
  bool get isLoading => _isLoading;
  bool get isSaving => _isSavingSettings || _isSavingResult;
  bool get isImporting => _isImporting;
  bool get canDiscardUnreadable => _canDiscardUnreadable;
  Object? get error => _error;
  BreathingSettings get settings => _settings;
  BreathingSettings get draftSettings => _draftSettings;
  List<BreathingSession> get history => UnmodifiableListView(_history);
  BreathingPattern get selectedPattern => _selectedPattern;
  int get customizationStep => _customizationStep;
  BreathingPhase get phase => _phase;
  double get phaseProgress =>
      (_phaseElapsed.inMicroseconds / _phaseDuration.inMicroseconds).clamp(
        0.0,
        1.0,
      );
  int get completedCycles => _completedCycles;
  bool get isPaused => _isPaused;
  bool get isMeasuring => _measuringInhale != null;
  Duration get measuredDuration => _measuredDuration;
  BreathingSession? get result => _result;
  bool get requiresFullscreen =>
      _screen == BreathingScreen.practice || _screen == BreathingScreen.result;
  bool get hasUnsavedResult =>
      _result != null && _savedResultRevision < _result!.revision;

  /// Loads data without replacing an unreadable snapshot.
  Future<void> load() async {
    if (!_active || _isLoading || _isReady) {
      return;
    }
    _isLoading = true;
    _error = null;
    _notify();
    try {
      final snapshot = await _repository.load();
      if (!_active) {
        return;
      }
      _acceptSnapshot(snapshot);
      _isReady = true;
      _canDiscardUnreadable = false;
    } catch (error) {
      if (!_active) {
        return;
      }
      _recordLoadFailure(error);
    } finally {
      if (_active) {
        _isLoading = false;
        _notify();
      }
    }
  }

  /// Performs the explicitly confirmed recovery of this feature's snapshot.
  Future<void> discardUnreadableSnapshot() async {
    if (!_active || !_canDiscardUnreadable || _isLoading) {
      return;
    }
    _isLoading = true;
    _error = null;
    _notify();
    try {
      final snapshot = await _repository.discardUnreadableSnapshot();
      if (!_active) {
        return;
      }
      _acceptSnapshot(snapshot);
      _isReady = true;
      _canDiscardUnreadable = false;
    } catch (error) {
      if (_active) {
        _recordLoadFailure(error);
      }
    } finally {
      if (_active) {
        _isLoading = false;
        _notify();
      }
    }
  }

  void _recordLoadFailure(Object error) {
    _error = error;
    _isReady = false;
    _canDiscardUnreadable =
        error is BreathingStorageException && error.canDiscard;
  }

  void _acceptSnapshot(BreathingSnapshot snapshot) {
    _settings = snapshot.settings;
    _draftSettings = _settings;
    _setHistory(snapshot.sessions);
  }

  void _setHistory(List<BreathingSession> sessions) {
    _history = List.of(sessions)
      ..sort((first, second) {
        final byTime = second.startedAt.compareTo(first.startedAt);
        return byTime == 0 ? first.id.compareTo(second.id) : byTime;
      });
  }

  void selectPattern(BreathingPattern pattern) {
    if (!_canNavigate) {
      return;
    }
    _selectedPattern = pattern;
    _notify();
  }

  bool get _canNavigate =>
      _active &&
      _isReady &&
      !isSaving &&
      !hasUnsavedResult &&
      _screen != BreathingScreen.practice;

  void quickStart() {
    if (!_canNavigate) {
      return;
    }
    _selectedPattern = BreathingPattern.basic;
    preparePractice();
  }

  void preparePractice() {
    if (!_canNavigate) {
      return;
    }
    _changeScreen(BreathingScreen.preRating);
  }

  /// Starts an attempt; skipping the rating deliberately stores null.
  void startPractice(int? stressBefore) {
    if (!_canNavigate) {
      return;
    }
    _validateRating(stressBefore);
    _stressBefore = stressBefore;
    _startAttempt();
  }

  void _startAttempt() {
    _attemptId = _sessionId();
    _startedAt = _now();
    _result = null;
    _savedResultRevision = -1;
    _completedCycles = 0;
    _phase = BreathingPhase.inhale;
    _phaseElapsed = Duration.zero;
    _phaseDuration = _durationFor(_phase);
    _isPaused = false;
    _error = null;
    _lastRefresh = _elapsed;
    _changeScreen(BreathingScreen.practice);
    _updateTimer();
  }

  void openCustomization() {
    if (!_canNavigate) {
      return;
    }
    _draftSettings = _settings;
    _customizationStep = 0;
    _changeScreen(BreathingScreen.customize);
  }

  void setBackground(BreathingBackground background) {
    if (!_canCustomize) {
      return;
    }
    if (background == BreathingBackground.personal &&
        _draftSettings.personalPhotoBase64 == null) {
      return;
    }
    _draftSettings = _draftSettings.copyWith(background: background);
    _notify();
  }

  bool get _canCustomize =>
      _active && _screen == BreathingScreen.customize && !isSaving;

  Future<void> importPhoto() async {
    if (!_canCustomize || _isImporting) {
      return;
    }
    final generation = _navigationGeneration;
    _isImporting = true;
    _error = null;
    _notify();
    try {
      final photo = await _photoImporter.pickPhoto();
      if (!_active || generation != _navigationGeneration) {
        return;
      }
      if (photo != null) {
        _draftSettings = _draftSettings.copyWith(
          background: BreathingBackground.personal,
          personalPhotoBase64: photo,
        );
      }
    } catch (error) {
      if (_active && generation == _navigationGeneration) {
        _error = error;
      }
    } finally {
      if (_active && generation == _navigationGeneration) {
        _isImporting = false;
        _notify();
      }
    }
  }

  /// Adjusts a duration without changing a phase already in progress.
  void adjustDuration({required bool inhale, required int delta}) {
    if (!_active || delta == 0) {
      return;
    }
    final practicing =
        _screen == BreathingScreen.practice &&
        _selectedPattern == BreathingPattern.custom;
    if (!_canCustomize && !practicing) {
      return;
    }
    if (practicing) {
      refresh();
    }
    if (practicing && _screen != BreathingScreen.practice) {
      return;
    }
    final source = practicing ? _settings : _draftSettings;
    final previous = inhale ? source.inhaleDuration : source.exhaleDuration;
    final duration = _clampDuration(previous + Duration(seconds: delta));
    final updated = inhale
        ? source.copyWith(inhaleDuration: duration)
        : source.copyWith(exhaleDuration: duration);
    if (practicing) {
      _settings = updated;
      unawaited(_persistPracticeSettings());
    } else {
      _draftSettings = updated;
    }
    _notify();
  }

  void beginDurationMeasurement({required bool inhale}) {
    if (!_canCustomize || isMeasuring) {
      return;
    }
    _measuringInhale = inhale;
    _measurementStarted = _elapsed;
    _measuredDuration = Duration.zero;
    _updateTimer();
    _notify();
  }

  void finishDurationMeasurement() {
    if (!_active || !isMeasuring) {
      return;
    }
    final inhale = _measuringInhale!;
    final duration = _clampDuration(_elapsed - _measurementStarted);
    _draftSettings = inhale
        ? _draftSettings.copyWith(inhaleDuration: duration)
        : _draftSettings.copyWith(exhaleDuration: duration);
    _measuredDuration = duration;
    _measuringInhale = null;
    _updateTimer();
    _notify();
  }

  /// Cancels interrupted gestures without committing their elapsed duration.
  void cancelDurationMeasurement() {
    if (!_active || !isMeasuring) {
      return;
    }
    _measuringInhale = null;
    _measuredDuration = Duration.zero;
    _updateTimer();
    _notify();
  }

  static Duration _clampDuration(Duration duration) => Duration(
    microseconds: duration.inMicroseconds.clamp(
      const Duration(seconds: 3).inMicroseconds,
      const Duration(seconds: 9).inMicroseconds,
    ),
  );

  Future<void> nextCustomizationStep() async {
    if (!_canCustomize || _isImporting) {
      return;
    }
    cancelDurationMeasurement();
    if (_customizationStep < 2) {
      _customizationStep++;
      _notify();
      return;
    }
    _isSavingSettings = true;
    _error = null;
    _notify();
    try {
      final snapshot = await _repository.saveSettings(_draftSettings);
      if (!_active) {
        return;
      }
      _acceptSnapshot(snapshot);
      _changeScreen(BreathingScreen.landing);
    } catch (error) {
      if (_active) {
        _error = error;
      }
    } finally {
      if (_active) {
        _isSavingSettings = false;
        _notify();
      }
    }
  }

  /// Restores the saved value of this step before moving forward.
  Future<void> skipCustomizationStep() async {
    if (!_canCustomize || _isImporting) {
      return;
    }
    cancelDurationMeasurement();
    _draftSettings = switch (_customizationStep) {
      0 => BreathingSettings(
        background: _settings.background,
        personalPhotoBase64: _settings.personalPhotoBase64,
        inhaleDuration: _draftSettings.inhaleDuration,
        exhaleDuration: _draftSettings.exhaleDuration,
        showCircle: _draftSettings.showCircle,
        showText: _draftSettings.showText,
      ),
      1 => _draftSettings.copyWith(inhaleDuration: _settings.inhaleDuration),
      _ => _draftSettings.copyWith(exhaleDuration: _settings.exhaleDuration),
    };
    await nextCustomizationStep();
  }

  void previousCustomizationStep() {
    if (!_canCustomize) {
      return;
    }
    cancelDurationMeasurement();
    if (_customizationStep > 0) {
      _customizationStep--;
      _notify();
    } else {
      returnToLanding();
    }
  }

  void toggleCircle() => _toggleVisibility(circle: true);
  void toggleText() => _toggleVisibility(circle: false);

  void _toggleVisibility({required bool circle}) {
    if (!_active || _screen != BreathingScreen.practice) {
      return;
    }
    _settings = circle
        ? _settings.copyWith(showCircle: !_settings.showCircle)
        : _settings.copyWith(showText: !_settings.showText);
    _notify();
    unawaited(_persistPracticeSettings());
  }

  Future<void> _persistPracticeSettings() async {
    final generation = ++_settingsGeneration;
    _practiceSettingsDirty = true;
    try {
      await _repository.saveSettings(_settings);
      if (_active && generation == _settingsGeneration) {
        _practiceSettingsDirty = false;
      }
      if (_active &&
          generation == _settingsGeneration &&
          _screen == BreathingScreen.practice) {
        _error = null;
        _notify();
      }
    } catch (error) {
      if (_active &&
          generation == _settingsGeneration &&
          _screen == BreathingScreen.practice) {
        _error = error;
        _notify();
      }
    }
  }

  /// Samples the monotonic clock; animation and text visibility cannot alter it.
  void refresh() {
    if (!_active) {
      return;
    }
    if (isMeasuring) {
      _measuredDuration = _elapsed - _measurementStarted;
      if (_measuredDuration >= const Duration(seconds: 9)) {
        finishDurationMeasurement();
      } else {
        _notify();
      }
      return;
    }
    if (_screen != BreathingScreen.practice || _isPaused) {
      return;
    }
    final elapsed = _elapsed;
    final delta = elapsed - _lastRefresh;
    _lastRefresh = elapsed;
    if (delta.isNegative) {
      return;
    }
    _phaseElapsed += delta;
    while (_phaseElapsed >= _phaseDuration) {
      _phaseElapsed -= _phaseDuration;
      if (_advancePhase()) {
        _finish();
        return;
      }
      _phaseDuration = _durationFor(_phase);
    }
    _notify();
  }

  bool _advancePhase() {
    final box = _selectedPattern == BreathingPattern.box;
    _phase = switch (_phase) {
      BreathingPhase.inhale =>
        box ? BreathingPhase.holdInhale : BreathingPhase.exhale,
      BreathingPhase.holdInhale => BreathingPhase.exhale,
      BreathingPhase.exhale =>
        box ? BreathingPhase.holdExhale : BreathingPhase.inhale,
      BreathingPhase.holdExhale => BreathingPhase.inhale,
    };
    if (_phase == BreathingPhase.inhale) {
      _completedCycles++;
    }
    return _completedCycles == 8;
  }

  Duration _durationFor(BreathingPhase phase) {
    if (_selectedPattern == BreathingPattern.box) {
      return const Duration(seconds: 4);
    }
    if (_selectedPattern == BreathingPattern.basic) {
      return const Duration(seconds: 3);
    }
    return phase == BreathingPhase.inhale
        ? _settings.inhaleDuration
        : _settings.exhaleDuration;
  }

  void pause() {
    if (!_active || _screen != BreathingScreen.practice || _isPaused) {
      return;
    }
    refresh();
    if (_screen != BreathingScreen.practice) {
      return;
    }
    _isPaused = true;
    _updateTimer();
    _notify();
  }

  void resume() {
    if (!_active || _screen != BreathingScreen.practice || !_isPaused) {
      return;
    }
    _isPaused = false;
    _lastRefresh = _elapsed;
    _updateTimer();
    _notify();
  }

  void handleAppInactive() {
    cancelDurationMeasurement();
    pause();
  }

  /// Discards the unfinished attempt and retains settings and the pre-rating.
  void restart() {
    if (!_active || _screen != BreathingScreen.practice) {
      return;
    }
    _startAttempt();
  }

  void end() {
    if (!_active || _screen != BreathingScreen.practice) {
      return;
    }
    refresh();
    if (_screen == BreathingScreen.practice) {
      _finish();
    }
  }

  void _finish({bool save = true, bool notify = true}) {
    final startedAt = _startedAt!;
    final endedAt = _now();
    _result = BreathingSession(
      id: _attemptId!,
      startedAt: startedAt,
      endedAt: endedAt.isBefore(startedAt) ? startedAt : endedAt,
      pattern: _selectedPattern,
      completedCycles: _completedCycles,
      stressBefore: _stressBefore,
    );
    _savedResultRevision = -1;
    _screen = BreathingScreen.result;
    _isPaused = false;
    _phaseElapsed = Duration.zero;
    _timer?.cancel();
    _timer = null;
    if (notify) {
      _notify();
    }
    if (save) {
      unawaited(_saveResult());
    }
  }

  Future<void> updateAfterRating(int? rating) async {
    if (!_active || _screen != BreathingScreen.result || _result == null) {
      return;
    }
    _validateRating(rating);
    final previous = _result!;
    _result = BreathingSession(
      id: previous.id,
      startedAt: previous.startedAt,
      endedAt: previous.endedAt,
      pattern: previous.pattern,
      completedCycles: previous.completedCycles,
      stressBefore: previous.stressBefore,
      stressAfter: rating,
      revision: previous.revision + 1,
    );
    _notify();
    await _saveResult();
  }

  Future<void> retryResultSave() => _saveResult();

  Future<void> _saveResult() {
    if (!_active || _result == null || !hasUnsavedResult) {
      return Future.value();
    }
    if (_resultSaveFuture != null) {
      return _resultSaveFuture!;
    }
    _isSavingResult = true;
    final future = Future<void>.microtask(_drainResultSaves);
    _resultSaveFuture = future;
    return future;
  }

  Future<void> _drainResultSaves() async {
    _isSavingResult = true;
    _error = null;
    _notify();
    try {
      while (_active && hasUnsavedResult) {
        final pending = _result!;
        try {
          if (_practiceSettingsDirty) {
            final settingsGeneration = _settingsGeneration;
            await _repository.saveSettings(_settings);
            if (!_active || _result?.id != pending.id) {
              return;
            }
            if (settingsGeneration == _settingsGeneration) {
              _practiceSettingsDirty = false;
            }
          }
          final snapshot = await _repository.saveSession(pending);
          if (!_active || _result?.id != pending.id) {
            return;
          }
          _setHistory(snapshot.sessions);
          _savedResultRevision = pending.revision;
          _error = null;
        } catch (error) {
          if (!_active || _result?.id != pending.id) {
            return;
          }
          _error = error;
          // A newer rating submitted during a failing write still gets its own
          // attempt. Retrying must never replay an older revision over it.
          if (_result!.revision == pending.revision) {
            break;
          }
        }
      }
    } finally {
      _resultSaveFuture = null;
      if (_active) {
        _isSavingResult = false;
        _notify();
      }
    }
  }

  void showInfo() {
    if (_canNavigate) {
      _changeScreen(BreathingScreen.info);
    }
  }

  void showHistory() {
    if (_canNavigate) {
      _changeScreen(BreathingScreen.history);
    }
  }

  /// Returns false while a result still requires saving or explicit discard.
  bool returnToLanding() {
    if (!_canNavigate) {
      return false;
    }
    _result = null;
    _changeScreen(BreathingScreen.landing);
    return true;
  }

  void leaveWithoutSaving() {
    if (!_active || _screen != BreathingScreen.result || _isSavingResult) {
      return;
    }
    _result = null;
    _error = null;
    _changeScreen(BreathingScreen.landing);
  }

  /// Handles in-feature Back; true delegates departure to the owning Menu.
  bool handleBack() {
    if (!_active) {
      return true;
    }
    switch (_screen) {
      case BreathingScreen.practice:
        pause();
        return false;
      case BreathingScreen.customize:
        previousCustomizationStep();
        return false;
      case BreathingScreen.result:
        returnToLanding();
        return false;
      case BreathingScreen.info:
      case BreathingScreen.history:
      case BreathingScreen.preRating:
        returnToLanding();
        return false;
      case BreathingScreen.landing:
        return true;
    }
  }

  /// Stops synchronously so SOS navigation never depends on a storage write.
  void departForEmergency() {
    if (!_active) {
      return;
    }
    if (_screen == BreathingScreen.practice) {
      // Freeze first. The save below is deliberately detached from navigation.
      if (!_isPaused) {
        final delta = _elapsed - _lastRefresh;
        if (!delta.isNegative) {
          _phaseElapsed += delta;
        }
        while (_phaseElapsed >= _phaseDuration) {
          _phaseElapsed -= _phaseDuration;
          if (_advancePhase()) {
            break;
          }
          _phaseDuration = _durationFor(_phase);
        }
      }
      _finish(save: false, notify: false);
    }
    final pending = hasUnsavedResult ? _result : null;
    _departed = true;
    _timer?.cancel();
    _timer = null;
    _stopwatch.stop();
    if (pending != null) {
      unawaited(_saveEmergency(pending));
    }
  }

  Future<void> _saveEmergency(BreathingSession pending) async {
    try {
      await _repository.saveSession(pending);
    } catch (_) {
      // Emergency access remains available even when local storage fails.
    }
  }

  void _changeScreen(BreathingScreen screen) {
    cancelDurationMeasurement();
    _navigationGeneration++;
    _isImporting = false;
    _screen = screen;
    _error = null;
    _notify();
  }

  void _updateTimer() {
    _timer?.cancel();
    _timer = null;
    if (_active &&
        (isMeasuring || _screen == BreathingScreen.practice && !_isPaused)) {
      _timer = Timer.periodic(
        const Duration(milliseconds: 33),
        (_) => refresh(),
      );
    }
  }

  static void _validateRating(int? rating) {
    if (rating != null && (rating < 1 || rating > 10)) {
      throw ArgumentError.value(rating, 'rating', 'Must be between 1 and 10.');
    }
  }

  void _notify() {
    if (_active) {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _timer?.cancel();
    _stopwatch.stop();
    super.dispose();
  }
}
