import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:mazilon/menu.dart';
import 'package:mazilon/util/Form/formPagePhoneModel.dart';
import 'package:mazilon/util/appInformation.dart';
import 'package:mazilon/util/userInformation.dart';
import 'package:provider/provider.dart';
import 'package:mazilon/l10n/app_localizations.dart';

Widget getMenuForTests(
    UserInformation mockUserInformation, AppInformation mockAppInformation,
    {Locale locale = const Locale('he')}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<UserInformation>.value(value: mockUserInformation),
      ChangeNotifierProvider<AppInformation>.value(value: mockAppInformation),
    ],
    child: MaterialApp(
      supportedLocales: AppLocalizations.supportedLocales,
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      home: ScreenUtilInit(
        designSize: const Size(360, 690),
        child: Menu(
          phonePageData: PhonePageData(
            key: 'phonePageData',
            header: 'header',
            subTitle: 'subTitle',
            midTitle: 'midTitle',
            phoneNameTitle: 'phoneNameTitle',
            phoneNumberTitle: 'phoneNumberTitle',
            phoneNames: [],
            phoneNumbers: [],
            savedPhoneNames: [],
            savedPhoneNumbers: [],
            phoneDescription: [],
          ),
          changeLocale: (String locale) {},
          hasFilled: false,
        ),
      ),
    ),
  );
}
