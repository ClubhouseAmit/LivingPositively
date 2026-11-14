import 'package:flutter/widgets.dart' hide Text;

import 'package:mazilon/design_system/tokens/button_sizes.dart';
import 'package:mazilon/design_system/tokens/color_tokens.dart';
import 'package:mazilon/design_system/tokens/spacing.dart';
import 'package:mazilon/design_system/widgets/lp_button.dart';
import 'package:mazilon/design_system/widgets/lp_checkbox.dart';
import 'package:mazilon/design_system/widgets/text.dart';

/// The LP-DS list row (Figma component set `List` 96:2245, its `checked` and
/// `to do` looks): a raised card holding a round checkbox, a title, and an
/// optional icon button at the end.
///
/// Checked or to-do is [checked], state rather than a variant, and Figma has
/// one look, so there is no variant enum yet. Tapping anywhere on the card
/// but the icon button toggles it. Figma's `empty state` and `edit` looks are a text entry
/// (placeholder, caret, a send button), a different behavior, so they are
/// not this widget.
class ListRow extends StatelessWidget {
  const ListRow({
    super.key,
    required this.title,
    required this.checked,
    required this.onChanged,
    this.actionIcon,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final bool checked;
  final ValueChanged<bool> onChanged;

  /// The icon of the end button. Figma swaps the icon (screens use
  /// Waveform) but always at `Button-icon` size s, so the row builds the
  /// button itself. Null: no button, same row height.
  final IconData? actionIcon;

  /// What a screen reader announces for the button. Required with
  /// [actionIcon]; release builds fall back to [title].
  final String? actionLabel;

  /// Null shows the button disabled.
  final VoidCallback? onAction;

  // Figma measurements, owned here like Chip's.
  static const radius = 20.0;
  static const border = 0.5;

  /// Figma's one-line row height (12 + a 32 icon button + 12, and its
  /// outer half-pixel strokes). A painted border takes no layout space.
  static const height = 57.0;

  // The content is at least the action's 48 tap target (LpButton.icon), so
  // the padding shrinks to keep the row at Figma's 57, with or without one.
  static const _verticalPadding = (height - LpButtonSizes.minTapTarget) / 2;

  // Brings a wrapped title back to Figma's 12 from the border.
  static const _titleVerticalPadding = AppSpacing.md - _verticalPadding;

  void _toggle() => onChanged(!checked);

  @override
  Widget build(BuildContext context) {
    // In build, not the initializer: check_guidelines' text scan reads an
    // initializer assert as an unclosed method.
    assert(
      actionIcon == null || actionLabel != null,
      'an icon button needs actionLabel for screen readers',
    );
    final AppColorTokens colors = context.colors;
    // On the whole card, so its padding and gaps toggle too. The button's
    // own recognizer wins in its area, enabled or not.
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _toggle,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.surfaceRaised,
          border: Border.all(color: colors.effectHairline, width: border),
          borderRadius: BorderRadius.circular(radius),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: _verticalPadding,
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minHeight: LpButtonSizes.minTapTarget,
            ),
            child: Row(
              children: [
                Expanded(child: _content(colors)),
                if (actionIcon != null) ...[
                  const SizedBox(width: AppSpacing.sm),
                  LpButton.icon(
                    icon: actionIcon!,
                    // Release builds skip the assert; never crash on it.
                    semanticLabel: actionLabel ?? title,
                    onPressed: onAction,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Checkbox and title, read as one checkbox by a screen reader.
  Widget _content(AppColorTokens colors) {
    return Semantics(
      checked: checked,
      enabled: true,
      label: title,
      onTap: _toggle,
      excludeSemantics: true,
      child: Row(
        children: [
          LpCheckbox(
            value: checked,
            onChanged: onChanged,
            semanticLabel: title,
            variant: LpCheckboxVariant.rounded,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.xs,
                vertical: _titleVerticalPadding,
              ),
              child: Text(
                title,
                style: AppTextStyle.figmaBodyLarge,
                color: colors.contentPrimary,
                textAlign: TextAlign.start,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
