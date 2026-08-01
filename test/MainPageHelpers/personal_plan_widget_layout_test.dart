import 'dart:math';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
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

  testWidgets('header controls preserve directional order in Hebrew', (
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

  testWidgets('header controls preserve directional order in English', (
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

  testWidgets('refresh control uses the localized grey refresh icon', (
    tester,
  ) async {
    await pumpWithProviders(
      tester,
      PersonalPlanWidget(
        text: planText(const <String>[
          'First item',
          'Second item',
          'Third item',
        ]),
        changeCurrentIndex: (_, _) {},
      ),
      surfaceSize: const Size(700, 1200),
    );

    final refresh = find.byKey(const Key('personalPlanHeaderRefresh'));
    expect(refresh, findsOneWidget);
    expect(find.byTooltip('Refresh personal plan'), findsOneWidget);
    final button = tester.widget<IconButton>(refresh);
    expect(button.onPressed, isNotNull);
    expect(button.color, Theme.of(tester.element(refresh)).colorScheme.outline);
    expect(
      button.disabledColor,
      Theme.of(tester.element(refresh)).disabledColor,
    );

    final icon = tester.widget<Icon>(
      find.descendant(of: refresh, matching: find.byIcon(Icons.refresh)),
    );
    expect(icon.color, isNull);
    expect(icon.size, min(35.sp, 40));
  });

  testWidgets('refresh is disabled when there is no alternative preview', (
    tester,
  ) async {
    await pumpWithProviders(
      tester,
      PersonalPlanWidget(
        text: planText(const <String>[]),
        changeCurrentIndex: (_, _) {},
      ),
      surfaceSize: const Size(700, 1200),
    );

    final refresh = find.byKey(const Key('personalPlanHeaderRefresh'));
    expect(refresh, findsOneWidget);
    expect(tester.widget<IconButton>(refresh).onPressed, isNull);
    expect(find.byType(PersonalPlanItem), findsNothing);

    await pumpWithProviders(
      tester,
      PersonalPlanWidget(
        text: planText(const <String>['Only item']),
        changeCurrentIndex: (_, _) {},
      ),
      surfaceSize: const Size(700, 1200),
    );

    expect(tester.widget<IconButton>(refresh).onPressed, isNull);
    expect(_previewItemTexts(tester), <String>['Only item']);

    await pumpWithProviders(
      tester,
      PersonalPlanWidget(
        text: planText(const <String>['First item', 'Second item']),
        changeCurrentIndex: (_, _) {},
      ),
      surfaceSize: const Size(700, 1200),
    );

    expect(tester.widget<IconButton>(refresh).onPressed, isNull);
    expect(_previewItemTexts(tester), hasLength(2));

    await pumpWithProviders(
      tester,
      PersonalPlanWidget(
        text: planText(const <String>['Repeated item', 'Repeated item']),
        changeCurrentIndex: (_, _) {},
      ),
      surfaceSize: const Size(700, 1200),
    );

    expect(tester.widget<IconButton>(refresh).onPressed, isNull);
    expect(_previewItemTexts(tester), <String>[
      'Repeated item',
      'Repeated item',
    ]);

    await pumpWithProviders(
      tester,
      PersonalPlanWidget(
        text: planText(const <String>[
          'Repeated item',
          'Repeated item',
          'Repeated item',
        ]),
        changeCurrentIndex: (_, _) {},
      ),
      surfaceSize: const Size(700, 1200),
    );

    expect(tester.widget<IconButton>(refresh).onPressed, isNull);
    expect(_previewItemTexts(tester), <String>[
      'Repeated item',
      'Repeated item',
    ]);
    final disabledIcon = find.descendant(
      of: refresh,
      matching: find.byIcon(Icons.refresh),
    );
    expect(
      IconTheme.of(tester.element(disabledIcon)).color,
      Theme.of(tester.element(refresh)).disabledColor,
    );
  });

  testWidgets('refresh is disabled for a two-item preview', (tester) async {
    await pumpWithProviders(
      tester,
      PersonalPlanWidget(
        text: planText(const <String>['First item', 'Second item']),
        changeCurrentIndex: (_, _) {},
      ),
      surfaceSize: const Size(420, 1200),
      ignoreOverflow: false,
    );

    final refresh = find.byKey(const Key('personalPlanHeaderRefresh'));
    final before = _previewItemTexts(tester);
    expect(tester.widget<IconButton>(refresh).onPressed, isNull);
    await tester.tap(refresh);
    await tester.pump();

    expect(_previewItemTexts(tester), before);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'refresh selects a different pair when more items are available',
    (tester) async {
      const items = <String>['First item', 'Second item', 'Third item'];
      await pumpWithProviders(
        tester,
        PersonalPlanWidget(
          text: planText(items),
          changeCurrentIndex: (_, _) {},
        ),
        surfaceSize: const Size(420, 1200),
        ignoreOverflow: false,
      );

      final before = _previewItemTexts(tester);
      await tester.tap(find.byKey(const Key('personalPlanHeaderRefresh')));
      await tester.pump();
      final after = _previewItemTexts(tester);

      expect(after, hasLength(2));
      expect(after.every(items.contains), isTrue);
      expect(after.toSet().length, 2);
      expect(
        after.toSet().containsAll(before) && before.toSet().containsAll(after),
        isFalse,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('refresh changes the visible pair when source items repeat', (
    tester,
  ) async {
    const items = <String>['Repeated item', 'Repeated item', 'Different item'];
    await pumpWithProviders(
      tester,
      PersonalPlanWidget(text: planText(items), changeCurrentIndex: (_, _) {}),
      surfaceSize: const Size(420, 1200),
      ignoreOverflow: false,
    );

    final before = _previewItemTexts(tester)..sort();
    expect(
      tester
          .widget<IconButton>(
            find.byKey(const Key('personalPlanHeaderRefresh')),
          )
          .onPressed,
      isNotNull,
    );
    await tester.tap(find.byKey(const Key('personalPlanHeaderRefresh')));
    await tester.pump();
    final after = _previewItemTexts(tester)..sort();

    expect(after, isNot(equals(before)));
    expect(tester.takeException(), isNull);
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

    await tester.tap(find.byKey(const Key('personalPlanHeaderRefresh')));
    await tester.pump();
    expect(tester.takeException(), isNull);
  });
}

List<String> _previewItemTexts(WidgetTester tester) {
  return tester
      .widgetList<PersonalPlanItem>(find.byType(PersonalPlanItem))
      .map((item) => item.text)
      .toList();
}

void _expectHeaderControlLayout(WidgetTester tester, {required bool isRtl}) {
  final header = find.byKey(const Key('personalPlanHeader'));
  final title = find.byKey(const Key('personalPlanHeaderTitle'));
  final document = find.byKey(const Key('personalPlanHeaderDocument'));
  final actions = find.byKey(const Key('personalPlanHeaderActions'));
  final refresh = find.byKey(const Key('personalPlanHeaderRefresh'));
  final download = find.byKey(const Key('personalPlanHeaderDownload'));
  final share = find.byKey(const Key('personalPlanHeaderShare'));

  expect(header, findsOneWidget);
  expect(
    Directionality.of(tester.element(header)),
    isRtl ? TextDirection.rtl : TextDirection.ltr,
  );

  final titleX = tester.getCenter(title).dx;
  final documentX = tester.getCenter(document).dx;
  final refreshX = tester.getCenter(refresh).dx;
  final downloadX = tester.getCenter(download).dx;
  final shareX = tester.getCenter(share).dx;

  if (isRtl) {
    expect(shareX, lessThan(downloadX));
    expect(downloadX, lessThan(refreshX));
    expect(refreshX, lessThan(documentX));
    expect(documentX, lessThan(titleX));
  } else {
    expect(titleX, lessThan(documentX));
    expect(documentX, lessThan(refreshX));
    expect(refreshX, lessThan(downloadX));
    expect(downloadX, lessThan(shareX));
  }

  expect(tester.getSize(document), const Size(48, 48));
  expect(tester.getSize(refresh), const Size(48, 48));
  expect(tester.getSize(download), const Size(48, 48));
  expect(tester.getSize(share), const Size(48, 48));
  expect((refreshX - downloadX).abs(), closeTo(48, 0.5));
  expect((downloadX - shareX).abs(), closeTo(48, 0.5));
  expect((titleX - documentX).abs(), lessThan((titleX - downloadX).abs()));
  expect((titleX - documentX).abs(), lessThan((titleX - refreshX).abs()));
  expect((titleX - documentX).abs(), lessThan((titleX - shareX).abs()));

  final transform = tester.widget<Transform>(
    find.byKey(const Key('personalPlanHeaderShareTransform')),
  );
  expect(transform.transform.entry(0, 0), isRtl ? -1.0 : 1.0);

  final actionsRect = tester.getRect(actions);
  if (isRtl) {
    expect(tester.getRect(share).left, closeTo(actionsRect.left, 0.5));
  } else {
    expect(tester.getRect(share).right, closeTo(actionsRect.right, 0.5));
  }
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
