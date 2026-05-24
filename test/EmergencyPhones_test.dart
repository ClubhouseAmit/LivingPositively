import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mazilon/global_enums.dart';
import 'package:mazilon/l10n/app_localizations.dart';
import 'package:mazilon/util/Phone/EmergencyPhones.dart';
import 'package:mazilon/util/persistent_memory_service.dart';
import 'package:mazilon/util/userInformation.dart';
import 'package:provider/provider.dart';

class _FakePersistentMemoryService implements PersistentMemoryService {
  @override
  Future<dynamic> getItem(String key, PersistentMemoryType type) async => null;
  @override
  Future<void> reset() async {}
  @override
  Future<void> setItem(String key, PersistentMemoryType type, value) async {}
}

Widget _hostGrid(UserInformation userInfo,
    {Locale locale = const Locale('en', 'US')}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<UserInformation>.value(value: userInfo),
    ],
    child: MaterialApp(
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      locale: locale,
      home: ScreenUtilInit(
        designSize: const Size(360, 690),
        child: Scaffold(body: const EmergencyPhonesGrid()),
      ),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
      'unknown countryCode falls back to default emergency country and renders entries',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final user = UserInformation(
      service: _FakePersistentMemoryService(),
      gender: 'male',
      // Country code that has no mapping in `findCountryByCode`.
      location: 'XX',
    );

    await tester.pumpWidget(_hostGrid(user));
    await tester.pumpAndSettle();

    // The default emergency country has at least one entry rendered.
    expect(find.byType(EmergencyPhoneItem), findsWidgets);
  });

  testWidgets(
      'tapping an EmergencyPhoneItem opens the EmergencyDialogBox',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final user = UserInformation(
      service: _FakePersistentMemoryService(),
      gender: 'male',
      location: 'US',
    );

    await tester.pumpWidget(_hostGrid(user));
    await tester.pumpAndSettle();

    final items = find.byType(EmergencyPhoneItem);
    expect(items, findsWidgets);

    // Tap the first item to trigger the showDialog onTap handler.
    await tester.tap(items.first, warnIfMissed: false);
    await tester.pumpAndSettle();

    // A dialog with a Close button should be displayed (EmergencyDialogBox).
    expect(find.byType(AlertDialog), findsOneWidget);
  });

  testWidgets(
      'falls back to locale country code when user.location is empty',
      (tester) async {
    final user = UserInformation(
      service: _FakePersistentMemoryService(),
      gender: 'male',
      location: '',
    );

    await tester.pumpWidget(_hostGrid(user, locale: const Locale('en', 'US')));
    await tester.pumpAndSettle();

    // The fallback path must still produce at least one rendered emergency
    // item (the exact country depends on AppLocalizations resolution).
    expect(find.byType(EmergencyPhoneItem), findsWidgets);
  });
}
