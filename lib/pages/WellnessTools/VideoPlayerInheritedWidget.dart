import 'package:flutter/material.dart';

// InheritedWidget to manage video state
class VideoPlayerInheritedWidget extends InheritedWidget { // Method to change video

  const VideoPlayerInheritedWidget({
    required this.videoId, required this.changeVideo, required super.child, super.key,
  });
  final String videoId;
  final Function(String newVideoId) changeVideo;

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
