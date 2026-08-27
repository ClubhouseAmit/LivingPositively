// Phase 7 (ADR-002): integration test for VideoPlayerPage
// (`lib/pages/WellnessTools/player.dart`).
//
// The unit suite cannot pump VideoPlayerPage because the embedded
// YoutubePlayer wraps a native platform view (Android: a WebView; iOS: a
// WKWebView) that is unavailable under `flutter test`. Coverage stalled at
// 5.3%.
//
// On the integration_test binding running on a real Android emulator we pump
// the real VideoPlayerPage and exercise:
//
//   * initState — calls super.initState()
//   * didChangeDependencies — invokes _initializeController for controller
//     construction + listener registration, then branches on
//     VideoPlayerInheritedWidget's videoId
//   * the `listener` closure — fires when the controller's value changes,
//     calling onFullScreenChanged + _trackIsPlaying + _logEvent (both
//     unpaused/paused branches)
//   * build — controller.metadata.videoId getter read
//   * dispose — controller teardown
//
// The YouTube iframe itself is external to the app. These tests never wait for
// a remote metadata or playback event; controller state is updated directly
// where the app's listener behavior needs to be exercised.
//
// We mock the GetIt-provided AnalyticsService so _logEvent's
// `trackEvent` calls don't reach Mixpanel.
//
// Local-verification note (per ADR-002 hard rule #5): under `flutter test
// integration_test/wellness_player_test.dart` (no emulator), the YoutubePlayer
// platform view will fail to render and this file will fail to pump. That is
// expected — it is the whole reason this file lives in integration_test/
// rather than test/. The test logic is verifiable by construction (the
// listener/track/log calls are exercised via direct controller state updates,
// which work on any binding) and the documentation here is the
// contract for the CI emulator-runner job.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mazilon/AnalyticsService.dart';
import 'package:mazilon/l10n/app_localizations.dart';
import 'package:mazilon/pages/WellnessTools/VideoPlayerInheritedWidget.dart';
import 'package:mazilon/pages/WellnessTools/player.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

class _RecordingAnalytics implements AnalyticsService {
  final List<MapEntry<String, Map<String, dynamic>?>> events = [];

  @override
  Future<void> init() async {}

  @override
  Future<void> trackEvent(
    String eventName, [
    Map<String, dynamic>? properties,
  ]) async {
    events.add(MapEntry(eventName, properties));
  }
}

Widget _harness({
  required Function(bool) onFullScreenChanged,
  String inheritedVideoId = 'dQw4w9WgXcQ',
  List<String>? videoIds,
  bool isFullScreen = false,
}) {
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(
      body: VideoPlayerInheritedWidget(
        videoId: inheritedVideoId,
        changeVideo: (_) {},
        isFullScreen: isFullScreen,
        child: VideoPlayerPage(
          onFullScreenChanged: onFullScreenChanged,
          videoData: {
            'videoId': videoIds ?? [inheritedVideoId],
          },
        ),
      ),
    ),
  );
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late _RecordingAnalytics analytics;

  setUp(() async {
    await GetIt.instance.reset();
    analytics = _RecordingAnalytics();
    GetIt.instance.registerSingleton<AnalyticsService>(analytics);
  });

  tearDown(() async {
    await GetIt.instance.reset();
  });

  testWidgets(
    'VideoPlayerPage initState constructs controller and registers listener',
    (tester) async {
      var fullScreenChanges = <bool>[];
      const inheritedVideoId = 'dQw4w9WgXcQ';

      await tester.pumpWidget(
        _harness(
          onFullScreenChanged: (b) => fullScreenChanges.add(b),
          inheritedVideoId: inheritedVideoId,
          videoIds: const ['9bZkp7q19f0'],
        ),
      );
      // Allow the YoutubePlayer to begin initialising. On the Android emulator
      // its native handshake takes a few frames; on `flutter test` this will
      // throw and the test will fail — see file-level docstring.
      await tester.pump(const Duration(milliseconds: 100));

      // The VideoPlayerPage widget is in the tree. (We deliberately do NOT
      // pumpAndSettle here because the YoutubePlayer's internal animation
      // controller never settles.)
      expect(find.byType(VideoPlayerPage), findsOneWidget);
      final state = tester.state(find.byType(VideoPlayerPage)) as dynamic;
      final YoutubePlayerController controller =
          state.controller as YoutubePlayerController;
      expect(controller.key, inheritedVideoId);
    },
  );

  testWidgets(
    'listener fires on controller state change → onFullScreenChanged + _trackIsPlaying',
    (tester) async {
      final fullScreenChanges = <bool>[];

      await tester.pumpWidget(
        _harness(onFullScreenChanged: (b) => fullScreenChanges.add(b)),
      );
      await tester.pump(const Duration(milliseconds: 100));

      // Reach into the state to grab the controller and synthesise state
      // changes that drive the listener through both playback branches. The
      // controller is a public field on _VideoPlayerPageState, but the state
      // class itself is private — use the widget-test convention of grabbing
      // the State via `tester.state` and `dynamic` to call into it.
      final state = tester.state(find.byType(VideoPlayerPage)) as dynamic;
      final YoutubePlayerController controller =
          state.controller as YoutubePlayerController;

      // Drive fullscreen + playback transitions.
      controller.enterFullScreen();
      await tester.pump();
      controller.update(playerState: PlayerState.playing);
      await tester.pump();
      controller.update(playerState: PlayerState.paused);
      await tester.pump();

      expect(fullScreenChanges, contains(true));
      // Both unpaused + paused tracks should have fired.
      final names = analytics.events.map((e) => e.key).toSet();
      expect(names, containsAll(<String>{'Video unpaused', 'Video paused'}));
    },
  );

  testWidgets(
    'retries initialization when an inherited video ID becomes valid',
    (tester) async {
      const validVideoId = 'dQw4w9WgXcQ';

      await tester.pumpWidget(
        _harness(
          onFullScreenChanged: (_) {},
          inheritedVideoId: 'bad',
          videoIds: const ['bad'],
        ),
      );
      await tester.pump();
      expect(find.byType(YoutubePlayer), findsNothing);

      await tester.pumpWidget(
        _harness(
          onFullScreenChanged: (_) {},
          inheritedVideoId: validVideoId,
          videoIds: const ['bad'],
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      final state = tester.state(find.byType(VideoPlayerPage)) as dynamic;
      final YoutubePlayerController controller =
          state.controller as YoutubePlayerController;
      expect(controller.key, validVideoId);
      expect(find.byType(YoutubePlayer), findsOneWidget);
    },
  );

  testWidgets(
    'didChangeDependencies preserves the controller for an inherited video change',
    (tester) async {
      const firstVideoId = 'dQw4w9WgXcQ';
      const secondVideoId = '9bZkp7q19f0';
      await tester.pumpWidget(
        _harness(onFullScreenChanged: (_) {}, inheritedVideoId: firstVideoId),
      );
      await tester.pump(const Duration(milliseconds: 100));
      final state = tester.state(find.byType(VideoPlayerPage)) as dynamic;
      final YoutubePlayerController controller =
          state.controller as YoutubePlayerController;

      // The real controller remains mounted while the inherited selection
      // changes. Do not wait for the external YouTube iframe to load it.
      await tester.pumpWidget(
        _harness(
          onFullScreenChanged: (_) {},
          inheritedVideoId: secondVideoId,
          videoIds: const [firstVideoId],
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(VideoPlayerPage), findsOneWidget);
      expect(
        (tester.state(find.byType(VideoPlayerPage)) as dynamic).controller,
        same(controller),
      );
      expect(find.byType(YoutubePlayer), findsOneWidget);
    },
  );

  testWidgets(
    'synchronizes inherited fullscreen configuration with the controller',
    (tester) async {
      const videoId = 'dQw4w9WgXcQ';
      final fullscreenChanges = <bool>[];
      var configuredFullScreen = true;
      late void Function(bool) updateFullScreen;

      await tester.pumpWidget(
        StatefulBuilder(
          builder: (_, setState) {
            updateFullScreen = (bool value) {
              setState(() => configuredFullScreen = value);
            };
            return _harness(
              onFullScreenChanged: fullscreenChanges.add,
              inheritedVideoId: videoId,
              isFullScreen: configuredFullScreen,
            );
          },
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      final state = tester.state(find.byType(VideoPlayerPage)) as dynamic;
      final YoutubePlayerController controller =
          state.controller as YoutubePlayerController;
      expect(controller.value.fullScreenOption.enabled, isTrue);
      expect(fullscreenChanges, isEmpty);

      updateFullScreen(false);
      await tester.pump(null, EnginePhase.build);
      expect(controller.value.fullScreenOption.enabled, isTrue);
      expect(fullscreenChanges, isEmpty);

      updateFullScreen(true);
      await tester.pump(null, EnginePhase.build);
      await tester.pump();
      expect(controller.value.fullScreenOption.enabled, isTrue);
      expect(fullscreenChanges, isEmpty);

      updateFullScreen(false);
      await tester.pump();
      expect(controller.value.fullScreenOption.enabled, isFalse);
      expect(fullscreenChanges, [false]);

      updateFullScreen(true);
      await tester.pump();
      expect(controller.value.fullScreenOption.enabled, isTrue);
      expect(fullscreenChanges, [false, true]);

      updateFullScreen(false);
      await tester.pump(null, EnginePhase.build);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      expect(fullscreenChanges, [false, true]);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'an untagged player error keeps an equivalent selection retryable',
    (tester) async {
      const firstVideoId = 'dQw4w9WgXcQ';
      await tester.pumpWidget(
        _harness(onFullScreenChanged: (_) {}, inheritedVideoId: firstVideoId),
      );

      final state = tester.state(find.byType(VideoPlayerPage)) as dynamic;
      final YoutubePlayerController controller =
          state.controller as YoutubePlayerController;

      // The iframe can report an error without metadata. The retry path must not
      // depend on a network-backed video activation.
      controller.update(error: YoutubeError.cannotFindVideo);
      await tester.pump();

      await tester.pumpWidget(
        _harness(
          onFullScreenChanged: (_) {},
          inheritedVideoId: 'https://www.youtube.com/watch?v=$firstVideoId',
          videoIds: const [firstVideoId],
        ),
      );
      await tester.pump();

      expect(find.byType(YoutubePlayer), findsOneWidget);
      expect(
        (tester.state(find.byType(VideoPlayerPage)) as dynamic).controller,
        same(controller),
      );
    },
  );

  testWidgets('a stale player error does not invalidate a newer selection', (
    tester,
  ) async {
    const firstVideoId = 'dQw4w9WgXcQ';
    const staleVideoId = '9bZkp7q19f0';
    const newestVideoId = 'M7lc1UVf-VE';
    await tester.pumpWidget(
      _harness(onFullScreenChanged: (_) {}, inheritedVideoId: firstVideoId),
    );

    final state = tester.state(find.byType(VideoPlayerPage)) as dynamic;
    final YoutubePlayerController controller =
        state.controller as YoutubePlayerController;
    await tester.pumpWidget(
      _harness(
        onFullScreenChanged: (_) {},
        inheritedVideoId: staleVideoId,
        videoIds: const [firstVideoId],
      ),
    );
    await tester.pumpWidget(
      _harness(
        onFullScreenChanged: (_) {},
        inheritedVideoId: newestVideoId,
        videoIds: const [firstVideoId],
      ),
    );
    // This retains staleVideoId in the controller metadata, exactly as the
    // iframe's error-only event handling does.
    controller.update(
      metaData: const YoutubeMetaData(videoId: staleVideoId),
      error: YoutubeError.cannotFindVideo,
    );
    await tester.pump();

    expect(find.byType(YoutubePlayer), findsOneWidget);
    expect(
      (tester.state(find.byType(VideoPlayerPage)) as dynamic).controller,
      same(controller),
    );
  });

  testWidgets('a tagged player error keeps the requested video retryable', (
    tester,
  ) async {
    const firstVideoId = 'dQw4w9WgXcQ';
    const retriedVideoId = '9bZkp7q19f0';
    await tester.pumpWidget(
      _harness(onFullScreenChanged: (_) {}, inheritedVideoId: firstVideoId),
    );

    final state = tester.state(find.byType(VideoPlayerPage)) as dynamic;
    final YoutubePlayerController controller =
        state.controller as YoutubePlayerController;
    await tester.pumpWidget(
      _harness(
        onFullScreenChanged: (_) {},
        inheritedVideoId: retriedVideoId,
        videoIds: const [firstVideoId],
      ),
    );
    await tester.pump();

    // A tagged error clears the in-flight request so the equivalent URL form
    // can request the same video again without waiting for remote playback.
    controller.update(
      metaData: const YoutubeMetaData(videoId: retriedVideoId),
      error: YoutubeError.cannotFindVideo,
    );
    await tester.pump();

    await tester.pumpWidget(
      _harness(
        onFullScreenChanged: (_) {},
        inheritedVideoId: 'https://www.youtube.com/watch?v=$retriedVideoId',
        videoIds: const [firstVideoId],
      ),
    );
    await tester.pump();

    expect(find.byType(YoutubePlayer), findsOneWidget);
    expect(
      (tester.state(find.byType(VideoPlayerPage)) as dynamic).controller,
      same(controller),
    );
  });

  testWidgets('VideoPlayerPage closes its controller stream on disposal', (
    tester,
  ) async {
    await tester.pumpWidget(_harness(onFullScreenChanged: (_) {}));
    await tester.pump(const Duration(milliseconds: 100));
    final state = tester.state(find.byType(VideoPlayerPage)) as dynamic;
    final YoutubePlayerController controller =
        state.controller as YoutubePlayerController;
    final streamClosed = Completer<void>();
    controller.stream.listen(null, onDone: streamClosed.complete);

    // Replacing the page closes the owned controller and its value stream.
    await tester.pumpWidget(const MaterialApp(home: SizedBox.shrink()));
    await tester.pump();

    expect(find.byType(VideoPlayerPage), findsNothing);
    await expectLater(
      streamClosed.future.timeout(const Duration(seconds: 5)),
      completes,
    );
  });
}
