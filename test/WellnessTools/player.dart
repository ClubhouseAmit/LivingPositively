import 'package:flutter/material.dart';

class YoutubePlayerPage extends StatefulWidget {
  const YoutubePlayerPage({
    required this.setBool, required this.controller, super.key,
  });
  final int controller;
  final Function setBool;
  @override
  _YoutubePlayerPageState createState() => _YoutubePlayerPageState();
}

class _YoutubePlayerPageState extends State<YoutubePlayerPage> {
  @override
  @override
  Widget build(BuildContext context) {
    return Container(child: Text(widget.controller.toString()));
  }
}
