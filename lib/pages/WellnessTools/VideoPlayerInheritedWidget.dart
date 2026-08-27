import 'package:flutter/material.dart';

// InheritedWidget to manage video state
class VideoPlayerInheritedWidget extends InheritedWidget {
  final String videoId;
  final Function(String newVideoId) changeVideo; // Method to change video
  final bool isFullScreen;

  const VideoPlayerInheritedWidget({
    super.key,
    required this.videoId,
    required this.changeVideo,
    this.isFullScreen = false,
    required super.child,
  });

  // Convenience method to access the nearest instance of VideoPlayerInheritedWidget
  static VideoPlayerInheritedWidget? of(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<VideoPlayerInheritedWidget>();
  }

  @override
  bool updateShouldNotify(VideoPlayerInheritedWidget oldWidget) {
    return videoId != oldWidget.videoId ||
        isFullScreen != oldWidget.isFullScreen;
  }
}
