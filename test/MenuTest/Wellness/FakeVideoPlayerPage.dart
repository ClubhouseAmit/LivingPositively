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
    // Simulate a mock video player
    return Container(
      color: Colors.grey,
      child: Center(child: Text('Mock Video Player')),
    );
  }
}
