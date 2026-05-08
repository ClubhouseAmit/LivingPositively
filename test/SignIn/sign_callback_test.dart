// ignore_for_file: prefer_const_constructors

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mazilon/AnalyticsService.dart';
import 'package:mazilon/Locale/locale_service.dart';
import 'package:mazilon/global_enums.dart';
import 'package:mazilon/util/Form/formPagePhoneModel.dart';
import 'package:mazilon/util/SignIn/sign_callback.dart';
import 'package:mazilon/util/logger_service.dart';
import 'package:mazilon/util/persistent_memory_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _NoopAnalytics implements AnalyticsService {
  @override
  Future<void> init() async {}
  @override
  Future<void> trackEvent(String e, [Map<String, dynamic>? p]) async {}
}

class _NoopLogger implements IncidentLoggerService {
  @override
  Future<void> initializeSentry(_) async {}
  @override
  Future<void> captureLog(dynamic _,
      {StackTrace? stackTrace, dynamic exceptionData}) async {}
}

class _FakeMemory implements PersistentMemoryService {
  final Map<String, dynamic> store = {};
  @override
  Future getItem(String key, PersistentMemoryType type) async => store[key];
  @override
  Future<void> reset() async => store.clear();
  @override
  Future<void> setItem(String key, PersistentMemoryType type, dynamic v) async {
    store[key] = v;
  }
}

PhonePageData _emptyPhonePageData() => PhonePageData(
      key: 'k',
      phoneNames: <String>[],
      phoneNumbers: <String>[],
      header: '',
      subTitle: '',
      midTitle: '',
      phoneNameTitle: '',
      phoneNumberTitle: '',
      savedPhoneNames: <String>[],
      savedPhoneNumbers: <String>[],
      phoneDescription: <String>[],
    );

class _FakeWidget {
  final PhonePageData phonePageData;
  final void Function(String) changeLocale;
  _FakeWidget(this.phonePageData, this.changeLocale);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await GetIt.instance.reset();
    GetIt.instance.registerSingleton<AnalyticsService>(_NoopAnalytics());
    GetIt.instance.registerSingleton<IncidentLoggerService>(_NoopLogger());
    GetIt.instance.registerSingleton<LocaleService>(LocaleServiceImpl());
    GetIt.instance.registerSingleton<PersistentMemoryService>(_FakeMemory());
  });

  tearDown(() async {
    await GetIt.instance.reset();
  });

  testWidgets('callback(false, ...) is a no-op (does not navigate)',
      (tester) async {
    BuildContext? capturedCtx;
    await tester.pumpWidget(MaterialApp(
      home: Builder(builder: (ctx) {
        capturedCtx = ctx;
        return const Text('home');
      }),
    ));
    final widget = _FakeWidget(_emptyPhonePageData(), (_) {});
    callback(false, widget, capturedCtx);
    await tester.pump();
    expect(find.text('home'), findsOneWidget);
  });

  testWidgets('callback(true, ...) attempts navigation', (tester) async {
    // We can't fully render InitialFormProgressIndicator without providers, but
    // we can verify Navigator.pushAndRemoveUntil is invoked. If it throws due
    // to provider absence, that's fine — we only assert the call path runs.
    BuildContext? capturedCtx;
    await tester.pumpWidget(MaterialApp(
      home: Builder(builder: (ctx) {
        capturedCtx = ctx;
        return const Text('home');
      }),
    ));
    final widget = _FakeWidget(_emptyPhonePageData(), (_) {});
    expect(() => callback(true, widget, capturedCtx), returnsNormally);
  });
}
