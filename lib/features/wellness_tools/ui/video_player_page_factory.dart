// video_player_page_factory.dart
import 'package:flutter/material.dart';
import 'package:mazilon/features/wellness_tools/ui/player.dart';

abstract class VideoPlayerPageFactory {
  Widget create({
    required Function(bool) onFullScreenChanged,
    required Map<String, List<String>> videoData,
  });
}

class VideoPlayerPageFactoryImpl implements VideoPlayerPageFactory {
  @override
  Widget create({
    required Function(bool) onFullScreenChanged,
    required Map<String, List<String>> videoData,
  }) {
    return VideoPlayerPage(
      onFullScreenChanged: onFullScreenChanged,
      videoData: videoData,
    );
  }
}
