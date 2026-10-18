import 'package:flutter/material.dart' show Brightness, Theme;
import 'package:flutter/widgets.dart';

/// True when the app theme is dark.
///
/// The one Material import in the LP buttons: dark mode is the user's own
/// setting (on, off or scheduled), applied through `MaterialApp.themeMode`,
/// so the theme is the only place that knows it. With no `Theme` above,
/// `Theme.of` falls back to light, so the buttons still render without
/// Material.
bool lpIsDark(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark;

/// Tap, pressed state, semantics and the minimum tap area shared by
/// `LpButton`, `LpIconButton` and `LpTextButton`.
///
/// [builder] draws the visible button for the current pressed state. The tap
/// area is at least [minTapTarget] square even when the visible
/// button is smaller (Figma sizes s and xs), with the visible part centered.
///
/// `onPressed: null` disables it: taps are ignored and [builder] is never
/// asked for the pressed look.
class LpPressable extends StatefulWidget {
  const LpPressable({
    super.key,
    required this.onPressed,
    required this.semanticLabel,
    required this.builder,
  });

  /// Minimum tap area, whatever the visible size.
  static const minTapTarget = 48.0;

  final VoidCallback? onPressed;

  /// What a screen reader announces. It replaces the visible text, so the
  /// label is not read twice.
  final String semanticLabel;

  final Widget Function(BuildContext context, bool pressed) builder;

  @override
  State<LpPressable> createState() => _LpPressableState();
}

class _LpPressableState extends State<LpPressable> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (!mounted || widget.onPressed == null) return;
    setState(() => _pressed = value);
  }

  void _onTapDown(TapDownDetails _) => _setPressed(true);

  void _onTapUp(TapUpDetails _) => _setPressed(false);

  void _onTapCancel() => _setPressed(false);

  @override
  Widget build(BuildContext context) {
    final bool enabled = widget.onPressed != null;
    return Semantics(
      button: true,
      enabled: enabled,
      label: widget.semanticLabel,
      // excludeSemantics hides the GestureDetector's tap, so re-expose it.
      onTap: widget.onPressed,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onPressed,
        onTapDown: _onTapDown,
        onTapUp: _onTapUp,
        onTapCancel: _onTapCancel,
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minWidth: LpPressable.minTapTarget,
            minHeight: LpPressable.minTapTarget,
          ),
          child: Center(
            widthFactor: 1,
            heightFactor: 1,
            child: widget.builder(context, enabled && _pressed),
          ),
        ),
      ),
    );
  }
}
