import 'package:url_launcher_platform_interface/link.dart';
import 'package:url_launcher_platform_interface/url_launcher_platform_interface.dart';

import '../../test_support/contract_persistent_memory_service.dart';

/// In-memory persistence used by SOS and emergency-delivery widget tests.
final class FakePersistentMemoryService extends ContractPersistentMemoryService {
  FakePersistentMemoryService() {
    onMissingRead = (_, _) => null;
  }
}

/// URL launcher fake that records attempts and can model launch failures.
class FakeUrlLauncherPlatform extends UrlLauncherPlatform {
  FakeUrlLauncherPlatform({this.shouldSucceed = true, this.launchError});

  final List<String> launchedUrls = [];
  final bool shouldSucceed;
  final Object? launchError;

  String? get lastLaunchedUrl =>
      launchedUrls.isEmpty ? null : launchedUrls.last;

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
    launchedUrls.add(url);
    if (launchError != null) {
      throw launchError!;
    }
    return shouldSucceed;
  }
}
