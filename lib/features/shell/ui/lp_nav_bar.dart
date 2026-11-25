import 'dart:ui' show ImageFilter;

import 'package:flutter/widgets.dart' hide Text;

import 'package:mazilon/design_system/tokens/button_sizes.dart';
import 'package:mazilon/design_system/tokens/color_tokens.dart';
import 'package:mazilon/design_system/tokens/spacing.dart';
import 'package:mazilon/design_system/widgets/text.dart';

/// One tab of [LpNavBar]: data, not a widget.
class LpNavTab {
  const LpNavTab({required this.icon, required this.label, this.selectedIcon});

  final IconData icon;
  final String label;

  /// Figma swaps to the filled icon on the selected tab; null keeps [icon].
  final IconData? selectedIcon;
}

/// The LP-DS bottom navigation bar (Figma component set `Mobile` 271:84,
/// page "Navigation bar" 137:19): a frosted pill with equal-width tabs.
///
/// The selected tab is [selectedIndex], state rather than a variant: its
/// icon sits in a content/primary 12% pill and its label turns
/// content/primary. Tabs follow the text direction, so the first one is on
/// the right in Hebrew. The bar takes the width it is given; the caller adds
/// the side margin and the safe area below it.
class LpNavBar extends StatelessWidget {
  const LpNavBar({
    super.key,
    required this.tabs,
    required this.selectedIndex,
    required this.onSelected,
  }) : assert(selectedIndex >= 0 && selectedIndex < tabs.length);

  final List<LpNavTab> tabs;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  // Figma measurements, owned here like LpSwitch's.
  static const itemVerticalPadding = 6.0;
  static const iconPillWidth = 56.0;
  static const iconPillHeight = 32.0;
  static const iconSize = 24.0;

  /// Figma's background blur radius is 6.5; a Gaussian sigma is about half.
  static const blurSigma = 3.25;

  static const _shape = StadiumBorder();

  @override
  Widget build(BuildContext context) {
    final AppColorTokens colors = context.colors;
    return ClipPath(
      clipper: const ShapeBorderClipper(shape: _shape),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
        child: DecoratedBox(
          decoration: ShapeDecoration(
            color: colors.surfaceRaisedHighest90,
            shape: StadiumBorder(
              side: BorderSide(color: colors.effectHairline),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.xs,
            ),
            child: Row(
              children: [
                for (int i = 0; i < tabs.length; i++)
                  Expanded(child: _tab(colors, i)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _tab(AppColorTokens colors, int index) {
    final LpNavTab tab = tabs[index];
    final bool selected = index == selectedIndex;
    return Semantics(
      button: true,
      selected: selected,
      label: tab.label,
      onTap: () => onSelected(index),
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => onSelected(index),
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minHeight: LpButtonSizes.minTapTarget,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: itemVerticalPadding),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _iconPill(colors, tab, selected),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  tab.label,
                  style: AppTextStyle.figmaLabelSmall,
                  color: selected
                      ? colors.contentPrimary
                      : colors.contentSecondary,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _iconPill(AppColorTokens colors, LpNavTab tab, bool selected) {
    return DecoratedBox(
      decoration: ShapeDecoration(
        color: selected ? colors.contentPrimary12 : null,
        shape: _shape,
      ),
      child: SizedBox(
        width: iconPillWidth,
        height: iconPillHeight,
        child: Center(
          child: Icon(
            selected ? tab.selectedIcon ?? tab.icon : tab.icon,
            size: iconSize,
            color: colors.contentPrimary,
          ),
        ),
      ),
    );
  }
}
