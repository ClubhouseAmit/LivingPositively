import 'package:flutter/material.dart';

class FeelGoodInheritedWidget extends InheritedWidget {
  final List<String> imagePaths;
  final Function(String source) getImage;
  final Function(String path, {BoxFit fit}) displayImage;
  final Function(int index) deleteImage;
  final Function(int index) rotateImage;
  final int Function(String path) getImageRotation;

  const FeelGoodInheritedWidget({
    super.key,
    required this.imagePaths,
    required this.getImage,
    required this.deleteImage,
    required this.rotateImage,
    required this.getImageRotation,
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
    if (imagePaths.length != oldWidget.imagePaths.length) {
      return true;
    }
    for (int i = 0; i < imagePaths.length; i++) {
      if (imagePaths[i] != oldWidget.imagePaths[i]) {
        return true;
      }
      if (getImageRotation(imagePaths[i]) !=
          oldWidget.getImageRotation(imagePaths[i])) {
        return true;
      }
    }

    return false;
  }
}
