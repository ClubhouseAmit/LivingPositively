import 'package:flutter/material.dart';

// InheritedWidget to manage video state
class VideoPlayerInheritedWidget extends InheritedWidget {
  final String videoId;
  final Function(String newVideoId) changeVideo; // Method to change video

  const VideoPlayerInheritedWidget({
    super.key,
    required this.videoId,
    required this.changeVideo,
    required super.child,
  });

  // Convenience method to access the nearest instance of VideoPlayerInheritedWidget
  static VideoPlayerInheritedWidget? of(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<VideoPlayerInheritedWidget>();
  }

  @override
  bool updateShouldNotify(VideoPlayerInheritedWidget oldWidget) {
    return videoId != oldWidget.videoId; // Notify children when videoId changes
  }
}
