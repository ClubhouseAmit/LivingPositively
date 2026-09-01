// test/wellness_tools_test.dart
import 'package:flutter/material.dart';

class FakeVideoPlayerPage extends StatelessWidget {
  final Function(bool) onFullScreenChanged;
  final Map<String, List<String>> videoData;

  const FakeVideoPlayerPage({
    super.key,
    required this.onFullScreenChanged,
    required this.videoData,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      key: const Key('fake-video-player'),
      child: ColoredBox(
        color: Colors.grey,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              key: const Key('fake-video-player-enter-fullscreen'),
              onPressed: () => onFullScreenChanged(true),
              icon: const Icon(Icons.fullscreen),
            ),
            IconButton(
              key: const Key('fake-video-player-exit-fullscreen'),
              onPressed: () => onFullScreenChanged(false),
              icon: const Icon(Icons.fullscreen_exit),
            ),
          ],
        ),
      ),
    );
  }
}
