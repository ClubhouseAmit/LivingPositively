import 'package:flutter/material.dart';

// InheritedWidget to manage video state
class VideoPlayerInheritedWidget extends InheritedWidget {
  final String videoId;
  final Function(String newVideoId) changeVideo; // Method to change video

  /// The fullscreen mode requested by the page and its descendants.
  ///
  /// Defaults to `false`, requesting inline player content. This value is the
  /// desired target rather than a reflection of the controller's current
  /// fullscreen state; descendants synchronize with it and report confirmed
  /// transitions through their callbacks.
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
