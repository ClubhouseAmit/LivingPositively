import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mazilon/pages/WellnessTools/VideoPlayerPageFactory.dart';
import 'package:mazilon/pages/WellnessTools/player.dart';

import '../helpers/widget_test_scaffold.dart';

void main() {
  setUp(() {
    registerTestServices(locale: 'en');
  });

  tearDown(() {
    resetTestServices();
  });

  test('VideoPlayerPageFactoryImpl.create returns a Widget', () {
    final factory = VideoPlayerPageFactoryImpl();
    final widget = factory.create(
      onFullScreenChanged: (_) {},
      videoData: <String, List<String>>{},
    );
    expect(widget, isA<Widget>());
  });

  test('factory implements the abstract VideoPlayerPageFactory interface', () {
    final factory = VideoPlayerPageFactoryImpl();
    expect(factory, isA<VideoPlayerPageFactory>());
  });

  testWidgets('VideoPlayerPage shows unavailable state for empty video list', (
    tester,
  ) async {
    await pumpWithProviders(
      tester,
      VideoPlayerPage(
        onFullScreenChanged: (_) {},
        videoData: const <String, List<String>>{'videoId': <String>[]},
      ),
    );

    expect(find.text('This video is unavailable right now.'), findsOneWidget);
  });
}
