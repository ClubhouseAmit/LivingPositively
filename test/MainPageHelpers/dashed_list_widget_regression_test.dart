import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mazilon/MainPageHelpers/components/dashed_list_widget.dart';
import 'package:mazilon/MainPageHelpers/components/gratitude_section.dart';
import 'package:mazilon/util/layout/directional_widgets.dart';
import 'package:mazilon/util/userInformation.dart';

import '../helpers/widget_test_scaffold.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => registerTestServices(locale: 'en'));
  tearDown(resetTestServices);

  testWidgets(
    'DashedListWidget should contain a second promotion during the fade animation',
    (tester) async {
      final user = UserInformation(gender: 'other', localeName: 'en');
      final items = <String>[];

      await pumpWithProviders(
        tester,
        StatefulBuilder(
          builder: (context, setHostState) => Scaffold(
            body: DashedListWidget(
              title: 'Title',
              subtitle: 'Subtitle',
              iconAsset: 'assets/images/diamond_icon.svg',
              items: items,
              suggestions: const ['one', 'two', 'three', 'four', 'five'],
              totalCount: items.length,
              onOpenSection: () {},
              onAddSuggestion: (suggestion) {
                setHostState(() => items.insert(0, suggestion));
              },
            ),
          ),
        ),
        userInformation: user,
        surfaceSize: const Size(800, 1200),
      );

      await tester.tap(find.text('one'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 410));
      await tester.pump();
      expect(items, hasLength(1));
      await tester.tap(find.text('two'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 410));
      await tester.pump();
      await tester.pumpAndSettle();

      expect(items, hasLength(2));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('DashedListWidget should mirror its see-all chevron in RTL', (
    tester,
  ) async {
    final user = UserInformation(gender: 'other', localeName: 'he');

    await pumpWithProviders(
      tester,
      Scaffold(
        body: DashedListWidget(
          title: 'כותרת',
          subtitle: 'תיאור',
          iconAsset: 'assets/images/diamond_icon.svg',
          items: const [],
          suggestions: const ['אחד'],
          totalCount: 0,
          onOpenSection: () {},
        ),
      ),
      userInformation: user,
      locale: const Locale('he'),
    );

    expect(find.byIcon(Icons.chevron_left), findsOneWidget);
    expect(find.byIcon(Icons.chevron_right), findsNothing);
  });

  testWidgets('GratitudeSectionWidget should count the full journal', (
    tester,
  ) async {
    final now = DateTime.now();
    final year = now.year.toString().padLeft(4, '0');
    final month = now.month.toString().padLeft(2, '0');
    final day = now.day.toString().padLeft(2, '0');
    final user = UserInformation(
      gender: 'other',
      localeName: 'en',
      thanks: {
        'thanks': const ['historic', 'today'],
        'dates': ['2000-01-01', '$year-$month-$day'],
      },
    );

    await pumpWithProviders(
      tester,
      Scaffold(body: GratitudeSectionWidget(onOpenSection: () {})),
      userInformation: user,
    );

    final section = tester.widget<DashedListWidget>(
      find.byType(DashedListWidget),
    );
    expect(section.items, ['today']);
    expect(section.totalCount, 2);
  });

  testWidgets('CardContainer should use its default radius safely', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: CardContainer(child: SizedBox())),
    );

    final container = tester.widget<Container>(
      find.descendant(
        of: find.byType(CardContainer),
        matching: find.byType(Container),
      ),
    );
    final decoration = container.decoration! as BoxDecoration;
    expect(decoration.borderRadius, BorderRadius.circular(16));
  });
}
