import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mazilon/features/personal_plan/data/phone_models.dart';
import 'package:mazilon/main.dart' show MyApp;
import 'package:mazilon/util/async/global_enums.dart';
import 'package:mazilon/util/async/app_material_localizations.dart';
import 'package:mazilon/util/userInformation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../helpers/widget_test_scaffold.dart';

void main() {
  group('MyApp time format integration', () {
    testWidgets('should provide Hebrew OS time format from the real app root', (
      tester,
    ) async {
      final services = registerTestServices(locale: 'he');
      addTearDown(resetTestServices);
      SharedPreferences.setMockInitialValues({});
      PackageInfo.setMockInitialValues(
        appName: 'Mazilon',
        packageName: 'com.mazilon',
        version: '1.0.0',
        buildNumber: '1',
        buildSignature: '',
      );
      await services.memory.setItem(
        'localeName',
        PersistentMemoryType.String,
        'he',
      );
      tester.platformDispatcher.alwaysUse24HourFormatTestValue = false;
      tester.binding.handleMetricsChanged();
      addTearDown(tester.platformDispatcher.clearAlwaysUse24HourTestValue);
      final phones = PhonePageData(
        key: 'PhonePage',
        phoneNames: [],
        phoneNumbers: [],
        header: '',
        subTitle: '',
        midTitle: '',
        phoneNameTitle: '',
        phoneNumberTitle: '',
        savedPhoneNames: [],
        savedPhoneNumbers: [],
        phoneDescription: [],
      );
      await pumpWithProviders(
        tester,
        ChangeNotifierProvider<PhonePageData>.value(
          value: phones,
          child: const MyApp(),
        ),
        userInformation: UserInformation(localeName: 'he'),
        locale: const Locale('he'),
      );
      await tester.pump();
      final app = tester.widgetList<MaterialApp>(find.byType(MaterialApp)).last;
      expect(
        app.localizationsDelegates!.first,
        isA<AppMaterialLocalizationsDelegate>(),
      );
      expect(app.builder, isNotNull);
      final navigator =
          GetIt.instance<GlobalKey<NavigatorState>>().currentState!;
      navigator.push<void>(
        MaterialPageRoute(
          builder: (context) => Scaffold(
            body: Text(const TimeOfDay(hour: 19, minute: 5).format(context)),
          ),
        ),
      );
      await tester.pump();
      expect(find.text('7:05 PM', skipOffstage: false), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(seconds: 10));
      phones.dispose();
    });
  });
}
