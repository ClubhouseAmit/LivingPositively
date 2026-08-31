import 'package:flutter_test/flutter_test.dart';
import 'package:mazilon/features/mood_medicine/data/mood_medicine_source_link_service.dart';
import 'package:url_launcher_platform_interface/link.dart';
import 'package:url_launcher_platform_interface/url_launcher_platform_interface.dart';

final class _FakeUrlLauncherPlatform extends UrlLauncherPlatform {
  String? lastLaunchedUrl;
  bool launchResult = true;
  Object? launchError;

  @override
  LinkDelegate? get linkDelegate => null;

  @override
  Future<bool> canLaunch(String url) async => true;

  @override
  Future<bool> launch(
    String url, {
    required bool useSafariVC,
    required bool useWebView,
    required bool enableJavaScript,
    required bool enableDomStorage,
    required bool universalLinksOnly,
    required Map<String, String> headers,
    String? webOnlyWindowName,
  }) async {
    lastLaunchedUrl = url;
    if (launchError case final Object error) {
      throw error;
    }
    return launchResult;
  }
}

void main() {
  group('UrlLauncherMoodMedicineSourceLinkService', () {
    test('should reject non-HTTPS sources before platform handoff', () async {
      final UrlLauncherPlatform originalPlatform = UrlLauncherPlatform.instance;
      final _FakeUrlLauncherPlatform fakePlatform = _FakeUrlLauncherPlatform();
      UrlLauncherPlatform.instance = fakePlatform;
      addTearDown(() => UrlLauncherPlatform.instance = originalPlatform);

      final bool opened = await const UrlLauncherMoodMedicineSourceLinkService()
          .openExternal(Uri.parse('http://example.com/source'));

      expect(opened, isFalse);
      expect(fakePlatform.lastLaunchedUrl, isNull);
    });

    test('should delegate HTTPS sources to the platform launcher', () async {
      final UrlLauncherPlatform originalPlatform = UrlLauncherPlatform.instance;
      final _FakeUrlLauncherPlatform fakePlatform = _FakeUrlLauncherPlatform();
      UrlLauncherPlatform.instance = fakePlatform;
      addTearDown(() => UrlLauncherPlatform.instance = originalPlatform);

      final Uri source = Uri.parse('https://example.com/source');
      final bool opened = await const UrlLauncherMoodMedicineSourceLinkService()
          .openExternal(source);

      expect(opened, isTrue);
      expect(fakePlatform.lastLaunchedUrl, source.toString());
    });

    test('should return false when HTTPS handoff is rejected', () async {
      final UrlLauncherPlatform originalPlatform = UrlLauncherPlatform.instance;
      final _FakeUrlLauncherPlatform fakePlatform = _FakeUrlLauncherPlatform()
        ..launchResult = false;
      UrlLauncherPlatform.instance = fakePlatform;
      addTearDown(() => UrlLauncherPlatform.instance = originalPlatform);

      final Uri source = Uri.parse('https://example.com/source');
      final bool opened = await const UrlLauncherMoodMedicineSourceLinkService()
          .openExternal(source);

      expect(opened, isFalse);
      expect(fakePlatform.lastLaunchedUrl, source.toString());
    });

    test('should propagate HTTPS platform failures after handoff', () async {
      final UrlLauncherPlatform originalPlatform = UrlLauncherPlatform.instance;
      final _FakeUrlLauncherPlatform fakePlatform = _FakeUrlLauncherPlatform()
        ..launchError = StateError('launcher failed');
      UrlLauncherPlatform.instance = fakePlatform;
      addTearDown(() => UrlLauncherPlatform.instance = originalPlatform);

      final Uri source = Uri.parse('https://example.com/source');
      await expectLater(
        const UrlLauncherMoodMedicineSourceLinkService().openExternal(source),
        throwsA(isA<StateError>()),
      );
      expect(fakePlatform.lastLaunchedUrl, source.toString());
    });
  });
}
