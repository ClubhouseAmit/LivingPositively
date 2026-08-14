import 'package:flutter/material.dart';

/// Named font-weight tokens matching the Figma design's own naming
/// (Regular/Medium/SemiBold/Bold), since Flutter's FontWeight only exposes
/// w100-w900 plus `normal` (w400) and `bold` (w700) — no `medium`/`semiBold`.
///
/// Usage:
/// ```dart
/// TextStyle(fontWeight: AppFontWeight.medium)
/// ```
abstract class AppFontWeight {
  static const regular = FontWeight.w400;
  static const medium = FontWeight.w500;
  static const semiBold = FontWeight.w600;
  static const bold = FontWeight.w700;
}
