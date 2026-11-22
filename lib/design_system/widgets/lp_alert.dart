import 'package:flutter/widgets.dart' hide Text;

import 'package:mazilon/design_system/tokens/button_sizes.dart';
import 'package:mazilon/design_system/tokens/color_tokens.dart';
import 'package:mazilon/design_system/tokens/spacing.dart';
import 'package:mazilon/design_system/widgets/text.dart';

/// The four looks of Figma `notification-item`, from its `severity`
/// property. Figma's `heb` looks are the same four mirrored; the ambient
/// [Directionality] does that.
enum LpAlertVariant { info, warning, error, success }

/// The LP-DS inline alert (Figma component set `notification-item` 88:1889,
/// page "Notification"): a tinted banner with an icon, a title and a
/// message, and an optional trailing icon (Figma's chevron).
///
/// Beside the old `Alert`, which reads light-only `AppColors` (DESIGN.md §1A).
/// [icon] is a slot: Figma swaps it per severity, and the caller passes the
/// one it wants. Tappable only when [onTap] is set.
class LpAlert extends StatelessWidget {
  const LpAlert({
    super.key,
    required this.icon,
    this.title,
    this.message,
    this.variant = LpAlertVariant.info,
    this.trailingIcon,
    this.onTap,
  });

  final IconData icon;

  /// Figma's `title` (Label/Small). Null hides it, as Figma's `Show title`.
  final String? title;

  /// Figma's `subtitle` (Caption/Small). Null hides it.
  final String? message;

  final LpAlertVariant variant;

  /// Figma's `chevron icon`, hidden by default. Pass a chevron that mirrors
  /// in RTL (its `matchTextDirection`).
  final IconData? trailingIcon;

  final VoidCallback? onTap;

  // Figma measurements, owned here like LpCheckbox's.
  static const radius = 8.0;
  static const iconSize = 16.0;

  ({Color background, Color content}) _colors(AppColorTokens colors) =>
      switch (variant) {
        // Figma draws info text in content/primary; it has no info-content.
        LpAlertVariant.info => (
          background: colors.notificationsInfoBg,
          content: colors.contentPrimary,
        ),
        // Figma paints warning text with error-content and only the chevron
        // with warning-content; warning-content is used throughout until the
        // designer confirms which is meant.
        LpAlertVariant.warning => (
          background: colors.notificationsWarningBg,
          content: colors.notificationsWarningContent,
        ),
        LpAlertVariant.error => (
          background: colors.notificationsErrorBg,
          content: colors.notificationsErrorContent,
        ),
        LpAlertVariant.success => (
          background: colors.notificationsSuccessBg,
          content: colors.notificationsSuccessContent,
        ),
      };

  @override
  Widget build(BuildContext context) {
    // In build, not the initializer: check_guidelines' text scan reads an
    // initializer assert as an unclosed method.
    assert(title != null || message != null, 'an alert needs some text');
    final (:background, :content) = _colors(context.colors);
    final Widget banner = DecoratedBox(
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(radius),
      ),
      child: Padding(
        // Figma's info look has 8 at the end and a 4 gap; the other three
        // have 12 and 8. One layout for all four, the majority's.
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        child: Row(
          children: [
            Expanded(child: _content(content)),
            if (trailingIcon != null) ...[
              const SizedBox(width: AppSpacing.sm),
              ExcludeSemantics(
                child: SizedBox.square(
                  dimension: LpButtonSizes.iconButtonS,
                  child: Icon(
                    trailingIcon,
                    size: LpButtonSizes.iconButtonIconS,
                    color: content,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
    if (onTap == null) return Semantics(container: true, child: banner);
    // One node: the button carries the text, so a screen reader stops once.
    return MergeSemantics(
      child: Semantics(
        button: true,
        onTap: onTap,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          excludeFromSemantics: true,
          onTap: onTap,
          child: banner,
        ),
      ),
    );
  }

  /// Figma `.notification-content`: the icon, then title over message.
  Widget _content(Color color) {
    return MergeSemantics(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ExcludeSemantics(
            child: Icon(icon, size: iconSize, color: color),
          ),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (title != null)
                  Text(
                    title!,
                    style: AppTextStyle.figmaLabelSmall,
                    color: color,
                  ),
                if (title != null && message != null)
                  const SizedBox(height: AppSpacing.xs),
                if (message != null)
                  Text(
                    message!,
                    style: AppTextStyle.figmaCaptionSmall,
                    color: color,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
