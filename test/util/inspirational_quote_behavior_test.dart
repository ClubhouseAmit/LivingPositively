import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mazilon/util/HomePage/inspirationalQuote.dart';

import '../helpers/widget_test_scaffold.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    registerTestServices(locale: 'en');
  });

  tearDown(() {
    resetTestServices();
  });

  testWidgets('empty quote list renders without throwing or controls', (
    tester,
  ) async {
    await pumpWithProviders(
      tester,
      const Scaffold(body: InspirationalQuote(quotes: <String>[])),
    );

    expect(find.byType(InspirationalQuote), findsOneWidget);
    expect(find.text('No quote is available right now.'), findsOneWidget);
    expect(find.byIcon(Icons.close), findsNothing);
    expect(find.byIcon(Icons.refresh), findsNothing);
  });

  testWidgets('dismissed quote can be restored from snackbar undo', (
    tester,
  ) async {
    await pumpWithProviders(
      tester,
      const Scaffold(body: InspirationalQuote(quotes: <String>['quote-1'])),
      surfaceSize: const Size(900, 900),
    );

    expect(find.text('quote-1'), findsOneWidget);

    await tester.tap(find.byTooltip('Dismiss quote'));
    await tester.pump();

    expect(find.text('Quote dismissed.'), findsOneWidget);
    expect(find.text('quote-1'), findsNothing);

    tester.widget<SnackBarAction>(find.byType(SnackBarAction)).onPressed();
    await tester.pump();

    expect(find.text('quote-1'), findsOneWidget);
  });
}
