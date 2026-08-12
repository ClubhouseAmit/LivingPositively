import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mazilon/global_enums.dart';
import 'package:mazilon/pages/home.dart';
import 'package:mazilon/util/Form/formPagePhoneModel.dart';
import 'package:mazilon/util/userInformation.dart';
import 'package:mazilon/MainPageHelpers/components/reminders_section.dart';
import 'package:mazilon/util/Thanks/AddForm.dart';

import '../helpers/widget_test_scaffold.dart';

PhonePageData _phoneData() => PhonePageData(
      key: 'phonePageData',
      header: 'header',
      subTitle: 'subTitle',
      midTitle: 'midTitle',
      phoneNameTitle: 'phoneNameTitle',
      phoneNumberTitle: 'phoneNumberTitle',
      phoneNames: const [],
      phoneNumbers: const [],
      savedPhoneNames: const [],
      savedPhoneNumbers: const [],
      phoneDescription: const [],
    );

Future<T> _onPlatform<T>(TargetPlatform platform, Future<T> Function() body) async {
  debugDefaultTargetPlatformOverride = platform;
  try {
    return await body();
  } finally {
    debugDefaultTargetPlatformOverride = null;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late UserInformation user;

  setUp(() {
    registerTestServices(locale: 'en');
    user = UserInformation();
    user.gender = 'other';
    user.localeName = 'en';
    user.notificationHour = 14;
    user.notificationMinute = 30;
  });

  tearDown(() {
    resetTestServices();
  });


  testWidgets('RemindersSectionWidget is shown on Android (supported) with actual data and active edit', (
    WidgetTester tester,
  ) async {
    await _onPlatform(TargetPlatform.android, () async {
      PagesCode? navigatedCode;

      await pumpWithProviders(
        tester,
        Home(
          phonePageData: _phoneData(),
          changeCurrentIndex: (BuildContext context, PagesCode code) {
            navigatedCode = code;
          },
          changeLocale: (_) {},
          openMainMenu: (_) {},
        ),
        userInformation: user,
        surfaceSize: const Size(1024, 2400),
      );

      await tester.pumpAndSettle();

      // Verify widget exists
      expect(find.byType(RemindersSectionWidget), findsOneWidget);

      // Verify the edit button (IconButton) exists and is clickable by tooltip
      final editButtonFinder = find.descendant(
        of: find.byType(RemindersSectionWidget),
        matching: find.byTooltip('Edit entry'),
      );
      expect(editButtonFinder, findsOneWidget);

      await tester.tap(editButtonFinder);
      await tester.pumpAndSettle();

      expect(find.byType(AddForm), findsOneWidget);
    });
  });
}
