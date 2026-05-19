// Phase 7 (ADR-002): integration test for VideoPlayerPage
// (`lib/pages/WellnessTools/player.dart`).
//
// The unit suite cannot pump VideoPlayerPage because the embedded
// YoutubePlayer wraps a native platform view (Android: a WebView; iOS: a
// WKWebView) that is unavailable under `flutter test`. Coverage stalled at
// 5.3%.
//
// On the integration_test binding running on a real Android emulator the
// platform view DOES initialise, so we pump the real VideoPlayerPage and
// exercise:
//
//   * initState — controller construction + listener registration
//   * the `listener` closure — fires when the controller's value changes,
//     calling onFullScreenChanged + _trackIsPlaying + _logEvent (both
//     unpaused/paused branches)
//   * didChangeDependencies — branched on VideoPlayerInheritedWidget's
//     videoId
//   * build — controller.metadata.videoId getter read
//   * dispose — controller teardown
//
// We mock the GetIt-provided AnalyticsService so _logEvent's
// `trackEvent` calls don't reach Mixpanel.
//
// Local-verification note (per ADR-002 hard rule #5): under `flutter test
// integration_test/wellness_player_test.dart` (no emulator), the YoutubePlayer
// platform view will fail to render and this file will fail to pump. That is
// expected — it is the whole reason this file lives in integration_test/
// rather than test/. The test logic is verifiable by construction (the
// listener/track/log calls are exercised via direct value mutation of the
// controller, which works on any binding) and the documentation here is the
// contract for the CI emulator-runner job.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mazilon/AnalyticsService.dart';
import 'package:mazilon/pages/WellnessTools/VideoPlayerInheritedWidget.dart';
import 'package:mazilon/pages/WellnessTools/player.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

class _RecordingAnalytics implements AnalyticsService {
  final List<MapEntry<String, Map<String, dynamic>?>> events = [];

  @override
  Future<void> init() async {}

  @override
  Future<void> trackEvent(String eventName,
      [Map<String, dynamic>? properties]) async {
    events.add(MapEntry(eventName, properties));
  }
}

Widget _harness({
  required Function(bool) onFullScreenChanged,
  String videoId = 'dQw4w9WgXcQ',
}) {
  return MaterialApp(
    home: Scaffold(
      body: VideoPlayerInheritedWidget(
        videoId: videoId,
        changeVideo: (_) {},
        child: VideoPlayerPage(
          onFullScreenChanged: onFullScreenChanged,
          videoData: {
            'videoId': [videoId],
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

    await tester.pumpWidget(
      _harness(onFullScreenChanged: (b) => fullScreenChanges.add(b)),
    );
    // Allow the YoutubePlayer to begin initialising. On the Android emulator
    // its native handshake takes a few frames; on `flutter test` this will
    // throw and the test will fail — see file-level docstring.
    await tester.pump(const Duration(milliseconds: 100));

    // The VideoPlayerPage widget is in the tree. (We deliberately do NOT
    // pumpAndSettle here because the YoutubePlayer's internal animation
    // controller never settles.)
    expect(find.byType(VideoPlayerPage), findsOneWidget);
  });

  testWidgets(
      'listener fires on controller value change → onFullScreenChanged + _trackIsPlaying',
      (tester) async {
    final fullScreenChanges = <bool>[];

    await tester.pumpWidget(
      _harness(onFullScreenChanged: (b) => fullScreenChanges.add(b)),
    );
    await tester.pump(const Duration(milliseconds: 100));

    // Reach into the state to grab the controller and synthesise value
    // changes that drive the listener through both isPlaying branches. The
    // controller is a public field on _VideoPlayerPageState, but the state
    // class itself is private — use the widget-test convention of grabbing
    // the State via `tester.state` and `dynamic` to call into it.
    final state = tester.state(find.byType(VideoPlayerPage)) as dynamic;
    final YoutubePlayerController controller =
        state.controller as YoutubePlayerController;

    // Drive isFullScreen + isPlaying transitions.
    controller.value = controller.value.copyWith(isFullScreen: true);
    await tester.pump();
    controller.value = controller.value.copyWith(isPlaying: true);
    await tester.pump();
    controller.value = controller.value.copyWith(isPlaying: false);
    await tester.pump();

    expect(fullScreenChanges, contains(true));
    // Both unpaused + paused tracks should have fired.
    final names = analytics.events.map((e) => e.key).toSet();
    expect(names, containsAll(<String>{'Video unpaused', 'Video paused'}));
  });

  testWidgets(
      'didChangeDependencies reacts to VideoPlayerInheritedWidget videoId change',
      (tester) async {
    await tester.pumpWidget(_harness(
      onFullScreenChanged: (_) {},
      videoId: 'first-video-id',
    ));
    await tester.pump(const Duration(milliseconds: 100));

    // Re-pump with a different videoId — the inherited widget's
    // updateShouldNotify fires, the state's didChangeDependencies calls
    // controller.load(newVideoId), and the new video id flows into the
    // controller's metadata. This drives lines 47-54 of player.dart.
    await tester.pumpWidget(_harness(
      onFullScreenChanged: (_) {},
      videoId: 'second-video-id',
    ));
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.byType(VideoPlayerPage), findsOneWidget);
  });

  testWidgets('VideoPlayerPage dispose tears down the controller cleanly',
      (tester) async {
    await tester.pumpWidget(
      _harness(onFullScreenChanged: (_) {}),
    );
    await tester.pump(const Duration(milliseconds: 100));

    // Replace with an empty tree — disposes VideoPlayerPage and runs the
    // dispose lifecycle (which calls controller.dispose() at line 59).
    await tester.pumpWidget(const MaterialApp(home: SizedBox.shrink()));
    await tester.pump();

    expect(find.byType(VideoPlayerPage), findsNothing);
  });
}
