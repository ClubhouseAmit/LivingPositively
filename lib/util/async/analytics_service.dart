import 'dart:async';

import 'package:flutter/foundation.dart' show debugPrint, visibleForTesting;
import 'package:get_it/get_it.dart';
import 'package:mazilon/util/async/logger_service.dart';
import 'package:mixpanel_flutter/mixpanel_flutter.dart';

const _mixpanelProjectToken = String.fromEnvironment('MIXPANEL_PROJECT_TOKEN');

abstract class AnalyticsService {
  Future<void> init();
  Future<void> trackEvent(String eventName, [Map<String, dynamic>? properties]);
}

class MixPanelService implements AnalyticsService {
  @visibleForTesting
  static String? debugProjectTokenOverride;
  @visibleForTesting
  static DateTime Function() debugClock = DateTime.now;

  late Mixpanel _mixpanel;
  bool _isInitialized = false;
  Future<void>? _initialization;
  int _startupGeneration = 0;
  bool _startupTimedOut = false;
  final _pendingEvents = <({String name, Map<String, dynamic>? properties})>[];
  DateTime? _lastFailure;
  final _reportedStartupConditions = <String>{};
  bool _deliveryFailureReported = false;
  String key = "";
  @override
  Future<void> init() {
    if (_isInitialized) return Future<void>.value();
    if (_lastFailure case final failed?) {
      if (debugClock().difference(failed) < const Duration(minutes: 1)) {
        return Future<void>.value();
      }
    }
    return _initialization ??= _initialize();
  }

  Future<void> _initialize() async {
    final token = debugProjectTokenOverride ?? _mixpanelProjectToken;
    if (token.isEmpty || _isInitialized) return;
    key = token;
    final generation = ++_startupGeneration;
    // Retain late results until a retry supersedes this startup attempt.
    await _startNative(generation).timeout(
      const Duration(seconds: 5),
      onTimeout: () {
        if (generation != _startupGeneration || _isInitialized) return;
        _startupTimedOut = true;
        _lastFailure = debugClock();
        _initialization = null;
        _reportStartupCondition('Mixpanel startup timed out');
      },
    );
  }

  Future<void> _startNative(int generation) async {
    final Mixpanel mixpanel;
    try {
      mixpanel = await Mixpanel.init(key, trackAutomaticEvents: false);
    } catch (_) {
      if (generation != _startupGeneration) return;
      _startupTimedOut = false;
      _lastFailure = debugClock();
      _pendingEvents.clear();
      _initialization = null;
      _reportStartupCondition('Mixpanel initialization failed');
      return;
    }
    if (generation != _startupGeneration) return;
    _mixpanel = mixpanel;
    // Keep new events in the same FIFO until every older startup event settles.
    while (generation == _startupGeneration && _pendingEvents.isNotEmpty) {
      final event = _pendingEvents.removeAt(0);
      try {
        await mixpanel.track(event.name, properties: event.properties);
      } catch (_) {
        // A rejected event must not discard the rest or invalidate a ready SDK.
        if (generation == _startupGeneration && !_deliveryFailureReported) {
          _deliveryFailureReported = true;
          _reportDiagnostic('Mixpanel startup event delivery failed');
        }
      }
    }
    if (generation == _startupGeneration) {
      _isInitialized = true;
      _lastFailure = null;
      _startupTimedOut = false;
    }
  }

  void _reportStartupCondition(String message) {
    if (!_reportedStartupConditions.add(message)) return;
    _reportDiagnostic(message);
  }

  void _reportDiagnostic(String message) {
    debugPrint(message);
    final services = GetIt.instance;
    if (!services.isRegistered<IncidentLoggerService>()) return;
    unawaited(
      Future<void>.sync(
        () => services<IncidentLoggerService>().captureLog(
          StateError(message),
          stackTrace: StackTrace.current,
        ),
      ).catchError((_) {}),
    );
  }

  @override
  Future<void> trackEvent(
    String eventName, [
    Map<String, dynamic>? properties,
  ]) async {
    if ((debugProjectTokenOverride ?? _mixpanelProjectToken).isEmpty) return;
    if (_isInitialized) {
      await _mixpanel.track(eventName, properties: properties);
      return;
    }
    if (_lastFailure case final failed?) {
      if (!_startupTimedOut &&
          debugClock().difference(failed) < const Duration(minutes: 1)) {
        return;
      }
    }
    if (_pendingEvents.length == 64) {
      _pendingEvents.removeAt(0);
      _reportStartupCondition('Mixpanel startup event buffer exceeded');
    }
    final capturedProperties = <String, dynamic>{
      'time': debugClock().millisecondsSinceEpoch,
      ...?properties,
    };
    _pendingEvents.add((name: eventName, properties: capturedProperties));
    await init();
  }

  Mixpanel get mixpanel => _mixpanel;
}
