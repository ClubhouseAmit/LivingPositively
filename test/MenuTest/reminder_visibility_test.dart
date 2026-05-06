import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mazilon/AnalyticsService.dart';
import 'package:mazilon/global_enums.dart';
import 'package:mazilon/iFx/service_locator.dart';
import 'package:mazilon/file_service.dart';
import 'package:mazilon/util/appInformation.dart';
import 'package:mazilon/util/persistent_memory_service.dart';
import 'package:mazilon/util/userInformation.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'TestMenu.dart';
import 'test_data.dart';

class _FakeAnalyticsService implements AnalyticsService {
  @override
  Future<void> init() async {}

  @override
  Future<void> trackEvent(
    String eventName, [
    Map<String, dynamic>? properties,
  ]) async {}
}

class _FakePersistentMemoryService implements PersistentMemoryService {
  _FakePersistentMemoryService({
    Map<String, dynamic>? initialValues,
  }) : _values = {...?initialValues};

  final Map<String, dynamic> _values;

  @override
  Future<dynamic> getItem(String key, PersistentMemoryType type) async {
    if (_values.containsKey(key)) {
      return _values[key];
    }

    throw StateError(
      'Unexpected persistent memory read for key "$key" with type $type',
    );
  }

  @override
  Future<void> reset() async {}

  @override
  Future<void> setItem(
    String key,
    PersistentMemoryType type,
    dynamic value,
  ) async {
    _values[key] = value;
  }
}

class _FakeFileService implements FileService {
  @override
  Future<void> share(
    String message,
    List<dynamic> titles,
    List<dynamic> subTitles,
    Map<String, String> texts,
    ShareFileType saveFormat,
    String textDirection,
  ) async {}

  @override
  Future<String?> download(
    List<dynamic> titles,
    List<dynamic> subTitles,
    Map<String, String> texts,
    ShareFileType saveFormat,
    String textDirection,
  ) async {
    return null;
  }

  @override
  Future<void> shareTextOnly(String message) async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('fake persistent memory requires explicit values for reads', () async {
    final service = _FakePersistentMemoryService();

    expect(
      service.getItem('unexpectedKey', PersistentMemoryType.Bool),
      throwsA(isA<StateError>()),
    );
  });

  late UserInformation mockUserInformation;
  late AppInformation mockAppInformation;

  setUp(() async {
    await GetIt.instance.reset();
    getIt.registerLazySingleton<AnalyticsService>(() => _FakeAnalyticsService());
    getIt.registerLazySingleton<FileService>(() => _FakeFileService());
    getIt.registerLazySingleton<PersistentMemoryService>(
      () => _FakePersistentMemoryService(
        initialValues: {
          'hasFilled': false,
          'location': '',
          'phonePageDataSavedPhoneNames': <String>[],
          'phonePageDataSavedPhoneNumbers': <String>[],
        },
      ),
    );
    PackageInfo.setMockInitialValues(
      appName: 'Mazilon',
      packageName: 'mazilon',
      version: '1.0.0',
      buildNumber: '1',
      buildSignature: '',
    );

    mockUserInformation = UserInformation()
      ..gender = 'male'
      ..localeName = 'he';
    mockAppInformation = AppInformation();
    getData(mockAppInformation);
  });

  Future<void> openMenu(WidgetTester tester) async {
    await tester.pumpWidget(
      getMenuForTests(mockUserInformation, mockAppInformation),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.menu));
    await tester.pumpAndSettle();
  }

  testWidgets('hides the reminders menu entry on iOS', (
    WidgetTester tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    try {
      await openMenu(tester);

      expect(find.byIcon(Icons.notification_add), findsNothing);
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });

  testWidgets('shows the reminders menu entry on Android', (
    WidgetTester tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    try {
      await openMenu(tester);

      expect(find.byIcon(Icons.notification_add), findsOneWidget);
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });
}
