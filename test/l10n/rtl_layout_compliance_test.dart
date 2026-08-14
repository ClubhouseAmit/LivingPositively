import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mazilon/MainPageHelpers/personalPlanWidget.dart';
import 'package:mazilon/file_service.dart';
import 'package:mazilon/form/formpagetemplate.dart';
import 'package:mazilon/iFx/service_locator.dart';
import 'package:mazilon/l10n/app_localizations.dart';
import 'package:mazilon/util/Form/PagePhoneItem.dart';
import 'package:mazilon/util/FormAnswer/addFormAnswer.dart';
import 'package:mazilon/util/HomePage/NameBar.dart';
import 'package:mazilon/util/HomePage/sectionBarHome.dart';
import 'package:mazilon/util/appInformation.dart';
import 'package:mazilon/util/userInformation.dart';
import 'package:provider/provider.dart';

import '../MenuTest/shareAndDownload/share_and_download_test.mocks.dart'
    as share_mocks;

Future<void> pumpArabicHarness(
  WidgetTester tester,
  Widget child, {
  bool wrapInScaffold = true,
  String gender = 'male',
  String name = 'Tester',
}) async {
  await getIt.reset();

  final fileService = share_mocks.MockFileService();
  when(
    fileService.download(any, any, any, any, any),
  ).thenAnswer((_) async => null);
  getIt.registerLazySingleton<FileService>(() => fileService);

  final persistentMemoryService = share_mocks.MockPersistentMemoryService();
  when(persistentMemoryService.getItem(any, any)).thenAnswer((_) async => null);
  when(persistentMemoryService.setItem(any, any, any)).thenAnswer((_) async {});

  final userInformation = UserInformation(service: persistentMemoryService)
    ..gender = gender
    ..name = name;
  final appInformation = AppInformation();

  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<UserInformation>.value(value: userInformation),
        ChangeNotifierProvider<AppInformation>.value(value: appInformation),
      ],
      child: MaterialApp(
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        locale: const Locale('ar'),
        home: ScreenUtilInit(
          designSize: const Size(360, 690),
          child: wrapInScaffold ? Scaffold(body: Center(child: child)) : child,
        ),
      ),
    ),
  );

  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('RTL layout compliance', () {
    testWidgets('NameBar uses directional outer padding', (
      WidgetTester tester,
    ) async {
      await pumpArabicHarness(
        tester,
        NameBar(icons: const [SizedBox()], greetingString: 'Greeting'),
      );

      final padding = tester.widget<Padding>(
        find.byWidgetPredicate(
          (widget) => widget is Padding && widget.child is Column,
        ),
      );

      expect(padding.padding, isA<EdgeInsetsDirectional>());
    });

    testWidgets('SectionBarHome subtitle padding is directional', (
      WidgetTester tester,
    ) async {
      await pumpArabicHarness(
        tester,
        SectionBarHome(
          textWidget: const Text('Title'),
          icon: Icons.info,
          icons: const [],
          subHeader: 'Subtitle',
        ),
      );

      final subtitlePadding = tester.widget<Padding>(
        find.byWidgetPredicate(
          (widget) => widget is Padding && widget.child is AutoSizeText,
        ),
      );

      expect(subtitlePadding.padding, isA<EdgeInsetsDirectional>());
    });

    testWidgets('PagePhoneItem description spacing is directional', (
      WidgetTester tester,
    ) async {
      await pumpArabicHarness(
        tester,
        PagePhoneItem(
          phoneNumber: '123456',
          phoneName: 'Hotline',
          phoneDescription: 'Description',
          icon: Icons.phone,
        ),
      );

      final descriptionPadding = tester.widget<Padding>(
        find.byWidgetPredicate(
          (widget) => widget is Padding && widget.child is AutoSizeText,
        ),
      );

      expect(descriptionPadding.padding, isA<EdgeInsetsDirectional>());
    });

    testWidgets('AddFormAnswer text-field padding is directional', (
      WidgetTester tester,
    ) async {
      await pumpArabicHarness(
        tester,
        AddFormAnswer(index: 0, edit: (_, _) {}, text: 'Initial value'),
      );

      final textField = tester.widget<TextField>(find.byType(TextField));

      expect(
        textField.decoration?.contentPadding,
        isA<EdgeInsetsDirectional>(),
      );
    });

    testWidgets('FormPageTemplate suggestion row padding is directional', (
      WidgetTester tester,
    ) async {
      await pumpArabicHarness(
        tester,
        FormPageTemplate(
          next: () {},
          prev: () {},
          collectionName: 'PersonalPlan-DifficultEvents',
        ),
        // FormPageTemplate is a wizard step hosted inside form.dart's
        // Scaffold; it no longer nests one of its own.
        wrapInScaffold: true,
      );

      final suggestionRows = tester.widgetList<InkWell>(
        find.byWidgetPredicate(
          (widget) =>
              widget is InkWell &&
              widget.key is ValueKey &&
              (widget.key as ValueKey).value.toString().startsWith(
                'suggestion-',
              ),
        ),
      );

      expect(suggestionRows, isNotEmpty);
      for (final row in suggestionRows) {
        final content = tester.widget<Container>(
          find.descendant(
            of: find.byWidget(row),
            matching: find.byType(Container),
          ),
        );
        expect(content.padding, isA<EdgeInsetsDirectional>());
        expect(content.alignment, AlignmentDirectional.centerStart);
      }
    });

    testWidgets('PersonalPlanWidget does not use a left arrow under RTL', (
      WidgetTester tester,
    ) async {
      await pumpArabicHarness(
        tester,
        PersonalPlanWidget(
          text: const {
            'list': ['One', 'Two'],
            'SubTitle': 'Subtitle',
          },
          changeCurrentIndex: (_, _) {},
        ),
      );

      expect(
        find.descendant(
          of: find.byType(PersonalPlanWidget),
          matching: find.byIcon(Icons.arrow_left),
        ),
        findsNothing,
      );
    });
  });
}
