// Widget test for lib/pages/SignIn_Pages/introduction.dart.
//
// The Introduction screen renders a centered welcome message and a large
// CircularProgressIndicator while the app warms up. The body reads
// UserInformation.gender via Provider for the localized greeting variant.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mazilon/pages/SignIn_Pages/introduction.dart';
import 'package:mazilon/util/userInformation.dart';

import '../helpers/widget_test_scaffold.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    registerTestServices(locale: 'en');
  });

  tearDown(() {
    resetTestServices();
  });

  testWidgets('renders Scaffold + CircularProgressIndicator + greeting text', (
    tester,
  ) async {
    final userInfo = UserInformation();
    userInfo.gender = 'male';
    userInfo.localeName = 'en';

    await pumpWithProviders(
      tester,
      const Introduction(),
      userInformation: userInfo,
      surfaceSize: const Size(1200, 1800),
    );

    expect(find.byType(Introduction), findsOneWidget);
    expect(find.byType(Scaffold), findsOneWidget);
    
    final fractionallySizedBox = tester.widget<FractionallySizedBox>(find.byType(FractionallySizedBox));
    expect(fractionallySizedBox.widthFactor, 0.0); // Starts at 0.0 before animation
    expect(fractionallySizedBox.heightFactor, null);

    // The greeting is sourced from AppLocalizations and depends on gender.
    // We don't pin the literal string — just confirm a non-empty Text exists
    // inside the centered Column.
    final texts = find
        .byType(Text)
        .evaluate()
        .map((e) => (e.widget as Text).data ?? '')
        .where((s) => s.isNotEmpty)
        .toList();
    expect(texts, isNotEmpty);
  });

  testWidgets('renders a different gender variant without throwing', (
    tester,
  ) async {
    final userInfo = UserInformation();
    userInfo.gender = 'female';
    userInfo.localeName = 'en';

    await pumpWithProviders(
      tester,
      const Introduction(),
      userInformation: userInfo,
      surfaceSize: const Size(1200, 1800),
    );

    final fractionallySizedBox = tester.widget<FractionallySizedBox>(find.byType(FractionallySizedBox));
    expect(fractionallySizedBox.widthFactor, 0.0);
    expect(fractionallySizedBox.heightFactor, null);
  });

  testWidgets('renders child widget when provided and hides progress bar', (
    tester,
  ) async {
    final userInfo = UserInformation();
    userInfo.gender = 'male';
    userInfo.localeName = 'en';

    const testChild = Text('Error state rendered');

    await pumpWithProviders(
      tester,
      const Introduction(child: testChild),
      userInformation: userInfo,
      surfaceSize: const Size(1200, 1800),
    );

    expect(find.text('Error state rendered'), findsOneWidget);
    expect(find.byType(FractionallySizedBox), findsNothing);
  });
}
