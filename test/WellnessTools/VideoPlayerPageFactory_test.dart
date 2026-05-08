import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mazilon/pages/WellnessTools/VideoPlayerPageFactory.dart';

void main() {
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
}
