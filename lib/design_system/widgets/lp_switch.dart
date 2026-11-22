import 'package:flutter/widgets.dart';

import 'package:mazilon/design_system/tokens/button_sizes.dart';
import 'package:mazilon/design_system/tokens/color_tokens.dart';

/// The LP-DS on/off switch (Figma component set `Toggle` 88:287, page
/// "Toggle switch" 88:233): a 64×28 pill track with a 38×24 pill knob.
///
/// On is [value] and disabled is a null [onChanged]: state, not variants.
/// On sits the knob at the end, so it mirrors in right-to-left text.
/// [semanticLabel] is required because the switch alone tells a screen
/// reader nothing. The tap area is at least 48 high around the 28 track.
class LpSwitch extends StatelessWidget {
  const LpSwitch({
    super.key,
    required this.value,
    required this.onChanged,
    required this.semanticLabel,
  });

  final bool value;
  final ValueChanged<bool>? onChanged;
  final String semanticLabel;

  // Figma measurements, owned here like LpButtonSizes.
  static const trackWidth = 64.0;
  static const trackHeight = 28.0;
  static const knobWidth = 38.0;
  static const knobHeight = 24.0;
  static const disabledOpacity = 0.5;

  @override
  Widget build(BuildContext context) {
    final ValueChanged<bool>? onChanged = this.onChanged;
    final VoidCallback? toggle = onChanged == null
        ? null
        : () => onChanged(!value);
    return Semantics(
      toggled: value,
      enabled: toggle != null,
      label: semanticLabel,
      onTap: toggle,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: toggle,
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minHeight: LpButtonSizes.minTapTarget,
          ),
          child: Center(
            widthFactor: 1,
            heightFactor: 1,
            child: Opacity(
              opacity: toggle == null ? disabledOpacity : 1,
              child: _track(context.colors, enabled: toggle != null),
            ),
          ),
        ),
      ),
    );
  }

  Widget _track(AppColorTokens colors, {required bool enabled}) {
    // Figma draws off and both disabled looks on surface/sunken.
    final Color fill = enabled && value
        ? colors.accentPrimary
        : colors.surfaceSunken;
    return Container(
      width: trackWidth,
      height: trackHeight,
      alignment: value
          ? AlignmentDirectional.centerEnd
          : AlignmentDirectional.centerStart,
      // The knob's 2px inset is what the track has left over.
      padding: const EdgeInsets.symmetric(
        horizontal: (trackHeight - knobHeight) / 2,
      ),
      decoration: ShapeDecoration(color: fill, shape: const StadiumBorder()),
      child: DecoratedBox(
        decoration: ShapeDecoration(
          color: colors.surfaceWhite,
          shape: const StadiumBorder(),
        ),
        child: const SizedBox(width: knobWidth, height: knobHeight),
      ),
    );
  }
}
