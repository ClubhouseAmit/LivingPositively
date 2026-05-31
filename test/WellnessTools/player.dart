import 'package:flutter/material.dart';

class YoutubePlayerPage extends StatefulWidget {
  final int controller;
  final Function setBool;
  const YoutubePlayerPage({
    super.key,
    required this.setBool,
    required this.controller,
  });
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
