import 'package:mixpanel_flutter/mixpanel_flutter.dart';

const _mixpanelProjectToken = String.fromEnvironment('MIXPANEL_PROJECT_TOKEN');

abstract class AnalyticsService {
  Future<void> init();
  Future<void> trackEvent(String eventName, [Map<String, dynamic>? properties]);
}

class MixPanelService implements AnalyticsService {
  late Mixpanel _mixpanel;
  bool _isInitialized = false;
  String key = "";
  @override
  Future<void> init() async {
    if (_mixpanelProjectToken.isEmpty) {
      return;
    }
    key = _mixpanelProjectToken;

    // Once you've called this method once, you can access `mixpanel` throughout the rest of your application.
    _mixpanel = await Mixpanel.init(key, trackAutomaticEvents: false);
    _isInitialized = true;
  }

  @override
  Future<void> trackEvent(String eventName,
      [Map<String, dynamic>? properties]) async {
    if (key == "") {
      return;
    }
    while (!_isInitialized) {
      await Future.delayed(Duration(milliseconds: 100));
    }

    await _mixpanel.track(eventName, properties: properties);
  }

  Mixpanel get mixpanel => _mixpanel;
}
