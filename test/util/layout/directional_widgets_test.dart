import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mazilon/util/layout/directional_widgets.dart';

import '../../helpers/widget_test_scaffold.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SectionHeaderWidget onTitleTap', () {
    setUp(() {
      registerTestServices(locale: 'en');
    });

    tearDown(() {
      resetTestServices();
    });

    testWidgets('should trigger onTitleTap and expose default key fallback when titleKey is omitted', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      try {
        var tapped = false;
        await pumpWithProviders(
          tester,
          Scaffold(
            body: SectionHeaderWidget(
              title: 'Default Key Section',
              leadingIcon: Icons.star,
              onTitleTap: () {
                tapped = true;
              },
            ),
          ),
        );

        final defaultKeyFinder = find.byKey(const Key('sectionHeaderTitleTapTarget'));
        expect(defaultKeyFinder, findsOneWidget);

        await tester.tap(defaultKeyFinder);
        await tester.pump();

        expect(tapped, isTrue);

        final semantics = tester.getSemantics(find.text('Default Key Section'));
        expect(semantics.getSemanticsData().hasAction(SemanticsAction.tap), isTrue);
      } finally {
        handle.dispose();
      }
    });

    testWidgets('should trigger onTitleTap when custom titleKey is provided', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      try {
        var tapped = false;
        await pumpWithProviders(
          tester,
          Scaffold(
            body: SectionHeaderWidget(
              title: 'My Section',
              titleKey: const Key('customTitleKey'),
              leadingIcon: Icons.star,
              onTitleTap: () {
                tapped = true;
              },
            ),
          ),
        );

        final titleFinder = find.byKey(const Key('customTitleKey'));
        expect(titleFinder, findsOneWidget);

        await tester.tap(titleFinder);
        await tester.pump();

        expect(tapped, isTrue);

        final semantics = tester.getSemantics(find.text('My Section'));
        expect(semantics.getSemanticsData().hasAction(SemanticsAction.tap), isTrue);
      } finally {
        handle.dispose();
      }
    });

    testWidgets('should trigger onTitleTap callback when leading icon is tapped', (
      tester,
    ) async {
      var tapped = false;
      await pumpWithProviders(
        tester,
        Scaffold(
          body: SectionHeaderWidget(
            title: 'My Section',
            leadingIcon: Icons.star,
            onTitleTap: () {
              tapped = true;
            },
          ),
        ),
      );

      final iconFinder = find.byIcon(Icons.star);
      expect(iconFinder, findsOneWidget);

      await tester.tap(iconFinder);
      await tester.pump();

      expect(tapped, isTrue);
    });

    testWidgets('should occupy full width of Expanded and be tappable in whitespace', (
      tester,
    ) async {
      var tapCount = 0;
      await pumpWithProviders(
        tester,
        Scaffold(
          body: SizedBox(
            width: 400,
            child: SectionHeaderWidget(
              title: 'Title',
              leadingIcon: Icons.star,
              onTitleTap: () {
                tapCount++;
              },
            ),
          ),
        ),
        surfaceSize: const Size(600, 800),
      );

      // Tap near the far end of the Expanded region (e.g. at x=250)
      await tester.tapAt(const Offset(250, 20));
      await tester.pump();

      expect(tapCount, equals(1));
    });

    testWidgets('should not wrap with button semantics or interactive key when onTitleTap is null', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      try {
        await pumpWithProviders(
          tester,
          const Scaffold(
            body: SectionHeaderWidget(
              title: 'Static Section',
              leadingIcon: Icons.star,
            ),
          ),
        );

        final titleFinder = find.text('Static Section');
        expect(titleFinder, findsOneWidget);

        expect(find.byKey(const Key('sectionHeaderTitleTapTarget')), findsNothing);

        final semantics = tester.getSemantics(titleFinder);
        expect(semantics.getSemanticsData().hasAction(SemanticsAction.tap), isFalse);
      } finally {
        handle.dispose();
      }
    });
  });
}
