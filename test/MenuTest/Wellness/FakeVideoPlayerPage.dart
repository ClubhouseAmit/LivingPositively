// test/wellness_tools_test.dart
import 'package:flutter/material.dart';

class FakeVideoPlayerPage extends StatelessWidget {

  const FakeVideoPlayerPage({
    required this.onFullScreenChanged, required this.videoData, super.key,
  });
  final Function(bool) onFullScreenChanged;
  final Map<String, List<String>> videoData;

  @override
  Widget build(BuildContext context) {
    // Simulate a mock video player
    return const ColoredBox(
      color: Colors.grey,
      child: Center(
        child: Text('Mock Video Player'),
      ),
    );
  }
}
