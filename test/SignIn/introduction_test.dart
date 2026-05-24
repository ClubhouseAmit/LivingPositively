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

  testWidgets('renders Scaffold + CircularProgressIndicator + greeting text',
      (tester) async {
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
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
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

  testWidgets('renders a different gender variant without throwing',
      (tester) async {
    final userInfo = UserInformation();
    userInfo.gender = 'female';
    userInfo.localeName = 'en';

    await pumpWithProviders(
      tester,
      const Introduction(),
      userInformation: userInfo,
      surfaceSize: const Size(1200, 1800),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });
}
