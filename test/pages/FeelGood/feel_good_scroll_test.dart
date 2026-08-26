import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mazilon/pages/FeelGood/add_Image_item.dart';
import 'package:mazilon/pages/FeelGood/feelGood.dart';

import '../../helpers/widget_test_scaffold.dart';

void main() {
  group('FeelGood', () {
    late TestServiceLocators locators;

    setUp(() {
      locators = registerTestServices();
    });

    tearDown(() {
      resetTestServices();
    });

    testWidgets('should keep the photo grid reachable when text is enlarged', (
      tester,
    ) async {
      locators.picker.seededImagePaths.addAll(
        List<String>.generate(8, (index) => 'test_path_$index.jpg'),
      );

      await pumpWithProviders(
        tester,
        Builder(
          builder: (context) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: TextScaler.linear(2.5)),
            child: const FeelGood(),
          ),
        ),
        locale: const Locale('he'),
        surfaceSize: const Size(360, 690),
        ignoreOverflow: false,
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);

      final pageScrollableFinder = find.byWidgetPredicate(
        (widget) =>
            widget is Scrollable &&
            widget.physics is! NeverScrollableScrollPhysics,
      );
      expect(pageScrollableFinder, findsOneWidget);
      final pageScrollable = tester.state<ScrollableState>(
        pageScrollableFinder,
      );
      expect(pageScrollable.position.maxScrollExtent, greaterThan(0));

      final addImage = find.byType(ImageAddItem);
      await tester.ensureVisible(addImage);
      await tester.pumpAndSettle();

      expect(pageScrollable.position.pixels, greaterThan(0));
      expect(tester.takeException(), isNull);
    });
  });
}
