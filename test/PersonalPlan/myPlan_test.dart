// ignore_for_file: prefer_const_constructors

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mazilon/l10n/app_localizations.dart';
import 'package:mazilon/pages/PersonalPlan/myPlan.dart';

Widget _wrap(Widget child, {Locale locale = const Locale('en')}) {
  return MaterialApp(
    locale: locale,
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    home: ScreenUtilInit(
      designSize: const Size(360, 690),
      child: Scaffold(body: SingleChildScrollView(child: child)),
    ),
  );
}

void main() {
  testWidgets('MyPlanSection renders title, subtitle, and answers',
      (tester) async {
    await tester.pumpWidget(_wrap(MyPlanSection(
      title: 'Difficult Events',
      subTitle: 'These are warning signs',
      answers: ['Feeling alone', 'Bad sleep', 'Stress'],
    )));
    await tester.pump();
    expect(find.text('Difficult Events'), findsOneWidget);
    expect(find.text('These are warning signs'), findsOneWidget);
    expect(find.text('Feeling alone'), findsOneWidget);
    expect(find.text('Bad sleep'), findsOneWidget);
    expect(find.text('Stress'), findsOneWidget);
  });

  testWidgets('MyPlanSection renders empty answers list', (tester) async {
    await tester.pumpWidget(_wrap(MyPlanSection(
      title: 'Empty',
      subTitle: 'No items',
      answers: const <String>[],
    )));
    await tester.pump();
    expect(find.text('Empty'), findsOneWidget);
    expect(find.text('No items'), findsOneWidget);
    expect(find.byIcon(Icons.circle), findsNothing);
  });

  testWidgets('MyPlanSection renders Hebrew text in RTL', (tester) async {
    await tester.pumpWidget(_wrap(
      MyPlanSection(
        title: 'אירועים קשים',
        subTitle: 'סימני אזהרה',
        answers: const ['בדידות', 'לחץ'],
      ),
      locale: const Locale('he'),
    ));
    await tester.pump();
    expect(find.text('אירועים קשים'), findsOneWidget);
    expect(find.text('בדידות'), findsOneWidget);
  });

  testWidgets('MyPlanSection renders one bullet per answer', (tester) async {
    await tester.pumpWidget(_wrap(MyPlanSection(
      title: 't',
      subTitle: 's',
      answers: const ['a', 'b', 'c', 'd'],
    )));
    await tester.pump();
    expect(find.byIcon(Icons.circle), findsNWidgets(4));
  });
}
