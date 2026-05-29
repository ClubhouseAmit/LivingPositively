// Phase E regression suite (ADR-005 §Decision step 5).
//
// Pins the shared async / loading-error contract introduced in
// `lib/util/async/async_state_view.dart`. The audit (`docs/UX_GAPS.md §1.5,
// §3.10`) flagged that async flows showed a bare spinner only while waiting,
// rendered nothing on error, and carried no screen-reader label. These tests
// exercise the REAL production widget (no stubs — see the team's test-pattern
// note) across all four states: loading, error-with-retry, empty, data.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mazilon/util/async/async_state_view.dart';

import '../../helpers/widget_test_scaffold.dart';

void main() {
  setUp(() {
    registerTestServices();
  });

  tearDown(() {
    resetTestServices();
  });

  group('AsyncStateView', () {
    testWidgets('shows a screen-reader-labelled spinner while waiting',
        (tester) async {
      final handle = tester.ensureSemantics();

      // A future that never completes keeps the view in the loading state.
      final never = Completer<List<String>>();
      addTearDown(() => never.complete(const []));

      await pumpWithProviders(
        tester,
        AsyncStateView<List<String>>(
          future: never.future,
          onData: (_, _) => const Text('data'),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      // English loading label from app_en.arb.
      expect(find.bySemanticsLabel('Loading'), findsOneWidget);
      expect(find.text('data'), findsNothing);

      // Dispose before the test body ends — the framework's
      // handle-leak check runs ahead of addTearDown callbacks.
      handle.dispose();
    });

    testWidgets('renders data when the future resolves', (tester) async {
      await pumpWithProviders(
        tester,
        AsyncStateView<List<String>>(
          future: Future.value(const ['a', 'b']),
          onData: (_, data) => Text('items:${data.length}'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('items:2'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('shows error message and retry button when future rejects',
        (tester) async {
      var retried = 0;

      // Complete with the error AFTER pump so FutureBuilder is already
      // listening — an eagerly-created Future.error reads as "unhandled" to
      // the test zone.
      final completer = Completer<List<String>>();
      await pumpWithProviders(
        tester,
        AsyncStateView<List<String>>(
          future: completer.future,
          onRetry: () => retried++,
          onData: (_, _) => const Text('data'),
        ),
      );
      completer.completeError(Exception('boom'));
      await tester.pumpAndSettle();

      // The data branch must NOT render on error (the old bug rendered an
      // empty grid silently).
      expect(find.text('data'), findsNothing);
      // English error + retry strings from app_en.arb.
      expect(find.text('Something went wrong.'), findsOneWidget);
      expect(find.text('Try again'), findsOneWidget);

      await tester.tap(find.text('Try again'));
      await tester.pump();
      expect(retried, 1);
    });

    testWidgets('hides retry button when no onRetry is provided',
        (tester) async {
      final completer = Completer<List<String>>();
      await pumpWithProviders(
        tester,
        AsyncStateView<List<String>>(
          future: completer.future,
          onData: (_, _) => const Text('data'),
        ),
      );
      completer.completeError(Exception('boom'));
      await tester.pumpAndSettle();

      // Message still shown (failure is never silent) but no retry control.
      expect(find.text('Something went wrong.'), findsOneWidget);
      expect(find.text('Try again'), findsNothing);
    });

    testWidgets('routes through emptyBuilder when isEmpty is true',
        (tester) async {
      await pumpWithProviders(
        tester,
        AsyncStateView<List<String>>(
          future: Future.value(const <String>[]),
          isEmpty: (data) => data.isEmpty,
          emptyBuilder: (_) => const Text('nothing here'),
          onData: (_, _) => const Text('data'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('nothing here'), findsOneWidget);
      expect(find.text('data'), findsNothing);
    });

    testWidgets('falls back to data builder when empty but no emptyBuilder',
        (tester) async {
      await pumpWithProviders(
        tester,
        AsyncStateView<List<String>>(
          future: Future.value(const <String>[]),
          isEmpty: (data) => data.isEmpty,
          onData: (_, data) => Text('data:${data.length}'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('data:0'), findsOneWidget);
    });
  });

  group('AsyncLoadingIndicator', () {
    testWidgets('uses an explicit label without any localizations in scope',
        (tester) async {
      final handle = tester.ensureSemantics();

      // Deliberately NOT using pumpWithProviders: no AppLocalizations
      // delegate, mirroring the boot spinner in main.dart.
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AsyncLoadingIndicator(semanticLabel: 'Booting'),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.bySemanticsLabel('Booting'), findsOneWidget);

      handle.dispose();
    });
  });
}
