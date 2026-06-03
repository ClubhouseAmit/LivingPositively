// Widget tests for the real [VideoPlayerPage] (lib/pages/WellnessTools/player.dart).
//
// The production widget embeds a [YoutubePlayer], whose underlying WebView never
// becomes "ready" in a widget-test environment, so JS method calls no-op safely.
// We exercise the State logic that previously had ~5% coverage by driving the
// widget's internal [YoutubePlayerController] value directly: every value change
// fires the State's listener, which forwards full-screen changes to
// [VideoPlayerPage.onFullScreenChanged] and logs play/pause analytics events via
// the GetIt-registered [AnalyticsService]. We assert against the
// [NoopAnalyticsService] fake registered by the shared test scaffold.

import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mazilon/pages/WellnessTools/VideoPlayerInheritedWidget.dart';
import 'package:mazilon/pages/WellnessTools/player.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

import '../helpers/widget_test_scaffold.dart';

/// Stub [PlatformInAppWebViewWidget] that renders nothing. The real
/// implementation is a native platform view that is unavailable in widget
/// tests; [VideoPlayerPage] embeds a [YoutubePlayer] which builds one of these.
/// Returning an empty box lets the player's State mount so its
/// listener/analytics/lifecycle logic can be exercised.
class _StubInAppWebViewWidget extends PlatformInAppWebViewWidget {
  _StubInAppWebViewWidget(super.params) : super.implementation();

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();

  @override
  void dispose() {}

  @override
  T controllerFromPlatform<T>(PlatformInAppWebViewController controller) {
    // Never reached: onWebViewCreated only fires for the real platform view.
    throw UnimplementedError();
  }
}

/// Minimal [InAppWebViewPlatform] that only knows how to build the stub widget.
/// All other factory methods inherit their default "not implemented" throw,
/// which is fine because the player never invokes them in tests.
class _StubInAppWebViewPlatform extends InAppWebViewPlatform {
  @override
  PlatformInAppWebViewWidget createPlatformInAppWebViewWidget(
    PlatformInAppWebViewWidgetCreationParams params,
  ) {
    return _StubInAppWebViewWidget(params);
  }
}

void main() {
  late TestServiceLocators services;

  setUp(() {
    InAppWebViewPlatform.instance = _StubInAppWebViewPlatform();
    services = registerTestServices();
  });

  tearDown(() {
    resetTestServices();
  });

  // Retrieves the controller owned by the State, via the built YoutubePlayer.
  YoutubePlayerController controllerOf(WidgetTester tester) =>
      tester.widget<YoutubePlayer>(find.byType(YoutubePlayer)).controller;

  testWidgets('builds a YoutubePlayer seeded with the first videoId', (
    tester,
  ) async {
    await pumpWithProviders(
      tester,
      VideoPlayerPage(
        onFullScreenChanged: (_) {},
        videoData: const {
          'videoId': ['abcdefghijk'],
        },
      ),
    );

    expect(find.byType(YoutubePlayer), findsOneWidget);
    expect(controllerOf(tester).initialVideoId, 'abcdefghijk');
  });

  testWidgets('falls back to empty initial videoId when data is missing', (
    tester,
  ) async {
    await pumpWithProviders(
      tester,
      VideoPlayerPage(
        onFullScreenChanged: (_) {},
        videoData: const {},
      ),
    );

    expect(controllerOf(tester).initialVideoId, '');
  });

  testWidgets('forwards full-screen changes to onFullScreenChanged', (
    tester,
  ) async {
    final fullScreenStates = <bool>[];
    await pumpWithProviders(
      tester,
      VideoPlayerPage(
        onFullScreenChanged: fullScreenStates.add,
        videoData: const {
          'videoId': ['abcdefghijk'],
        },
      ),
    );

    final controller = controllerOf(tester);
    controller.updateValue(controller.value.copyWith(isFullScreen: true));
    await tester.pump();
    controller.updateValue(controller.value.copyWith(isFullScreen: false));
    await tester.pump();

    // The listener fires onFullScreenChanged on every value change; assert the
    // observed transition into and out of full screen is captured in order.
    expect(fullScreenStates, contains(true));
    expect(fullScreenStates.last, false);
  });

  testWidgets('logs "Video unpaused" with title and url when playback starts', (
    tester,
  ) async {
    await pumpWithProviders(
      tester,
      VideoPlayerPage(
        onFullScreenChanged: (_) {},
        videoData: const {
          'videoId': ['abcdefghijk'],
        },
      ),
    );

    final controller = controllerOf(tester);
    controller.updateValue(
      controller.value.copyWith(
        isPlaying: true,
        metaData: const YoutubeMetaData(
          title: 'Calm Breathing',
          videoId: 'abcdefghijk',
        ),
      ),
    );
    await tester.pump();

    final unpaused = services.analytics.events.firstWhere(
      (e) => e.key == 'Video unpaused',
      orElse: () => const MapEntry('', null),
    );
    expect(unpaused.key, 'Video unpaused');
    expect(unpaused.value?['title'], 'Calm Breathing');
    expect(unpaused.value?['url'], 'abcdefghijk');
  });

  testWidgets('logs "Video paused" when playback transitions to paused', (
    tester,
  ) async {
    await pumpWithProviders(
      tester,
      VideoPlayerPage(
        onFullScreenChanged: (_) {},
        videoData: const {
          'videoId': ['abcdefghijk'],
        },
      ),
    );

    final controller = controllerOf(tester);
    const meta = YoutubeMetaData(title: 'Grounding', videoId: 'abcdefghijk');
    controller.updateValue(
      controller.value.copyWith(isPlaying: true, metaData: meta),
    );
    await tester.pump();
    controller.updateValue(
      controller.value.copyWith(isPlaying: false, metaData: meta),
    );
    await tester.pump();

    expect(
      services.analytics.events.map((e) => e.key),
      containsAllInOrder(['Video unpaused', 'Video paused']),
    );
  });

  testWidgets('does not re-log analytics when play state is unchanged', (
    tester,
  ) async {
    await pumpWithProviders(
      tester,
      VideoPlayerPage(
        onFullScreenChanged: (_) {},
        videoData: const {
          'videoId': ['abcdefghijk'],
        },
      ),
    );

    final controller = controllerOf(tester);
    const meta = YoutubeMetaData(title: 'Stretch', videoId: 'abcdefghijk');
    controller.updateValue(
      controller.value.copyWith(isPlaying: true, metaData: meta),
    );
    await tester.pump();
    // A value change that leaves isPlaying untouched must not emit a new event.
    controller.updateValue(
      controller.value.copyWith(isFullScreen: true, metaData: meta),
    );
    await tester.pump();

    final playEvents = services.analytics.events
        .where((e) => e.key == 'Video unpaused' || e.key == 'Video paused')
        .length;
    expect(playEvents, 1);
  });

  testWidgets(
    'didChangeDependencies loads the videoId from VideoPlayerInheritedWidget',
    (tester) async {
      await pumpWithProviders(
        tester,
        VideoPlayerInheritedWidget(
          // A non-empty id that differs from the controller's empty metadata
          // forces the load() branch; an invalid (<11 char) id makes the load
          // observable via errorCode == 1.
          videoId: 'changed-id',
          changeVideo: (_) {},
          child: VideoPlayerPage(
            onFullScreenChanged: (_) {},
            videoData: const {},
          ),
        ),
      );

      expect(controllerOf(tester).value.errorCode, 1);
    },
  );

  testWidgets('disposes cleanly without throwing', (tester) async {
    await pumpWithProviders(
      tester,
      VideoPlayerPage(
        onFullScreenChanged: (_) {},
        videoData: const {
          'videoId': ['abcdefghijk'],
        },
      ),
    );

    // Replacing the tree disposes the State; the dispose() override resets the
    // controller value before disposing it (guarding youtube_player_flutter#1143).
    await tester.pumpWidget(const SizedBox.shrink());
    expect(tester.takeException(), isNull);
  });
}
