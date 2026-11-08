import 'package:flutter/material.dart' show Brightness, Theme;
import 'package:flutter/widgets.dart';
import 'package:mazilon/design_system/tokens/color_tokens.dart';
import 'package:mazilon/features/shell/ui/app_time_format.dart';

/// `MaterialApp.builder` for every app root: above the navigator, so pages,
/// dialogs and sheets all get the same color tokens and time format.
///
/// The mode is read from the theme `MaterialApp` already resolved from the
/// user's own dark-mode setting, so `main.dart` stays its only source. Set
/// `themeAnimationDuration: Duration.zero` on the app: the tokens switch at
/// once, and an animated theme would fade Material widgets beside them.
Widget appBuilder(BuildContext context, Widget? child) => AppColorScope(
  tokens: Theme.of(context).brightness == Brightness.dark
      ? AppColorTokens.dark
      : AppColorTokens.light,
  child: appTimeFormatBuilder(context, child),
);
