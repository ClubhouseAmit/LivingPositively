import 'package:flutter/material.dart';

/// Builds a circular action with tooltip, button semantics, and a minimum
/// 48dp tap target. The tap target expands when the visual diameter is larger.
Widget circularActionButton(
  BuildContext context, {
  required String tooltip,
  required VoidCallback onTap,
  IconData? icon,
  Widget? child,
  double diameter = 40,
  double iconSize = 20,
}) {
  assert(
    (icon == null) != (child == null),
    'Provide exactly one of icon or child.',
  );

  final colorScheme = Theme.of(context).colorScheme;
  final tapTargetDiameter = diameter < 48 ? 48.0 : diameter;
  final visual =
      child ??
      CircleAvatar(
        radius: diameter / 2,
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        child: Icon(icon, size: iconSize),
      );

  return Tooltip(
    message: tooltip,
    child: Semantics(
      button: true,
      label: tooltip,
      child: SizedBox(
        width: tapTargetDiameter,
        height: tapTargetDiameter,
        child: Material(
          type: MaterialType.transparency,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onTap,
            child: Center(child: visual),
          ),
        ),
      ),
    ),
  );
}
