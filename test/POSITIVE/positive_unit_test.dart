// Widget tests for the REAL Positive page in lib/pages/positive.dart.
//
// Replaces the previous test which loaded a sibling stub `positiveTest.dart`
// that fabricated its own widget tree and ignored Provider/GetIt entirely.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mazilon/pages/positive.dart';
import 'package:mazilon/pages/thankYou.dart';
import 'package:mazilon/util/Traits/positiveTraitItemSug.dart';
import 'package:mazilon/util/userInformation.dart';

import '../helpers/widget_test_scaffold.dart';

/// Advance the fake clock past the legacy delayed-popup window.
///
/// PR #282 intentionally removed the old 10-second modal nag from [Positive],
/// but this helper still gives older queued dialog work a chance to settle and
/// dismisses any dialog opened by an interaction under test.
Future<void> _advancePastInitDelayAndDismiss(WidgetTester tester) async {
  await tester.pump(const Duration(seconds: 11));
  // pumpAndSettle would also drain animations.
  await tester.pump();
  // Tap the dialog's close button if present.
  final dialogButton = find.byType(TextButton);
  if (dialogButton.evaluate().isNotEmpty) {
    for (final element in dialogButton.evaluate()) {
      // Find the one that's inside an AlertDialog and tap it.
      final ancestor = element.findAncestorWidgetOfExactType<AlertDialog>();
      if (ancestor != null) {
        await tester.tap(find.byWidget(element.widget), warnIfMissed: false);
        await tester.pumpAndSettle();
        break;
      }
    }
  }
  drainOverflowExceptions(tester);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late UserInformation userInformation;

  setUp(() {
    registerTestServices(locale: 'en');
    userInformation = UserInformation();
    userInformation.gender = 'other';
    userInformation.localeName = 'en';
  });

  tearDown(() {
    resetTestServices();
  });

  group('Positive (real production widget)', () {
    testWidgets('renders empty positive page with suggestions and add icon', (
      tester,
    ) async {
      await pumpWithProviders(
        tester,
        const Positive(),
        userInformation: userInformation,
        surfaceSize: const Size(1024, 1800),
      );

      expect(find.byType(Positive), findsOneWidget);
      // No existing positive traits → no ThankYou rows.
      expect(find.byType(ThankYou), findsNothing);
      // The positive page renders up to three suggestion widgets.
      expect(find.byType(PositiveTraitItemSug), findsWidgets);
      // The page-level add icon (Icons.add) is visible.
      expect(find.byIcon(Icons.add), findsWidgets);

      await _advancePastInitDelayAndDismiss(tester);
    });

    testWidgets('refresh button rebuilds suggestions without error', (
      tester,
    ) async {
      await pumpWithProviders(
        tester,
        const Positive(),
        userInformation: userInformation,
        surfaceSize: const Size(1024, 1800),
      );

      final refreshIcon = find.byIcon(Icons.refresh);
      expect(refreshIcon, findsOneWidget);
      await tester.ensureVisible(refreshIcon);
      final refreshButton = find.ancestor(
        of: refreshIcon,
        matching: find.byType(TextButton),
      );
      await tester.tap(refreshButton, warnIfMissed: false);
      await tester.pump();
      // Page rebuilt; suggestions still render.
      expect(find.byType(PositiveTraitItemSug), findsWidgets);

      await _advancePastInitDelayAndDismiss(tester);
    });

    testWidgets('existing positive traits render as ThankYou rows', (
      tester,
    ) async {
      userInformation.updatePositiveTraits(['Kind', 'Patient']);

      await pumpWithProviders(
        tester,
        const Positive(),
        userInformation: userInformation,
        surfaceSize: const Size(1024, 1800),
      );

      expect(find.byType(ThankYou), findsNWidgets(2));
      expect(find.text('Kind'), findsOneWidget);
      expect(find.text('Patient'), findsOneWidget);

      await _advancePastInitDelayAndDismiss(tester);
    });

    testWidgets(
      'divider only shows when there is at least one positive trait',
      (tester) async {
        userInformation.updatePositiveTraits(['Brave']);
        await pumpWithProviders(
          tester,
          const Positive(),
          userInformation: userInformation,
          surfaceSize: const Size(1024, 1800),
        );
        expect(find.byType(Divider), findsOneWidget);
        await _advancePastInitDelayAndDismiss(tester);
      },
    );

    testWidgets(
      'after init delay the page does not show the removed modal nag',
      (tester) async {
        await pumpWithProviders(
          tester,
          const Positive(),
          userInformation: userInformation,
          surfaceSize: const Size(1024, 1800),
        );
        // Before the delay fires, no dialog yet.
        expect(find.byType(AlertDialog), findsNothing);
        // Advance past the old 10s popup window. The UX-gap fix removed that
        // delayed modal, so the page should remain usable without interruption.
        await tester.pump(const Duration(seconds: 11));
        await tester.pump();
        expect(find.byType(AlertDialog), findsNothing);
      },
    );
  });
}
