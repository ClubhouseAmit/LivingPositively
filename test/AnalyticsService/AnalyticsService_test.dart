import 'package:flutter_test/flutter_test.dart';
import 'package:mazilon/AnalyticsService.dart';

void main() {
  group('MixPanelService (no token)', () {
    // The service is gated on a String.fromEnvironment compile-time const.
    // In `flutter test` it's the empty string, so init/trackEvent must
    // short-circuit without throwing.
    test('init() returns without error when token empty', () async {
      final svc = MixPanelService();
      await svc.init();
      // Reaches here without throw
      expect(svc.key, '');
    });

    test('trackEvent() returns without error when token empty', () async {
      final svc = MixPanelService();
      await svc.init();
      await svc.trackEvent('event-name');
      await svc.trackEvent('event-with-props', {'a': 1});
    });

    test('AnalyticsService is implemented by MixPanelService', () {
      expect(MixPanelService(), isA<AnalyticsService>());
    });
  });
}
