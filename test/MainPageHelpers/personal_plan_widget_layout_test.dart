import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mazilon/MainPageHelpers/personalPlanWidget.dart';
import 'package:mazilon/global_enums.dart';
import 'package:mazilon/util/personalPlanItem.dart';

import '../helpers/widget_test_scaffold.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    registerTestServices(locale: 'en');
  });

  tearDown(() {
    resetTestServices();
  });

  Map<String, dynamic> planText(List<String> items) {
    return <String, dynamic>{
      'SubTitle': 'A personal plan preview',
      'list': items,
    };
  }

  testWidgets('uses a single-column wrap on narrow width', (tester) async {
    await pumpWithProviders(
      tester,
      PersonalPlanWidget(
        text: planText(const <String>['First long item', 'Second long item']),
        changeCurrentIndex: (_, _) {},
      ),
      surfaceSize: const Size(420, 1200),
      ignoreOverflow: false,
    );

    expect(tester.takeException(), isNull);
    expect(find.byType(PersonalPlanItem), findsNWidgets(2));

    final firstTop = tester.getTopLeft(find.byType(PersonalPlanItem).at(0));
    final secondTop = tester.getTopLeft(find.byType(PersonalPlanItem).at(1));
    expect(secondTop.dy, greaterThan(firstTop.dy));
  });

  testWidgets('uses two preview columns on wide width', (tester) async {
    await pumpWithProviders(
      tester,
      PersonalPlanWidget(
        text: planText(const <String>['First long item', 'Second long item']),
        changeCurrentIndex: (_, _) {},
      ),
      surfaceSize: const Size(900, 1200),
      ignoreOverflow: false,
    );

    expect(tester.takeException(), isNull);
    expect(find.byType(PersonalPlanItem), findsNWidgets(2));

    final firstTop = tester.getTopLeft(find.byType(PersonalPlanItem).at(0));
    final secondTop = tester.getTopLeft(find.byType(PersonalPlanItem).at(1));
    expect((secondTop.dy - firstTop.dy).abs(), lessThan(2));
    expect(secondTop.dx, greaterThan(firstTop.dx));
  });

  testWidgets('header controls are ordered and evenly spaced in Hebrew', (
    tester,
  ) async {
    await pumpWithProviders(
      tester,
      PersonalPlanWidget(
        text: planText(const <String>['First item', 'Second item']),
        changeCurrentIndex: (_, _) {},
      ),
      locale: const Locale('he'),
      surfaceSize: const Size(700, 1200),
      ignoreOverflow: false,
    );

    _expectHeaderControlLayout(tester, isRtl: true);
  });

  testWidgets('header controls are ordered and evenly spaced in English', (
    tester,
  ) async {
    await pumpWithProviders(
      tester,
      PersonalPlanWidget(
        text: planText(const <String>['First item', 'Second item']),
        changeCurrentIndex: (_, _) {},
      ),
      surfaceSize: const Size(700, 1200),
      ignoreOverflow: false,
    );

    _expectHeaderControlLayout(tester, isRtl: false);
  });

  testWidgets('header subtitle follows an ambient Directionality override', (
    tester,
  ) async {
    await pumpWithProviders(
      tester,
      Directionality(
        textDirection: TextDirection.rtl,
        child: PersonalPlanWidget(
          text: planText(const <String>['First item', 'Second item']),
          changeCurrentIndex: (_, _) {},
        ),
      ),
      surfaceSize: const Size(700, 1200),
      ignoreOverflow: false,
    );

    _expectHeaderControlLayout(tester, isRtl: true);
    final subtitle = tester.widget<AutoSizeText>(
      find.descendant(
        of: find.byKey(const Key('personalPlanHeader')),
        matching: find.byWidgetPredicate(
          (widget) =>
              widget is AutoSizeText &&
              widget.data == 'A personal plan preview',
        ),
      ),
    );
    expect(subtitle.textAlign, TextAlign.right);
  });

  testWidgets('header title opens the full Personal Plan', (tester) async {
    var fullPlanCalls = 0;
    await pumpWithProviders(
      tester,
      PersonalPlanWidget(
        text: planText(const <String>['First item', 'Second item']),
        changeCurrentIndex: (_, page) {
          if (page == PagesCode.FullPlan) {
            fullPlanCalls++;
          }
        },
      ),
      surfaceSize: const Size(700, 1200),
    );

    await tester.tap(find.byKey(const Key('personalPlanHeaderTitle')));
    await tester.pump();

    expect(fullPlanCalls, 1);
  });

  testWidgets('view-all control is a TextButton that opens full plan', (
    tester,
  ) async {
    var fullPlanCalls = 0;
    await pumpWithProviders(
      tester,
      PersonalPlanWidget(
        text: planText(const <String>['First item', 'Second item']),
        changeCurrentIndex: (_, page) {
          if (page == PagesCode.FullPlan) {
            fullPlanCalls++;
          }
        },
      ),
      surfaceSize: const Size(700, 1200),
    );

    final button = find.byKey(const Key('personalPlanViewAllButton'));
    expect(button, findsOneWidget);
    expect(
      find.descendant(of: button, matching: find.text('To see My Plan')),
      findsOneWidget,
    );

    await tester.tap(button);
    await tester.pump();
    expect(fullPlanCalls, 1);

    fullPlanCalls = 0;
    for (var i = 0; i < 8; i++) {
      if (_focusedWithin(tester, button)) {
        break;
      }
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
    }
    expect(_focusedWithin(tester, button), isTrue);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    expect(fullPlanCalls, 1);
  });

  testWidgets('Hebrew view-all control uses right-pointing arrow', (
    tester,
  ) async {
    await pumpWithProviders(
      tester,
      PersonalPlanWidget(
        text: planText(const <String>['First item', 'Second item']),
        changeCurrentIndex: (_, _) {},
      ),
      locale: const Locale('he'),
      surfaceSize: const Size(700, 1200),
    );

    final button = find.byKey(const Key('personalPlanViewAllButton'));
    expect(button, findsOneWidget);
    expect(
      find.descendant(of: button, matching: find.text('לכל התוכנית')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: button, matching: find.byIcon(Icons.arrow_right)),
      findsOneWidget,
    );
    expect(
      find.descendant(of: button, matching: find.byIcon(Icons.arrow_left)),
      findsNothing,
    );
  });

  testWidgets('large Hebrew preview text does not overflow', (tester) async {
    await pumpWithProviders(
      tester,
      MediaQuery(
        data: const MediaQueryData(textScaler: TextScaler.linear(2.0)),
        child: PersonalPlanWidget(
          text: planText(const <String>[
            'פעולה ארוכה מאוד לשמירה על עצמי בזמן מצוקה',
            'עוד פעולה ארוכה מאוד שאמורה להישאר בתוך הכרטיס',
          ]),
          changeCurrentIndex: (_, _) {},
        ),
      ),
      locale: const Locale('he'),
      surfaceSize: const Size(420, 1600),
      ignoreOverflow: false,
    );

    expect(tester.takeException(), isNull);
    expect(find.byType(PersonalPlanItem), findsNWidgets(2));
  });
}

void _expectHeaderControlLayout(WidgetTester tester, {required bool isRtl}) {
  final header = find.byKey(const Key('personalPlanHeader'));
  final title = find.byKey(const Key('personalPlanHeaderTitle'));
  final document = find.byKey(const Key('personalPlanHeaderDocument'));
  final download = find.byKey(const Key('personalPlanHeaderDownload'));
  final share = find.byKey(const Key('personalPlanHeaderShare'));

  expect(header, findsOneWidget);
  expect(
    Directionality.of(tester.element(header)),
    isRtl ? TextDirection.rtl : TextDirection.ltr,
  );

  final titleX = tester.getCenter(title).dx;
  final documentX = tester.getCenter(document).dx;
  final downloadX = tester.getCenter(download).dx;
  final shareX = tester.getCenter(share).dx;

  if (isRtl) {
    expect(shareX, lessThan(downloadX));
    expect(downloadX, lessThan(documentX));
    expect(documentX, lessThan(titleX));
  } else {
    expect(titleX, lessThan(documentX));
    expect(documentX, lessThan(downloadX));
    expect(downloadX, lessThan(shareX));
  }

  expect(tester.getSize(document), const Size(48, 48));
  expect(tester.getSize(download), const Size(48, 48));
  expect(tester.getSize(share), const Size(48, 48));
  expect(
    (shareX - downloadX).abs(),
    closeTo((downloadX - documentX).abs(), 0.5),
  );
  expect((titleX - documentX).abs(), lessThan((titleX - downloadX).abs()));
  expect((titleX - documentX).abs(), lessThan((titleX - shareX).abs()));

  final transform = tester.widget<Transform>(
    find.byKey(const Key('personalPlanHeaderShareTransform')),
  );
  expect(transform.transform.entry(0, 0), isRtl ? -1.0 : 1.0);
}

bool _focusedWithin(WidgetTester tester, Finder finder) {
  final focusedContext = tester.binding.focusManager.primaryFocus?.context;
  if (focusedContext == null) {
    return false;
  }
  final targetElements = finder.evaluate().toSet();
  if (targetElements.contains(focusedContext)) {
    return true;
  }
  var found = false;
  focusedContext.visitAncestorElements((ancestor) {
    if (targetElements.contains(ancestor)) {
      found = true;
      return false;
    }
    return true;
  });
  return found;
}
