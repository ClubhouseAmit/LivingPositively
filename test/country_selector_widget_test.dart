import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:country_code_picker/country_code_picker.dart';
import 'package:get_it/get_it.dart';
import 'package:mazilon/initialForm/CountrySelectorWidget.dart';
import 'package:mazilon/l10n/app_localizations.dart';
import 'package:mazilon/util/persistent_memory_service.dart';
import 'package:mazilon/util/theme/app_theme.dart';
import 'package:mazilon/util/userInformation.dart';
import 'package:provider/provider.dart';

import '../test_support/contract_persistent_memory_service.dart';

final class InMemoryPersistentMemoryService
    extends ContractPersistentMemoryService {
  InMemoryPersistentMemoryService() {
    onMissingRead = (_, _) => null;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await GetIt.instance.reset();
    GetIt.instance.registerSingleton<PersistentMemoryService>(
      InMemoryPersistentMemoryService(),
    );
  });

  tearDown(() async {
    await GetIt.instance.reset();
  });

  testWidgets('Country selector defaults to locale when location is empty', (
    WidgetTester tester,
  ) async {
    tester.binding.platformDispatcher.localeTestValue = const Locale(
      'en',
      'US',
    );
    addTearDown(() {
      tester.binding.platformDispatcher.clearLocaleTestValue();
    });
    final userInfo = UserInformation(
      service: InMemoryPersistentMemoryService(),
    );

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<UserInformation>.value(value: userInfo),
        ],
        child: ScreenUtilInit(
          designSize: const Size(360, 690),
          child: MaterialApp(
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            locale: const Locale('en', 'US'),
            home: Scaffold(
              body: CountrySelectorWidget(
                text: 'Country/Region',
                disclaimerText: '',
              ),
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(userInfo.location, 'US');
  });

  testWidgets('Country selector keeps country names legible in dark mode', (
    WidgetTester tester,
  ) async {
    final userInfo = UserInformation(
      service: InMemoryPersistentMemoryService(),
    );
    final darkTheme = buildDarkTheme();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<UserInformation>.value(value: userInfo),
        ],
        child: ScreenUtilInit(
          designSize: const Size(360, 690),
          child: MaterialApp(
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            locale: const Locale('en', 'US'),
            theme: ThemeData.light(),
            darkTheme: darkTheme,
            themeMode: ThemeMode.dark,
            home: Scaffold(
              body: CountrySelectorWidget(
                text: 'Country/Region',
                disclaimerText: '',
              ),
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();
    await tester.tap(find.byType(CountryCodePicker));
    await tester.pumpAndSettle();

    final dialog = tester.widget<SelectionDialog>(find.byType(SelectionDialog));
    expect(dialog.backgroundColor, darkTheme.colorScheme.surface);
    expect(dialog.textStyle?.color, darkTheme.colorScheme.onSurface);
  });
}
