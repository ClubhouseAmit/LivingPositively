import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mazilon/global_enums.dart';
import 'package:mazilon/iFx/service_locator.dart';
import 'package:mazilon/l10n/app_localizations.dart';
import 'package:mazilon/pages/PersonalPlan/myPlanPageFull.dart';
import 'package:mazilon/util/Form/formPagePhoneModel.dart';
import 'package:mazilon/util/appInformation.dart';
import 'package:mazilon/util/persistent_memory_service.dart';
import 'package:mazilon/util/userInformation.dart';
import 'package:provider/provider.dart';

class _MemoryService implements PersistentMemoryService {
  final Map<String, dynamic> values;

  _MemoryService(this.values);

  @override
  Future<dynamic> getItem(String key, PersistentMemoryType type) async {
    if (values.containsKey(key)) {
      return values[key];
    }
    if (type == PersistentMemoryType.StringList) {
      return <String>[];
    }
    if (type == PersistentMemoryType.String) {
      return '';
    }
    if (type == PersistentMemoryType.Bool) {
      return false;
    }
    return null;
  }

  @override
  Future<void> reset() async {
    values.clear();
  }

  @override
  Future<void> setItem(
      String key, PersistentMemoryType type, dynamic value) async {
    values[key] = value;
  }
}

PhonePageData _phonePageData() {
  return PhonePageData(
    key: 'PhonePage',
    phoneNames: const [],
    phoneNumbers: const [],
    header: '',
    subTitle: '',
    midTitle: '',
    phoneNameTitle: '',
    phoneNumberTitle: '',
    savedPhoneNames: const [],
    savedPhoneNumbers: const [],
    phoneDescription: const [],
  );
}

Widget _harness({
  required PersistentMemoryService service,
  Locale locale = const Locale('en'),
}) {
  getIt.registerLazySingleton<PersistentMemoryService>(() => service);

  final userInformation = UserInformation(service: service)
    ..gender = 'male'
    ..difficultEvents = ['standard difficult event']
    ..makeSafer = []
    ..feelBetter = []
    ..distractions = [];

  return MultiProvider(
    providers: [
      ChangeNotifierProvider<UserInformation>.value(value: userInformation),
      ChangeNotifierProvider<AppInformation>.value(value: AppInformation()),
    ],
    child: MaterialApp(
      supportedLocales: AppLocalizations.supportedLocales,
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      home: ScreenUtilInit(
        designSize: const Size(360, 690),
        child: MyPlanPageFull(
          phonePageData: _phonePageData(),
          hasFilled: true,
          changeLocale: (_) {},
        ),
      ),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(() async {
    await GetIt.instance.reset();
  });

  testWidgets('full My Plan displays saved custom categories after phones',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      _harness(
        service: _MemoryService({
          'customCategoryTitles': <String>[
            'כותרת אישית',
            'English custom title',
          ],
          'customCategoryDescriptions': <String>[
            'טקסט חופשי בעברית',
            'English free text',
          ],
        }),
      ),
    );
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('כותרת אישית'));
    expect(find.text('standard difficult event'), findsOneWidget);
    expect(find.text('כותרת אישית'), findsOneWidget);
    expect(find.text('טקסט חופשי בעברית'), findsOneWidget);
    expect(find.text('English custom title'), findsOneWidget);
    expect(find.text('English free text'), findsOneWidget);
  });

  testWidgets('full My Plan ignores incomplete custom category rows',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      _harness(
        service: _MemoryService({
          'customCategoryTitles': <String>[
            'Valid title',
            '',
            'Missing notes title',
          ],
          'customCategoryDescriptions': <String>[
            'Valid notes',
            'No title notes',
            '',
          ],
        }),
      ),
    );
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Valid title'));
    expect(find.text('Valid title'), findsOneWidget);
    expect(find.text('Valid notes'), findsOneWidget);
    expect(find.text('No title notes'), findsNothing);
    expect(find.text('Missing notes title'), findsNothing);
  });
}
