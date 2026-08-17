import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class FeelGoodInheritedWidget extends InheritedWidget {
  final List<String> imagePaths;
  final Function(String source) getImage;
  final Widget Function(String path, {BoxFit fit}) displayImage;
  final Function(int index) deleteImage;
  final Function(int index) rotateImage;
  final int Function(String path) getImageRotation;
  final Map<String, int> imageRotations;

  const FeelGoodInheritedWidget({
    super.key,
    required this.imagePaths,
    required this.getImage,
    required this.deleteImage,
    required this.rotateImage,
    required this.getImageRotation,
    required this.imageRotations,
    required super.child,
    required this.displayImage,
  });

  // Convenience method to access the nearest instance of FeelGoodInheritedWidget
  static FeelGoodInheritedWidget? of(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<FeelGoodInheritedWidget>();
  }

  @override
  bool updateShouldNotify(FeelGoodInheritedWidget oldWidget) {
    return !listEquals(imagePaths, oldWidget.imagePaths) ||
        !mapEquals(imageRotations, oldWidget.imageRotations);
  }
}
