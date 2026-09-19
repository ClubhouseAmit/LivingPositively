import 'package:flutter/widgets.dart';

import 'package:mazilon/design_system/primitives/app_text.dart';
import 'package:mazilon/design_system/tokens/colors.dart';
import 'package:mazilon/design_system/tokens/spacing.dart';

/// Which semantic action this button represents.
enum AppButtonVariant {
  /// `AppColors.primary`/`onPrimary` — replaces `ConfirmationButton`.
  primary,

  /// `AppColors.error`/`onError` — replaces `CancelButton`/`ResetButton`.
  destructive,
}

/// Design-system button primitive.
///
/// Built on `GestureDetector` (`widgets.dart`), not `TextButton`: a Material
/// `TextButton` carries ink-splash behavior and a 48px minimum tap target
/// that come from Material's `ButtonStyle`, not from this design. Press
/// feedback here is a plain opacity dip — a deliberate, visible affordance,
/// not Material's ripple, so the same code renders identically on iOS and
/// Android (see the platform-agnostic decision this session made).
///
/// `onPressed: null` disables the button: dimmed, and taps are ignored.
class AppButton extends StatefulWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.fullWidth = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;

  /// Matches `ConfirmationButton`'s full-width behavior by default.
  /// `CancelButton`/`ResetButton`'s width-capping is a screen-layout concern
  /// for the call site, not this primitive — wrap in a `SizedBox`/`Center`.
  final bool fullWidth;

  @override
  State<AppButton> createState() => _AppButtonState();
}

class _AppButtonState extends State<AppButton> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (!mounted || widget.onPressed == null) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final bool enabled = widget.onPressed != null;
    final (Color background, Color foreground) = switch (widget.variant) {
      AppButtonVariant.primary => (AppColors.primary, AppColors.onPrimary),
      AppButtonVariant.destructive => (AppColors.error, AppColors.onError),
    };

    Widget content = AnimatedOpacity(
      duration: const Duration(milliseconds: 100),
      opacity: !enabled
          ? 0.5
          : _pressed
          ? 0.7
          : 1,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(AppRadii.button),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xl,
            vertical: AppSpacing.md,
          ),
          child: Center(
            child: AppText(
              widget.label,
              style: AppTextStyle.labelLarge,
              color: foreground,
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );

    if (widget.fullWidth) {
      content = SizedBox(width: double.infinity, child: content);
    }

    return Semantics(
      button: true,
      enabled: enabled,
      label: widget.label,
      child: GestureDetector(
        onTap: widget.onPressed,
        onTapDown: (_) => _setPressed(true),
        onTapCancel: () => _setPressed(false),
        onTapUp: (_) => _setPressed(false),
        child: content,
      ),
    );
  }
}
