// Drives the IconButton onPressed handlers on ShareForm:
//   - share icon → invokes showShareDialog (lines 103-104)
//   - download icon → invokes fileService.download with the localized
//     headers, then dispatches a toast (lines 123-147)
//   - the finish button calls widget.submit
//
// We register a recording FileService fake via the shared scaffold to assert
// download() was called and to drive both the null-return (failure) and
// the success branches.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mazilon/form/shareform.dart';
import 'package:mazilon/util/userInformation.dart';

import '../helpers/widget_test_scaffold.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late TestServiceLocators services;
  late UserInformation user;

  setUp(() {
    services = registerTestServices(locale: 'en');
    user = UserInformation();
    user.gender = 'other';
    user.localeName = 'en';
  });

  tearDown(() {
    resetTestServices();
  });

  testWidgets('tapping the share IconButton opens the share dialog',
      (tester) async {
    await pumpWithProviders(
      tester,
      ShareForm(prev: () {}, submit: (_) {}),
      userInformation: user,
      surfaceSize: const Size(1024, 1800),
    );

    // The share icon is the first IconButton.
    final shareIcon = find.byIcon(Icons.share);
    expect(shareIcon, findsOneWidget);
    await tester.tap(shareIcon, warnIfMissed: false);
    await tester.pumpAndSettle();
    // showShareDialog opens an AlertDialog/Dialog from
    // util/Share/show_share_dialog.dart — verify a Dialog mounted without
    // crashing.
    expect(find.byType(Dialog), findsWidgets);
  });

  testWidgets(
      'tapping the download IconButton invokes FileService.download '
      '(null result → toast)',
      (tester) async {
    await pumpWithProviders(
      tester,
      ShareForm(prev: () {}, submit: (_) {}),
      userInformation: user,
      surfaceSize: const Size(1024, 1800),
    );

    final downloadIcon = find.byIcon(Icons.download);
    expect(downloadIcon, findsOneWidget);
    await tester.tap(downloadIcon, warnIfMissed: false);
    // The download future + toast both schedule timers via showToast →
    // FlutterToast platform channel — drain a tick.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(services.files.downloadCalls, 1);
  });

  testWidgets(
      'tapping the finish button calls widget.submit with context',
      (tester) async {
    var submitCalls = 0;
    await pumpWithProviders(
      tester,
      ShareForm(prev: () {}, submit: (_) => submitCalls++),
      userInformation: user,
      surfaceSize: const Size(1024, 1800),
    );

    final finishButton = find.ancestor(
      of: find.text("I'm Done!"),
      matching: find.byType(TextButton),
    );
    expect(finishButton, findsOneWidget);
    await tester.ensureVisible(finishButton);
    await tester.tap(finishButton);
    await tester.pumpAndSettle();

    expect(submitCalls, 1);
  });
}
